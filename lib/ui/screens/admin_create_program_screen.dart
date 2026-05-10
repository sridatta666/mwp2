import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class AdminCreateProgramScreen extends ConsumerStatefulWidget {
  const AdminCreateProgramScreen({super.key});

  @override
  ConsumerState<AdminCreateProgramScreen> createState() => _AdminCreateProgramScreenState();
}

class _AdminCreateProgramScreenState extends ConsumerState<AdminCreateProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  String _coverImageUrl = '';
  String _difficultyLevel = 'Beginner';
  int _durationWeeks = 4;
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await ref.read(supabaseServiceProvider).createProgram(
        title: _title,
        description: _description,
        coverImageUrl: _coverImageUrl,
        difficultyLevel: _difficultyLevel,
        durationWeeks: _durationWeeks,
      );
      
      if (mounted) {
        ref.invalidate(programsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program created successfully!')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEW PROGRAM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
                    _buildTextField('Title', 'e.g. 30 Days to Handstand', (v) => _title = v!, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Description', 'Program overview...', (v) => _description = v!, required: true, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField('Cover Image URL', 'https://...', (v) => _coverImageUrl = v!, required: true),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Difficulty Level',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      initialValue: _difficultyLevel,
                      items: ['Beginner', 'Intermediate', 'Advanced', 'All Levels']
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => _difficultyLevel = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Duration (Weeks)',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '4',
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a valid number' : null,
                      onSaved: (v) => _durationWeeks = int.parse(v!),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('CREATE PROGRAM'),
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
