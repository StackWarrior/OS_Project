import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz_question.dart';
import '../routes/app_routes.dart';
import '../state/app_state.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key, required this.result});

  final QuizSessionResult result;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEn = app.locale.languageCode == 'en';
    final course = app.courseById(result.courseId);
    final theme = Theme.of(context);
    final pct = result.total == 0 ? 0 : (100 * result.correct / result.total).round();

    return Scaffold(
      appBar: AppBar(title: Text(isEn ? 'Quiz results' : 'نتائج الاختبار')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            result.courseTitle,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: result.total == 0 ? 0 : result.correct / result.total,
                          strokeWidth: 10,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                        Center(
                          child: Text(
                            '$pct%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Score' : 'النتيجة',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          isEn
                              ? '${result.correct} / ${result.total} correct'
                              : '${result.correct} / ${result.total} إجابة صحيحة',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEn
                              ? (pct >= 70 ? 'Great job — keep building momentum.' : 'Review the lesson and try again anytime.')
                              : (pct >= 70 ? 'عمل رائع - استمر في التقدم.' : 'راجع الدرس وحاول مرة أخرى في أي وقت.'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(isEn ? 'Review' : 'مراجعة', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (course == null)
            Text(isEn ? 'Course unavailable.' : 'الدورة غير متوفرة.')
          else
            ...List.generate(course.quiz.length, (i) {
              final q = course.quiz[i];
              final picked = i < result.selectedAnswers.length ? result.selectedAnswers[i] : -1;
              final ok = picked == q.correctIndex;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    ok ? Icons.check_circle : Icons.cancel,
                    color: ok ? Colors.green : theme.colorScheme.error,
                  ),
                  title: Text(q.prompt, maxLines: 3, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    picked < 0
                        ? (isEn ? 'No answer (timeout)' : 'لا توجد إجابة (انتهى الوقت)')
                        : (isEn ? 'Your answer: ${q.options[picked]}' : 'إجابتك: ${q.options[picked]}'),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: course == null ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(isEn ? 'Back to course' : 'العودة للدورة'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.quiz,
                arguments: result.courseId,
              );
            },
            icon: const Icon(Icons.replay),
            label: Text(isEn ? 'Retry quiz' : 'إعادة الاختبار'),
          ),
        ],
      ),
    );
  }
}
