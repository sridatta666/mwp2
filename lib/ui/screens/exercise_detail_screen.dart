import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/exercise.dart';
import '../../services/bunny_stream_service.dart';
import '../../providers/providers.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  final BunnyStreamService _streamService = BunnyStreamService();
  WebViewController? _webViewController;
  bool _isVideoReady = false;
  bool _hasVideoError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoId = widget.exercise.bunnyVideoId;

    if (videoId == null || videoId.isEmpty || videoId == 'test_video_id') {
      setState(() {
        _hasVideoError = true;
        _errorMessage = 'No video available for this exercise.';
      });
      return;
    }

    // Check encoding status from Bunny API
    try {
      final status = await _streamService.getVideoStatus(videoId);
      final encodeProgress = status['encodeProgress'] ?? 0;
      final videoStatus = status['status'] ?? -1;
      print('[BunnyStream] Video "$videoId" status=$videoStatus encodeProgress=$encodeProgress');

      if (videoStatus != 4) {
        if (mounted) {
          setState(() {
            _hasVideoError = true;
            _errorMessage = 'Video is still encoding ($encodeProgress% complete). Try again shortly.';
          });
        }
        return;
      }
    } catch (e) {
      print('[BunnyStream] Could not check video status: $e');
      // Continue — we'll try to play anyway
    }

    // Use Bunny's embedded player via WebView (bypasses Referer/CDN auth)
    final libraryId = _streamService.libraryId;
    final embedUrl = 'https://iframe.mediadelivery.net/embed/$libraryId/$videoId?autoplay=true&loop=true&preload=true';
    print('[BunnyStream] Embed URL: $embedUrl');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isVideoReady = true);
          },
          onWebResourceError: (error) {
            print('[BunnyStream] WebView error: ${error.description}');
            if (mounted) {
              setState(() {
                _hasVideoError = true;
                _errorMessage = 'Could not load video player: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));

    setState(() {
      _webViewController = controller;
    });
  }

  Future<void> _deleteExercise() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Exercise?'),
        content: const Text('This will permanently delete the exercise and its video from the server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (widget.exercise.bunnyVideoId != null && widget.exercise.bunnyVideoId != 'test_video_id') {
        await _streamService.deleteVideo(widget.exercise.bunnyVideoId!);
      }

      await ref.read(supabaseServiceProvider).deleteExercise(widget.exercise.id);

      if (mounted) {
        ref.invalidate(exercisesProvider);
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Go back
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exercise deleted.')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildVideoPlayer() {
    if (_hasVideoError) {
      return Container(
        height: 300,
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, color: Colors.grey, size: 48),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_webViewController == null || !_isVideoReady) {
      return Container(
        height: 300,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 300,
      child: WebViewWidget(controller: _webViewController!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.exercise.title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player (WebView)
            _buildVideoPlayer(),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'INSTRUCTIONS',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.exercise.instructions ?? 'No detailed instructions provided.',
                          style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (widget.exercise.description != null) ...[
                    Text(
                      'ABOUT THIS EXERCISE',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.exercise.description!,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
