
/* /// Application color palette
class AppColors {
  // Dark Theme Colors (Primary)
  static const Color primaryColor = Color(0xFF1A1A2E);      // Deep navy
  static const Color secondaryColor = Color(0xFF16213E);    // Dark blue
  static const Color accentColor = Color(0xFFE94560);       // Vibrant red
  static const Color goldColor = Color(0xFFFFD700);         // Gold (pro)
  
  // Background Colors (Dark)
  static const Color darkBackground = Color(0xFF0F0F1E);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  
  // Light Theme Colors (Alternative)
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF6366F1);      // Indigo
  static const Color lightCard = Color(0xFFFFFFFF);
  
  // Text Colors (Dark Theme)
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF707070);
  static const Color textHint = Color(0xFF606060);
  
  // Text Colors (Light Theme)
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF606060);
  static const Color lightTextDisabled = Color(0xFF9E9E9E);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Overlay Colors
  static const Color overlay = Color(0x80000000);           // Semi-transparent black
  static const Color shimmerBase = Color(0xFF2A2A3E);
  static const Color shimmerHighlight = Color(0xFF3A3A4E);
  
  // Border Colors
  static const Color borderColor = Color(0xFF2A2A3E);
  static const Color dividerColor = Color(0xFF2A2A3E);
  
  // Rating Colors
  static const Color ratingGold = Color(0xFFFFD700);
  static const Color ratingBad = Color(0xFFF44336);
  static const Color ratingAverage = Color(0xFFFFC107);
  static const Color ratingGood = Color(0xFF4CAF50);
  static const Color ratingExcellent = Color(0xFF2196F3);
  
  // Special Colors
  static const Color proGradientStart = Color(0xFFFFD700);
  static const Color proGradientEnd = Color(0xFFFFA500);
  static const Color freeWatermark = Color(0x59FFFFFF);     // Semi-transparent white
  
  // Chip Colors
  static const Color chipBackground = Color(0xFF2A2A3E);
  static const Color chipSelectedBackground = Color(0xFFE94560);
  
  // Ad Colors
  static const Color adBackground = Color(0xFF2A2A3E);
  static const Color adBorder = Color(0xFF3A3A4E);
  
  /// Get rating color based on value (0-10)
  static Color getRatingColor(double rating) {
    if (rating >= 8.0) return ratingExcellent;
    if (rating >= 7.0) return ratingGood;
    if (rating >= 5.0) return ratingAverage;
    return ratingBad;
  }
  
  /// Get genre color (assign colors to different genres)
  static Color getGenreColor(int index) {
    final colors = [
      accentColor,
      lightPrimary,
      success,
      warning,
      info,
      goldColor,
    ];
    return colors[index % colors.length];
  }
}

 */