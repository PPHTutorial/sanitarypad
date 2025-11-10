import 'package:flutter/material.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.90; // 10% margin on each side
    final horizontalMargin = (screenWidth - dialogWidth) / 2;

    return Center(
      child: Container(
        width: dialogWidth,
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
        padding: padding ??
            EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
        child: child,
      ),
    );
  }
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
