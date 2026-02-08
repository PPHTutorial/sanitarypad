import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/themes/app_dimensions.dart';
import '../../../../app/themes/app_text_styles.dart';
import '../../../../core/constants/tmdb_endpoints.dart';
import '../../../../domain/entities/movie.dart';
import '../../../widgets/cached_image_widget.dart';

/// Horizontal movie card with title, rating, and type badge
class HorizontalMovieCard extends StatelessWidget {
  final Movie movie;
  final String typeBadge; // e.g., "Popular", "Top Rated", "Latest Trailers"
  final VoidCallback? onTap;

  const HorizontalMovieCard({
    super.key,
    required this.movie,
    required this.typeBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
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
              // Poster image
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
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 40,
                    ),
                  ),
                ),

              // Gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100.h,
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

              // Type badge at top
              Positioned(
                top: 8.h,
                left: 8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    typeBadge,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),

              // Title and rating at bottom
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
                      SizedBox(height: 4.h),
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14.w,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            movie.formattedRating,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '(${movie.mediaType == "tv" ? "Series" : "Movie"})',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                            ),
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
    );
  }
}
