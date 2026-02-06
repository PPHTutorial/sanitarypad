import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

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

  const OutOfCreditsDialog({
    super.key,
    this.canWatchAd = true,
    this.onWatchAd,
    this.onUpgrade,
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
            const Text(
              'Out of Credits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have used all your daily credits. Upgrade to a higher tier or watch an ad to earn more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
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
}
