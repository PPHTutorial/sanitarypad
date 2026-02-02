import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App logo widget using the MovieWalls image asset
class AppLogo extends StatelessWidget {
  final double? height;
  final double? width;
  final EdgeInsets? padding;
  final bool showText;
  
  const AppLogo({
    super.key,
    this.height,
    this.width,
    this.padding,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Image.asset(
        'assets/images/logo.png',
        height: height ?? 40.h,
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback if image not found
          return Container(
            height: height ?? 40.h,
            width: width,
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Icon(
              Icons.movie_filter_rounded,
              size: (height ?? 40.h) * 0.8,
              color: Theme.of(context).iconTheme.color,
            ),
          );
        },
      ),
    );
  }
}

