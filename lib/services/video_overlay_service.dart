import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoOverlayState {
  final String? videoId;
  final bool isVisible;
  final bool isMinimized;

  const VideoOverlayState({
    this.videoId,
    this.isVisible = false,
    this.isMinimized = false,
  });

  VideoOverlayState copyWith({
    String? videoId,
    bool? isVisible,
    bool? isMinimized,
  }) {
    return VideoOverlayState(
      videoId: videoId ?? this.videoId,
      isVisible: isVisible ?? this.isVisible,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

class VideoOverlayNotifier extends StateNotifier<VideoOverlayState> {
  VideoOverlayNotifier() : super(const VideoOverlayState());

  void playVideo(String videoId) {
    state = VideoOverlayState(
      videoId: videoId,
      isVisible: true,
      isMinimized: false,
    );
  }

  void minimize() {
    if (state.isVisible) {
      state = state.copyWith(isMinimized: true);
    }
  }

  void maximize() {
    if (state.isVisible) {
      state = state.copyWith(isMinimized: false);
    }
  }

  void close() {
    state = const VideoOverlayState(isVisible: false);
  }
}

final videoOverlayProvider =
    StateNotifierProvider<VideoOverlayNotifier, VideoOverlayState>((ref) {
  return VideoOverlayNotifier();
});
