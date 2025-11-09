import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Wrapper widget that ensures splash screen background color
/// extends behind the status bar and to the bottom of the screen
class SplashBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const SplashBackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.splashDark : AppTheme.splashLight;

    // Set system UI overlay style to make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    // Return child wrapped in container with splash background
    // This ensures the background extends behind status bar
    return Container(
      color: backgroundColor, // Full screen background matching splash
      child: child,
    );
  }
}
