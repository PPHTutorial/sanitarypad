import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/utils/responsive_helper.dart';
import '../../app/themes/app_dimensions.dart';

/// Responsive grid widget that adapts to screen size
class ResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double aspectRatio;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 1.5,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridColumns(context);
    
    return GridView.builder(
      padding: padding ?? EdgeInsets.all(AppDimensions.gridPadding),
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.gridSpacing,
        crossAxisSpacing: AppDimensions.gridSpacing,
        childAspectRatio: aspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Staggered grid for varied item heights
class ResponsiveStaggeredGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  
  const ResponsiveStaggeredGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridColumns(context);
    
    return MasonryGridView.builder(
      padding: padding ?? EdgeInsets.all(AppDimensions.gridPadding),
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
      ),
      mainAxisSpacing: AppDimensions.gridSpacing,
      crossAxisSpacing: AppDimensions.gridSpacing,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Sliver responsive grid
class SliverResponsiveGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double aspectRatio;
  
  const SliverResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveHelper.getGridColumns(context);
    
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppDimensions.gridSpacing,
        crossAxisSpacing: AppDimensions.gridSpacing,
        childAspectRatio: aspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
      ),
    );
  }
}

