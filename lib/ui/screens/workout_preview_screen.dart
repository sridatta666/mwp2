import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/workout.dart';
import '../../providers/providers.dart';
import 'workout_player_screen.dart';

class WorkoutPreviewScreen extends ConsumerWidget {
  final Workout workout;

  const WorkoutPreviewScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(workoutDetailsProvider(workout.id));
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                workout.title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 20),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary.withValues(alpha: 0.3), Colors.black],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.fitness_center, size: 64, color: primary.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),

          // Workout description
          if (workout.description != null && workout.description!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  workout.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ),
              ),
            ),

          detailsAsync.when(
            data: (blocks) {
              if (blocks.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No exercises in this workout.', style: TextStyle(color: Colors.grey))),
                );
              }

              // Calculate summary
              int totalExercises = 0;
              int estimatedMinutes = 0;
              for (final block in blocks) {
                totalExercises += block.exercises.length;
                for (final ex in block.exercises) {
                  estimatedMinutes += ((ex.durationSeconds ?? 45) + (ex.restSeconds ?? 15));
                }
                estimatedMinutes *= block.rounds;
              }
              estimatedMinutes = estimatedMinutes ~/ 60;
              if (estimatedMinutes < 1) estimatedMinutes = 1;

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Summary chips
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        _buildChip(context, Icons.layers, '${blocks.length} Blocks'),
                        const SizedBox(width: 12),
                        _buildChip(context, Icons.fitness_center, '$totalExercises Exercises'),
                        const SizedBox(width: 12),
                        _buildChip(context, Icons.timer, '~${estimatedMinutes}m'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Blocks and exercises
                  ...blocks.asMap().entries.expand((entry) {
                    final blockIndex = entry.key;
                    final block = entry.value;

                    return [
                      // Block header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${blockIndex + 1}',
                                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    block.title.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 14),
                                  ),
                                  Text(
                                    '${block.blockType.toUpperCase()} • ${block.rounds} round${block.rounds != 1 ? 's' : ''} • ${block.exercises.length} exercises',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Exercises in block
                      ...block.exercises.asMap().entries.map((exEntry) {
                        final exercise = exEntry.value;
                        final exName = exercise.exercise?.title ?? 'Unknown';
                        final isTimeBased = exercise.durationSeconds != null && exercise.durationSeconds! > 0;
                        
                        String detailStr;
                        if (isTimeBased) {
                          detailStr = '${exercise.durationSeconds}s';
                        } else {
                          final parts = <String>[];
                          if (exercise.sets != null) parts.add('${exercise.sets} sets');
                          if (exercise.reps != null) parts.add('${exercise.reps} reps');
                          detailStr = parts.isEmpty ? 'Custom' : parts.join(' × ');
                        }
                        
                        if (exercise.restSeconds != null && exercise.restSeconds! > 0) {
                          detailStr += ' • ${exercise.restSeconds}s rest';
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[850]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isTimeBased ? Icons.timer : Icons.repeat,
                                  color: primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(exName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text(detailStr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      if (blockIndex < blocks.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Divider(color: Colors.grey[850]),
                        ),
                    ];
                  }),

                  const SizedBox(height: 100), // Space for FAB
                ]),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => WorkoutPlayerScreen(workout: workout)),
              );
            },
            backgroundColor: primary,
            icon: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
            label: const Text(
              'START WORKOUT',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
