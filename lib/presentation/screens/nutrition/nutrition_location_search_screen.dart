import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/location_search_service.dart';
import '../../../services/credit_manager.dart';

enum NutritionLocationCategory {
  pharmacy('pharmacy', 'Pharmacy', Icons.local_pharmacy),
  supermarket('supermarket', 'Supermarket', Icons.shopping_basket),
  market('market', 'Market', Icons.store),
  eatery('restaurant', 'Eatery', Icons.restaurant);

  final String type;
  final String displayName;
  final IconData icon;
  const NutritionLocationCategory(this.type, this.displayName, this.icon);
}

class NutritionLocationSearchScreen extends ConsumerStatefulWidget {
  const NutritionLocationSearchScreen({super.key});

  @override
  ConsumerState<NutritionLocationSearchScreen> createState() =>
      _NutritionLocationSearchScreenState();
}

class _NutritionLocationSearchScreenState
    extends ConsumerState<NutritionLocationSearchScreen> {
  NutritionLocationCategory _selectedCategory =
      NutritionLocationCategory.pharmacy;
  final List<NearbyPlace> _places = [];
  bool _isLoading = true;
  bool _isAccessBlocked = false;
  bool _isWatchingAds = false;
  String? _error;
  bool _creditsDeducted = false;
  final _service = LocationSearchService();

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    setState(() {
      _isLoading = true;
      _isAccessBlocked = false;
    });

    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager.requestCredit(
      context,
      ActionType.nutritionSearch,
      showDialog: false,
    );

    if (hasCredits) {
      _fetchPlaces();
    } else {
      if (mounted) {
        setState(() {
          _isAccessBlocked = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unlockWithAds() async {
    setState(() => _isWatchingAds = true);
    final creditManager = ref.read(creditManagerProvider);
    final success = await creditManager.showTripleAdsForAccess(context);

    if (success && mounted) {
      setState(() {
        _isAccessBlocked = false;
        _isWatchingAds = false;
      });
      _fetchPlaces();
    } else if (mounted) {
      setState(() => _isWatchingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete ad requirement.')),
      );
    }
  }

  Future<void> _fetchPlaces() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.findNearbyPlaces(
          _selectedCategory.type, _selectedCategory.displayName);
      if (mounted) {
        if (!_creditsDeducted && results.isNotEmpty) {
          final creditManager = ref.read(creditManagerProvider);
          await creditManager.consumeCredits(ActionType.nutritionSearch);
          _creditsDeducted = true;
        }

        setState(() {
          _places.clear();
          _places.addAll(results);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to fetch results. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isAccessBlocked) {
      return _buildAccessBlockedScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Nutrition & Wellness Finder',
          style: ResponsiveConfig.textStyle(
            size: 20,
            weight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.primary),
            onPressed: _fetchPlaces,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: NutritionLocationCategory.values.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat.displayName),
                    selected: isSelected,
                    avatar: Icon(cat.icon,
                        size: 16,
                        color: isSelected ? Colors.white : colorScheme.primary),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        _fetchPlaces();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Searching for ${_selectedCategory.displayName.toLowerCase()}s...',
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        color: theme.textTheme.bodySmall?.color ??
                            AppTheme.mediumGray,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? _buildErrorScreen()
                : _places.isEmpty
                    ? _buildEmptyScreen()
                    : _buildResultsList(),
      ),
    );
  }

  Widget _buildAccessBlockedScreen(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.lock,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Unlock Wellness Finder',
              textAlign: TextAlign.center,
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This feature requires 5 credits or watching 3 ads to access nearby wellness spots.',
              textAlign: TextAlign.center,
              style: ResponsiveConfig.textStyle(
                size: 16,
                color: theme.textTheme.bodyMedium?.color ?? AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: 48),
            _isWatchingAds
                ? Column(
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      const Text('Playing ads... Please wait.'),
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _unlockWithAds,
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Watch 3 Ads to Unlock'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchPlaces,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined,
              size: 64, color: AppTheme.mediumGray.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No locations found nearby',
            style: ResponsiveConfig.textStyle(
              size: 18,
              weight: FontWeight.bold,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching in a different area',
            style: ResponsiveConfig.textStyle(
              size: 14,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _fetchPlaces,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Refresh Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final p = _places[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showPlaceDetails(p),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: _buildPlaceImage(p, 100, 100),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            weight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (p.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.address!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color ??
                                  AppTheme.mediumGray,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (p.rating != null) ...[
                              const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                p.rating!,
                                style: ResponsiveConfig.textStyle(
                                  size: 12,
                                  weight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (p.reviewsCount != null)
                                Text(
                                  '(${p.reviewsCount})',
                                  style: ResponsiveConfig.textStyle(
                                    size: 12,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color ??
                                        AppTheme.mediumGray,
                                  ),
                                ),
                            ],
                            const Spacer(),
                            if (p.isOpen != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (p.isOpen! ? Colors.green : Colors.red)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.isOpen! ? 'OPEN' : 'CLOSED',
                                  style: ResponsiveConfig.textStyle(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color:
                                        p.isOpen! ? Colors.green : Colors.red,
                                  ),
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
        );
      },
    );
  }

  Widget _buildPlaceImage(NearbyPlace p, double width, double height) {
    if (p.photoReference == null) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        child: Icon(_selectedCategory.icon,
            color: Theme.of(context).colorScheme.primary),
      );
    }

    return FutureBuilder<String?>(
      future: _service.getMapsApiKey(),
      builder: (context, snapshot) {
        final apiKey = snapshot.data;
        if (apiKey == null) {
          return Container(
            width: width,
            height: height,
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(_selectedCategory.icon,
                color: Theme.of(context).colorScheme.primary),
          );
        }

        final photoUrl = p.getPhotoUrl(apiKey);
        if (photoUrl == null) {
          return Container(
            width: width,
            height: height,
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(_selectedCategory.icon,
                color: Theme.of(context).colorScheme.primary),
          );
        }

        return CachedNetworkImage(
          imageUrl: photoUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(_selectedCategory.icon,
                color: Theme.of(context).colorScheme.primary),
          ),
        );
      },
    );
  }

  Future<void> _showPlaceDetails(NearbyPlace p) async {
    if (p.placeId != null && (p.phone == null || p.website == null)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Fetching details...'),
            ],
          ),
        ),
      );

      final details = await _service.getPlaceDetails(p.placeId!);
      if (mounted) {
        Navigator.pop(context);
        if (details != null) {
          _showDetailsDialog(details);
        } else {
          _showDetailsDialog(p);
        }
      }
    } else {
      _showDetailsDialog(p);
    }
  }

  void _showDetailsDialog(NearbyPlace p) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: _buildPlaceImage(p, double.infinity, 250),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: IconButton(
                        icon: Icon(Icons.close, color: colorScheme.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: ResponsiveConfig.textStyle(
                        size: 22,
                        weight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (p.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            p.rating!,
                            style: ResponsiveConfig.textStyle(
                              size: 16,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${p.reviewsCount ?? '0'} Reviews)',
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    if (p.address != null)
                      _buildDetailItem(Icons.location_on, p.address!),
                    if (p.isOpen != null)
                      _buildDetailItem(
                        Icons.access_time,
                        p.isOpen! ? 'Open Now' : 'Currently Closed',
                        color: p.isOpen! ? Colors.green : Colors.red,
                      ),
                    if (p.phone != null)
                      _buildDetailItem(Icons.phone, p.phone!),
                    if (p.website != null)
                      _buildDetailItem(Icons.language, p.website!),
                    const SizedBox(height: 32),
                    if (p.website != null && p.website!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final creditManager =
                                ref.read(creditManagerProvider);
                            final hasCredits =
                                await creditManager.requestCredit(
                              context,
                              ActionType.nutritionSearch,
                            );

                            if (hasCredits) {
                              await creditManager
                                  .consumeCredits(ActionType.nutritionSearch);
                              final url = Uri.parse(p.website!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          icon: const Icon(Icons.language),
                          label: const Text('Visit Website'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (p.phone != null) {
                            final url = Uri.parse('tel:${p.phone}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Location'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: color ??
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppTheme.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
