import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/providers.dart';
import '../../services/bunny_stream_service.dart';

class AdminCreateExerciseScreen extends ConsumerStatefulWidget {
  const AdminCreateExerciseScreen({super.key});

  @override
  ConsumerState<AdminCreateExerciseScreen> createState() => _AdminCreateExerciseScreenState();
}

class _AdminCreateExerciseScreenState extends ConsumerState<AdminCreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  String _instructions = '';
  String _muscleGroup = 'full_body';
  XFile? _selectedVideo;
  bool _isLoading = false;
  String _loadingMessage = '';

  final _bunnyService = BunnyStreamService();
  final _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a video.')));
      return;
    }

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Uploading video to Bunny.net... (this may take a while)';
    });

    try {
      // 1. Upload video to Bunny.net
      final videoId = await _bunnyService.uploadVideo(_selectedVideo!.path, _title);

      setState(() {
        _loadingMessage = 'Saving exercise to database...';
      });

      // 2. Save exercise to Supabase
      await ref.read(supabaseServiceProvider).createExercise(
        title: _title,
        description: _description,
        instructions: _instructions,
        videoUrl: videoId,
        muscleGroup: _muscleGroup,
      );
      
      if (mounted) {
        ref.invalidate(exercisesProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exercise created successfully!')));
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
        title: const Text('NEW EXERCISE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(_loadingMessage, style: const TextStyle(color: Colors.white)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField('Title', 'e.g. Pushup', (v) => _title = v!, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Description', 'Brief overview of the exercise', (v) => _description = v!, required: true, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField('Instructions', 'Step by step instructions', (v) => _instructions = v!, required: true, maxLines: 4),
                    const SizedBox(height: 16),
                    
                    // Muscle Group Dropdown
                    DropdownButtonFormField<String>(
                      value: _muscleGroup,
                      decoration: InputDecoration(
                        labelText: 'Muscle Group',
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'chest', child: Text('Chest')),
                        DropdownMenuItem(value: 'back', child: Text('Back')),
                        DropdownMenuItem(value: 'shoulders', child: Text('Shoulders')),
                        DropdownMenuItem(value: 'arms', child: Text('Arms')),
                        DropdownMenuItem(value: 'legs', child: Text('Legs')),
                        DropdownMenuItem(value: 'core', child: Text('Core')),
                        DropdownMenuItem(value: 'full_body', child: Text('Full Body')),
                        DropdownMenuItem(value: 'cardio', child: Text('Cardio')),
                      ],
                      onChanged: (v) => setState(() => _muscleGroup = v!),
                    ),
                    const SizedBox(height: 24),
                    
                    // Video Picker UI
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.video_library, size: 48, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            _selectedVideo == null ? 'No Video Selected' : 'Video Selected: ${_selectedVideo!.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _pickVideo,
                            icon: Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
                            label: Text('Select Video File', style: TextStyle(color: Theme.of(context).primaryColor)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CREATE EXERCISE'),
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
