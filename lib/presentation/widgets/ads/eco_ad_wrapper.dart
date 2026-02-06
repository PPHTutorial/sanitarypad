import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../services/ads_service.dart';

enum AdType { banner, native }

class EcoAdWrapper extends ConsumerWidget {
  final AdType adType;
  final Widget?
      child; // Optional child to show for non-ad users (or to wrap around)
  final bool showAbove; // Whether to show ad above or below the child

  const EcoAdWrapper({
    super.key,
    this.adType = AdType.banner,
    this.child,
    this.showAbove = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(userSubscriptionProvider);
    final isEco = sub?.tier == AppConstants.tierEconomy || sub?.tier == 'free';

    if (!isEco) {
      return child ?? const SizedBox.shrink();
    }

    Widget adWidget;
    switch (adType) {
      case AdType.banner:
        adWidget = const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: BannerAdWidget(),
        );
        break;
      case AdType.native:
        adWidget = const Padding(
          padding: EdgeInsets.all(16.0),
          child: NativeAdWidget(),
        );
        break;
    }

    if (child == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [adWidget],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showAbove) adWidget,
        child!,
        if (!showAbove) adWidget,
      ],
    );
  }
}
