import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../data/seed_data.dart';
import '../models/course.dart';
import '../models/quiz_question.dart';
import '../state/app_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.currentUser;
    final theme = Theme.of(context);

    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Admin Access Only'),
              const SizedBox(height: 12),
              Text(
                'Only authorized administrators can access this dashboard.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final courses = app.courses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin · Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Reload seed (demo)',
            onPressed: () async {
              final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset catalog?'),
                      content: const Text(
                        'This replaces the in-app catalog with the built-in seed list.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok || !context.mounted) return;
              for (final c in List<Course>.from(app.courses)) {
                await app.deleteCourse(c.id);
              }
              for (final c in buildSeedCourses()) {
                await app.upsertCourse(c);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catalog reset to seed data')),
                );
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Stats', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile(context, 'Revenue', '\$${app.totalRevenue.toStringAsFixed(0)}', Icons.payments_outlined, Colors.green),
                const SizedBox(width: 12),
                _buildStatTile(context, 'Users', '${app.totalUsersCount}', Icons.people_outline, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile(context, 'Courses', '${courses.length}', Icons.menu_book_outlined, Colors.orange),
                const SizedBox(width: 12),
                _buildStatTile(context, 'Featured', '${app.featuredCoursesCount}', Icons.star_outline, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Course Catalog', style: theme.textTheme.titleMedium),
                Text('${courses.length} courses', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = courses[i];
                return Card(
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        c.thumbnailUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                      ),
                    ),
                    title: Text(c.title),
                    subtitle: Text('${c.category} · \$${c.price.toStringAsFixed(2)}'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        if (c.featured)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCourse(context, app, c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final del = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete course?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (del) await app.deleteCourse(c.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () => _editCourse(context, app, c),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCourse(
          context,
          app,
          Course(
            id: 'new-${DateTime.now().millisecondsSinceEpoch}',
            title: 'New course',
            description: 'Describe outcomes, prerequisites, and projects.',
            category: 'Mobile',
            price: 19.99,
            thumbnailUrl: 'https://picsum.photos/seed/newcourse/800/480',
            videoUrl: kDemoVideoUrl,
            durationMinutes: 120,
            featured: false,
            quiz: [
              QuizQuestion(
                id: 'nq1',
                prompt: 'Sample question?',
                options: const ['A', 'B', 'C', 'D'],
                correctIndex: 0,
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCourse(BuildContext context, AppState app, Course course) async {
    final title = TextEditingController(text: course.title);
    final desc = TextEditingController(text: course.description);
    final category = TextEditingController(text: course.category);
    final price = TextEditingController(text: course.price.toStringAsFixed(2));
    final duration = TextEditingController(text: course.durationMinutes.toString());
    final thumb = TextEditingController(text: course.thumbnailUrl);
    final video = TextEditingController(text: course.videoUrl);
    var featured = course.featured;

    final formKey = GlobalKey<FormState>();
    bool isUploading = false;
    double? uploadProgress;

    Future<void> pickAndUpload(StateSetter setModal, bool isVideo) async {
      final picker = ImagePicker();
      final XFile? file = isVideo 
          ? await picker.pickVideo(source: ImageSource.gallery) 
          : await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (file == null) return;

      setModal(() {
        isUploading = true;
        uploadProgress = 0.0;
      });

      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final destination = isVideo ? 'courses/videos/$fileName' : 'courses/thumbnails/$fileName';
        final ref = FirebaseStorage.instance.ref().child(destination);

        final metadata = SettableMetadata(
          contentType: isVideo ? 'video/mp4' : 'image/jpeg',
        );

        final uploadTask = ref.putFile(File(file.path), metadata);
        
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.state == TaskState.running) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            setModal(() => uploadProgress = progress);
          }
        });

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();

        setModal(() {
          if (isVideo) {
            video.text = url;
          } else {
            thumb.text = url;
          }
          isUploading = false;
          uploadProgress = null;
        });
      } catch (e) {
        setModal(() {
          isUploading = false;
          uploadProgress = null;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }

    try {
      final ok = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            builder: (ctx) {
              return StatefulBuilder(
                builder: (context, setModal) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Form(
                          key: formKey,
                          child: Stack(
                            children: [
                              ListView(
                                controller: scrollController,
                                children: [
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.outlineVariant,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    course.id.startsWith('new-') ? 'Create New Course' : 'Edit Course Details',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 24),

                                  Text('General Information', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: title,
                                    decoration: _inputDecoration('Course Title', Icons.title),
                                    validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: category,
                                    decoration: _inputDecoration('Category', Icons.category_outlined),
                                    validator: (v) => v == null || v.isEmpty ? 'Category is required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: desc,
                                    maxLines: 3,
                                    decoration: _inputDecoration('Description', Icons.description_outlined),
                                    validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                                  ),
                                  const SizedBox(height: 32),

                                  // Media Section Header
                                  Text('Media Assets', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                                  const SizedBox(height: 16),

                                  // Thumbnail Upload Area
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => pickAndUpload(setModal, false),
                                              child: Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.surface,
                                                  borderRadius: BorderRadius.circular(12),
                                                  image: thumb.text.isNotEmpty
                                                      ? DecorationImage(image: NetworkImage(thumb.text), fit: BoxFit.cover)
                                                      : null,
                                                ),
                                                child: thumb.text.isEmpty ? const Icon(Icons.add_a_photo_outlined) : null,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Course Thumbnail', style: Theme.of(context).textTheme.labelLarge),
                                                  const Text('JPG or PNG, recommended 800x480', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                  const SizedBox(height: 8),
                                                  FilledButton.tonalIcon(
                                                    onPressed: () => pickAndUpload(setModal, false),
                                                    icon: const Icon(Icons.upload, size: 18),
                                                    label: const Text('Upload Image'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: thumb,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: _inputDecoration('Thumbnail URL', Icons.link).copyWith(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (_) => setModal(() {}),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Video Upload Area
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surface,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  video.text.isNotEmpty ? Icons.play_circle_fill : Icons.video_library_outlined,
                                                  color: video.text.isNotEmpty ? Theme.of(context).colorScheme.primary : null,
                                                  size: 32,
                                                ),
                                                onPressed: video.text.isEmpty ? null : () => _previewVideo(context, video.text),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Promo Video', style: Theme.of(context).textTheme.labelLarge),
                                                  const Text('MP4 format, max 50MB', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                                  const SizedBox(height: 8),
                                                  FilledButton.tonalIcon(
                                                    onPressed: () => pickAndUpload(setModal, true),
                                                    icon: const Icon(Icons.video_call, size: 18),
                                                    label: const Text('Upload Video'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextFormField(
                                          controller: video,
                                          style: const TextStyle(fontSize: 12),
                                          decoration: _inputDecoration('Video URL', Icons.link).copyWith(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          onChanged: (_) => setModal(() {}),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),
                                  Text('Pricing & Duration', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: price,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration('Price', Icons.attach_money),
                                          validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: duration,
                                          keyboardType: TextInputType.number,
                                          decoration: _inputDecoration('Duration (min)', Icons.timer_outlined),
                                          validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: featured,
                                    title: const Text('Featured Course'),
                                    subtitle: const Text('Highlight this course on the home screen'),
                                    activeThumbColor: Theme.of(context).colorScheme.primary,
                                    onChanged: (v) => setModal(() => featured = v),
                                  ),

                                  const SizedBox(height: 32),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: isUploading
                                        ? null
                                        : () {
                                            if (formKey.currentState?.validate() ?? false) {
                                              Navigator.pop(ctx, true);
                                            }
                                          },
                                    icon: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                                    label: Text(isUploading ? 'Uploading...' : 'Save Changes'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                              if (isUploading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            value: uploadProgress,
                                            strokeWidth: 6,
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'Uploading Media...',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          if (uploadProgress != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              '${(uploadProgress! * 100).toStringAsFixed(0)}%',
                                              style: Theme.of(context).textTheme.bodyLarge,
                                            ),
                                          ],
                                          const SizedBox(height: 32),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 48),
                                            child: LinearProgressIndicator(
                                              value: uploadProgress,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ) ??
          false;

      if (!ok || !context.mounted) return;

      final p = double.tryParse(price.text.trim()) ?? course.price;
      final d = int.tryParse(duration.text.trim()) ?? course.durationMinutes;

      await app.upsertCourse(
        course.copyWith(
          title: title.text.trim(),
          description: desc.text.trim(),
          category: category.text.trim(),
          price: p,
          durationMinutes: d,
          thumbnailUrl: thumb.text.trim(),
          videoUrl: video.text.trim(),
          featured: featured,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Course updated successfully'),
          ),
        );
      }
    } finally {
      title.dispose();
      desc.dispose();
      category.dispose();
      price.dispose();
      duration.dispose();
      thumb.dispose();
      video.dispose();
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _previewVideo(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => _VideoPreviewDialog(url: url),
    );
  }
}

class _VideoPreviewDialog extends StatefulWidget {
  final String url;
  const _VideoPreviewDialog({required this.url});

  @override
  State<_VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<_VideoPreviewDialog> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        aspectRatio: controller.value.aspectRatio,
      );
      if (mounted) {
        setState(() {
          _video = controller;
          _chewie = chewie;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Video Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          else if (_chewie != null)
            AspectRatio(
              aspectRatio: _video!.value.aspectRatio,
              child: Chewie(controller: _chewie!),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
