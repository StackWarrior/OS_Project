import 'quiz_question.dart';

class Course {
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.durationMinutes,
    required this.quiz,
    this.featured = false,
  });

  final String id;
  String title;
  String description;
  String category;
  double price;
  String thumbnailUrl;
  String videoUrl;
  int durationMinutes;
  List<QuizQuestion> quiz;
  bool featured;

  Course copyWith({
    String? title,
    String? description,
    String? category,
    double? price,
    String? thumbnailUrl,
    String? videoUrl,
    int? durationMinutes,
    List<QuizQuestion>? quiz,
    bool? featured,
  }) {
    return Course(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quiz: quiz ?? List<QuizQuestion>.from(this.quiz),
      featured: featured ?? this.featured,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'thumbnailUrl': thumbnailUrl,
        'videoUrl': videoUrl,
        'durationMinutes': durationMinutes,
        'quiz': quiz.map((q) => q.toJson()).toList(),
        'featured': featured,
      };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Untitled Course',
        description: j['description']?.toString() ?? '',
        category: j['category']?.toString() ?? 'General',
        price: (j['price'] as num?)?.toDouble() ?? 0.0,
        thumbnailUrl: j['thumbnailUrl']?.toString() ?? '',
        videoUrl: j['videoUrl']?.toString() ?? '',
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        quiz: (j['quiz'] as List?)
                ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        featured: j['featured'] as bool? ?? false,
      );
}
