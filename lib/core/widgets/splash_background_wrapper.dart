import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Wrapper widget that ensures splash screen background color
/// extends behind the status bar and to the bottom of the screen
/// This includes the Android system navigation bar (home keys area)
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

    // Create system UI overlay style that matches splash screen background
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor:
          Colors.transparent, // Transparent so background shows through
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          backgroundColor, // Android home keys area background
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent, // Remove divider
    );

    // Use AnnotatedRegion to ensure the system UI style is applied to all child widgets
    // This is more reliable than SystemChrome.setSystemUIOverlayStyle
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Container(
        color: backgroundColor, // Full screen background matching splash
        child: child,
      ),
    );
  }
}
