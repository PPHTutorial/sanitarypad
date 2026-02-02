import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import '../../../../app/themes/app_dimensions.dart';
import '../../../../app/themes/app_text_styles.dart';
import '../../../../core/constants/tmdb_endpoints.dart';
import '../../../../domain/entities/movie.dart';
import '../../../providers/favorites_provider.dart';
import '../../../widgets/cached_image_widget.dart';

/// Wallpaper grid item widget
class WallpaperGridItem extends ConsumerWidget {
  final Movie movie;
  final VoidCallback? onTap;
  final bool showFavoriteButton;

  const WallpaperGridItem({
    super.key,
    required this.movie,
    this.onTap,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(movie.id));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image via TMDB URLs
              if (movie.hasPoster)
                CachedImageWidget(
                  imageUrl: TMDBEndpoints.posterUrl(
                    movie.posterPath!,
                    size: PosterSize.w500,
                  ),
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  child: Center(
                    child: Icon(
                      Icons.movie_outlined,
                      color: Theme.of(context).colorScheme.error,
                      size: 40,
                    ),
                  ),
                ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: ResponsiveConfig.height(105),
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
                ),
              ),

              // Movie info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        movie.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        movie.releaseDate.toString(),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      // Rating and year
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14.w,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            movie.formattedRating,
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (movie.releaseYear != null) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '• ${movie.releaseYear}',
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite button
              if (showFavoriteButton)
                Positioned(
                  top: AppDimensions.space8,
                  right: AppDimensions.space8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Theme.of(context).colorScheme.error
                            : Colors.white,
                      ),
                      iconSize: 20.w,
                      padding: EdgeInsets.all(AppDimensions.space8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref
                            .read(favoritesProviders.notifier)
                            .toggleFavorite(movie);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
