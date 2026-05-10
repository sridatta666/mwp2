class Exercise {
  final String id;
  final String title;
  final String? description;
  final String? bunnyVideoId;
  final String? instructions;
  final String? muscleGroup;

  Exercise({
    required this.id,
    required this.title,
    this.description,
    this.bunnyVideoId,
    this.instructions,
    this.muscleGroup,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      bunnyVideoId: json['bunny_video_id'],
      instructions: json['instructions'],
      muscleGroup: json['muscle_group'],
    );
  }
}
