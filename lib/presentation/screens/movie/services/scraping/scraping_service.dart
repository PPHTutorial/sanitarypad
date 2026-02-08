import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/movie_model.dart';

/// Movie/Trailer scraping result (paged)
class ScrapedPage<T> {
  final int page;
  final List<T> data;
  ScrapedPage({required this.page, required this.data});
}

/// Versatile scraping/caching service for all TMDB endpoints
class ScrapingService {
  static final ScrapingService instance = ScrapingService._();
  final Dio _client = Dio(BaseOptions(
    connectTimeout: AppConstants.requestTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {'User-Agent': 'Mozilla/5.0'},
  ));

  ScrapingService._();

  /// Main paged data cache structure (endpoint + group + extra param + page)
  String _boxName(String key) =>
      'v${AppConstants.cacheSchemaVersion}_${key}_scraped_pages';

  /// Fetch and cache movies HTML per-page. If any prior page missing, re-fetch all.
  Future<List<MovieModel>> fetchAndCacheMoviesHtmlPaged({
    required String endpointKey, // e.g. 'trending_this_week'
    required String url,
    int page = 1,
    Map<String, String>? extraHeaders,
    String? body,
    bool post = false,
    String? uniqueComposite,
    bool forceNetwork = false,
  }) async {
    final boxName = _boxName(uniqueComposite ?? endpointKey);
    await Hive.openBox(boxName);
    final box = Hive.box(boxName);

    List<MovieModel> movies = [];
    // Only refetch if the current page or any before is not present OR forced
    bool needsRefresh = forceNetwork;
    if (!needsRefresh) {
      for (int p = 1; p <= page; p++) {
        final key = '${endpointKey}_page_$p';
        if (!box.containsKey(key)) {
          needsRefresh = true;
          break;
        }
      }
    }

    if (!needsRefresh) {
      // Return persisted data (all pages up to current)
      for (int p = 1; p <= page; p++) {
        final key = '${endpointKey}_page_$p';
        final entries = box.get(key) as List?;
        if (entries != null) {
          movies.addAll(entries.cast<MovieModel>());
        }
      }
      return movies;
    }

    // If missing, refetch ALL up to current
    await box.clear();
    for (int p = 1; p <= page; p++) {
      final data = await _fetchMoviesFromHtml(
        url: url,
        page: p,
        headers: extraHeaders,
        body: body,
        post: post,
      );
      // Save this page
      final key = '${endpointKey}_page_$p';
      await box.put(key, data);
      movies.addAll(data);
    }
    return movies;
  }

  /// Core: fetch HTML endpoint and parse MovieModel list
  Future<List<MovieModel>> _fetchMoviesFromHtml({
    required String url,
    int page = 1,
    Map<String, String>? headers,
    String? body,
    bool post = false,
  }) async {
    final allHeaders = {
      ...?headers,
      'Accept': 'text/html, */*; q=0.01',
      'Accept-Language': 'en-US,en;q=0.9',
      'Cache-Control': 'no-cache',
    };
    Response<String> response;
    if (post) {
      response = await _client.post<String>(
        url,
        data: body?.replaceFirst('page=1', 'page=$page'),
        options: Options(headers: allHeaders),
      );
    } else {
      var trueUrl = url;
      if (!url.contains('page=') && page > 1) {
        trueUrl += '${url.contains('?') ? '&' : '?'}page=$page';
      } else {
        trueUrl = url.replaceFirst(RegExp(r'page=[^&]*'), 'page=$page');
      }
      response = await _client.get<String>(trueUrl,
          options: Options(headers: allHeaders));
    }
    if (response.data == null) return [];
    return extractMoviesFromHtml(response.data!);
  }

