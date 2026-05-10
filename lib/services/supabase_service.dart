import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program.dart';
import '../models/workout.dart';
import '../models/workout_block.dart';
import '../models/exercise.dart';

import '../models/user_stats.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all programs
  Future<List<Program>> getPrograms() async {
    final response = await _client.from('programs').select().order('created_at');
    return (response as List).map((e) => Program.fromJson(e)).toList();
  }

  // Fetch workouts for a program
  Future<List<Workout>> getWorkoutsForProgram(String programId) async {
    final response = await _client
        .from('workouts')
        .select()
        .eq('program_id', programId)
        .order('order_index');
    return (response as List).map((e) => Workout.fromJson(e)).toList();
  }

  // Fetch a complete workout with blocks and exercises
  Future<List<WorkoutBlock>> getWorkoutDetails(String workoutId) async {
    final response = await _client
        .from('workout_blocks')
        .select('''
          *,
          workout_exercises (
            *,
            exercises (*)
          )
        ''')
        .eq('workout_id', workoutId)
        .order('order_index');
        
    return (response as List).map((e) => WorkoutBlock.fromJson(e)).toList();
  }

  // Fetch all exercises for the library
  Future<List<Exercise>> getExercises() async {
    final response = await _client.from('exercises').select().order('title');
    return (response as List).map((e) => Exercise.fromJson(e)).toList();
  }

  // Fetch ALL workouts (for admin picker)
  Future<List<Workout>> getAllWorkouts() async {
    final response = await _client.from('workouts').select().order('title');
    return (response as List).map((e) => Workout.fromJson(e)).toList();
  }

  // Fetch blocks for a workout (for admin picker)
  Future<List<WorkoutBlock>> getBlocksForWorkout(String workoutId) async {
    final response = await _client
        .from('workout_blocks')
        .select()
        .eq('workout_id', workoutId)
        .order('order_index');
    return (response as List).map((e) => WorkoutBlock.fromJson(e)).toList();
  }

  // Log a completed workout
  Future<void> logWorkout(String workoutId, int durationSeconds) async {
    final user = _client.auth.currentUser;
    if (user == null) return; // Must be logged in

    await _client.from('user_progress').insert({
      'user_id': user.id,
      'workout_id': workoutId,
      'duration_seconds': durationSeconds,
    });
  }

  // Fetch and calculate user stats
  Future<UserStats> getUserStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return UserStats.empty();

    final response = await _client
        .from('user_progress')
        .select('completed_at, duration_seconds')
        .eq('user_id', user.id)
        .order('completed_at', ascending: false);

    final List data = response as List;
    if (data.isEmpty) return UserStats.empty();

    int totalDuration = 0;
    Set<String> uniqueDays = {};

    for (var row in data) {
      totalDuration += (row['duration_seconds'] as num?)?.toInt() ?? 0;
      final dateStr = row['completed_at'] as String?;
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        uniqueDays.add('${date.year}-${date.month}-${date.day}');
      }
    }

    // A simple streak calculator
    int streak = 0;
    DateTime checkDate = DateTime.now();
    while (uniqueDays.contains('${checkDate.year}-${checkDate.month}-${checkDate.day}')) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    // If they haven't worked out today, maybe they worked out yesterday
    if (streak == 0) {
      checkDate = DateTime.now().subtract(const Duration(days: 1));
      while (uniqueDays.contains('${checkDate.year}-${checkDate.month}-${checkDate.day}')) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    return UserStats(
      totalWorkouts: data.length,
      activeDays: uniqueDays.length,
      totalDurationSeconds: totalDuration,
      currentStreak: streak,
    );
  }

  // ADMIN METHODS ==============================================

  Future<void> createProgram({
    required String title,
    required String description,
    required String coverImageUrl,
    required String difficultyLevel,
    required int durationWeeks,
  }) async {
    await _client.from('programs').insert({
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
      'difficulty_level': difficultyLevel,
      'duration_weeks': durationWeeks,
    });
  }

  Future<void> createExercise({
    required String title,
    required String description,
    required String instructions,
    required String videoUrl,
    String? muscleGroup,
  }) async {
    await _client.from('exercises').insert({
      'title': title,
      'description': description,
      'instructions': instructions,
      'bunny_video_id': videoUrl,
      'muscle_group': muscleGroup ?? 'full_body',
    });
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _client.from('exercises').delete().eq('id', exerciseId);
  }

  Future<void> deleteProgram(String programId) async {
    await _client.from('programs').delete().eq('id', programId);
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _client.from('workouts').delete().eq('id', workoutId);
  }

  Future<void> deleteWorkoutBlock(String blockId) async {
    await _client.from('workout_blocks').delete().eq('id', blockId);
  }

  Future<void> deleteWorkoutExercise(String id) async {
    await _client.from('workout_exercises').delete().eq('id', id);
  }

  Future<void> updateProgram(String id, Map<String, dynamic> data) async {
    await _client.from('programs').update(data).eq('id', id);
  }

  Future<void> updateWorkout(String id, Map<String, dynamic> data) async {
    await _client.from('workouts').update(data).eq('id', id);
  }

  Future<void> createWorkout({
    required String programId,
    required String title,
    required String description,
    required int orderIndex,
  }) async {
    await _client.from('workouts').insert({
      'program_id': programId,
      'title': title,
      'description': description,
      'order_index': orderIndex,
    });
  }

  Future<void> createWorkoutBlock({
    required String workoutId,
    required String title,
    required String blockType,
    required int orderIndex,
    int rounds = 1,
  }) async {
    await _client.from('workout_blocks').insert({
      'workout_id': workoutId,
      'title': title,
      'block_type': blockType,
      'order_index': orderIndex,
      'rounds': rounds,
    });
  }

  Future<void> addExerciseToBlock({
    required String blockId,
    required String exerciseId,
    required int orderIndex,
    int? reps,
    int? sets,
    int? durationSeconds,
    int? restSeconds,
  }) async {
    await _client.from('workout_exercises').insert({
      'block_id': blockId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'reps': reps,
      'sets': sets,
      'duration_seconds': durationSeconds,
      'rest_seconds': restSeconds,
    });
  }

  // PROGRESS TRACKING ==========================================

  /// Returns daily workout data for the last N days
  Future<List<Map<String, dynamic>>> getWeeklyProgress({int days = 7}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final response = await _client
        .from('user_progress')
        .select('completed_at, duration_seconds')
        .eq('user_id', user.id)
        .gte('completed_at', since)
        .order('completed_at');

    return (response as List).cast<Map<String, dynamic>>();
  }
}
