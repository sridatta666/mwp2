import 'package:mwp2/models/exercise.dart'; // We'll fix package name later

class WorkoutBlock {
  final String id;
  final String workoutId;
  final String title;
  final String blockType; // warmup, circuit, cooldown
  final int orderIndex;
  final int rounds;
  final List<WorkoutExercise> exercises;

  WorkoutBlock({
    required this.id,
    required this.workoutId,
    required this.title,
    required this.blockType,
    required this.orderIndex,
    required this.rounds,
    this.exercises = const [],
  });

  factory WorkoutBlock.fromJson(Map<String, dynamic> json) {
    return WorkoutBlock(
      id: json['id'],
      workoutId: json['workout_id'],
      title: json['title'],
      blockType: json['block_type'],
      orderIndex: json['order_index'],
      rounds: json['rounds'] ?? 1,
      exercises: json['workout_exercises'] != null 
          ? (json['workout_exercises'] as List).map((e) => WorkoutExercise.fromJson(e)).toList() 
          : [],
    );
  }
}

class WorkoutExercise {
  final String id;
  final String blockId;
  final String exerciseId;
  final int? reps;
  final int? sets;
  final int? durationSeconds;
  final int? restSeconds;
  final int orderIndex;
  
  // Populated relation
  Exercise? exercise;

  WorkoutExercise({
    required this.id,
    required this.blockId,
    required this.exerciseId,
    this.reps,
    this.sets,
    this.durationSeconds,
    this.restSeconds,
    required this.orderIndex,
    this.exercise,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'],
      blockId: json['block_id'],
      exerciseId: json['exercise_id'],
      reps: json['reps'],
      sets: json['sets'],
      durationSeconds: json['duration_seconds'],
      restSeconds: json['rest_seconds'],
      orderIndex: json['order_index'],
      exercise: json['exercises'] != null ? Exercise.fromJson(json['exercises']) : null,
    );
  }
}