  /// Extract MovieModel from HTML (bring back and improve previous logic)
  List<MovieModel> extractMoviesFromHtml(String htmlBody) {
    final document = html_parser.parse(htmlBody);
    final List<Element> items = document.querySelectorAll(
        '.card.style_1, .card, .item, .result, .card.v4, .card.v2');
    return items
        .map((el) {
          try {
            // Prefer options block data attributes
            final options = el.querySelector('.options');
            int id = int.tryParse(options?.attributes['data-id'] ?? '0') ?? 0;
            String mediaType =
                options?.attributes['data-media-type'] ?? 'movie';

            // Fallback: derive from href
            Element? link = el.querySelector(
                'h2 > a[href*="/movie/"], h2 > a[href*="/tv/"], a[href*="/movie/"], a[href*="/tv/"]');
            String? href = link?.attributes['href'] ??
                el
                    .querySelector('[href*="/movie/"], [href*="/tv/"]')
                    ?.attributes['href'];
            if ((id == 0 || mediaType.isEmpty) && href != null) {
              final match = RegExp(r'/(movie|tv)/(\d+)').firstMatch(href);
              if (match != null) {
                mediaType =
                    mediaType.isEmpty ? (match.group(1) ?? 'movie') : mediaType;
                id = id == 0 ? (int.tryParse(match.group(2) ?? '0') ?? 0) : id;
              }
            }

            // Title: from h2 > a or link title
            String title =
                el.querySelector('h2 > a')?.attributes['title']?.trim() ??
                    el.querySelector('h2 > a')?.text.trim() ??
                    link?.attributes['title']?.trim() ??
                    link?.text.trim() ??
                    el.querySelector('.title, h2, h3, .name')?.text.trim() ??
                    '';

            // Skip refine widgets (Sort / Where to watch / Filters)
            final tLow = title.toLowerCase();
            if (tLow == 'sort' ||
                tLow.startsWith('where to watch') ||
                tLow.contains('filters')) {
              return null;
            }

            // Poster path
            String? posterPath;
            final img = el.querySelector('img');
            if (img != null) {
              posterPath = img.attributes['data-src'] ?? img.attributes['src'];
              posterPath ??= img.attributes['data-srcset']
                  ?.split(',')
                  .first
                  .trim()
                  .split(' ')
                  .first;
              // Normalize /t/p path from media.themoviedb.org or image.tmdb.org
              if (posterPath != null) {
                final idx = posterPath.indexOf('/t/p/');
                if (idx != -1) {
                  posterPath = posterPath.substring(idx); // keep '/t/p/...'
                }
              }
            }

            // Overview and date
            final overview = el
                .querySelector('.overview, .content p, .details p')
                ?.text
                .trim();
            final dateText = el
                .querySelector('.content > p, .release_date, time')
                ?.text
                .trim();

            // Rating
            final ratingPercent = el
                .querySelector('.user_score_chart')
                ?.attributes['data-percent'];
            final ratingText = el.querySelector('.vote_average, .rating')?.text;
            final double voteAverage =
                _parseVoteAverage(ratingPercent, ratingText);
            final int voteCount = int.tryParse(el
                        .querySelector('.vote_count')
                        ?.text
                        .replaceAll(RegExp(r'\D'), '') ??
                    '') ??
                0;

            if (id == 0 && title.isEmpty && posterPath == null) return null;

            return MovieModel(
              id: id,
              title: title.isNotEmpty ? title : 'Unknown',
              overview: overview,
              posterPath: posterPath,
              backdropPath: null,
              voteAverage: voteAverage,
              voteCount: voteCount,
              releaseDate: dateText?.isNotEmpty == true ? dateText : null,
              genreIds: const <int>[],
              popularity: 0.0,
              adult: el.text.toLowerCase().contains('adult') ||
                  el.classes.contains('adult'),
              originalTitle: null,
              originalLanguage: null,
              mediaType: mediaType,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MovieModel>()
        .toList();
  }

  double _parseVoteAverage(String? percent, String? text) {
    if (percent != null) {
      final p = double.tryParse(percent.replaceAll('%', '').trim());
      if (p != null) return (p / 10.0).clamp(0.0, 10.0);
    }
    if (text != null) {
      final v = double.tryParse(text.trim());
      if (v != null) return v.clamp(0.0, 10.0);
    }
    return 0.0;
  }

  /// Restore the search HTML extraction logic (TMDB search page)
  List<MovieModel> extractSearchResultsFromHtml(String htmlBody) {
    final document = html_parser.parse(htmlBody);
    final List<Element> results =
        document.querySelectorAll('.search_result, .card, .item, .result');
    final out = <MovieModel>[];
    final seen = <int>{};
    for (final el in results) {
      try {
        final link = el.querySelector(
            'h2 > a[href*="/movie/"], h2 > a[href*="/tv/"], a[href*="/movie/"], a[href*="/tv/"]');
        String? href = link?.attributes['href'] ??
            el
                .querySelector('[href*="/movie/"], [href*="/tv/"]')
                ?.attributes['href'];
        if (href == null) {
          continue; // ignore non-content cards like refine widgets
        }
        final match = RegExp(r'/(movie|tv)/(\d+)').firstMatch(href);
        if (match == null) continue;
        final mediaType = match.group(1) ?? 'movie';
        final id = int.tryParse(match.group(2) ?? '0') ?? 0;
        if (id == 0 || seen.contains(id)) continue;

        String title =
            link?.attributes['title']?.trim() ?? link?.text.trim() ?? '';
        if (title.isEmpty) {
          title = el.querySelector('.title, h2, h3, .name')?.text.trim() ?? '';
        }
        if (title.isEmpty) continue;
        // Skip refine/sort widgets
        final low = title.toLowerCase();
        if (low == 'sort' || low.startsWith('where to watch')) continue;

        String? posterPath;
        final imgEl = el.querySelector('img');
        if (imgEl != null) {
          posterPath = imgEl.attributes['data-src'] ??
              imgEl.attributes['src'] ??
              imgEl.attributes['data-srcset']
                  ?.split(',')
                  .first
                  .trim()
                  .split(' ')
                  .first;
          final idx = posterPath != null ? posterPath.indexOf('/t/p/') : -1;
          if (idx != -1 && posterPath != null) {
            posterPath = posterPath.substring(idx);
          }
        }
        final overview =
            el.querySelector('.overview, .content p, .details p')?.text.trim();
        final model = MovieModel(
          id: id,
          title: title,
          overview: overview,
          posterPath: posterPath,
          backdropPath: null,
          voteAverage: 0.0,
          voteCount: 0,
          releaseDate: null,
          genreIds: const <int>[],
          popularity: 0.0,
          adult: el.text.toLowerCase().contains('adult'),
          originalTitle: null,
          originalLanguage: null,
          mediaType: mediaType,
        );
        out.add(model);
        seen.add(id);
      } catch (_) {
        // skip
      }
    }
    return out;
  }

  /// Clear cache for a scraping endpoint
  Future<void> clearScrapedCache(String endpointKey,
      {String? uniqueComposite}) async {
    final boxName = _boxName(uniqueComposite ?? endpointKey);
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      await box.clear();
    }
  }

  /// Fetch detailed info for a movie or tv by id
  Future<Map<String, dynamic>> fetchDetails({
    required String mediaType, // 'movie' or 'tv'
    required int id,
  }) async {
    final url = '${AppConstants.tmdbBaseUrl}/$mediaType/$id';
    final resp = await _client.get<String>(url,
        options: Options(headers: {
          'Accept': 'text/html, */*; q=0.01',
        }));
        
    final doc = html_parser.parse(resp.data ?? '');

    String? overview = doc
        .querySelector(
            '.overview, .wrap .content .overview, .header + .overview p')
        ?.text
        .trim();
    overview ??= doc
        .querySelector(
            '#series_overview, #movie_overview, .content .overview p')
        ?.text
        .trim();

    final tagline = doc.querySelector('.tagline')?.text.trim();

    // Facts block often contains runtime, status, original language, etc.
    String? runtime;
    final facts = doc.querySelectorAll('.facts li, .facts p');
    for (final f in facts) {
      final txt = f.text.trim().toLowerCase();
      if (txt.contains('runtime') ||
          txt.contains('duration') ||
          txt.contains('episode runtime')) {
        runtime = f.text.trim();
        break;
      }
    }

    String? releaseDate;
    releaseDate = doc
        .querySelector(
            '.release, .release_date, .header .date, .title .release_date')
        ?.text
        .trim();
    releaseDate ??= doc
        .querySelector(
            'span.release, span.release_date, .content .release_date')
        ?.text
        .trim();

    String? certification;
    certification = doc.querySelector('.certification')?.text.trim();

    final genres = <String>[];
    doc.querySelectorAll('.genres a, .genres span a').forEach((a) {
      final t = a.text.trim();
      if (t.isNotEmpty) genres.add(t);
    });

    String? userScore;
    final percent =
        doc.querySelector('.user_score_chart')?.attributes['data-percent'];
    if (percent != null && percent.isNotEmpty) userScore = percent.trim();

    return {
      'overview': overview,
      'tagline': tagline,
      'runtime': runtime,
      'releaseDate': releaseDate,
      'certification': certification,
      'genres': genres,
      'userScore': userScore,
      'episodes': _extractEpisodes(doc, id, mediaType),
    };
  }

  List<Map<String, dynamic>> _extractEpisodes(
      Document doc, int id, String mediaType) {
    if (mediaType != 'tv') return [];

    final episodes = <Map<String, dynamic>>[];
    final seasonPanel = doc.querySelector('.panel.season');

    if (seasonPanel != null) {
      // 1. Get Season Number
      // Example: <h2><a href="...">Season 4</a></h2>
      final seasonTitle = seasonPanel.querySelector('h2')?.text.trim();
      int seasonNum = 1; // Default
      if (seasonTitle != null) {
        final match = RegExp(r'Season (\d+)').firstMatch(seasonTitle);
        if (match != null) {
          seasonNum = int.tryParse(match.group(1) ?? '1') ?? 1;
        }
      }

      // 2. Get Episode Count
      // Example: <h4>2026 • 8 Episodes</h4>
      final subHeader = seasonPanel
              .querySelector('.season_overview')
              ?.parent
              ?.querySelector('h4')
              ?.text
              .trim() ??
          seasonPanel.querySelector('h4')?.text.trim();

      int episodeCount = 0;
      if (subHeader != null) {
        final match = RegExp(r'(\d+) Episodes').firstMatch(subHeader);
        if (match != null) {
          episodeCount = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }

      // 3. Generate Episode List
      if (episodeCount > 0) {
        for (int i = 1; i <= episodeCount; i++) {
          episodes.add({
            'media': 'tv',
            'id': id,
            'season': seasonNum,
            'episode': i,
            'name': 'Episode $i',
          });
        }
      }
    }
    return episodes;
  }

  /// Fetch image paths for posters/backdrops
  Future<List<String>> fetchImages({
    required String mediaType, // 'movie' or 'tv'
    required int id,
    required String kind, // 'posters' or 'backdrops'
  }) async {
    final url = '${AppConstants.tmdbBaseUrl}/$mediaType/$id/images/$kind';
    final resp = await _client.get<String>(url,
        options: Options(headers: {
          'Accept': 'text/html, */*; q=0.01',
        }));
    final doc = html_parser.parse(resp.data ?? '');
    final paths = <String>[];
    for (final img in doc.querySelectorAll('img')) {
      String? src = img.attributes['data-src'] ??
          img.attributes['src'] ??
          img.attributes['data-srcset']
              ?.split(',')
              .first
              .trim()
              .split(' ')
              .first;
      if (src == null || src.isEmpty) continue;
      // Normalize to /t/p path
      final idx = src.indexOf('/t/p/');
      if (idx != -1) {
        src = src.substring(idx);
        paths.add(src);
      } else if (src.startsWith('/t/p/')) {
        paths.add(src);
      }
    }
    // Deduplicate
    return paths.toSet().toList();
  }
}
