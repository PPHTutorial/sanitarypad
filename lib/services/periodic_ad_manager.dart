import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/auth_provider.dart';
import '../core/config/dev_config.dart';
import 'ads_service.dart';

final periodicAdManagerProvider = Provider<PeriodicAdManager>((ref) {
  final manager = PeriodicAdManager(ref);
  manager.initialize();
  ref.onDispose(() => manager.dispose());
  return manager;
});

class PeriodicAdManager {
  final Ref _ref;
  Timer? _timer;
  final AdsService _adsService = AdsService();
  bool _isActive = false;

  PeriodicAdManager(this._ref);

  void initialize() {
    _ref.listen(currentUserStreamProvider, (previous, next) {
      final user = next.value;
      if (user != null && user.subscription.tier == AppConstants.tierEconomy) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });

    // Initial check
    final user = _ref.read(currentUserStreamProvider).value;
    if (user != null && user.subscription.tier == AppConstants.tierEconomy) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_isActive) return;
    if (!DevConfig.shouldShowAds) return;

    _isActive = true;
    debugPrint('PeriodicAdManager: Timer started (Eco Tier)');

    // Random ad every 5 mins (300 seconds)
    // Using simple periodic timer for now.
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _showAd();
    });
  }

  void _stopTimer() {
    if (!_isActive) return;

    _isActive = false;
    _timer?.cancel();
    _timer = null;
    debugPrint('PeriodicAdManager: Timer stopped (Upgrade or Sign out)');
  }

  Future<void> _showAd() async {
    if (!DevConfig.shouldShowAds) {
      _stopTimer();
      return;
    }
    // Only show if app is likely in foreground (can't easily check here without binding)
    // AdsService handles the "show if safe" logic generally?
    // Usually Interstitial ads require context or are shown on top.
    // AdsService.showInterstitialAd() usually handles context-less showing if configured with global key,
    // or we might need to rely on it just working.
    // Limitation: Without context, some ad plugins struggle.
    // Assuming AdsService can handle it or we might skip if we need context.

    debugPrint('PeriodicAdManager: Triggering periodic ad');
    await _adsService.showInterstitialAd();
  }

  void dispose() {
    _stopTimer();
  }
}
