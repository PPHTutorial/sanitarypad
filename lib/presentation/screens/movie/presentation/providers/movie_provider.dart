import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/movie.dart';
import '../../services/scraping/scraping_service.dart';
import 'package:intl/intl.dart';
import '../../services/storage/cache_policy_service.dart';
// Data fetching removed for rebuild. Providers now stub empty data.

/// Pagination state
class PaginationState {
  final List<Movie> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMoreData;
  final String? error;

  const PaginationState({
    this.items = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMoreData = true,
    this.error,
  });

  PaginationState copyWith({
    List<Movie>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMoreData,
    String? error,
  }) {
    return PaginationState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      error: error,
    );
  }
}

// Real provider using ScrapingService
final movieScraperProvider = Provider<MovieScraperSource>(
  (ref) => MovieScraperSource(),
);

class MovieScraperSource {
  final _scraper = ScrapingService.instance;

  /// 1. Trending (group: today | this-week)
  Future<List<Movie>> getTrending({String group = 'this-week'}) async {
    final key = 'trending_$group';
    final url =
        'https://www.themoviedb.org/remote/panel?panel=trending_scroller&group=$group';
    final models = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: key,
      url: url,
      page: 1,
      extraHeaders: {'x-requested-with': 'XMLHttpRequest'},
      uniqueComposite: key,
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );
    return models.map((m) => m.toEntity()).toList();
  }

  /// 2. Popular (groups: streaming, on-tv, for-rent, in-theatres)
  Future<List<Movie>> getPopular({
    int page = 1,
    String group = 'streaming',
  }) async {
    final key = 'popular_$group';
    final url =
        'https://www.themoviedb.org/remote/panel?panel=popular_scroller&group=$group';
    final models = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: key,
      url: url,
      page: page,
      extraHeaders: {'x-requested-with': 'XMLHttpRequest'},
      uniqueComposite: key,
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );
    return models.map((m) => m.toEntity()).toList();
  }

  /// 3. Trailers (groups: popular, streaming, on-tv)
  Future<List<Movie>> getTrailers({String group = 'popular'}) async {
    final key = 'trailers_$group';
    final url =
        'https://www.themoviedb.org/remote/panel?panel=trailer_scroller&group=$group';
    final models = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: key,
      url: url,
      page: 1,
      extraHeaders: {'x-requested-with': 'XMLHttpRequest'},
      uniqueComposite: key,
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );
    return models.map((m) => m.toEntity()).toList();
  }

  /// 4. Free to Watch (group: movie | tv)
  Future<List<Movie>> getFreeToWatch({String group = 'tv'}) async {
    final key = 'free_$group&sort_by=popularity.desc';
    final url =
        'https://www.themoviedb.org/remote/panel?panel=free_scroller&group=$group';
    final models = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: key,
      url: url,
      page: 1,
      extraHeaders: {'x-requested-with': 'XMLHttpRequest'},
      uniqueComposite: key,
      post: false,
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );
    return models.map((m) => m.toEntity()).toList();
  }

  /// 5. Discover movies (with arbitrary POST body)
  Future<List<Movie>> getDiscover({
    int page = 1,
    String sortBy = 'popularity.desc',
    String? region,
    String watchRegion = '',
    String? releaseDateLte,
    String? releaseDateGte,
    Map<String, String>? customParams,
  }) async {
    // Create POST body based on endpoints.md logic
    final DateFormat fmt = DateFormat('yyyy-MM-dd');
    final today = fmt.format(DateTime.now());
    final defaultLte = releaseDateLte ?? today;
    final body = {
      'air_date.gte': '',
      'air_date.lte': '',
      'certification': '',
      'certification_country': region ?? 'GH',
      'debug': '',
      'first_air_date.gte': '',
      'first_air_date.lte': '',
      'page': page.toString(),
      'primary_release_date.gte': '',
      'primary_release_date.lte': '',
      'region': region ?? '',
      'release_date.gte': releaseDateGte ?? '',
      'release_date.lte': defaultLte,
      'show_me': 'everything',
      'sort_by': sortBy,
      'vote_average.gte': '0',
      'vote_average.lte': '10',
      'vote_count.gte': '0',
      'watch_region': watchRegion,
      'with_genres': '',
      'with_keywords': '',
      'with_networks': '',
      'with_origin_country': '',
      'with_original_language': '',
      'with_watch_monetization_types': '',
      'with_watch_providers': '',
      'with_release_type': '',
      'with_runtime.gte': '0',
      'with_runtime.lte': '400',
    };
    if (customParams != null) body.addAll(customParams);
    final bodyStr = body.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final key = 'discover_${body['sort_by']}_${watchRegion}_page_${page}';
    final url = 'https://www.themoviedb.org/discover/movie';
    final models = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: key,
      url: url,
      page: 1,
      extraHeaders: {
        'x-requested-with': 'XMLHttpRequest',
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      },
      body: bodyStr,
      post: false,
      uniqueComposite: key,
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );
    return models.map((m) => m.toEntity()).toList().sublist(3);
  }

  /// 5b. Discover movies via /movie endpoint with query parameters (for search screen)
  Future<List<Movie>> getDiscoverViaMovieUrl({
    int page = 1,
    String sortBy = 'popularity.desc',
    String? region,
    String watchRegion = '',
    String? releaseDateLte,
    String? releaseDateGte,
    Map<String, String>? customParams,
  }) async {
    // Create query parameters from body structure
    final DateFormat fmt = DateFormat('yyyy-MM-dd');
    final today = fmt.format(DateTime.now());
    final defaultLte = releaseDateLte ?? today;

    final queryParams = <String, String>{
      'air_date.gte': '',
      'air_date.lte': '',
      'certification': '',
      'certification_country': region ?? 'GH',
      'debug': '',
      'first_air_date.gte': '',
      'first_air_date.lte': '',
      'page': page.toString(),
      'primary_release_date.gte': '',
      'primary_release_date.lte': '',
      'region': region ?? '',
      'release_date.gte': releaseDateGte ?? '',
      'release_date.lte': defaultLte,
      'show_me': 'everything',
      'sort_by': sortBy,
      'vote_average.gte': '0',
      'vote_average.lte': '10',
      'vote_count.gte': '0',
      'watch_region': watchRegion,
      'with_genres': '',
      'with_keywords': '',
      'with_networks': '',
      'with_origin_country': '',
      'with_original_language': '',
      'with_watch_monetization_types': '',
      'with_watch_providers': '',
      'with_release_type': '',
      'with_runtime.gte': '0',
      'with_runtime.lte': '400',
    };

    if (customParams != null) queryParams.addAll(customParams);

    // Build URL with query parameters
    final queryString = queryParams.entries
        .where((e) => e.value.isNotEmpty) // Only include non-empty params
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final url = 'https://www.themoviedb.org/movie?$queryString';
    // endpointKey should NOT include page number - it's used for the cache box name
    // The page number is handled internally by fetchAndCacheMoviesHtmlPaged
    final endpointKey = 'discover_movie_${sortBy}_${watchRegion}';
    final uniqueComposite = endpointKey; // Same for all pages of this query

    print('🌐 [getDiscoverViaMovieUrl] URL: $url');
    print('🌐 [getDiscoverViaMovieUrl] Page: $page');
    print('🌐 [getDiscoverViaMovieUrl] EndpointKey: $endpointKey');

    // fetchAndCacheMoviesHtmlPaged returns ALL pages from 1 to page
    // We need to extract only the items for the requested page
    // Strategy: Calculate how many items were in previous pages, then extract only new ones

    int previousItemsCount = 0;
    if (page > 1) {
      // Fetch pages 1 to (page-1) to get the count of previous items
      final previousModels = await _scraper.fetchAndCacheMoviesHtmlPaged(
        endpointKey: endpointKey,
        url: url,
        page: page - 1,
        extraHeaders: {'x-requested-with': 'XMLHttpRequest'},
        body: null,
        post: false,
        uniqueComposite: uniqueComposite,
        forceNetwork: false, // Use cache if available
      );
      previousItemsCount = previousModels.length;
      print(
        '🌐 [getDiscoverViaMovieUrl] Previous pages (1-${page - 1}) have $previousItemsCount items',
      );
    }

    // Now fetch all pages up to current page
    final allModels = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: endpointKey,
      url: url,
      page: page,
      extraHeaders: {'x-requested-with': 'XMLHttpRequest'},
      body: null,
      post: false,
      uniqueComposite: uniqueComposite,
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );

    // Extract only the new page's items (items beyond previousItemsCount)
    final newModels = previousItemsCount < allModels.length
        ? allModels.sublist(previousItemsCount)
        : allModels; // If page 1, return all

    final result = newModels.map((m) => m.toEntity()).toList();
    print(
      '🌐 [getDiscoverViaMovieUrl] Total models: ${allModels.length}, Previous: $previousItemsCount, New page items: ${result.length}',
    );

    return result;
  }

  /// 6. Upcoming - release dates must be dynamic by current date
  Future<List<Movie>> getUpcoming({int page = 1, String? watchRegion}) async {
    final DateFormat fmt = DateFormat('yyyy-MM-dd');
    final now = DateTime.now();
    final gte = fmt.format(now);
    final lte = fmt.format(now.add(Duration(days: 180)));
    final body = {
      'air_date.gte': '',
      'air_date.lte': '',
      'certification': '',
      'certification_country': watchRegion ?? 'GH',
      'debug': '',
      'first_air_date.gte': '',
      'first_air_date.lte': '',
      'page': page.toString(),
      'primary_release_date.gte': '',
      'primary_release_date.lte': '',
      'region': '',
      'release_date.gte': gte,
      'release_date.lte': lte,
      'show_me': 'everything',
      'sort_by': 'popularity.desc',
      'vote_average.gte': '0',
      'vote_average.lte': '10',
      'vote_count.gte': '0',
      'watch_region': watchRegion ?? 'GH',
      'with_genres': '',
      'with_keywords': '',
      'with_networks': '',
      'with_origin_country': '',
      'with_original_language': '',
      'with_watch_monetization_types': '',
      'with_watch_providers': '',
      'with_release_type': '',
      'with_runtime.gte': '0',
      'with_runtime.lte': '400',
    };
    final bodyStr = body.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final key =
        'release_date.gte=$gte&release_date.lte=$lte&show_me=everything&sort_by=popularity.desc';
    final url = 'https://www.themoviedb.org/movie?${key}';
    final models = await _scraper.fetchAndCacheMoviesHtmlPaged(
      endpointKey: '',
      url: url,
      page: 1,
      extraHeaders: {
        'x-requested-with': 'XMLHttpRequest',
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
      },
      body: bodyStr,
      post: false,
      uniqueComposite: '',
      forceNetwork: CachePolicyService.instance.consumeForceNetwork(),
    );
    print('urls: ${url}');
    return models.map((m) => m.toEntity()).toList();
  }
}

