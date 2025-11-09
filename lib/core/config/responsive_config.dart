import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive Configuration
///
/// Provides adaptive sizing, spacing, and typography that automatically
/// adjusts to different screen sizes, densities, and text scaling preferences.
/// This ensures the app looks and feels native on every device.
///
/// Usage examples:
/// - Use extension methods directly: 16.w, 24.h, 14.sp, 12.r
/// - Or use helper methods: ResponsiveConfig.width(16), ResponsiveConfig.height(24)
class ResponsiveConfig {
  // Design reference dimensions (based on a standard phone screen)
  // These are used as the baseline for responsive scaling
  static const double designWidth = 375.0; // iPhone 12/13/14 standard width
  static const double designHeight = 812.0; // iPhone 12/13/14 standard height

  /// Initialize responsive configuration
  ///
  /// Call this in the main app's build method to set up responsive scaling
  static Widget init({
    required BuildContext context,
    required Widget child,
    double? designWidth,
    double? designHeight,
    bool minTextAdapt = true,
    bool splitScreenMode = false,
  }) {
    return ScreenUtilInit(
      designSize: Size(
        designWidth ?? ResponsiveConfig.designWidth,
        designHeight ?? ResponsiveConfig.designHeight,
      ),
      minTextAdapt: minTextAdapt,
      splitScreenMode: splitScreenMode,
      builder: (context, child) => child!,
      child: child,
    );
  }

  /// Get responsive width using ScreenUtil
  ///
  /// Returns a width value that scales based on screen width
  /// Usage: width: ResponsiveConfig.width(100)
  static double width(double width) {
    return ScreenUtil().setWidth(width);
  }

  /// Get responsive height using ScreenUtil
  ///
  /// Returns a height value that scales based on screen height
  /// Usage: height: ResponsiveConfig.height(50)
  static double height(double height) {
    return ScreenUtil().setHeight(height);
  }

  /// Get responsive font size using ScreenUtil
  ///
  /// Returns a font size that scales based on screen size and text scaling
  /// Usage: fontSize: ResponsiveConfig.fontSize(16)
  static double fontSize(double size) {
    return ScreenUtil().setSp(size);
  }

  /// Get responsive radius using ScreenUtil
  ///
  /// Returns a radius value that scales proportionally
  /// Usage: borderRadius: BorderRadius.circular(ResponsiveConfig.radius(12))
  static double radius(double radius) {
    return ScreenUtil().radius(radius);
  }

  /// Get responsive spacing
  ///
  /// Returns spacing that adapts to screen size
  /// Usage: SizedBox(height: ResponsiveConfig.spacing(16))
  static double spacing(double spacing) {
    return ScreenUtil().setHeight(spacing);
  }

  /// Get responsive horizontal spacing
  ///
  /// Returns horizontal spacing that adapts to screen width
  /// Usage: SizedBox(width: ResponsiveConfig.spacingH(16))
  static double spacingH(double spacing) {
    return ScreenUtil().setWidth(spacing);
  }

  /// Get responsive vertical spacing
  ///
  /// Returns vertical spacing that adapts to screen height
  /// Usage: SizedBox(height: ResponsiveConfig.spacingV(16))
  static double spacingV(double spacing) {
    return ScreenUtil().setHeight(spacing);
  }

  /// Get screen width
  static double get screenWidth => ScreenUtil().screenWidth;

  /// Get screen height
  static double get screenHeight => ScreenUtil().screenHeight;

  /// Get status bar height
  static double get statusBarHeight => ScreenUtil().statusBarHeight;

  /// Get bottom bar height (safe area)
  static double get bottomBarHeight => ScreenUtil().bottomBarHeight;

  /// Get screen width percentage
  ///
  /// Returns a percentage of screen width
  /// Usage: width: ResponsiveConfig.widthPercent(50) // 50% of screen width
  static double widthPercent(double percent) {
    return (percent / 100) * screenWidth;
  }

  /// Get screen height percentage
  ///
  /// Returns a percentage of screen height
  /// Usage: height: ResponsiveConfig.heightPercent(30) // 30% of screen height
  static double heightPercent(double percent) {
    return (percent / 100) * screenHeight;
  }

  /// Check if device is tablet
  static bool get isTablet {
    return screenWidth >= 600;
  }

  /// Check if device is phone
  static bool get isPhone {
    return screenWidth < 600;
  }

  /// Check if device is small phone
  static bool get isSmallPhone {
    return screenWidth < 360;
  }

  /// Check if device is large phone
  static bool get isLargePhone {
    return screenWidth >= 360 && screenWidth < 600;
  }

