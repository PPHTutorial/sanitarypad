import 'package:flutter/material.dart';

/// Helper class for responsive design
class ResponsiveHelper {
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Check if mobile device
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }
  
  /// Check if tablet device
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  /// Check if desktop device
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= desktopBreakpoint;
  }
  
  /// Get grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint) return 6;
    if (width >= tabletBreakpoint) return 4;
    if (width >= mobileBreakpoint) return 3;
    return 2;
  }
  
  /// Get grid columns with custom breakpoints
  static int getGridColumnsCustom(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  /// Get spacing based on screen density
  static double getSpacing(BuildContext context, double base) {
    return base * MediaQuery.of(context).textScaleFactor;
  }
  
  /// Get image aspect ratio based on screen
  static double getImageAspectRatio(BuildContext context) {
    return getGridColumns(context) >= 4 ? 0.7 : 0.68;
  }
  
  /// Get responsive value
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
  
  /// Get padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
  
  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
  
  /// Get status bar height
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  
  /// Get bottom padding (for navigation bar)
  static double getBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  
  /// Get orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  /// Check if landscape
  static bool isLandscape(BuildContext context) {
    return getOrientation(context) == Orientation.landscape;
  }
  
  /// Check if portrait
  static bool isPortrait(BuildContext context) {
    return getOrientation(context) == Orientation.portrait;
  }
  
  /// Get device pixel ratio
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  
  /// Check if high resolution device
  static bool isHighResolution(BuildContext context) {
    return getDevicePixelRatio(context) > 2.0;
  }
}

