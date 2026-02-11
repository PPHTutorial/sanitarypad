import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/dermatologist_service.dart';
import '../../../services/credit_manager.dart';

class DermatologistSearchScreen extends ConsumerStatefulWidget {
  const DermatologistSearchScreen({super.key});

  @override
  ConsumerState<DermatologistSearchScreen> createState() =>
      _DermatologistSearchScreenState();
}

class _DermatologistSearchScreenState
    extends ConsumerState<DermatologistSearchScreen> {
  final List<Dermatologist> _dermatologists = [];
  bool _isLoading = true;
  bool _isAccessBlocked = false;
  bool _isWatchingAds = false;
  String? _error;
  bool _creditsDeducted = false;
  final _service = DermatologistService();

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
      ActionType.dermatologist,
      showDialog: false, // We'll handle our own UI
    );

    if (hasCredits) {
      // Don't consume yet, wait for successful fetch
      _fetchDermatologists();
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
      _fetchDermatologists();
    } else if (mounted) {
      setState(() => _isWatchingAds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete ad requirement.')),
      );
    }
  }

  Future<void> _fetchDermatologists() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.findNearbyDermatologists();
      if (mounted) {
        // ONLY DEDUCT CREDITS AFTER SUCCESSFUL FETCH
        if (!_creditsDeducted && results.isNotEmpty) {
          final creditManager = ref.read(creditManagerProvider);
          await creditManager.consumeCredits(ActionType.dermatologist);
          _creditsDeducted = true;
        }

        setState(() {
          _dermatologists.clear();
          _dermatologists.addAll(results);
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
          'Specialist Finder',
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
            onPressed: _fetchDermatologists,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Searching for specialists...',
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color ??
                            AppTheme.mediumGray,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? _buildErrorScreen()
                : _dermatologists.isEmpty
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
              'Unlock Specialist Search',
              textAlign: TextAlign.center,
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This feature requires credit or watching ads multiple times to access nearby dermatologists.',
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
                          label: const Text('Watch Ads to Unlock'),
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
              onPressed: _fetchDermatologists,
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
            'No clinics found nearby',
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
            onPressed: _fetchDermatologists,
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
      itemCount: _dermatologists.length,
      itemBuilder: (context, index) {
        final d = _dermatologists[index];
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
            onTap: () => _showSpecialistDetails(d),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: _buildClinicImage(d, 100, 100),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            weight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (d.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            d.address!,
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
                            if (d.rating != null) ...[
                              const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                d.rating!,
                                style: ResponsiveConfig.textStyle(
                                  size: 12,
                                  weight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (d.reviewsCount != null)
                                Text(
                                  '(${d.reviewsCount})',
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
                            if (d.isOpen != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (d.isOpen! ? Colors.green : Colors.red)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  d.isOpen! ? 'OPEN' : 'CLOSED',
                                  style: ResponsiveConfig.textStyle(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color:
                                        d.isOpen! ? Colors.green : Colors.red,
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

  Widget _buildClinicImage(Dermatologist d, double width, double height) {
    if (d.photoReference == null) {
      return Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        child: Icon(Icons.local_hospital,
            color: Theme.of(context).colorScheme.primary),
      );
    }

    return FutureBuilder<String?>(
      future: _service.getMapsApiKey(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final apiKey = snapshot.data;

        if (apiKey == null) {
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(Icons.local_hospital, color: theme.colorScheme.primary),
          );
        }

        final photoUrl = d.getPhotoUrl(apiKey);
        if (photoUrl == null) {
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(Icons.local_hospital, color: theme.colorScheme.primary),
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
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: width,
            height: height,
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            child: Icon(Icons.local_hospital, color: theme.colorScheme.primary),
          ),
        );
      },
    );
  }

  Future<void> _showSpecialistDetails(Dermatologist d) async {
    // Show a loading state if we don't have phone/website yet
    if (d.placeId != null && (d.phone == null || d.website == null)) {
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
              const Text('Fetching specialist details...'),
            ],
          ),
        ),
      );

      final details = await _service.getPlaceDetails(d.placeId!);
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        if (details != null) {
          _showDetailsDialog(details);
        } else {
          _showDetailsDialog(d); // Fallback to basic info
        }
      }
    } else {
      _showDetailsDialog(d);
    }
  }

  void _showDetailsDialog(Dermatologist d) {
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
              // Header Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: _buildClinicImage(d, double.infinity, 250),
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
                      d.name,
                      style: ResponsiveConfig.textStyle(
                        size: 22,
                        weight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (d.rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            d.rating!,
                            style: ResponsiveConfig.textStyle(
                              size: 16,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${d.reviewsCount ?? '0'} Reviews)',
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
                    if (d.address != null)
                      _buildDetailItem(Icons.location_on, d.address!),
                    if (d.isOpen != null)
                      _buildDetailItem(
                        Icons.access_time,
                        d.isOpen! ? 'Open Now' : 'Currently Closed',
                        color: d.isOpen! ? Colors.green : Colors.red,
                      ),
                    if (d.phone != null)
                      _buildDetailItem(Icons.phone, d.phone!),
                    if (d.website != null)
                      _buildDetailItem(Icons.language, d.website!),
                    const SizedBox(height: 32),
                    if (d.website != null && d.website!.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final creditManager =
                                ref.read(creditManagerProvider);
                            final hasCredits =
                                await creditManager.requestCredit(
                              context,
                              ActionType.dermatologist,
                            );

                            if (hasCredits) {
                              await creditManager
                                  .consumeCredits(ActionType.dermatologist);
                              final url = Uri.parse(d.website!);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Could not launch website.')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.language),
                          label: const Text('Visit Website'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Starting video consultation with ${d.name}...'),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.video_call),
                          label: const Text('Book Video Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (d.phone != null) {
                            final url = Uri.parse('tel:${d.phone}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Office'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(color: theme.colorScheme.primary),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: color ??
                    theme.textTheme.bodyLarge?.color ??
                    AppTheme.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
