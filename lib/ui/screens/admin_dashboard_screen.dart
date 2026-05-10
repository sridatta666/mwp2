import 'package:flutter/material.dart';
import 'admin_create_program_screen.dart';
import 'admin_create_exercise_screen.dart';
import 'admin_add_workout_screen.dart';
import 'admin_add_block_screen.dart';
import 'admin_add_exercise_to_block_screen.dart';
import 'admin_manage_content_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ADMIN DASHBOARD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CONTENT MANAGEMENT',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            _buildAdminCard(
              context,
              icon: Icons.fitness_center,
              title: 'Add New Exercise',
              subtitle: 'Add a new exercise to the global library.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreateExerciseScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              icon: Icons.calendar_month,
              title: 'Create New Program',
              subtitle: 'Create a multi-week workout program.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCreateProgramScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              icon: Icons.list_alt,
              title: 'Assign Workout to Program',
              subtitle: 'Add a new workout sequence to an existing program.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddWorkoutScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              icon: Icons.view_agenda,
              title: 'Add Block to Workout',
              subtitle: 'Create sections like Warm Up, Circuit, Cool Down.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddBlockScreen())),
            ),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Add Exercise to Block',
              subtitle: 'Assign exercises with reps, sets, and timing.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAddExerciseToBlockScreen())),
            ),

            const SizedBox(height: 32),
            Text('CONTENT MANAGEMENT', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
            const SizedBox(height: 16),
            _buildAdminCard(
              context,
              icon: Icons.edit_note,
              title: 'Manage / Delete Content',
              subtitle: 'View, edit, and delete programs, workouts, and exercises.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageContentScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
