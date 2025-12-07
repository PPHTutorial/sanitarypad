import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dio/dio.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../core/utils/debouncer.dart';
import '../../../domain/entities/movie.dart';
import '../../../services/scraping/scraping_service.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import '../home/widgets/wallpaper_grid_item.dart';
import '../detail/movie_detail_screen.dart';

/// Search screen provider
final searchQueryProvider = StateProvider<String>((ref) => '');
final sortByProvider = StateProvider<String>((ref) => 'popularity.desc');
final regionProvider = StateProvider<String>((ref) => '');
final fromDateProvider = StateProvider<String>((ref) => '');
final toDateProvider = StateProvider<String>((ref) => '');
final genresProvider = StateProvider<String>(
  (ref) => '',
); // comma-separated genre ids

final searchResultsProvider = FutureProvider.family<List<Movie>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  try {
    final searchUrl =
        'https://www.themoviedb.org/search/movie?query=' +
        Uri.encodeComponent(query);
    final scraper = ScrapingService.instance;
    final response = await Dio().get<String>(
      searchUrl,
      options: Options(headers: {'Accept': 'text/html, */*; q=0.01'}),
    );
    final models = scraper.extractSearchResultsFromHtml(response.data ?? '');
    final movies = models.map((m) => m.toEntity()).toList();
    // Dedupe by id
    final seen = <int>{};
    final deduped = <Movie>[];
    for (final m in movies) {
      if (seen.add(m.id)) deduped.add(m);
    }
    return deduped;
  } catch (e) {
    throw Exception('Failed to search: $e');
  }
});

