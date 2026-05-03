import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  Timer? _progressTimer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final app = context.read<AppState>();
    final course = app.courseById(widget.courseId);
    if (course == null) {
      setState(() {
        _loading = false;
        _error = 'Course not found';
      });
      return;
    }
    if (!app.isPurchased(course.id)) {
      setState(() {
        _loading = false;
        _error = 'Purchase this course to watch lessons.';
      });
      return;
    }

    final uri = Uri.parse(course.videoUrl);
    final controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller.initialize();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load video. Check your connection.';
      });
      return;
    }

    final resume = app.progressFor(course.id);
    if (resume > 0) {
      await controller.seekTo(Duration(seconds: resume));
    }

    if (!mounted) return;

    final chewie = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        handleColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.grey.shade400,
      ),
    );

    setState(() {
      _video = controller;
      _chewie = chewie;
      _loading = false;
    });

    _progressTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final v = _video;
      if (v == null || !v.value.isInitialized) return;
      final sec = v.value.position.inSeconds;
      await context.read<AppState>().setVideoProgress(course.id, sec);
    });
  }

  Future<void> _saveProgressNow() async {
    final v = _video;
    final courseId = widget.courseId;
    if (v != null && v.value.isInitialized) {
      await context.read<AppState>().setVideoProgress(
            courseId,
            v.value.position.inSeconds,
          );
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final course = app.courseById(widget.courseId);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveProgressNow();
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(course?.title ?? 'Lesson'),
          actions: [
            TextButton(
              onPressed: () async {
                await _saveProgressNow();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress saved. You can resume anytime.')),
                );
              },
              child: const Text('Save'),
            ),
            IconButton(
              tooltip: 'Take quiz',
              onPressed: course == null
                  ? null
                  : () async {
                      await _saveProgressNow();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamed(
                        AppRoutes.quiz,
                        arguments: course.id,
                      );
                    },
              icon: const Icon(Icons.fact_check),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Go back'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (course != null && app.progressFor(course.id) > 0)
                        ListTile(
                          tileColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                          leading: const Icon(Icons.history),
                          title: Text(
                            'Resume: ${Duration(seconds: app.progressFor(course.id)).toString().split('.').first}',
                          ),
                          subtitle: const Text('Progress is saved automatically every few seconds.'),
                        ),
                      Expanded(
                        child: Center(
                          child: _chewie != null
                              ? Chewie(controller: _chewie!)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
