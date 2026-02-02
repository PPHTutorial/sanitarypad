import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../domain/entities/movie.dart';
import '../../../services/storage/download_service.dart';
import '../../../services/storage/wallpaper_service.dart';
// Data fetching removed during rebuild
import '../../../services/permissions/permission_service.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/cached_image_widget.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/download_progress_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../../services/scraping/scraping_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/constants/tmdb_endpoints.dart';
import '../../../core/constants/app_constants.dart';

/// Complete movie detail screen with posters and backdrops gallery
class MovieDetailScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  int _selectedTab = 1; // 0: Backdrops, 1: Posters

  List<String> _allPosters = [];
  List<String> _allBackdrops = [];
  bool _isLoadingImages = false;

  // Movie details from HTML scraping
  String? _overview;
  String? _tagline;
  String? _runtime;
  String? _releaseDate;
  String? _certification;
  List<String> _genres = [];

  @override
  void initState() {
    super.initState();
    _fetchAllImages(); // Stubbed during logic rebuild
    _fetchMovieDetails(); // Stubbed during logic rebuild
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final mediaType =
          widget.movie.mediaType.isNotEmpty ? widget.movie.mediaType : 'movie';
      final map = await ScrapingService.instance.fetchDetails(
        mediaType: mediaType,
        id: widget.movie.id,
      );
      if (!mounted) return;
      setState(() {
        _overview = map['overview'] as String?;
        _tagline = map['tagline'] as String?;
        _runtime = map['runtime'] as String?;
        _releaseDate = map['releaseDate'] as String?;
        _certification = map['certification'] as String?;
        _genres = (map['genres'] as List?)?.cast<String>() ?? [];
      });
    } catch (e) {
      // keep UI resilient
    }
  }

  Future<void> _fetchAllImages() async {
    setState(() => _isLoadingImages = true);
    try {
      final mediaType =
          widget.movie.mediaType.isNotEmpty ? widget.movie.mediaType : 'movie';
      final posters = await ScrapingService.instance.fetchImages(
        mediaType: mediaType,
        id: widget.movie.id,
        kind: 'posters',
      );
      final backdrops = await ScrapingService.instance.fetchImages(
        mediaType: mediaType,
        id: widget.movie.id,
        kind: 'backdrops',
      );
      if (!mounted) return;
      setState(() {
        _allPosters = posters;
        _allBackdrops = backdrops;
        _isLoadingImages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          /* Consumer(
            builder: (context, ref, child) {
              final isPro = ref.watch(isProUserProvider);
              return IconButton(
                icon: const Icon(Icons.downloading),
                tooltip: isPro ? 'Download all images' : 'Pro feature',
                onPressed: () async {
                  await _handleDownloadAll(context);
                },
              );
            },
          ), */
          Consumer(
            builder: (context, ref, child) {
              final isFavorite = ref.watch(isFavoriteProvider(widget.movie.id));
              return IconButton(
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  ref
                      .read(favoritesProviders.notifier)
                      .toggleFavorite(widget.movie);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await Share.share(
                  'Check out ${widget.movie.title}!\nDownload the MovieWalls app for amazing wallpapers!',
                  subject: widget.movie.title,
                );
              } catch (e) {
                print('Share failed: $e');
              }
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Sliver hero with overview overlay
          SliverAppBar(
            elevation: 0,
            pinned: false,
            stretch: true,
            automaticallyImplyLeading: false,
            expandedHeight: ResponsiveConfig.height(400),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.movie.hasBackdrop)
                    CachedImageWidget(
                      imageUrl: TMDBEndpoints.backdropUrl(
                        widget.movie.backdropPath!,
                        size: BackdropSize.w1280,
                      ),
                      fit: BoxFit.cover,
                    )
                  else if (widget.movie.hasPoster)
                    CachedImageWidget(
                      imageUrl: TMDBEndpoints.posterUrl(
                        widget.movie.posterPath!,
                        size: PosterSize.w780,
                      ),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: Theme.of(context).colorScheme.surface),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Overview overlay

                  Positioned(
                    left: AppDimensions.space20,
                    right: AppDimensions.space20,
                    bottom: AppDimensions.space16 * 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.movie.title,
                          style: AppTextStyles.headline3
                              .copyWith(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppDimensions.space8),
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: 18.w,
                                color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 4.w),
                            Text(widget.movie.formattedRating,
                                style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                        if (_overview != null && _overview!.isNotEmpty) ...[
                          SizedBox(height: AppDimensions.space12),
                          Text(
                            _overview!,
                            style: AppTextStyles.bodyMedium
                                .copyWith(height: 1.5, color: Colors.white70),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppDimensions.space8),
                          GestureDetector(
                            onTap: () => _showFullOverview(context),
                            child: Text(
                              'Read more',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppTheme.deepPink,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                      bottom: ResponsiveConfig.height(20),
                      right: ResponsiveConfig.width(20),
                      child: InkWell(
                        onTap: () {
                          context.push('/movies/play', extra: widget.movie);
                        },
                        child: Container(
                          width: ResponsiveConfig.width(60),
                          height: ResponsiveConfig.height(60),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(
                              ResponsiveConfig.radius(100),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(0, 5),
                                  spreadRadius: 2),
                            ],
                          ),
                          child: Icon(Icons.play_arrow_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 35),
                        ),
                      )),
                ],
              ),
            ),
          ),

          // Sticky tabs header
          //SizedBox(height: AppDimensions.space12),
          SliverPersistentHeader(
            key: const ValueKey("123"),
            pinned: true,
            delegate: _StickyTabHeader(
              minExtentHeight: ResponsiveConfig.height(60),
              maxExtentHeight: ResponsiveConfig.height(60),
              builder: (context) => Container(
                height: ResponsiveConfig.height(80),
                //color: AppColors.darkBackground,
                //margin: EdgeInsets.only(top: AppDimensions.space4),
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.space20,
                  //vertical: AppDimensions.space8
                ),
                child: Container(
                  height: ResponsiveConfig.height(80),
                  padding: ResponsiveConfig.padding(all: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: _buildTabButton(
                              'Posters', 1, Icons.aspect_ratio)),
                      SizedBox(width: ResponsiveConfig.width(8)),
                      Expanded(
                          child: _buildTabButton('Backdrops', 0, Icons.photo)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppDimensions.space20),

                // Gallery
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                  child: _buildGallery(),
                ),

                ResponsiveConfig.spacingBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      // Removed bottom actions; toolbar buttons handle downloads
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        // Fetch images when switching tabs
        if (_allPosters.isEmpty && _allBackdrops.isEmpty) {
          _fetchAllImages();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.surface),
            SizedBox(width: ResponsiveConfig.width(4)),
            Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery() {
    if (_isLoadingImages) {
      return const LoadingIndicator(size: 48);
    }

    // Use fetched images
    final List<String> images = _selectedTab == 0 ? _allBackdrops : _allPosters;

    if (images.isEmpty) {
      print(
          '🔍 [MOVIE DETAIL] No images available for movie ID: ${widget.movie.id}, Tab: ${_selectedTab == 0 ? "Backdrops" : "Posters"}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48.w,
              color: Theme.of(context).colorScheme.surface,
            ),
            SizedBox(height: AppDimensions.space16),
            Text(
              'No images available',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppDimensions.space8),
            Text(
              'Movie ID: ${widget.movie.id}',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppDimensions.space12,
          crossAxisSpacing: AppDimensions.space12,
          childAspectRatio:
              _selectedTab == 0 ? 1.78 : 0.67, // Backdrop vs Poster ratio
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final rawPath = images[index];
          final isBackdrop = _selectedTab == 0;
          final imageUrl = isBackdrop
              ? TMDBEndpoints.backdropUrl(rawPath, size: BackdropSize.w1280)
              : TMDBEndpoints.posterUrl(rawPath, size: PosterSize.w780);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _ImageFullScreenView(
                    imageUrl: imageUrl,
                    rawPath: rawPath,
                    isBackdrop: isBackdrop,
                    movieTitle: widget.movie.title,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: CachedImageWidget(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  // Removed bottom actions; toolbar buttons handle downloads

  Future<void> _handleDownloadAll(BuildContext context) async {
    // Pro version - download all is always available
    final isPro = ref.read(isProUserProvider);

    // Get all images
    final allImages = <String>[];
    allImages.addAll(_allBackdrops);
    allImages.addAll(_allPosters);

    if (allImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No images available to download')),
        );
      }
      return;
    }

    await _showDownloadAllConfirmationAndDownload(context, allImages, isPro);
  }

  Future<void> _showDownloadAllConfirmationAndDownload(
    BuildContext context,
    List<String> allImages,
    bool isPro,
  ) async {
    // Show confirmation dialog
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download All Images?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to download ${allImages.length} images.'),
            const SizedBox(height: 12),
            const Text(
              '⚠️ This will incur significant internet data usage.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Images: ${_allBackdrops.length} backdrops + ${_allPosters.length} posters',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue Download'),
          ),
        ],
      ),
    );

    if (shouldContinue != true) return;

    await _downloadAllImages(allImages);
  }

  Future<void> _downloadAllImages(List<String> imagePaths) async {
    if (!mounted) return;

    await PermissionService.instance.requestAllPermissions();
    if (!await PermissionService.instance.hasStoragePermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
      return;
    }

    final isProUser = ref.read(isProUserProvider);

    // Build URLs with original quality
    final imageUrls = <String>[];
    final imageNames = <String>[];

    for (final path in imagePaths) {
      // Determine if it's a backdrop or poster based on which list it's in
      final isBackdrop = _allBackdrops.contains(path);
      final url = isBackdrop
          ? TMDBEndpoints.backdropUrl(path, size: BackdropSize.original)
          : TMDBEndpoints.posterUrl(path, size: PosterSize.original);

      // Skip if already downloaded
      if (DownloadService.instance.isAlreadyDownloaded(url)) {
        continue;
      }

      imageUrls.add(url);
      imageNames.add(isBackdrop
          ? 'Backdrop ${_allBackdrops.indexOf(path) + 1}'
          : 'Poster ${_allPosters.indexOf(path) + 1}');
    }

    if (imageUrls.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All images already downloaded!')),
        );
      }
      return;
    }

    // Create progress streams
    final progressController = StreamController<double>.broadcast();
    final currentItemController = StreamController<String>.broadcast();
    final completedController = StreamController<int>.broadcast();

    // Show progress dialog (don't await - it stays open via streams)
    DownloadProgressDialog.show(
      context: context,
      title: 'Downloading Images',
      subtitle: 'Downloading ${imageUrls.length} images...',
      progressStream: progressController.stream,
      currentItemStream: currentItemController.stream,
      totalItems: imageUrls.length,
      completedItemsStream: completedController.stream,
    );

    try {
      int completed = 0;

      for (int i = 0; i < imageUrls.length; i++) {
        currentItemController.add(imageNames[i]);

        try {
          await DownloadService.instance.downloadWallpaper(
            imageUrl: imageUrls[i],
            movieTitle: widget.movie.title,
            isPro: isProUser,
            onProgress: (progress) {
              final overallProgress = (i + progress) / imageUrls.length;
              progressController.add(overallProgress);
            },
          );

          completed++;
          completedController.add(completed);
          progressController.add((i + 1) / imageUrls.length);
        } catch (e) {
          AppLogger.e('Failed to download ${imageUrls[i]}', e);
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully downloaded $completed/${imageUrls.length} images!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Download all failed', e, stackTrace);
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await progressController.close();
      await currentItemController.close();
      await completedController.close();
    }
  }

  void _showFullOverview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: ResponsiveConfig.screenHeight * 0.60,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: AppDimensions.space12),
              width: ResponsiveConfig.width(40),
              height: ResponsiveConfig.height(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(ResponsiveConfig.radius(4)),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space16,
              ),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveConfig.width(50),
                    height: ResponsiveConfig.height(50),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Icon(
                      Icons.movie,
                      color: Theme.of(context).colorScheme.primary,
                      size: ResponsiveConfig.iconSize(30),
                    ),
                  ),
                  SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          style: AppTextStyles.headline4,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_tagline != null && _tagline!.isNotEmpty) ...[
                          SizedBox(height: ResponsiveConfig.height(4)),
                          Text(
                            _tagline!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: AppDimensions.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Synopsis
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppDimensions.space20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.08),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.format_quote,
                                size: ResponsiveConfig.width(24),
                                //
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Synopsis',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  fontSize: 18.sp,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppDimensions.space16),
                          Text(
                            _overview ?? 'No overview available',
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.6,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimensions.space20),

                    // Additional details
                    if (_certification != null ||
                        _releaseDate != null ||
                        _runtime != null ||
                        _genres.isNotEmpty) ...[
                      Text(
                        'Details',
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: AppDimensions.space16),
                      Wrap(
                        spacing: AppDimensions.space12,
                        runSpacing: AppDimensions.space12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (_certification != null &&
                              _certification!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveConfig.width(14),
                                vertical: ResponsiveConfig.height(10),
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveConfig.width(8),
                                      vertical: ResponsiveConfig.height(4),
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          ResponsiveConfig.borderRadius(8),
                                    ),
                                    child: Text(
                                      _certification!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveConfig.fontSize(12),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ResponsiveConfig.spacingBox(width: 8),
                                  Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontSize: ResponsiveConfig.fontSize(14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_releaseDate != null && _releaseDate!.isNotEmpty)
                            Container(
                              padding: ResponsiveConfig.padding(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimary,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 16.w,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _releaseDate!,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                          if (_runtime != null && _runtime!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time,
                                      size: 16.w,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface),
                                  SizedBox(width: 8.w),
                                  Text(
                                    _runtime!,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (_genres.isNotEmpty) ...[
                        SizedBox(height: AppDimensions.space12),
                        Wrap(
                          spacing: AppDimensions.space12,
                          runSpacing: AppDimensions.space12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: _genres.map((genre) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                //color: AppColors.darkBackground,
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSmall),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                genre,
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      SizedBox(height: AppDimensions.space20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Full screen image viewer
class _ImageFullScreenView extends ConsumerStatefulWidget {
  final String imageUrl;
  final String rawPath;
  final bool isBackdrop;
  final String movieTitle;

  const _ImageFullScreenView({
    required this.imageUrl,
    required this.rawPath,
    required this.isBackdrop,
    required this.movieTitle,
  });

  @override
  ConsumerState<_ImageFullScreenView> createState() =>
      _ImageFullScreenViewState();
}

class _ImageFullScreenViewState extends ConsumerState<_ImageFullScreenView> {
  bool _isDownloading = false;
  bool _isSettingWallpaper = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);

    try {
      final status = await PermissionService.instance.hasStoragePermission();
      if (!status) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

      // Use TMDB original size URL directly
      final downloadUrl = widget.isBackdrop
          ? TMDBEndpoints.backdropUrl(widget.rawPath,
              size: BackdropSize.original)
          : TMDBEndpoints.posterUrl(widget.rawPath, size: PosterSize.original);

      await DownloadService.instance.downloadWallpaper(
        imageUrl: downloadUrl,
        movieTitle: widget.movieTitle,
        isPro: true, // Pro version - always pro
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _setAsWallpaper() async {
    setState(() => _isSettingWallpaper = true);

    try {
      final granted = await PermissionService.instance.requestAllPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
        }
        return;
      }

      // Use TMDB original size URL for wallpaper
      // Use original quality URL
      final wallpaperUrl = widget.isBackdrop
          ? TMDBEndpoints.backdropUrl(widget.rawPath,
              size: BackdropSize.original)
          : TMDBEndpoints.posterUrl(widget.rawPath, size: PosterSize.original);

      // Set wallpaper directly from URL (uses original quality)
      final success = await WallpaperService.instance.setWallpaperFromUrl(
        imageUrl: wallpaperUrl,
        location: WallpaperLocation.both,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success
                  ? 'Wallpaper set successfully!'
                  : 'Failed to set wallpaper')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set wallpaper: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettingWallpaper = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProUserProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            child: CachedImageWidget(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          // Watermark overlay for free users
          if (!isPro)
            Center(
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8.w),
                  ),
                  child: Text(
                    AppConstants.watermarkText,
                    style: TextStyle(
                      color: Colors.white
                          .withOpacity(AppConstants.watermarkOpacity),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDownloading ? null : _download,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: const Text('Download',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: AppDimensions.space12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSettingWallpaper ? null : _setAsWallpaper,
                icon: _isSettingWallpaper
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.wallpaper),
                label: const Text('Set Wallpaper'),
                style: ElevatedButton.styleFrom(
                    //background
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sticky header delegate
class _StickyTabHeader extends SliverPersistentHeaderDelegate {
  final double minExtentHeight;
  final double maxExtentHeight;
  final WidgetBuilder builder;
  _StickyTabHeader(
      {required this.minExtentHeight,
      required this.maxExtentHeight,
      required this.builder});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return builder(context);
  }

  @override
  double get maxExtent => maxExtentHeight;

  @override
  double get minExtent => minExtentHeight;

  @override
  bool shouldRebuild(covariant _StickyTabHeader oldDelegate) {
    return oldDelegate.minExtentHeight != minExtentHeight ||
        oldDelegate.maxExtentHeight != maxExtentHeight ||
        oldDelegate.builder != builder;
  }
}
