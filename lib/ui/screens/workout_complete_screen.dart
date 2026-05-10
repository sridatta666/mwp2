import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkoutCompleteScreen extends StatefulWidget {
  final String workoutTitle;
  final int durationSeconds;
  final int exercisesCompleted;
  final int blocksCompleted;

  const WorkoutCompleteScreen({
    super.key,
    required this.workoutTitle,
    required this.durationSeconds,
    required this.exercisesCompleted,
    required this.blocksCompleted,
  });

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final mins = widget.durationSeconds ~/ 60;
    final secs = widget.durationSeconds % 60;
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated checkmark
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [primary.withValues(alpha: 0.3), Colors.transparent],
                      radius: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary,
                        boxShadow: [
                          BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5),
                        ],
                      ),
                      child: const Icon(Icons.check, color: Colors.black, size: 48),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'WORKOUT COMPLETE!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.workoutTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: primary,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(context, Icons.timer, timeStr, 'Duration'),
                        _buildStat(context, Icons.fitness_center, '${widget.exercisesCompleted}', 'Exercises'),
                        _buildStat(context, Icons.layers, '${widget.blocksCompleted}', 'Blocks'),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Motivational message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Row(
                        children: [
                          const Text('💪', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _getMotivationalMessage(),
                              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Done button
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('DONE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getMotivationalMessage() {
    final messages = [
      "Consistency is what transforms average into excellence. Keep showing up!",
      "You didn't come this far to only come this far. Keep pushing!",
      "Every rep counts. Every set matters. You're building something great.",
      "The only bad workout is the one that didn't happen. Great job today!",
      "Discipline is the bridge between goals and accomplishment.",
    ];
    return messages[DateTime.now().second % messages.length];
  }
}
