import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sanitarypad/core/theme/app_theme.dart'; // Unused
import 'package:sanitarypad/services/video_feed_service.dart';
import 'package:sanitarypad/services/video_overlay_service.dart';
import 'package:sanitarypad/services/credit_manager.dart';
import 'package:sanitarypad/models/workout_models.dart';
// Reuse Nutrition widgets if possible, or duplicate for independence
// Using a simple list for now

class SkincareVideosTab extends ConsumerStatefulWidget {
  final String userId;
  const SkincareVideosTab({super.key, required this.userId});

  @override
  ConsumerState<SkincareVideosTab> createState() => _SkincareVideosTabState();
}

class _SkincareVideosTabState extends ConsumerState<SkincareVideosTab> {
  // We can default to Skincare category
  final VideoCategory _category = VideoCategory.skincare;

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(workoutVideosByCategoryProvider(_category));

    return videosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return const Center(child: Text('No videos found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return _VideoCard(video: video);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _VideoCard extends ConsumerWidget {
  final WorkoutVideo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _playVideo(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.channelName ?? 'Unknown Channel',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playVideo(BuildContext context, WidgetRef ref) async {
    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager.requestCredit(
      context,
      ActionType.videoWatch,
    );

    if (hasCredits) {
      await creditManager.consumeCredits(ActionType.videoWatch);
      if (context.mounted) {
        ref.read(videoOverlayProvider.notifier).playVideo(video.videoId);
      }
    }
  }
}
