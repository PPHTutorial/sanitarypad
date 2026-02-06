import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/iap/subscription_manager.dart';

/// Ad banner widget (respects Pro status - no ads for Pro users)
class AdBannerWidget extends ConsumerStatefulWidget {
  final bool showAd;
  
  const AdBannerWidget({
    super.key,
    this.showAd = true,
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
//BannerAd? _bannerAd;
    final bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _maybeLoadAd();
  }

  void _maybeLoadAd() {
    // Check Pro status before loading ads
    final isPro = SubscriptionManager.instance.isProUser;
    if (widget.showAd && !isPro) {
      // Delay ad loading to ensure AdMob is fully initialized
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !SubscriptionManager.instance.isProUser) {
          
        }
      });
    }
  }

  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   
    
    // Don't show ads for Pro users or if ad not loaded
    return const SizedBox.shrink();
  }
}
