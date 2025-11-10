import 'package:flutter/material.dart';
import '../config/responsive_config.dart';

/// Reusable wrapper for modal bottom sheets and dialogs
/// Ensures consistent width (90% of screen) and proper spacing
class DialogWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const DialogWrapper({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: ResponsiveConfig.heightPercent(85),
        width: ResponsiveConfig.widthPercent(90),
        margin: ResponsiveConfig.margin(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: ResponsiveConfig.borderRadius(24),
        ),
        child: child,
      ),
    );
  }
}

/// Custom AlertDialog with proper width (90% of screen)
class FemCareAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? insetPadding;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  const FemCareAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.insetPadding,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.90; // 10% margin on each side
    final horizontalMargin = (screenWidth - dialogWidth) / 2;

    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      contentPadding:
          contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
      backgroundColor: backgroundColor,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
      // Use constraints to ensure proper width
      // AlertDialog respects insetPadding but also has maxWidth, so we use constraints
    );
  }
}

/// Helper function to show AlertDialog with proper width (90% of screen)
Future<T?> showFemCareDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
  List<Widget>? actions,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsetsGeometry? contentPadding,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black54,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final dialogWidth = screenWidth * 0.90; // 10% margin on each side
      final horizontalMargin = (screenWidth - dialogWidth) / 2;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: horizontalMargin),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
          ),
          child: AlertDialog(
            title: title,
            content: content,
            actions: actions,
            contentPadding:
                contentPadding ?? const EdgeInsets.fromLTRB(24, 20, 24, 24),
            backgroundColor: backgroundColor,
            shape: shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
          ),
        ),
      );
    },
  );
}

/// Helper function to wrap bottom sheet content with proper width and spacing
Widget wrapDialogContent(
  BuildContext context,
  Widget child, {
  EdgeInsets? padding,
}) {
  return DialogWrapper(
    padding: padding,
    child: child,
  );
}

/// Helper function to show a modal bottom sheet with proper width
Future<T?> showFemCareBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final dialogWidth = screenWidth * 0.90;
      final horizontalMargin = (screenWidth - dialogWidth) / 2;

      return Container(
        margin: EdgeInsets.only(
          left: horizontalMargin,
          right: horizontalMargin,
          top: 8,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: builder(context),
        ),
      );
    },
  );
}
