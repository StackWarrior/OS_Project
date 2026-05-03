import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final course = app.courseById(courseId);
    final theme = Theme.of(context);

    if (course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Course not found.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final purchased = app.isPurchased(course.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Toggle favorite',
                onPressed: () async {
                  await app.toggleFavorite(course.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          app.isFavorite(course.id)
                              ? 'Saved to favorites'
                              : 'Removed from favorites',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  app.isFavorite(course.id) ? Icons.favorite : Icons.favorite_border,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(course.category)),
                      Chip(
                        avatar: const Icon(Icons.timer, size: 18),
                        label: Text('${course.durationMinutes} min'),
                      ),
                      Chip(
                        avatar: const Icon(Icons.quiz, size: 18),
                        label: Text('${course.quiz.length} quiz questions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About this course',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        '\$${course.price.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      if (purchased)
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.videoPlayer,
                              arguments: course.id,
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Continue'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (!purchased)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.checkout,
                          arguments: course.id,
                        );
                      },
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: const Text('Enroll / Buy'),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.videoPlayer,
                          arguments: course.id,
                        );
                      },
                      icon: const Icon(Icons.play_circle),
                      label: const Text('Watch lessons'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.quiz,
                          arguments: course.id,
                        );
                      },
                      icon: const Icon(Icons.fact_check),
                      label: const Text('Take quiz'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
