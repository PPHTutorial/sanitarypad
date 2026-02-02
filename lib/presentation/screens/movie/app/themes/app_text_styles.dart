import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Application text styles
class AppTextStyles {
  // Headings
  static TextStyle get headline1 => TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  static TextStyle get headline2 => TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  static TextStyle get headline3 => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headline4 => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headline5 => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headline6 => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // Body text
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  // Buttons
  static TextStyle get button => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonSmall => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  // Captions
  static TextStyle get caption => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        height: 1.3,
      );

  static TextStyle get overline => TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.normal,
        letterSpacing: 1.5,
        height: 1.3,
      );

  // Labels
  static TextStyle get labelLarge => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  // Special styles
  static TextStyle get movieTitle => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  static TextStyle get movieSubtitle => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        height: 1.3,
      );

  static TextStyle get rating => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        height: 1.0,
      );

  static TextStyle get chip => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        height: 1.0,
      );

  static TextStyle get chipSelected => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        height: 1.0,
      );

  static TextStyle get proLabel => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        height: 1.0,
      );

  static TextStyle get watermarkLabel => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        height: 1.0,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  static TextStyle get searchHint => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
        height: 1.0,
      );

  static TextStyle get errorText => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  static TextStyle get successText => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  // Price styles
  static TextStyle get priceMain => TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        height: 1.0,
      );

  static TextStyle get priceSubtext => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        height: 1.2,
      );

  static TextStyle get priceSavings => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        height: 1.0,
      );
}
