import 'package:flutter/material.dart';

/// BuildContext extensions for easier access to common properties
extension ContextExtension on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);
  
  /// Get text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Get screen size
  Size get screenSize => mediaQuery.size;
  
  /// Get screen width
  double get screenWidth => screenSize.width;
  
  /// Get screen height
  double get screenHeight => screenSize.height;
  
  /// Get safe area padding
  EdgeInsets get padding => mediaQuery.padding;
  
  /// Get view insets (keyboard height, etc.)
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  
  /// Get device pixel ratio
  double get devicePixelRatio => mediaQuery.devicePixelRatio;
  
  /// Get text scale factor
  double get textScaleFactor => mediaQuery.textScaleFactor;
  
  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;
  
  /// Get keyboard height
  double get keyboardHeight => viewInsets.bottom;
  
  /// Get orientation
  Orientation get orientation => mediaQuery.orientation;
  
  /// Check if landscape
  bool get isLandscape => orientation == Orientation.landscape;
  
  /// Check if portrait
  bool get isPortrait => orientation == Orientation.portrait;
  
  /// Check if dark mode
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Check if light mode
  bool get isLightMode => theme.brightness == Brightness.light;
  
  /// Show snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
      ),
    );
  }
  
  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.error,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: Colors.green,
    );
  }
  
  /// Hide keyboard
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  /// Navigate to route
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// Replace current route
  Future<T?> pushReplacement<T, TO>(Widget page) {
    return Navigator.of(this).pushReplacement<T, TO>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
  
  /// Pop route
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }
  
  /// Pop until first route
  void popUntilFirst() {
    Navigator.of(this).popUntil((route) => route.isFirst);
  }
  
  /// Check if can pop
  bool get canPop => Navigator.of(this).canPop();
}

