import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Theme Configuration
///
/// A feminine, calming theme with pink as the base color.
/// Includes soft lavender, nude pinks, and neutrals for a supportive,
/// empathetic design suitable for a women's health and wellness app.
class AppTheme {
  // Base Pink Colors - Feminine Palette
  static const Color primaryPink = Color(0xFFE91E63); // Vibrant pink
  static const Color lightPink = Color(0xFFF8BBD0); // Soft pink
  static const Color palePink = Color(0xFFFCE4EC); // Very light pink
  static const Color deepPink = Color(0xFFC2185B); // Deep pink

  // Lavender Colors
  static const Color lavender = Color(0xFFE1BEE7); // Soft lavender
  static const Color lightLavender = Color(0xFFF3E5F5); // Very light lavender

  // Neutral Colors
  static const Color nudeBeige = Color(0xFFF5F5DC); // Nude beige
  static const Color warmWhite = Color(0xFFFFFBF7); // Warm white
  static const Color softGray = Color(0xFFF5F5F5); // Soft gray
  static const Color mediumGray = Color(0xFF9E9E9E); // Medium gray
  static const Color darkGray = Color(0xFF424242); // Dark gray

  // Splash Screen Background Colors (matching flutter_native_splash.yaml)
  static const Color splashLight = Color(0xFFFFF6F8); // Light pink background
  static const Color splashDark = Color(0xFF1A1A1A); // Dark background

  // Accent Colors
  static const Color accentCoral = Color(0xFFFF6B9D); // Coral accent
  static const Color accentRose = Color(0xFFFFB3BA); // Rose accent

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);
  static const Color infoBlue = Color(0xFF2196F3);

  /// Light Theme
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: primaryPink,
      primaryContainer: lightPink,
      secondary: lavender,
      secondaryContainer: lightLavender,
      surface: Colors.white,
      surfaceContainerHighest: softGray,
      error: errorRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkGray,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: splashLight, // Match splash screen

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: darkGray,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: const TextStyle(
          color: darkGray,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: primaryPink,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPink,
          side: const BorderSide(color: primaryPink, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryPink,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          color: mediumGray,
          fontSize: 16,
        ),
      ),

      // Text Theme with Red Hat Display font
      textTheme: GoogleFonts.redHatDisplayTextTheme(
        TextTheme(
          displayLarge: GoogleFonts.redHatDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: darkGray,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.redHatDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkGray,
            letterSpacing: -0.5,
          ),
          displaySmall: GoogleFonts.redHatDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: darkGray,
            letterSpacing: 0,
          ),
          headlineLarge: GoogleFonts.redHatDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: darkGray,
            letterSpacing: 0,
          ),
          headlineMedium: GoogleFonts.redHatDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkGray,
            letterSpacing: 0.15,
          ),
          headlineSmall: GoogleFonts.redHatDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkGray,
            letterSpacing: 0.15,
          ),
          titleLarge: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkGray,
            letterSpacing: 0.15,
          ),
          titleMedium: GoogleFonts.redHatDisplay(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkGray,
            letterSpacing: 0.1,
          ),
          titleSmall: GoogleFonts.redHatDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkGray,
            letterSpacing: 0.1,
          ),
          bodyLarge: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: darkGray,
            letterSpacing: 0.5,
          ),
          bodyMedium: GoogleFonts.redHatDisplay(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: darkGray,
            letterSpacing: 0.25,
          ),
          bodySmall: GoogleFonts.redHatDisplay(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: mediumGray,
            letterSpacing: 0.4,
          ),
          labelLarge: GoogleFonts.redHatDisplay(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkGray,
            letterSpacing: 0.1,
          ),
          labelMedium: GoogleFonts.redHatDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkGray,
            letterSpacing: 0.5,
          ),
          labelSmall: GoogleFonts.redHatDisplay(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: mediumGray,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryPink,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: mediumGray.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: palePink,
        deleteIconColor: primaryPink,
        disabledColor: softGray,
        selectedColor: lightPink,
        secondarySelectedColor: lightLavender,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          color: darkGray,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: darkGray,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryPink,
        unselectedItemColor: mediumGray,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.redHatDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkGray,
        ),
        contentTextStyle: GoogleFonts.redHatDisplay(
          fontSize: 16,
          color: darkGray,
        ),
        // Set insetPadding to ensure dialogs are wider (10% margin on each side = 90% width)
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        alignment: Alignment.center,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGray,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPink,
        linearTrackColor: palePink,
        circularTrackColor: palePink,
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: lightPink,
      primaryContainer: deepPink,
      secondary: lavender,
      secondaryContainer: Color.fromRGBO(
        (lavender.value >> 16) & 0xFF,
        (lavender.value >> 8) & 0xFF,
        lavender.value & 0xFF,
        0.3,
      ),
      surface: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF2C2C2C),
      error: errorRed,
      onPrimary: darkGray,
      onSecondary: darkGray,
      onSurface: Colors.white,
      onError: Colors.white,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: splashDark, // Match splash screen

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.redHatDisplay(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: lightPink,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPink,
          foregroundColor: darkGray,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightPink,
          side: const BorderSide(color: lightPink, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPink,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightPink,
        foregroundColor: darkGray,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 16,
        ),
      ),

      // Text Theme with Red Hat Display font
      textTheme: GoogleFonts.redHatDisplayTextTheme(
        TextTheme(
          displayLarge: GoogleFonts.redHatDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.redHatDisplay(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          displaySmall: GoogleFonts.redHatDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0,
          ),
          headlineLarge: GoogleFonts.redHatDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0,
          ),
          headlineMedium: GoogleFonts.redHatDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.15,
          ),
          headlineSmall: GoogleFonts.redHatDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.15,
          ),
          titleLarge: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.15,
          ),
          titleMedium: GoogleFonts.redHatDisplay(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
          titleSmall: GoogleFonts.redHatDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
          bodyLarge: GoogleFonts.redHatDisplay(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          bodyMedium: GoogleFonts.redHatDisplay(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.white,
            letterSpacing: 0.25,
          ),
          bodySmall: GoogleFonts.redHatDisplay(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.4,
          ),
          labelLarge: GoogleFonts.redHatDisplay(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
          labelMedium: GoogleFonts.redHatDisplay(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          labelSmall: GoogleFonts.redHatDisplay(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: lightPink,
        size: 24,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        deleteIconColor: lightPink,
        disabledColor: const Color(0xFF1E1E1E),
        selectedColor: deepPink,
        secondarySelectedColor: Color.fromRGBO(
          (lavender.value >> 16) & 0xFF,
          (lavender.value >> 8) & 0xFF,
          lavender.value & 0xFF,
          0.3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.redHatDisplay(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.redHatDisplay(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: lightPink,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 24),
        selectedLabelStyle: GoogleFonts.redHatDisplay(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.redHatDisplay(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: GoogleFonts.redHatDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        contentTextStyle: GoogleFonts.redHatDisplay(
          fontSize: 16,
          color: Colors.white,
        ),
        // Set insetPadding to ensure dialogs are wider (10% margin on each side = 90% width)
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        alignment: Alignment.center,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        contentTextStyle: GoogleFonts.redHatDisplay(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: lightPink,
        linearTrackColor: Color(0xFF2C2C2C),
        circularTrackColor: Color(0xFF2C2C2C),
      ),
    );
  }
}
