import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../services/permissions/permission_service.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import 'widgets/trending_carousel.dart';
import 'widgets/horizontal_movie_card.dart';
import '../detail/movie_detail_screen.dart';
import '../search/search_screen.dart';
import '../favorites/favorites_screen.dart';
import '../../widgets/app_logo.dart';

/// Home screen with real data - Complete implementation
class MovieMovieHomeScreen extends ConsumerStatefulWidget {
  const MovieMovieHomeScreen({super.key});

  @override
  ConsumerState<MovieMovieHomeScreen> createState() => _MovieMovieHomeScreenState();
}

class _MovieMovieHomeScreenState extends ConsumerState<MovieMovieHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkPermissionsOnLaunch();
  }

  Future<void> _checkPermissionsOnLaunch() async {
    // Check storage permission on app launch
    final hasStorage = await PermissionService.instance.hasStoragePermission();
    
    if (!hasStorage && mounted) {
      // Request permission with dialog
      await PermissionService.instance.requestAllPermissions(context: context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      ref.read(popularMoviesProvider.notifier).loadNextPage();
      ref.read(trendingMoviesProvider.notifier).refresh();
      ref.read(topRatedProvider.notifier).loadNextPage();
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final trendingAgg = ref.watch(trendingAggProvider);
    final popularAgg = ref.watch(popularAggProvider);
    final topRatedState = ref.watch(topRatedProvider);
    final trailersAgg = ref.watch(trailersAggProvider);
    final freeAgg = ref.watch(freeAggProvider);
    // Get provider states for new sections
    final upcomingState = ref.watch(upcomingProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const AppLogo(height: 32),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoritesScreen(),
                      ),
                    );
                  },
                ),
              ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(trendingMoviesProvider.notifier).refresh();
          await ref.read(popularMoviesProvider.notifier).refresh();
          await ref.read(topRatedProvider.notifier).refresh();
          await ref.read(trailersAggProvider.notifier).load();
          await ref.read(freeAggProvider.notifier).load();
          await ref.read(upcomingProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Trending Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.space16),
                child: Text(
                  'Trending Now',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ),

            // Trending Carousel
            if (trendingAgg.isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppDimensions.carouselHeight,
                  child: const LoadingIndicator(),
                ),
              )
            else if (trendingAgg.error != null)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: AppDimensions.carouselHeight,
                  child: AppErrorWidget(
                    message: 'Failed to load trending movies',
                    onRetry: () =>
                        ref.read(trendingAggProvider.notifier).load(),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: TrendingCarousel(
                  movies: trendingAgg.items.toList(),
                  seeMore: false,
                  limit: trendingAgg.items.length >= 20
                      ? 20
                      : trendingAgg.items.length,
                  onMovieTap: (movie) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movie: movie),
                      ),
                    );
                  },
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),
            
            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space16)),

            // Popular Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Popular Wallpapers',
                        style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        // Navigate to Search with popularity sort
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(sortByProvider.notifier).state =
                            'popularity.desc';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),
            // Top Popular Horizontal List
            if (popularAgg.items.isEmpty && popularAgg.isLoading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (popularAgg.items.isEmpty && popularAgg.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: popularAgg.error!,
                  onRetry: () =>
                      ref.read(popularAggProvider.notifier).loadInitial(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: popularAgg.items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = popularAgg.items[index];
                      return HorizontalMovieCard(
                        movie: movie,
                        typeBadge: 'Popular',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Top Rated Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Top Rated', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        ref.read(sortByProvider.notifier).state =
                            'vote_average.desc';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Top Rated Horizontal List
            if (topRatedState.items.isEmpty && topRatedState.isLoading)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (topRatedState.items.isEmpty && topRatedState.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: topRatedState.error!,
                  onRetry: () =>
                      ref.read(topRatedProvider.notifier).loadInitial(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: topRatedState.items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = topRatedState.items[index];
                      return HorizontalMovieCard(
                        movie: movie,
                        typeBadge: 'Top Rated',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),

            // Trailers Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Latest Trailers', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        // Use popularity for trailers discover as proxy
                        ref.read(sortByProvider.notifier).state =
                            'popularity.desc';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Trailers Horizontal List
            if (trailersAgg.items.isEmpty && trailersAgg.isLoading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (trailersAgg.items.isEmpty && trailersAgg.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: trailersAgg.error!,
                  onRetry: () => ref.read(trailersAggProvider.notifier).load(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: trailersAgg.items.length >= 5
                        ? 5
                        : trailersAgg.items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = trailersAgg.items[index];
                      return HorizontalMovieCard(
                        movie: movie,
                        typeBadge: 'Trailer',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),

            // Free To Watch Section Header
              SliverToBoxAdapter(
                child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Free to Watch', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state =
                            'release_date.desc';
                        // Default discover without region/date filters
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // Free To Watch Horizontal List
            if (freeAgg.items.isEmpty && freeAgg.isLoading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (freeAgg.items.isEmpty && freeAgg.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: freeAgg.error!,
                  onRetry: () => ref.read(freeAggProvider.notifier).load(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        freeAgg.items.length >= 5 ? 5 : freeAgg.items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = freeAgg.items[index];
                      return HorizontalMovieCard(
                        movie: movie,
                        typeBadge: 'Free',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space24)),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space16)),

            // New Releases Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Releases', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).state = '';
                        // Default discover without region/date filters
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchScreen()),
                        );
                      },
                      child: const Text('See more'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: AppDimensions.space12)),

            // New Releases Horizontal List
            if (upcomingState.items.isEmpty && upcomingState.isLoading)
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: Center(child: LoadingIndicator()),
                ),
              )
            else if (upcomingState.items.isEmpty && upcomingState.error != null)
              SliverToBoxAdapter(
                child: AppErrorWidget(
                  message: upcomingState.error!,
                  onRetry: () => ref.read(upcomingProvider.notifier).refresh(),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimensions.space16),
                    scrollDirection: Axis.horizontal,
                    itemCount: upcomingState.items.length >= 5
                        ? 5
                        : upcomingState.items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(width: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final movie = upcomingState.items[index];
                      return HorizontalMovieCard(
                        movie: movie,
                        typeBadge: 'Upcoming',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MovieDetailScreen(movie: movie),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
