import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class AdminAddBlockScreen extends ConsumerStatefulWidget {
  const AdminAddBlockScreen({super.key});

  @override
  ConsumerState<AdminAddBlockScreen> createState() => _AdminAddBlockScreenState();
}

class _AdminAddBlockScreenState extends ConsumerState<AdminAddBlockScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedWorkoutId;
  String _title = '';
  String _blockType = 'circuit';
  int _orderIndex = 1;
  int _rounds = 1;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedWorkoutId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select a workout.')));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await ref.read(supabaseServiceProvider).createWorkoutBlock(
        workoutId: _selectedWorkoutId!,
        title: _title,
        blockType: _blockType,
        orderIndex: _orderIndex,
        rounds: _rounds,
      );

      if (mounted) {
        ref.invalidate(workoutDetailsProvider(_selectedWorkoutId!));
        ref.invalidate(workoutBlocksProvider(_selectedWorkoutId!));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Block added successfully!')));
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD BLOCK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
                    // Step label
                    Text('STEP 1: SELECT WORKOUT', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 12),

                    workoutsAsync.when(
                      data: (workouts) {
                        if (workouts.isEmpty) {
                          return const Text('No workouts exist. Create a workout first.');
                        }
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Workout',
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: workouts.map((w) => DropdownMenuItem(value: w.id, child: Text(w.title))).toList(),
                          onChanged: (v) => setState(() => _selectedWorkoutId = v),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('Error: $err'),
                    ),

                    const SizedBox(height: 24),
                    Text('STEP 2: BLOCK DETAILS', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 12),

                    _buildTextField('Block Title', 'e.g. Warm Up, Main Circuit', (v) => _title = v!, required: true),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Block Type',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      initialValue: _blockType,
                      items: const [
                        DropdownMenuItem(value: 'warmup', child: Text('Warm Up')),
                        DropdownMenuItem(value: 'circuit', child: Text('Circuit')),
                        DropdownMenuItem(value: 'superset', child: Text('Superset')),
                        DropdownMenuItem(value: 'cooldown', child: Text('Cool Down')),
                      ],
                      onChanged: (v) => setState(() => _blockType = v!),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
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
                            validator: (v) => int.tryParse(v ?? '') == null ? 'Number' : null,
                            onSaved: (v) => _orderIndex = int.parse(v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Rounds',
                              filled: true,
                              fillColor: Colors.grey[900],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: '1',
                            validator: (v) => int.tryParse(v ?? '') == null ? 'Number' : null,
                            onSaved: (v) => _rounds = int.parse(v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('ADD BLOCK'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, String hint, void Function(String?) onSaved, {bool required = false, int maxLines = 1}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      maxLines: maxLines,
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      onSaved: onSaved,
    );
  }
}