/// Search screen with discover listing + search
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(
    delay: const Duration(milliseconds: 500),
  );
  final ScrollController _scrollController = ScrollController();

  List<Movie> _discoverItems = [];
  bool _isLoadingDiscover = false;
  int _currentPage = 1;
  bool _hasMore = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDiscover(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.call(() {
      ref.read(searchQueryProvider.notifier).state = query;
      if (query.isEmpty) {
        _loadDiscover(reset: true);
      }
    });
  }

  Future<void> _loadDiscover({bool reset = false}) async {
    if (_isLoadingDiscover) return;
    if (reset) {
      setState(() {
        _discoverItems = [];
        _currentPage = 1;
        _hasMore = true;
        _error = '';
      });
    }
    if (!_hasMore) return;

    // Capture the current page number before async operation
    final pageToLoad = _currentPage;

    setState(() {
      _isLoadingDiscover = true;
      _error = '';
    });

    try {
      final scraper = ref.read(movieScraperProvider);
      final sortBy = ref.read(sortByProvider);
      final region = ref.read(regionProvider);
      final fromDate = ref.read(fromDateProvider);
      final toDate = ref.read(toDateProvider);
      final genres = ref.read(genresProvider);

      final customParams = <String, String>{};
      if (genres.isNotEmpty) {
        customParams['with_genres'] = genres;
      }

      print(
        '🔍 [Discover] Loading page $pageToLoad with filters: sortBy=$sortBy, region=$region',
      );

      // Call getDiscoverViaMovieUrl with the page number (uses /movie endpoint with query params)
      final movies = await scraper.getDiscoverViaMovieUrl(
        page: pageToLoad,
        sortBy: sortBy,
        region: region.isEmpty ? null : region,
        watchRegion: region.isEmpty ? '' : region,
        releaseDateGte: fromDate.isEmpty ? null : fromDate,
        releaseDateLte: toDate.isEmpty ? null : toDate,
        customParams: customParams.isEmpty ? null : customParams,
      );

      print(
        '🔍 [Discover] getDiscoverViaMovieUrl returned ${movies.length} movies for page $pageToLoad',
      );

      if (mounted) {
        setState(() {
          _discoverItems = [..._discoverItems, ...movies];
          _hasMore = movies.length >= 20; // Assume 20 items per page
          _currentPage = pageToLoad + 1; // Increment for next load
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingDiscover = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isLoadingDiscover || !_hasMore) return; // Prevent multiple loads

    final position = _scrollController.position;
    // Trigger when user is 80% down the scroll (better UX than waiting for 100%)
    final threshold = position.maxScrollExtent * 0.8;

    if (position.pixels >= threshold) {
      final q = ref.read(searchQueryProvider);
      if (q.isEmpty) {
        print(
          '📜 [Scroll] Triggering load next page at ${(position.pixels / position.maxScrollExtent * 100).toStringAsFixed(1)}%',
        );
        _loadDiscover(reset: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = searchQuery.isNotEmpty
        ? ref.watch(searchResultsProvider(searchQuery))
        : null;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        toolbarHeight: 75,
        titleSpacing: 0,
        title: _buildSearchBar(),
        actions: [
          if (searchQuery.isEmpty)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filters',
              onPressed: _openFiltersSheet,
            ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
              _loadDiscover(reset: true);
            },
          ),
        ],
      ),
      body: searchResults == null
          ? _buildDiscoverBody()
          : searchResults.when(
              data: (movies) => movies.isEmpty
                  ? _buildNoResults()
                  : _buildSearchResults(movies),
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, stackTrace) => AppErrorWidget(
                message: 'Failed to search movies',
                onRetry: () =>
                    ref.invalidate(searchResultsProvider(searchQuery)),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 45.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search movies...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        _loadDiscover(reset: true);
                      },
                    )
                  : const SizedBox.shrink();
            },
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildDiscoverBody() {
    if (_error.isNotEmpty && _discoverItems.isEmpty) {
      return AppErrorWidget(
        message: _error,
        onRetry: () => _loadDiscover(reset: true),
      );
    }
    if (_isLoadingDiscover && _discoverItems.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (!_isLoadingDiscover && _discoverItems.isEmpty) {
      return const EmptyStateWidget(
        message: 'No movies found.\nTry adjusting filters or search.',
        icon: Icons.movie_outlined,
      );
    }
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (_) {
        return false;
      },
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.all(AppDimensions.space16),
        children: [
          const AdBannerWidget(),
          SizedBox(height: AppDimensions.space16),
          _buildGrid(_discoverItems),
          if (_isLoadingDiscover && _discoverItems.isNotEmpty) ...[
            SizedBox(height: AppDimensions.space16),
            const Center(child: LoadingIndicator()),
          ],
          SizedBox(height: AppDimensions.space24),
          // Middle Banner Ad
          const AdBannerWidget(),
          SizedBox(height: AppDimensions.space16),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return const EmptyStateWidget(
      message: 'No results found.\nTry a different search term.',
      icon: Icons.search_off,
    );
  }

  Widget _buildSearchResults(List<Movie> movies) {
    return ListView(
      padding: EdgeInsets.all(AppDimensions.space16),
      children: [
        const AdBannerWidget(),
        SizedBox(height: AppDimensions.space16),
        _buildGrid(movies),
        SizedBox(height: AppDimensions.space24),
        // Bottom Banner Ad
        const AdBannerWidget(),
        SizedBox(height: AppDimensions.space16),
      ],
    );
  }

  Widget _buildGrid(List<Movie> movies) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimensions.gridSpacing,
        crossAxisSpacing: AppDimensions.gridSpacing,
        childAspectRatio: AppDimensions.posterAspectRatio,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return WallpaperGridItem(
          movie: movie,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailScreen(movie: movie),
              ),
            );
          },
        );
      },
    );
  }

  void _openFiltersSheet() {
    final sortBy = ref.read(sortByProvider);
    final region = ref.read(regionProvider);
    final genres = ref.read(genresProvider);
    final from = ref.read(fromDateProvider);
    final to = ref.read(toDateProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      isScrollControlled: true,
      builder: (context) {
        String localSort = sortBy;
        String localRegion = region;
        String localGenres = genres;
        String localFrom = from;
        String localTo = to;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.space12),
                      Text('Filters', style: AppTextStyles.sectionTitle),
                      SizedBox(height: AppDimensions.space12),
                      _FilterCard(
                        child: DropdownButton<String>(
                          value: localSort,
                          items: const [
                            DropdownMenuItem(
                              value: 'popularity.desc',
                              child: Text('Popularity ↓'),
                            ),
                            DropdownMenuItem(
                              value: 'vote_average.desc',
                              child: Text('Rating ↓'),
                            ),
                            DropdownMenuItem(
                              value: 'primary_release_date.desc',
                              child: Text('Release date ↓'),
                            ),
                            DropdownMenuItem(
                              value: 'title.asc',
                              child: Text('Title A→Z'),
                            ),
                          ],
                          onChanged: (v) =>
                              setModal(() => localSort = v ?? localSort),
                          isExpanded: true,
                          style: AppTextStyles.bodyMedium,
                          dropdownColor: AppColors.darkSurface,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                          iconSize: 24,
                          underline: Container(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: AppDimensions.space12),
                      _FilterCard(
                        child: DropdownButton<String>(
                          value: localRegion.isEmpty ? '' : localRegion,
                          items: const [
                            DropdownMenuItem(
                              value: '',
                              child: Text('Any Region'),
                            ),
                            DropdownMenuItem(value: 'US', child: Text('US')),
                            DropdownMenuItem(value: 'GB', child: Text('UK')),
                            DropdownMenuItem(value: 'GH', child: Text('Ghana')),
                            DropdownMenuItem(value: 'IN', child: Text('India')),
                            DropdownMenuItem(
                              value: 'ZA',
                              child: Text('South Africa'),
                            ),
                            DropdownMenuItem(
                              value: 'NG',
                              child: Text('Nigeria'),
                            ),
                            DropdownMenuItem(value: 'KE', child: Text('Kenya')),
                            DropdownMenuItem(
                              value: 'ZA',
                              child: Text('Zambia'),
                            ),
                            DropdownMenuItem(
                              value: 'FR',
                              child: Text('France'),
                            ),
                            DropdownMenuItem(
                              value: 'DE',
                              child: Text('Germany'),
                            ),
                            DropdownMenuItem(value: 'IT', child: Text('Italy')),
                            DropdownMenuItem(value: 'ES', child: Text('Spain')),
                            DropdownMenuItem(
                              value: 'NL',
                              child: Text('Netherlands'),
                            ),
                            DropdownMenuItem(
                              value: 'BE',
                              child: Text('Belgium'),
                            ),
                            DropdownMenuItem(
                              value: 'CH',
                              child: Text('Switzerland'),
                            ),
                            DropdownMenuItem(
                              value: 'AT',
                              child: Text('Austria'),
                            ),
                            DropdownMenuItem(
                              value: 'SE',
                              child: Text('Sweden'),
                            ),
                          ],
                          onChanged: (v) =>
                              setModal(() => localRegion = v ?? localRegion),
                          isExpanded: true,
                          style: AppTextStyles.bodyMedium,
                          dropdownColor: AppColors.darkSurface,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                          iconSize: 24,
                          underline: Container(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: AppDimensions.space12),
                      _FilterCard(
                        child: TextField(
                          controller: TextEditingController(text: localGenres),
                          decoration: InputDecoration(
                            hintText: 'Genres (comma-separated IDs)',
                            filled: true,
                            fillColor: AppColors.darkBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.2),
                              ),
                            ),
                          ),
                          onChanged: (v) => localGenres = v.trim(),
                        ),
                      ),
                      SizedBox(height: AppDimensions.space12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(
                                localFrom.isEmpty ? 'From' : localFrom,
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  final y = picked.year.toString().padLeft(
                                    4,
                                    '0',
                                  );
                                  final m = picked.month.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final d = picked.day.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  setModal(() => localFrom = '$y-$m-$d');
                                }
                              },
                            ),
                          ),
                          SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event),
                              label: Text(localTo.isEmpty ? 'To' : localTo),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  final y = picked.year.toString().padLeft(
                                    4,
                                    '0',
                                  );
                                  final m = picked.month.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  final d = picked.day.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  setModal(() => localTo = '$y-$m-$d');
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimensions.space16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          SizedBox(width: AppDimensions.space12),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(sortByProvider.notifier).state =
                                  localSort;
                              ref.read(regionProvider.notifier).state =
                                  localRegion;
                              ref.read(genresProvider.notifier).state =
                                  localGenres;
                              ref.read(fromDateProvider.notifier).state =
                                  localFrom;
                              ref.read(toDateProvider.notifier).state = localTo;
                              Navigator.pop(context);
                              _loadDiscover(reset: true);
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterCard extends StatelessWidget {
  final Widget child;
  const _FilterCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}
