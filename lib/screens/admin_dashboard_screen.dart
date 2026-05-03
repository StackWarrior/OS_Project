import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              const Text('Admins only.'),
              const SizedBox(height: 12),
              Text(
                'Sign in with an email containing "admin".',
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
        title: const Text('Admin · Courses'),
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
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

  Future<void> _editCourse(BuildContext context, AppState app, Course course) async {
    final title = TextEditingController(text: course.title);
    final desc = TextEditingController(text: course.description);
    final category = TextEditingController(text: course.category);
    final price = TextEditingController(text: course.price.toStringAsFixed(2));
    final duration = TextEditingController(text: course.durationMinutes.toString());
    final thumb = TextEditingController(text: course.thumbnailUrl);
    final video = TextEditingController(text: course.videoUrl);
    var featured = course.featured;

    try {
    final ok = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (ctx) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: StatefulBuilder(
                builder: (context, setModal) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          course.id.startsWith('new-') ? 'Add course' : 'Edit course',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: title,
                          decoration: const InputDecoration(labelText: 'Title'),
                        ),
                        TextField(
                          controller: category,
                          decoration: const InputDecoration(labelText: 'Category'),
                        ),
                        TextField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Price'),
                        ),
                        TextField(
                          controller: duration,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Duration (min)'),
                        ),
                        TextField(
                          controller: thumb,
                          decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                        ),
                        TextField(
                          controller: video,
                          decoration: const InputDecoration(labelText: 'Video URL'),
                        ),
                        TextField(
                          controller: desc,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Description'),
                        ),
                        SwitchListTile(
                          value: featured,
                          title: const Text('Featured'),
                          onChanged: (v) => setModal(() => featured = v),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Save'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ) ??
        false;

    if (!ok || !context.mounted) return;

    final p = double.tryParse(price.text.trim()) ?? course.price;
    final d = int.tryParse(duration.text.trim()) ?? course.durationMinutes;

    await app.upsertCourse(
      course.copyWith(
        title: title.text.trim().isEmpty ? course.title : title.text.trim(),
        description: desc.text.trim().isEmpty ? course.description : desc.text.trim(),
        category: category.text.trim().isEmpty ? course.category : category.text.trim(),
        price: p,
        durationMinutes: d,
        thumbnailUrl: thumb.text.trim().isEmpty ? course.thumbnailUrl : thumb.text.trim(),
        videoUrl: video.text.trim().isEmpty ? course.videoUrl : video.text.trim(),
        featured: featured,
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course saved')),
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
}
