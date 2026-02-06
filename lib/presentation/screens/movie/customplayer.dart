import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../services/credit_manager.dart';

class CustomVideoPlayer extends ConsumerStatefulWidget {
  final String url;
  final String movieId;

  const CustomVideoPlayer({
    super.key,
    required this.url,
    required this.movieId,
  });

  @override
  ConsumerState<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends ConsumerState<CustomVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;

  // VLC/Netflix-style overlays
  String? _overlayText;
  IconData? _overlayIcon;
  Timer? _overlayTimer;

  // Premium Features
  bool _isLocked = false;
  double _volume = 1.0;
  double _brightness = 0.5;
  bool _showCustomControls = true;
  Timer? _hideControlsTimer;
  Timer? _creditDeductionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
      _startCreditDeductionTimer();
    });
  }

  void _startCreditDeductionTimer() {
    _creditDeductionTimer?.cancel();
    _creditDeductionTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      ref.read(creditManagerProvider).consumeCredits(ActionType.movie);
      debugPrint("🎬 30s Playback Reached: Credit Consumed.");
    });
  }

  Future<void> _initializePlayer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMs = prefs.getInt("movie_${widget.movieId}_position") ?? 0;
      final startPosition = Duration(milliseconds: savedMs);

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        // Optimize for streaming
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await _videoController!.initialize();
      _volume = _videoController!.value.volume;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        startAt: startPosition,
        showControls: false, // We'll use our own premium custom controls
        allowPlaybackSpeedChanging: true,
        fullScreenByDefault:
            false, // Disable Chewie's internal fullscreen to keep our overlays active
        allowFullScreen:
            false, // Let our Stack and SystemChrome handle the layout
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(color: Colors.black),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 42),
                const SizedBox(height: 12),
                const Text(
                  "Stream Blocked or Expired",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        allowedScreenSleep: false,
      );

      // Force Landscape and Hide System UI
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showCustomControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showCustomControls = !_showCustomControls;
    });
    if (_showCustomControls) _startHideTimer();
  }

  void _showOverlay(String text, IconData icon) {
    if (!mounted) return;
    setState(() {
      _overlayText = text;
      _overlayIcon = icon;
    });
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _overlayText = null;
          _overlayIcon = null;
        });
      }
    });
  }

  void _seek(bool forward) async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final currentPos = _videoController!.value.position;
    final newPos = forward
        ? currentPos + const Duration(seconds: 10)
        : currentPos - const Duration(seconds: 10);

    await _videoController!.seekTo(newPos);
    _showOverlay(
      forward ? "+10s" : "-10s",
      forward ? Icons.fast_forward : Icons.fast_rewind,
    );
  }

  Future<void> _savePosition() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    try {
      final position = _videoController!.value.position.inMilliseconds;
      if (position > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("movie_${widget.movieId}_position", position);
      }
    } catch (e) {
      debugPrint("Error saving position: $e");
    }
  }

  @override
  void dispose() {
    _savePosition();
    _overlayTimer?.cancel();
    _creditDeductionTimer?.cancel();
    _videoController?.dispose();
    _chewieController?.dispose();

    // Restore orientations and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_outlined,
                  color: Colors.pinkAccent, size: 64),
              const SizedBox(height: 16),
              const Text("Playback Error",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Go Back",
                    style: TextStyle(color: Colors.pinkAccent)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragUpdate: (details) {
          if (_isLocked) return;
          final height = MediaQuery.of(context).size.height;
          final delta = details.primaryDelta! / height;
          if (details.localPosition.dx <
              MediaQuery.of(context).size.width / 2) {
            // Brightness (Left side)
            setState(() {
              _brightness = (_brightness - delta).clamp(0.0, 1.0);
            });
            _showOverlay("${(_brightness * 100).toInt()}%", Icons.brightness_6);
          } else {
            // Volume (Right side)
            setState(() {
              _volume = (_volume - delta).clamp(0.0, 1.0);
              _videoController?.setVolume(_volume);
            });
            _showOverlay("${(_volume * 100).toInt()}%", Icons.volume_up);
          }
        },
        child: Stack(
          children: [
            // 1. The Player
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),

            // 2. Lock / Premium Controls Layer
            if (_showCustomControls)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: Column(
                    children: [
                      // Top Bar
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              if (!_isLocked)
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                    _isLocked ? Icons.lock : Icons.lock_open,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() => _isLocked = !_isLocked);
                                  _showOverlay(
                                      _isLocked
                                          ? "Screen Locked"
                                          : "Screen Unlocked",
                                      _isLocked ? Icons.lock : Icons.lock_open);
                                  if (!_isLocked) _startHideTimer();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Center Play/Pause & Seeks
                      if (!_isLocked)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.replay_10,
                                  color: Colors.white, size: 48),
                              onPressed: () => _seek(false),
                            ),
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.pinkAccent,
                                size: 84,
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                                _startHideTimer();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10,
                                  color: Colors.white, size: 48),
                              onPressed: () => _seek(true),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // Bottom Progress Bar
                      if (!_isLocked)
                        SafeArea(
                          child: Container(
                            margin: const EdgeInsets.only(
                                bottom: 16, left: 16, right: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Standard Video Player Progress Indicator (The pink bar)
                                VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.pinkAccent,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: _videoController!,
                                      builder: (context, VideoPlayerValue value,
                                          child) {
                                        return Text(
                                          _formatDuration(value.position),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        );
                                      },
                                    ),
                                    ValueListenableBuilder(
                                      valueListenable: _videoController!,
                                      builder: (context, VideoPlayerValue value,
                                          child) {
                                        return Text(
                                          _formatDuration(value.duration),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // VLC Style Overlay
            if (_overlayIcon != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_overlayIcon, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(_overlayText!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
