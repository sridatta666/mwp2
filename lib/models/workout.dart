class Workout {
  final String id;
  final String programId;
  final String title;
  final String? description;
  final int orderIndex;

  Workout({
    required this.id,
    required this.programId,
    required this.title,
    this.description,
    required this.orderIndex,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      programId: json['program_id'],
      title: json['title'],
      description: json['description'],
      orderIndex: json['order_index'],
    );
  }
}
