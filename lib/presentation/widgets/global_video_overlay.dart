import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanitarypad/presentation/screens/ytPlayer/youtube_player_flutter.dart';
import '../../services/video_overlay_service.dart';
import '../../core/theme/app_theme.dart';

class GlobalVideoOverlay extends ConsumerStatefulWidget {
  const GlobalVideoOverlay({super.key});

  @override
  ConsumerState<GlobalVideoOverlay> createState() => _GlobalVideoOverlayState();
}

class _GlobalVideoOverlayState extends ConsumerState<GlobalVideoOverlay> {
  YoutubePlayerController? _controller;
  String? _currentVideoId;

  @override
  void dispose() {
    _controller?.dispose();
    _resetOrientation();
    super.dispose();
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  void _initializeController(String videoId) {
    if (_controller != null) {
      if (_currentVideoId != videoId) {
        _controller!.load(videoId);
        _currentVideoId = videoId;
      }
      return;
    }

    _currentVideoId = videoId;
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        hideControls: false, // Show native controls
        forceHD: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoOverlayProvider);

    ref.listen(videoOverlayProvider, (previous, next) {
      if (next.videoId != null &&
          (previous?.videoId != next.videoId || _controller == null)) {
        _initializeController(next.videoId!);
      } else if (!next.isVisible && previous?.isVisible == true) {
        _controller?.pause();
        _resetOrientation();
      }
    });

    if (!state.isVisible || state.videoId == null) {
      return const SizedBox.shrink();
    }

    if (_controller == null && state.videoId != null) {
      _initializeController(state.videoId!);
    }

    return PopScope(
      canPop: !state.isVisible || state.videoId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (state.isVisible && state.videoId != null) {
          if (!state.isMinimized) {
            // If maximized, minimize
            ref.read(videoOverlayProvider.notifier).minimize();
          } else {
            // If minimized, close
            ref.read(videoOverlayProvider.notifier).close();
          }
        }
      },
      child: state.isMinimized
          ? _buildMinimizedOverlay(context)
          : _buildMaximizedOverlay(context),
    );
  }

  Widget _buildMaximizedOverlay(BuildContext context) {
    // YoutubePlayerBuilder handles the fullscreen toggling by pushing a new route
    // We need to ensure it wraps the content properly.
    // Wrap in an Overlay to satisfy Tooltip requirements from YoutubePlayer
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: SafeArea(
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppTheme.primaryPink,
                    onEnded: (_) =>
                        ref.read(videoOverlayProvider.notifier).close(),
                  ),
                  builder: (context, player) {
                    return Stack(
                      children: [
                        Center(child: player),
                        // Close/Minimize buttons (Only visible when NOT in fullscreen, which YoutubePlayer handles)
                        // Note: When fullscreen, the builder pushes a NEW route, so these buttons won't appear
                        // on the rotated screen, which is exactly what we want (clean fullscreen).
                        Positioned(
                          top: 16,
                          left: 16,
                          child: IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 32),
                            onPressed: () => ref
                                .read(videoOverlayProvider.notifier)
                                .minimize(),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 32),
                            onPressed: () =>
                                ref.read(videoOverlayProvider.notifier).close(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedOverlay(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: 200,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Stack(
            fit: StackFit.loose,
            children: [
              if (_controller != null)
                Overlay(
                  initialEntries: [
                    OverlayEntry(
                      builder: (context) => IgnorePointer(
                        child: YoutubePlayer(
                          controller: _controller!,
                          showVideoProgressIndicator: true,
                          width: 200,
                        ),
                      ),
                    ),
                  ],
                ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () =>
                      ref.read(videoOverlayProvider.notifier).maximize(),
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => ref.read(videoOverlayProvider.notifier).close(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
              const Positioned(
                bottom: 2,
                right: 2,
                child:
                    Icon(Icons.open_in_full, color: Colors.white54, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
