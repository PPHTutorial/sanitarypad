import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../core/constants/tmdb_endpoints.dart';
import '../../../domain/entities/movie.dart';

/// Wallpaper detail screen with full preview
class WallpaperDetailScreen extends StatefulWidget {
  final Movie movie;
  
  const WallpaperDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  bool _showUI = true;
  String _selectedQuality = 'HD';
  
  final List<String> _qualities = ['HD', 'Full HD', '4K', 'Original'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen zoomable image
          GestureDetector(
            onTap: () {
              setState(() {
                _showUI = !_showUI;
              });
            },
            child: PhotoView(
              imageProvider: NetworkImage(
                widget.movie.hasPoster
                    ? TMDBEndpoints.posterUrl(
                        widget.movie.posterPath!,
                        size: PosterSize.original,
                      )
                    : '',
              ),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          
          // Top bar
          if (_showUI)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),
          
          // Bottom sheet
          if (_showUI)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSheet(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8.h,
        left: AppDimensions.space16,
        right: AppDimensions.space16,
        bottom: AppDimensions.space16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {
              // TODO: Toggle favorite
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomSheet() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie title
          Text(
            widget.movie.title,
            style: AppTextStyles.headline4,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppDimensions.space8),
          
          // Rating and year
          Row(
            children: [
              Icon(
                Icons.star,
                size: 20.w,
                color: AppColors.ratingGold,
              ),
              SizedBox(width: 4.w),
              Text(
                widget.movie.formattedRating,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.movie.releaseYear != null) ...[
                SizedBox(width: 12.w),
                Text(
                  '• ${widget.movie.releaseYear}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ],
          ),
          
          SizedBox(height: AppDimensions.space16),
          
          // Quality selector
          Text(
            'Select Quality',
            style: AppTextStyles.labelLarge,
          ),
          SizedBox(height: AppDimensions.space8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _qualities.map((quality) {
                final isSelected = _selectedQuality == quality;
                final isPro = quality == '4K' || quality == 'Original';
                
                return Padding(
                  padding: EdgeInsets.only(right: AppDimensions.space8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(quality),
                        if (isPro) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.star,
                            size: 14.w,
                            color: AppColors.goldColor,
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedQuality = quality;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          SizedBox(height: AppDimensions.space16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Download wallpaper
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download started...')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Set as wallpaper
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Setting wallpaper...')),
                    );
                  },
                  icon: const Icon(Icons.wallpaper),
                  label: const Text('Set Wallpaper'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
                  ),
                ),
              ),
            ],
          ),
          
          // Watermark indicator for free users
          if (_selectedQuality != 'Original')
            Padding(
              padding: EdgeInsets.only(top: AppDimensions.space8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14.w,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Free version includes watermark',
                    style: AppTextStyles.watermarkLabel,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

