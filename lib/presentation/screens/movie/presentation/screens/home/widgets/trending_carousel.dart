import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../app/themes/app_colors.dart';
import '../../../../app/themes/app_dimensions.dart';
import '../../../../app/themes/app_text_styles.dart';
import '../../../../core/constants/tmdb_endpoints.dart';
import '../../../../domain/entities/movie.dart';
import '../../../widgets/cached_image_widget.dart';
import '../../search/search_screen.dart';

/// Trending movies carousel
class TrendingCarousel extends StatefulWidget {
  final List<Movie> movies;
  final Function(Movie)? onMovieTap;
  final bool seeMore;
  final int limit;

  const TrendingCarousel({
    super.key,
    required this.movies,
    this.onMovieTap,
    required this.seeMore,
    required this.limit,
  });

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return const SizedBox.shrink();
    }

    final base = widget.movies.take(widget.limit).toList();
    final carouselMovies = base;

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.seeMore
              ? carouselMovies.length + 1
              : carouselMovies.length,
          itemBuilder: (context, index, realIndex) {
            if (widget.seeMore) {
              return _buildSeeMoreCard(context);
            }
            final movie = carouselMovies[index];
            return _buildCarouselItem(movie);
          },
          options: CarouselOptions(
            height: 220.h,
            viewportFraction: 0.95,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        SizedBox(height: AppDimensions.space12),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: carouselMovies.length + 1,
          effect: ExpandingDotsEffect(
            activeDotColor: AppColors.accentColor,
            dotColor: AppColors.textDisabled,
            dotHeight: 8.h,
            dotWidth: 8.w,
            spacing: 4.w,
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(Movie movie) {
    return GestureDetector(
      onTap: () => widget.onMovieTap?.call(movie),
      child: Container(       
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Backdrop image
              if (movie.hasBackdrop)
                CachedImageWidget(
                  imageUrl: TMDBEndpoints.backdropUrl(
                    movie.backdropPath!,
                    size: BackdropSize.w1280,
                  ),
                  fit: BoxFit.cover,
                )
              else if (movie.hasPoster)
                CachedImageWidget(
                  imageUrl: TMDBEndpoints.posterUrl(
                    movie.posterPath!,
                    size: PosterSize.w780,
                  ),
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: AppColors.darkCard,
                  child: const Center(
                    child: Icon(
                      Icons.movie_outlined,
                      color: AppColors.textDisabled,
                      size: 60,
                    ),
                  ),
                ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Movie info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trending badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSmall,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14.w,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'TRENDING',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimensions.space8),
                      // Title
                      Text(
                        movie.title,
                        style: AppTextStyles.headline5,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppDimensions.space4),
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 18.w,
                            color: AppColors.ratingGold,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            movie.formattedRating,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (movie.releaseYear != null) ...[
                            SizedBox(width: 12.w),
                            Text(
                              '• ${movie.releaseYear}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
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

  Widget _buildSeeMoreCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Center(
          child: Text(
            'See more',
            style: AppTextStyles.headline5,
          ),
        ),
      ),
    );
  }
}
