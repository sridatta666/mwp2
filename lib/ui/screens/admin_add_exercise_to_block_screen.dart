import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class AdminAddExerciseToBlockScreen extends ConsumerStatefulWidget {
  const AdminAddExerciseToBlockScreen({super.key});

  @override
  ConsumerState<AdminAddExerciseToBlockScreen> createState() => _AdminAddExerciseToBlockScreenState();
}

class _AdminAddExerciseToBlockScreenState extends ConsumerState<AdminAddExerciseToBlockScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedWorkoutId;
  String? _selectedBlockId;
  String? _selectedExerciseId;
  int _orderIndex = 1;
  int? _reps;
  int? _sets;
  int? _durationSeconds;
  int? _restSeconds;
  bool _isLoading = false;
  bool _isTimedExercise = false;

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedBlockId == null || _selectedExerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await ref.read(supabaseServiceProvider).addExerciseToBlock(
        blockId: _selectedBlockId!,
        exerciseId: _selectedExerciseId!,
        orderIndex: _orderIndex,
        reps: _isTimedExercise ? null : _reps,
        sets: _isTimedExercise ? null : _sets,
        durationSeconds: _isTimedExercise ? _durationSeconds : null,
        restSeconds: _restSeconds,
      );

      if (mounted) {
        if (_selectedWorkoutId != null) {
          ref.invalidate(workoutDetailsProvider(_selectedWorkoutId!));
          ref.invalidate(workoutBlocksProvider(_selectedWorkoutId!));
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exercise added to block!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(allWorkoutsProvider);
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD EXERCISE TO BLOCK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- STEP 1: Select Workout ---
                    Text('STEP 1: SELECT WORKOUT', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 12),
                    workoutsAsync.when(
                      data: (workouts) {
                        if (workouts.isEmpty) return const Text('No workouts exist.');
                        return DropdownButtonFormField<String>(
                          decoration: _dropdownDecoration('Select Workout'),
                          items: workouts.map((w) => DropdownMenuItem(value: w.id, child: Text(w.title))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedWorkoutId = v;
                            _selectedBlockId = null; // Reset block selection
                          }),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    ),

                    // --- STEP 2: Select Block ---
                    if (_selectedWorkoutId != null) ...[
                      const SizedBox(height: 24),
                      Text('STEP 2: SELECT BLOCK', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                      const SizedBox(height: 12),
                      ref.watch(workoutBlocksProvider(_selectedWorkoutId!)).when(
                        data: (blocks) {
                          if (blocks.isEmpty) return const Text('No blocks in this workout. Add a block first.');
                          return DropdownButtonFormField<String>(
                            decoration: _dropdownDecoration('Select Block'),
                            items: blocks.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.title} (${b.blockType})'))).toList(),
                            onChanged: (v) => setState(() => _selectedBlockId = v),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err'),
                      ),
                    ],

                    // --- STEP 3: Select Exercise ---
                    if (_selectedBlockId != null) ...[
                      const SizedBox(height: 24),
                      Text('STEP 3: SELECT EXERCISE', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                      const SizedBox(height: 12),
                      exercisesAsync.when(
                        data: (exercises) {
                          if (exercises.isEmpty) return const Text('No exercises in library.');
                          return DropdownButtonFormField<String>(
                            decoration: _dropdownDecoration('Select Exercise'),
                            items: exercises.map((e) => DropdownMenuItem(value: e.id, child: Text(e.title))).toList(),
                            onChanged: (v) => setState(() => _selectedExerciseId = v),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error: $err'),
                      ),
                    ],

                    // --- STEP 4: Configure ---
                    if (_selectedExerciseId != null) ...[
                      const SizedBox(height: 24),
                      Text('STEP 4: CONFIGURE', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                      const SizedBox(height: 12),

                      // Toggle: reps-based or timed
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('Timed Exercise?', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Switch(
                              value: _isTimedExercise,
                              onChanged: (v) => setState(() => _isTimedExercise = v),
                              activeThumbColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_isTimedExercise) ...[
                        Row(
                          children: [
                            Expanded(child: _buildNumberField('Reps', (v) => _reps = v)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildNumberField('Sets', (v) => _sets = v)),
                          ],
                        ),
                      ] else ...[
                        _buildNumberField('Duration (seconds)', (v) => _durationSeconds = v),
                      ],

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildNumberField('Rest (seconds)', (v) => _restSeconds = v)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Order',
                                filled: true,
                                fillColor: Colors.grey[900],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              keyboardType: TextInputType.number,
                              initialValue: '1',
                              onSaved: (v) => _orderIndex = int.tryParse(v ?? '1') ?? 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('ADD EXERCISE TO BLOCK'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildNumberField(String label, void Function(int?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      keyboardType: TextInputType.number,
      onSaved: (v) => onSaved(int.tryParse(v ?? '')),
    );
  }
}
