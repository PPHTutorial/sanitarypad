import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/themes/app_colors.dart';

/// Loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  
  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.accentColor,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading effect
class LoadingShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  
  const LoadingShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
      ),
    );
  }
}

/// Grid shimmer loading
class GridShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double aspectRatio;
  
  const GridShimmerLoading({
    super.key,
    this.itemCount = 6,
    this.aspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const LoadingShimmer(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        );
      },
    );
  }
}

/// List shimmer loading
class ListShimmerLoading extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  
  const ListShimmerLoading({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return LoadingShimmer(
          height: itemHeight,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        );
      },
    );
  }
}

