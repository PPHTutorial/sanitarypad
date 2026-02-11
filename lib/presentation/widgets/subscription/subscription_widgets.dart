import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PaywallDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String> features;

  const PaywallDialog({
    super.key,
    required this.title,
    required this.message,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: AppTheme.primaryPink,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          color: AppTheme.primaryPink, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        feature,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Upgrade Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OutOfCreditsDialog extends StatelessWidget {
  final bool canWatchAd;
  final VoidCallback? onWatchAd;
  final VoidCallback? onUpgrade;
  final double availableCredits;
  final double requiredCredits;
  final int currentAdProgress;
  final String? title;
  final String? message;

  const OutOfCreditsDialog({
    super.key,
    this.canWatchAd = true,
    this.onWatchAd,
    this.onUpgrade,
    this.availableCredits = 0,
    this.requiredCredits = 0,
    this.currentAdProgress = 0,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt,
              color: Colors.amber,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Out of Credits',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ??
                  'No problem! You can watch a few ads to square up the credits needed. You can upgrade to a higher tier to get more credits.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Needed',
                      '${requiredCredits.toStringAsFixed(1)} credits'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Available',
                      '${availableCredits.toStringAsFixed(1)} credits'),
                  const Divider(height: 24, color: Colors.white10),
                  _buildAdsNeededRow(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (canWatchAd)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onWatchAd?.call();
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Watch Ad to earn credits'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onUpgrade != null) {
                    onUpgrade!();
                  } else {
                    context.push('/subscription');
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Upgrade Plan',
                  style: TextStyle(color: AppTheme.primaryPink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildAdsNeededRow() {
    final deficit = requiredCredits - availableCredits;
    if (deficit <= 0) return const SizedBox.shrink();

    // Each reward cycle grants creditsPerAdReward.
    final rewardsNeeded = (deficit / AppConstants.creditsPerAdReward).ceil();
    final totalAdsToWatch =
        (rewardsNeeded * AppConstants.adsNeededForReward) - currentAdProgress;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Ads to watch',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalAdsToWatch ads',
            style: const TextStyle(
                color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
