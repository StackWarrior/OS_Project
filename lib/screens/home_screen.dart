import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../state/shell_controller.dart';
import '../widgets/course_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final featured = app.courses.where((c) => c.featured).toList();
    final categories = app.categories;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${app.currentUser?.name ?? 'Learner'}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What do you want to learn today?',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _search,
                  onSubmitted: (q) {
                    context.read<ShellController>().goToTab(
                          1,
                          coursesSearch: q,
                        );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search courses, topics, categories…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        context.read<ShellController>().goToTab(
                              1,
                              coursesSearch: _search.text,
                            );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.read<ShellController>().goToTab(1);
                      },
                      child: const Text('Browse all'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      return FilledButton.tonal(
                        onPressed: () {
                          context.read<ShellController>().goToTab(
                                1,
                                category: c,
                              );
                        },
                        child: Text(c),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Featured courses',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Open favorites',
                      onPressed: () => context.read<ShellController>().goToTab(3),
                      icon: const Icon(Icons.favorite_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 360,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final course = featured[i];
                return SizedBox(
                  width: 300,
                  child: CourseCard(
                    course: course,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.courseDetail,
                        arguments: course.id,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}
