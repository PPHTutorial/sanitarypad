import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String url;
  final String movieId;

  const CustomVideoPlayer({
    super.key,
    required this.url,
    required this.movieId,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // 1. Load saved position
      final prefs = await SharedPreferences.getInstance();
      final savedMs = prefs.getInt("movie_${widget.movieId}_position") ?? 0;
      final startPosition = Duration(milliseconds: savedMs);

      // 2. Initialize Video Controller
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _videoController!.initialize();

      // 3. Initialize Chewie Controller
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        startAt: startPosition,
        showControls: true,
        allowPlaybackSpeedChanging: true,
        fullScreenByDefault: false, // Let user toggle or handle manually
        aspectRatio: _videoController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        allowedScreenSleep: false,
      );

      // 4. Update state
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // 5. Add listeners for saving position
      _videoController!.addListener(_onVideoControllerUpdate);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load video: $e";
        });
      }
      print("Error initializing player: $e");
    }
  }

  void _onVideoControllerUpdate() {
    // Save position periodically or on pause?
    // Doing it on every update is too frequent.
    // We'll save on dispose or pause.
  }

  Future<void> _savePosition() async {
    if (_videoController == null || !_videoController!.value.isInitialized)
      return;

    try {
      final position = _videoController!.value.position.inMilliseconds;
      if (position > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("movie_${widget.movieId}_position", position);
      }
    } catch (e) {
      print("Error saving position: $e");
    }
  }

  @override
  void dispose() {
    _savePosition(); // Save on exit
    _videoController?.removeListener(_onVideoControllerUpdate);
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              "Error loading video",
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SafeArea(
      child: Chewie(controller: _chewieController!),
    );
  }
}
