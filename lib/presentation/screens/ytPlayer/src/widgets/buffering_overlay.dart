import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import '../utils/youtube_player_controller.dart';

/// A widget to overlay the player when it's buffering.
class BufferingOverlay extends StatelessWidget {
  /// The [YoutubePlayerController] for the player.
  final YoutubePlayerController controller;

  /// Creates a [BufferingOverlay].
  const BufferingOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Solid black to hide any YouTube residuals
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Loader
              //_buildLoader(),
              //const SizedBox(height: 32),

              // Video Metadata
              if (controller.metadata.title.isNotEmpty)
                Text(
                  controller.metadata.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              if (controller.metadata.author.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  controller.metadata.author,
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const SizedBox(
      width: 60,
      height: 60,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        valueColor:
            AlwaysStoppedAnimation<Color>(AppTheme.primaryPink), // primaryPink
      ),
    );
  }
}