  /// Get responsive padding
  ///
  /// Returns EdgeInsets that scales based on screen size
  /// Usage: padding: ResponsiveConfig.padding(all: 16)
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(ScreenUtil().setWidth(all));
    }
    return EdgeInsets.only(
      left: ScreenUtil().setWidth(left ?? horizontal ?? 0),
      right: ScreenUtil().setWidth(right ?? horizontal ?? 0),
      top: ScreenUtil().setHeight(top ?? vertical ?? 0),
      bottom: ScreenUtil().setHeight(bottom ?? vertical ?? 0),
    );
  }

  /// Get responsive margin
  ///
  /// Returns EdgeInsets that scales based on screen size
  /// Usage: margin: ResponsiveConfig.margin(all: 16)
  static EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(ScreenUtil().setWidth(all));
    }
    return EdgeInsets.only(
      left: ScreenUtil().setWidth(left ?? horizontal ?? 0),
      right: ScreenUtil().setWidth(right ?? horizontal ?? 0),
      top: ScreenUtil().setHeight(top ?? vertical ?? 0),
      bottom: ScreenUtil().setHeight(bottom ?? vertical ?? 0),
    );
  }

  /// Get responsive SizedBox for width
  static SizedBox widthBox(double width) {
    return SizedBox(width: ScreenUtil().setWidth(width));
  }

  /// Get responsive SizedBox for height
  static SizedBox heightBox(double height) {
    return SizedBox(height: ScreenUtil().setHeight(height));
  }

  /// Get responsive SizedBox for spacing
  static SizedBox spacingBox({double? width, double? height}) {
    return SizedBox(
      width: width != null ? ScreenUtil().setWidth(width) : null,
      height: height != null ? ScreenUtil().setHeight(height) : null,
    );
  }

  /// Get responsive BorderRadius
  static BorderRadius borderRadius(double radius) {
    return BorderRadius.circular(ScreenUtil().radius(radius));
  }

  /// Get responsive BorderRadius with different values
  static BorderRadius borderRadiusOnly({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(ScreenUtil().radius(topLeft ?? 0)),
      topRight: Radius.circular(ScreenUtil().radius(topRight ?? 0)),
      bottomLeft: Radius.circular(ScreenUtil().radius(bottomLeft ?? 0)),
      bottomRight: Radius.circular(ScreenUtil().radius(bottomRight ?? 0)),
    );
  }

  /// Get responsive icon size
  static double iconSize(double size) {
    return ScreenUtil().setSp(size);
  }

  /// Get responsive text style
  ///
  /// Returns a TextStyle with responsive font size
  /// Usage: style: ResponsiveConfig.textStyle(size: 16, weight: FontWeight.w600)
  static TextStyle textStyle({
    required double size,
    FontWeight? weight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: ScreenUtil().setSp(size),
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Get device pixel ratio
  static double get devicePixelRatio => ScreenUtil().pixelRatio ?? 1.0;

  /// Get screen density
  static double get screenDensity => ScreenUtil().screenWidth / designWidth;

  /// Get responsive grid columns based on screen size
  static int getGridColumns({
    int phoneColumns = 2,
    int tabletColumns = 4,
  }) {
    return isTablet ? tabletColumns : phoneColumns;
  }

  /// Get responsive item spacing for grids
  static double getGridSpacing({
    double phoneSpacing = 8,
    double tabletSpacing = 16,
  }) {
    return isTablet
        ? ScreenUtil().setWidth(tabletSpacing)
        : ScreenUtil().setWidth(phoneSpacing);
  }

  /// Get responsive card height
  static double getCardHeight({
    double phoneHeight = 120,
    double tabletHeight = 150,
  }) {
    return isTablet
        ? ScreenUtil().setHeight(tabletHeight)
        : ScreenUtil().setHeight(phoneHeight);
  }

  /// Get responsive button height
  static double getButtonHeight({
    double phoneHeight = 48,
    double tabletHeight = 56,
  }) {
    return isTablet
        ? ScreenUtil().setHeight(tabletHeight)
        : ScreenUtil().setHeight(phoneHeight);
  }

  /// Get responsive app bar height
  static double getAppBarHeight({
    double phoneHeight = 56,
    double tabletHeight = 64,
  }) {
    return isTablet
        ? ScreenUtil().setHeight(tabletHeight)
        : ScreenUtil().setHeight(phoneHeight);
  }

  /// Get responsive bottom navigation height
  static double getBottomNavHeight({
    double phoneHeight = 56,
    double tabletHeight = 64,
  }) {
    return isTablet
        ? ScreenUtil().setHeight(tabletHeight)
        : ScreenUtil().setHeight(phoneHeight);
  }
}
