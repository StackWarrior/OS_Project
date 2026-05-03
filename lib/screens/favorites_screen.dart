import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../widgets/course_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEn = app.locale.languageCode == 'en';
    final theme = Theme.of(context);
    final favs = app.courses.where((c) => app.isFavorite(c.id)).toList();

    if (favs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 56, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text(isEn ? 'No favorites' : 'لا توجد مفضلات', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                isEn 
                  ? 'Tap the heart on a course to save it for later.'
                  : 'اضغط على القلب في الدورة التدريبية لحفظها لاحقًا.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: favs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final course = favs[i];
        return CourseCard(
          course: course,
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.courseDetail,
              arguments: course.id,
            );
          },
          trailing: IconButton(
            tooltip: isEn ? 'Remove' : 'إزالة',
            onPressed: () => app.toggleFavorite(course.id),
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
          ),
        );
      },
    );
  }
}
