class Program {
  final String id;
  final String title;
  final String? description;
  final String? difficultyLevel;
  final String? coverImageUrl;
  final int? durationWeeks;

  Program({
    required this.id,
    required this.title,
    this.description,
    this.difficultyLevel,
    this.coverImageUrl,
    this.durationWeeks,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficultyLevel: json['difficulty_level'],
      coverImageUrl: json['cover_image_url'],
      durationWeeks: json['duration_weeks'],
    );
  }
}