/// Trending movies state
class TrendingMoviesState {
  final List<Movie> items;
  final bool isLoading;
  final String? error;

  const TrendingMoviesState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  TrendingMoviesState copyWith({
    List<Movie>? items,
    bool? isLoading,
    String? error,
  }) {
    return TrendingMoviesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Trending movies provider with StateNotifier
final trendingMoviesProvider =
    StateNotifierProvider<TrendingMoviesNotifier, TrendingMoviesState>((ref) {
      final scraper = ref.watch(movieScraperProvider);
      return TrendingMoviesNotifier(scraper);
    });

/// Trending movies notifier
class TrendingMoviesNotifier extends StateNotifier<TrendingMoviesState> {
  final MovieScraperSource _scraper;

  TrendingMoviesNotifier(this._scraper) : super(const TrendingMoviesState()) {
    loadTrending();
  }

  /// Load trending movies
  Future<void> loadTrending() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final movies = await _scraper.getTrending();
      state = state.copyWith(items: movies, isLoading: false, error: null);
    } catch (e, stackTrace) {
      AppLogger.e('Error loading trending movies', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh trending movies
  Future<void> refresh() async {
    await loadTrending();
  }
}

/// Popular movies with pagination provider
final popularMoviesProvider =
    StateNotifierProvider<PopularMoviesNotifier, PaginationState>((ref) {
      final scraper = ref.watch(movieScraperProvider);
      return PopularMoviesNotifier(scraper);
    });

/// Popular movies notifier with pagination
class PopularMoviesNotifier extends StateNotifier<PaginationState> {
  final MovieScraperSource _scraper;

  PopularMoviesNotifier(this._scraper) : super(const PaginationState()) {
    loadInitial();
  }

  /// Load initial data
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final movies = await _scraper.getPopular(page: 1);
      state = state.copyWith(
        items: movies,
        currentPage: 1,
        isLoading: false,
        hasMoreData: movies.length >= 20,
        error: null,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error loading popular movies', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMoreData) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final movies = await _scraper.getPopular(page: nextPage);
      final updatedItems = [...state.items, ...movies];
      state = state.copyWith(
        items: updatedItems,
        currentPage: nextPage,
        isLoading: false,
        hasMoreData: movies.length >= 20,
        error: null,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error loading next page', e, stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    state = const PaginationState();
    await loadInitial();
  }
}

// ---- Trailers Provider ----
class TrailersState {
  final List<Movie> items;
  final bool isLoading;
  final String? error;
  const TrailersState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  TrailersState copyWith({
    List<Movie>? items,
    bool? isLoading,
    String? error,
  }) => TrailersState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

final trailersProvider =
    StateNotifierProvider.autoDispose<TrailersNotifier, TrailersState>((ref) {
      final scraper = ref.watch(movieScraperProvider);
      return TrailersNotifier(scraper);
    });

class TrailersNotifier extends StateNotifier<TrailersState> {
  final MovieScraperSource _scraper;
  TrailersNotifier(this._scraper) : super(const TrailersState()) {
    loadTrailers();
  }
  Future<void> loadTrailers({String group = 'popular'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movies = await _scraper.getTrailers(group: group);
      state = state.copyWith(items: movies, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ---- Free To Watch Provider ----
class FreeToWatchState {
  final List<Movie> items;
  final bool isLoading;
  final String? error;
  const FreeToWatchState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  FreeToWatchState copyWith({
    List<Movie>? items,
    bool? isLoading,
    String? error,
  }) => FreeToWatchState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

final freeToWatchProvider =
    StateNotifierProvider.autoDispose<FreeToWatchNotifier, FreeToWatchState>((
      ref,
    ) {
      final scraper = ref.watch(movieScraperProvider);
      return FreeToWatchNotifier(scraper);
    });

class FreeToWatchNotifier extends StateNotifier<FreeToWatchState> {
  final MovieScraperSource _scraper;
  FreeToWatchNotifier(this._scraper) : super(const FreeToWatchState()) {
    loadFreeToWatch();
  }
  Future<void> loadFreeToWatch({String group = 'movie'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movies = await _scraper.getFreeToWatch(group: group);
      state = state.copyWith(items: movies, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ---- Discover Provider ----
class DiscoverState {
  final List<Movie> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMoreData;
  final String? error;
  const DiscoverState({
    this.items = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMoreData = true,
    this.error,
  });
  DiscoverState copyWith({
    List<Movie>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMoreData,
    String? error,
  }) => DiscoverState(
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    hasMoreData: hasMoreData ?? this.hasMoreData,
    error: error,
  );
}

final discoverProvider =
    StateNotifierProvider.autoDispose<DiscoverNotifier, DiscoverState>((ref) {
      final scraper = ref.watch(movieScraperProvider);
      return DiscoverNotifier(scraper);
    });

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final MovieScraperSource _scraper;
  DiscoverNotifier(this._scraper) : super(const DiscoverState()) {
    loadInitial();
  }
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movies = await _scraper.getDiscover(page: 1);
      state = state.copyWith(
        items: movies,
        currentPage: 1,
        isLoading: false,
        hasMoreData: movies.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMoreData) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final movies = await _scraper.getDiscover(page: nextPage);
      final updatedItems = [...state.items, ...movies];
      state = state.copyWith(
        items: updatedItems,
        currentPage: nextPage,
        isLoading: false,
        hasMoreData: movies.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const DiscoverState();
    await loadInitial();
  }
}

// ---- Upcoming Provider ----
class UpcomingState {
  final List<Movie> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMoreData;
  final String? error;
  const UpcomingState({
    this.items = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMoreData = true,
    this.error,
  });
  UpcomingState copyWith({
    List<Movie>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMoreData,
    String? error,
  }) => UpcomingState(
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    hasMoreData: hasMoreData ?? this.hasMoreData,
    error: error,
  );
}

final upcomingProvider =
    StateNotifierProvider.autoDispose<UpcomingNotifier, UpcomingState>((ref) {
      final scraper = ref.watch(movieScraperProvider);
      return UpcomingNotifier(scraper);
    });

class UpcomingNotifier extends StateNotifier<UpcomingState> {
  final MovieScraperSource _scraper;
  UpcomingNotifier(this._scraper) : super(const UpcomingState()) {
    loadInitial();
  }
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movies = await _scraper.getUpcoming(page: 1);
      state = state.copyWith(
        items: movies,
        currentPage: 1,
        isLoading: false,
        hasMoreData: movies.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMoreData) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.currentPage + 1;
      final movies = await _scraper.getUpcoming(page: nextPage);
      final updatedItems = [...state.items, ...movies];
      state = state.copyWith(
        items: updatedItems,
        currentPage: nextPage,
        isLoading: false,
        hasMoreData: movies.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const UpcomingState();
    await loadInitial();
  }
}

// ---- Top Rated (via Discover sort_by=vote_average.desc) ----
class TopRatedState {
  final List<Movie> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMoreData;
  final String? error;
  const TopRatedState({
    this.items = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMoreData = true,
    this.error,
  });
  TopRatedState copyWith({
    List<Movie>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMoreData,
    String? error,
  }) => TopRatedState(
    items: items ?? this.items,
    currentPage: currentPage ?? this.currentPage,
    isLoading: isLoading ?? this.isLoading,
    hasMoreData: hasMoreData ?? this.hasMoreData,
    error: error,
  );
}

final topRatedProvider = StateNotifierProvider<TopRatedNotifier, TopRatedState>(
  (ref) {
    final scraper = ref.watch(movieScraperProvider);
    return TopRatedNotifier(scraper);
  },
);

class TopRatedNotifier extends StateNotifier<TopRatedState> {
  final MovieScraperSource _scraper;
  TopRatedNotifier(this._scraper) : super(const TopRatedState()) {
    loadInitial();
  }
  Future<void> loadInitial() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final movies = await _scraper.getDiscover(
        page: 1,
        sortBy: 'vote_average.desc',
      );
      state = state.copyWith(
        items: movies,
        currentPage: 1,
        isLoading: false,
        hasMoreData: movies.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMoreData) return;
    state = state.copyWith(isLoading: true);
    try {
      final next = state.currentPage + 1;
      final movies = await _scraper.getDiscover(
        page: next,
        sortBy: 'vote_average.desc',
      );
      state = state.copyWith(
        items: [...state.items, ...movies],
        currentPage: next,
        isLoading: false,
        hasMoreData: movies.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const TopRatedState();
    await loadInitial();
  }
}

extension on List<Movie> {
  List<Movie> dedupeById() {
    final seen = <int>{};
    final out = <Movie>[];
    for (final m in this) {
      if (seen.add(m.id)) out.add(m);
    }
    return out;
  }
}

class AggregatedState {
  final List<Movie> items;
  final bool isLoading;
  final String? error;
  const AggregatedState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  AggregatedState copyWith({
    List<Movie>? items,
    bool? isLoading,
    String? error,
  }) => AggregatedState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

final trendingAggProvider =
    StateNotifierProvider<TrendingAggNotifier, AggregatedState>((ref) {
      final src = ref.watch(movieScraperProvider);
      return TrendingAggNotifier(src);
    });

class TrendingAggNotifier extends StateNotifier<AggregatedState> {
  final MovieScraperSource _src;
  TrendingAggNotifier(this._src) : super(const AggregatedState()) {
    load();
  }
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final a = await _src.getTrending(group: 'this-week');
      final b = await _src.getTrending(group: 'today');
      final merged = [...a, ...b].dedupeById();
      state = state.copyWith(items: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final popularAggProvider =
    StateNotifierProvider<PopularAggNotifier, AggregatedState>((ref) {
      final src = ref.watch(movieScraperProvider);
      return PopularAggNotifier(src);
    });

class PopularAggNotifier extends StateNotifier<AggregatedState> {
  final MovieScraperSource _src;
  PopularAggNotifier(this._src) : super(const AggregatedState()) {
    loadInitial();
  }
  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final a = await _src.getPopular(group: 'streaming');
      final b = await _src.getPopular(group: 'on-tv');
      final c = await _src.getPopular(group: 'for-rent');
      final d = await _src.getPopular(group: 'in-theatres');
      final merged = [...a, ...b, ...c, ...d].dedupeById();
      state = state.copyWith(items: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final trailersAggProvider =
    StateNotifierProvider<TrailersAggNotifier, AggregatedState>((ref) {
      final src = ref.watch(movieScraperProvider);
      return TrailersAggNotifier(src);
    });

class TrailersAggNotifier extends StateNotifier<AggregatedState> {
  final MovieScraperSource _src;
  TrailersAggNotifier(this._src) : super(const AggregatedState()) {
    load();
  }
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final a = await _src.getTrailers(group: 'popular');
      final b = await _src.getTrailers(group: 'streaming');
      final c = await _src.getTrailers(group: 'on-tv');
      final merged = [...a, ...b, ...c].dedupeById();
      state = state.copyWith(items: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final freeAggProvider = StateNotifierProvider<FreeAggNotifier, AggregatedState>(
  (ref) {
    final src = ref.watch(movieScraperProvider);
    return FreeAggNotifier(src);
  },
);

class FreeAggNotifier extends StateNotifier<AggregatedState> {
  final MovieScraperSource _src;
  FreeAggNotifier(this._src) : super(const AggregatedState()) {
    load();
  }
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final a = await _src.getFreeToWatch(group: 'movie');
      final b = await _src.getFreeToWatch(group: 'tv');
      final merged = [...a, ...b].dedupeById();
      state = state.copyWith(items: merged, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
