import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz_question.dart';
import '../routes/app_routes.dart';
import '../state/app_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _qIndex = 0;
  int? _selected;
  late List<int> _answers;
  Timer? _timer;
  int _secondsLeft = 25;
  static const _perQuestionSeconds = 25;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final course = app.courseById(widget.courseId);
    _answers = List<int>.filled(course?.quiz.length ?? 0, -1);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _perQuestionSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _advance(auto: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _advance({bool auto = false}) {
    _timer?.cancel();
    final app = context.read<AppState>();
    final course = app.courseById(widget.courseId);
    if (course == null) return;

    final sel = _selected;
    _answers[_qIndex] = sel ?? -1;

    if (_qIndex >= course.quiz.length - 1) {
      _finish(course.quiz, course.title);
      return;
    }

    setState(() {
      _qIndex++;
      _selected = null;
    });
    _startTimer();
  }

  void _finish(List<QuizQuestion> questions, String title) {
    _timer?.cancel();
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      final a = _answers[i];
      if (a >= 0 && a == questions[i].correctIndex) correct++;
    }
    final result = QuizSessionResult(
      courseId: widget.courseId,
      courseTitle: title,
      correct: correct,
      total: questions.length,
      selectedAnswers: List<int>.from(_answers),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.quizResult,
      arguments: result,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final course = app.courseById(widget.courseId);
    final theme = Theme.of(context);

    if (course == null || course.quiz.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go back'),
          ),
        ),
      );
    }

    final q = course.quiz[_qIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz · ${_qIndex + 1}/${course.quiz.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.timer, size: 18),
              label: Text('$_secondsLeft s'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(q.prompt, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ...List.generate(q.options.length, (i) {
            final selected = _selected == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RadioListTile<int>(
                value: i,
                groupValue: _selected,
                onChanged: (v) {
                  setState(() => _selected = v);
                },
                title: Text(q.options[i]),
                tileColor: selected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                    : theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_qIndex > 0)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _qIndex--;
                      _selected = _answers[_qIndex] >= 0 ? _answers[_qIndex] : null;
                    });
                    _startTimer();
                  },
                  child: const Text('Previous'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (_selected == null && _answers[_qIndex] < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select an answer or wait for timeout')),
                    );
                    return;
                  }
                  _advance();
                },
                child: Text(_qIndex >= course.quiz.length - 1 ? 'Finish' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
