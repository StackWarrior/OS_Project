import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../state/shell_controller.dart';
import '../widgets/course_card.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  static const _pageSize = 6;
  int _loaded = _pageSize;
  String _category = 'All';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    final shell = context.read<ShellController>();
    shell.addListener(_onShell);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyShellHints());
  }

  void _onShell() => _applyShellHints();

  void _applyShellHints() {
    final shell = context.read<ShellController>();
    var changed = false;
    shell.consumeCoursesSearch((q) {
      _search.text = q;
      _loaded = _pageSize;
      changed = true;
    });
    shell.consumePendingCategory((c) {
      _category = c;
      _loaded = _pageSize;
      changed = true;
    });
    if (changed && mounted) setState(() {});
  }

  @override
  void dispose() {
    context.read<ShellController>().removeListener(_onShell);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final cats = ['All', ...app.categories];

    final total = app.countCourses(
      categoryQuery: _category,
      search: _search.text,
    );
    final page = app.coursesPage(
      offset: 0,
      limit: _loaded,
      categoryQuery: _category,
      search: _search.text,
    );
    final canLoadMore = _loaded < total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Filter this list…',
              prefixIcon: const Icon(Icons.filter_alt_outlined),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _loaded = _pageSize;
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _loaded = _pageSize;
              });
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = cats[i];
              final selected = _category == c;
              return FilterChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _category = c;
                    _loaded = _pageSize;
                  });
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                '${page.length} of $total courses',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (canLoadMore)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _loaded = (_loaded + _pageSize).clamp(0, total).toInt();
                    });
                  },
                  child: const Text('Load more'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: page.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final course = page[i];
              return CourseCard(
                course: course,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.courseDetail,
                    arguments: course.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
