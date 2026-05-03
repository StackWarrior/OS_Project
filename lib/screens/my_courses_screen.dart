import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../state/shell_controller.dart';
import '../widgets/course_card.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final owned = app.courses.where((c) => app.isPurchased(c.id)).toList();

    if (owned.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_outlined, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(
                'No purchases yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Browse the catalog and enroll to see your library here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<ShellController>().goToTab(1),
                child: const Text('Browse courses'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: owned.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final course = owned[i];
        final sec = app.progressFor(course.id);
        final hasProgress = sec > 0;
        return CourseCard(
          course: course,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.courseDetail,
              arguments: course.id,
            );
          },
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.videoPlayer,
                    arguments: course.id,
                  );
                },
                child: Text(hasProgress ? 'Continue' : 'Start'),
              ),
              if (hasProgress)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${Duration(seconds: sec).toString().split('.').first} watched',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
