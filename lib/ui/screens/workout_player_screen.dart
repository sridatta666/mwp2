import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/workout.dart';
import '../../models/workout_block.dart';
import '../../providers/providers.dart';
import '../../services/bunny_stream_service.dart';
import 'workout_complete_screen.dart';

class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const WorkoutPlayerScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends ConsumerState<WorkoutPlayerScreen> {
  int _currentBlockIndex = 0;
  int _currentExerciseIndex = 0;
  int _currentRound = 1;

  final BunnyStreamService _streamService = BunnyStreamService();
  WebViewController? _webViewController;
  String? _currentVideoId;

  Timer? _timer;
  int _secondsRemaining = 0;
  DateTime? _workoutStartTime;
  bool _isResting = false;
  int _restSecondsRemaining = 0;
  Timer? _restTimer;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _loadVideo(String videoId) {
    if (_currentVideoId == videoId) return;
    _currentVideoId = videoId;

    if (videoId == 'test_video_id' || videoId.isEmpty) {
      return;
    }

    final libraryId = _streamService.libraryId;
    final embedUrl = 'https://iframe.mediadelivery.net/embed/$libraryId/$videoId?autoplay=true&loop=true&muted=false&preload=true';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {},
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));

    setState(() {
      _webViewController = controller;
    });
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
    });

    if (seconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
              HapticFeedback.lightImpact();
            }
          } else {
            timer.cancel();
            HapticFeedback.heavyImpact();
            _triggerNextExercise();
          }
        });
      });
    }
  }

  void _triggerNextExercise() {
    final blocks = ref.read(workoutDetailsProvider(widget.workout.id)).value;
    if (blocks != null) {
      _nextExercise(blocks);
    }
  }

  void _nextExercise(List<WorkoutBlock> blocks) {
    if (blocks.isEmpty) return;
    HapticFeedback.selectionClick();
    
    _timer?.cancel();
    _restTimer?.cancel();
    setState(() => _isResting = false);
    
    final currentBlock = blocks[_currentBlockIndex];
    final currentEx = currentBlock.exercises[_currentExerciseIndex];
    final restSecs = currentEx.restSeconds ?? 0;

    // If there's rest time and we're moving to a next exercise, show rest overlay
    if (restSecs > 0) {
      _showRestTimer(restSecs, () => _advanceExercise(blocks));
    } else {
      _advanceExercise(blocks);
    }
  }

  void _showRestTimer(int seconds, VoidCallback onComplete) {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_restSecondsRemaining > 1) {
          _restSecondsRemaining--;
          if (_restSecondsRemaining <= 3) HapticFeedback.lightImpact();
        } else {
          timer.cancel();
          _isResting = false;
          HapticFeedback.heavyImpact();
          onComplete();
        }
      });
    });
  }

  void _advanceExercise(List<WorkoutBlock> blocks) {
    final currentBlock = blocks[_currentBlockIndex];
    
    if (_currentExerciseIndex < currentBlock.exercises.length - 1) {
      setState(() => _currentExerciseIndex++);
      _currentVideoId = null;
    } else {
      if (_currentRound < currentBlock.rounds) {
        setState(() {
          _currentRound++;
          _currentExerciseIndex = 0;
        });
        _currentVideoId = null;
      } else {
        if (_currentBlockIndex < blocks.length - 1) {
          setState(() {
            _currentBlockIndex++;
            _currentRound = 1;
            _currentExerciseIndex = 0;
          });
          _currentVideoId = null;
        } else {
          final durationSeconds = _workoutStartTime != null 
              ? DateTime.now().difference(_workoutStartTime!).inSeconds 
              : 0;

          // Count total exercises across all blocks
          int totalExercises = 0;
          for (final b in blocks) {
            totalExercises += b.exercises.length;
          }
              
          ref.read(supabaseServiceProvider).logWorkout(widget.workout.id, durationSeconds).then((_) {
            ref.invalidate(userStatsProvider);
            ref.invalidate(weeklyProgressProvider);
          });

          // Navigate to completion screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutCompleteScreen(
                workoutTitle: widget.workout.title,
                durationSeconds: durationSeconds,
                exercisesCompleted: totalExercises,
                blocksCompleted: blocks.length,
              ),
            ),
          );
        }
      }
    }
  }

  String _lastProcessedExerciseId = '';

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(workoutDetailsProvider(widget.workout.id));

    return Scaffold(
      backgroundColor: Colors.black,
      body: detailsAsync.when(
        data: (blocks) {
          if (blocks.isEmpty) return _buildErrorState('No exercises found in this workout.');

          final currentBlock = blocks[_currentBlockIndex];
          if (currentBlock.exercises.isEmpty) return _buildErrorState('Block has no exercises.');

          final currentWorkoutExercise = currentBlock.exercises[_currentExerciseIndex];
          final exercise = currentWorkoutExercise.exercise;
          
          if (exercise == null) return _buildErrorState('Exercise details missing.');

          // Setup video and timer if exercise changed
          final uniqueId = '${currentBlock.id}_${_currentRound}_${currentWorkoutExercise.id}';
          if (_lastProcessedExerciseId != uniqueId) {
            _lastProcessedExerciseId = uniqueId;
            
            final videoId = exercise.bunnyVideoId ?? 'test_video_id';
            _loadVideo(videoId);
            
            if (currentWorkoutExercise.durationSeconds != null && currentWorkoutExercise.durationSeconds! > 0) {
              _startTimer(currentWorkoutExercise.durationSeconds!);
            } else {
              _timer?.cancel();
            }
          }

          final isTimeBased = currentWorkoutExercise.durationSeconds != null && currentWorkoutExercise.durationSeconds! > 0;

          // Calculate progress
          int totalExercises = 0;
          int completedExercises = 0;
          for (int bi = 0; bi < blocks.length; bi++) {
            for (int ei = 0; ei < blocks[bi].exercises.length; ei++) {
              totalExercises++;
              if (bi < _currentBlockIndex || (bi == _currentBlockIndex && ei < _currentExerciseIndex)) {
                completedExercises++;
              }
            }
          }
          final progress = totalExercises > 0 ? (completedExercises / totalExercises) : 0.0;
          final elapsedMin = _elapsedSeconds ~/ 60;
          final elapsedSec = _elapsedSeconds % 60;
          final elapsedStr = '${elapsedMin.toString().padLeft(2, '0')}:${elapsedSec.toString().padLeft(2, '0')}';

          return Stack(
            fit: StackFit.expand,
            children: [
              // Video player (WebView)
              if (_webViewController != null)
                WebViewWidget(controller: _webViewController!)
              else
                Container(color: Colors.black),
              
              // Gradient overlay (IgnorePointer lets touches reach the WebView play button)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Controls
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top bar: close, block info, elapsed time
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${currentBlock.title} • Round $_currentRound/${currentBlock.rounds}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(elapsedStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: Colors.grey[800],
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Exercise ${completedExercises + 1} of $totalExercises',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            exercise.title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTimeBased ? '00:${_secondsRemaining.toString().padLeft(2, '0')}' : '${currentWorkoutExercise.reps ?? 0} Reps',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _nextExercise(blocks),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                ),
                                child: Text(isTimeBased ? 'SKIP' : 'NEXT'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Rest Timer Overlay
              if (_isResting)
                Container(
                  color: Colors.black.withValues(alpha: 0.9),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'REST',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$_restSecondsRemaining',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 96,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('seconds', style: TextStyle(color: Colors.grey, fontSize: 18)),
                        const SizedBox(height: 40),
                        OutlinedButton(
                          onPressed: () {
                            _restTimer?.cancel();
                            final blocks = ref.read(workoutDetailsProvider(widget.workout.id)).value;
                            setState(() => _isResting = false);
                            if (blocks != null) _advanceExercise(blocks);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).primaryColor),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          ),
                          child: Text('SKIP REST', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState('Failed to load workout: $err'),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          )
        ],
      ),
    );
  }
}
