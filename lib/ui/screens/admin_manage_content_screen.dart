import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class AdminManageContentScreen extends ConsumerWidget {
  const AdminManageContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MANAGE CONTENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          backgroundColor: Colors.black,
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'PROGRAMS'),
              Tab(text: 'WORKOUTS'),
              Tab(text: 'EXERCISES'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProgramsTab(),
            _WorkoutsTab(),
            _ExercisesTab(),
          ],
        ),
      ),
    );
  }
}

// =============== PROGRAMS TAB ===============
class _ProgramsTab extends ConsumerWidget {
  const _ProgramsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsProvider);
    return programsAsync.when(
      data: (programs) {
        if (programs.isEmpty) {
          return const Center(child: Text('No programs yet.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: programs.length,
          itemBuilder: (context, index) {
            final p = programs[index];
            return _ContentTile(
              title: p.title,
              subtitle: '${p.difficultyLevel ?? 'N/A'} • ${p.durationWeeks ?? 0} weeks',
              onDelete: () => _confirmDelete(context, ref, 'program', p.title, () async {
                await ref.read(supabaseServiceProvider).deleteProgram(p.id);
                ref.invalidate(programsProvider);
              }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// =============== WORKOUTS TAB ===============
class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(allWorkoutsProvider);
    return workoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return const Center(child: Text('No workouts yet.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final w = workouts[index];
            return _ContentTile(
              title: w.title,
              subtitle: 'Order: ${w.orderIndex}',
              onDelete: () => _confirmDelete(context, ref, 'workout', w.title, () async {
                await ref.read(supabaseServiceProvider).deleteWorkout(w.id);
                ref.invalidate(allWorkoutsProvider);
              }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// =============== EXERCISES TAB ===============
class _ExercisesTab extends ConsumerWidget {
  const _ExercisesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);
    return exercisesAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) {
          return const Center(child: Text('No exercises yet.', style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final e = exercises[index];
            return _ContentTile(
              title: e.title,
              subtitle: e.description ?? 'No description',
              onDelete: () => _confirmDelete(context, ref, 'exercise', e.title, () async {
                await ref.read(supabaseServiceProvider).deleteExercise(e.id);
                ref.invalidate(exercisesProvider);
              }),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// =============== SHARED WIDGETS ===============
class _ContentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  const _ContentTile({required this.title, required this.subtitle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

void _confirmDelete(BuildContext context, WidgetRef ref, String type, String name, Future<void> Function() onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Delete $type?'),
      content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await onConfirm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type deleted.')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
