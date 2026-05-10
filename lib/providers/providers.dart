import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../models/program.dart';
import '../models/workout.dart';
import '../models/workout_block.dart';
import '../models/exercise.dart';
import '../models/user_stats.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final programsProvider = FutureProvider<List<Program>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getPrograms();
});

final workoutsProvider = FutureProvider.family<List<Workout>, String>((ref, programId) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getWorkoutsForProgram(programId);
});

final workoutDetailsProvider = FutureProvider.family<List<WorkoutBlock>, String>((ref, workoutId) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getWorkoutDetails(workoutId);
});

final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getExercises();
});

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getUserStats();
});

final allWorkoutsProvider = FutureProvider<List<Workout>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getAllWorkouts();
});

final workoutBlocksProvider = FutureProvider.family<List<WorkoutBlock>, String>((ref, workoutId) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getBlocksForWorkout(workoutId);
});

final weeklyProgressProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return await service.getWeeklyProgress(days: 7);
});
