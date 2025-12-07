import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Application dimensions using flutter_screenutil for responsiveness
class AppDimensions {
  // Screen dimensions (initialized in main)
  static late double screenWidth;
  static late double screenHeight;
  static late double statusBarHeight;
  static late double bottomBarHeight;
  
  // Spacing scale (4-point grid system)
  static double get space4 => 4.w;      // Extra small
  static double get space8 => 8.w;      // Small
  static double get space12 => 12.w;    // Medium-small
  static double get space16 => 16.w;    // Medium
  static double get space20 => 20.w;    // Medium-large
  static double get space24 => 24.w;    // Large
  static double get space32 => 32.w;    // Extra large
  static double get space40 => 40.w;    // XXL
  static double get space48 => 48.w;    // XXXL
  
  // Icon sizes
  static double get iconXSmall => 16.w;
  static double get iconSmall => 18.w;
  static double get iconMedium => 24.w;
  static double get iconLarge => 32.w;
  static double get iconXLarge => 40.w;
  static double get iconXXLarge => 48.w;
  
  // Border radius
  static double get radiusSmall => 8.r;
  static double get radiusMedium => 12.r;
  static double get radiusLarge => 16.r;
  static double get radiusXLarge => 20.r;
  static double get radiusXXLarge => 24.r;
  static double get radiusCircular => 999.r;
  
  // Button dimensions
  static double get buttonHeightSmall => 36.h;
  static double get buttonHeightMedium => 48.h;
  static double get buttonHeightLarge => 56.h;
  static double get buttonPaddingHorizontal => 24.w;
  
  // Input dimensions
  static double get inputHeight => 48.h;
  static double get inputPadding => 16.w;
  
  // Card dimensions
  static double get cardPadding => 16.w;
  static double get cardElevation => 4.0;
  
  // Poster/Image dimensions
  static double get posterAspectRatio => 1.5; // Height / Width
  static double get backdropAspectRatio => 0.5625; // 16:9
  static double get profileAspectRatio => 1.5;
  
  // Grid spacing
  static double get gridSpacing => 8.w;
  static double get gridPadding => 16.w;
  
  // List spacing
  static double get listItemSpacing => 12.h;
  static double get listPadding => 16.w;
  
  // AppBar dimensions
  static double get appBarHeight => 56.h;
  static double get toolbarHeight => 56.h;
  
  // Bottom nav bar
  static double get bottomNavHeight => 60.h;
  static double get bottomNavIconSize => 24.w;
  
  // Carousel dimensions
  static double get carouselHeight => 280.h;
  static double get carouselItemSpacing => 8.w;
  
  // Chip dimensions
  static double get chipHeight => 32.h;
  static double get chipPadding => 12.w;
  static double get chipSpacing => 8.w;
  
  // Dialog dimensions
  static double get dialogMaxWidth => 400.w;
  static double get dialogPadding => 24.w;
  static double get dialogRadius => 16.r;
  
  // Bottom sheet dimensions
  static double get bottomSheetMaxHeight => 0.9.sh; // 90% of screen height
  static double get bottomSheetRadius => 20.r;
  static double get bottomSheetPadding => 16.w;
  
  // Divider
  static double get dividerThickness => 1.0;
  static double get dividerIndent => 16.w;
  
  // Border
  static double get borderWidth => 1.0;
  static double get borderWidthThick => 2.0;
  
  // Shimmer dimensions
  static double get shimmerPosterHeight => 200.h;
  static double get shimmerItemHeight => 100.h;
  
  // Ad dimensions
  static double get bannerAdHeight => 50.h;
  static double get bannerAdPadding => 8.w;
  
  // Quality selector
  static double get qualityChipWidth => 80.w;
  static double get qualityChipHeight => 36.h;
  
  // Cast item
  static double get castItemWidth => 80.w;
  static double get castItemHeight => 120.h;
  static double get castImageSize => 60.w;
  
  // Onboarding
  static double get onboardingImageHeight => 300.h;
  static double get onboardingTitleSize => 28.sp;
  static double get onboardingDescSize => 16.sp;
  
  // Pro upgrade
  static double get proIconSize => 80.w;
  static double get proBenefitIconSize => 24.w;
  static double get proPricingCardHeight => 100.h;
}

