import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class AdminAddWorkoutScreen extends ConsumerStatefulWidget {
  const AdminAddWorkoutScreen({super.key});

  @override
  ConsumerState<AdminAddWorkoutScreen> createState() => _AdminAddWorkoutScreenState();
}

class _AdminAddWorkoutScreenState extends ConsumerState<AdminAddWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedProgramId;
  String _title = '';
  String _description = '';
  int _orderIndex = 1;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select a program.')));
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await ref.read(supabaseServiceProvider).createWorkout(
        programId: _selectedProgramId!,
        title: _title,
        description: _description,
        orderIndex: _orderIndex,
      );
      
      if (mounted) {
        ref.invalidate(workoutsProvider(_selectedProgramId!));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout added successfully!')));
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
    final programsAsync = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD WORKOUT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
                    programsAsync.when(
                      data: (programs) {
                        if (programs.isEmpty) {
                          return const Text('No programs exist. Please create a program first.');
                        }
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Program',
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          initialValue: _selectedProgramId,
                          items: programs.map((p) => DropdownMenuItem(value: p.id, child: Text(p.title))).toList(),
                          onChanged: (v) => setState(() => _selectedProgramId = v),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Workout Title', 'e.g. Full Body Strength', (v) => _title = v!, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Description', 'What is this workout about?', (v) => _description = v!, required: true, maxLines: 2),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Order Index (Sequence in Program)',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '1',
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a valid number' : null,
                      onSaved: (v) => _orderIndex = int.parse(v!),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('ADD WORKOUT'),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      maxLines: maxLines,
      validator: required ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
      onSaved: onSaved,
    );
  }
}
