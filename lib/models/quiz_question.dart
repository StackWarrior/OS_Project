class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'options': options,
        'correctIndex': correctIndex,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
        id: j['id'] as String,
        prompt: j['prompt'] as String,
        options: (j['options'] as List<dynamic>).cast<String>(),
        correctIndex: j['correctIndex'] as int,
      );
}

class QuizSessionResult {
  const QuizSessionResult({
    required this.courseId,
    required this.courseTitle,
    required this.correct,
    required this.total,
    required this.selectedAnswers,
  });

  final String courseId;
  final String courseTitle;
  final int correct;
  final int total;
  /// Per-question index of selected option (-1 if timeout)
  final List<int> selectedAnswers;
}
