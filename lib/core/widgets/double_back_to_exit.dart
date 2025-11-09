import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Widget that implements double-back-to-exit functionality
/// Shows a snackbar when back is pressed, and only exits on second press
class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  final String? message;
  final Duration timeout;

  const DoubleBackToExit({
    super.key,
    required this.child,
    this.message,
    this.timeout = const Duration(seconds: 2),
  });

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPressTime;
  bool _isShowingSnackBar = false;

  void _handleBackPress() {
    final now = DateTime.now();
    final router = GoRouter.of(context);

    // Check if we can pop the navigation stack
    if (router.canPop()) {
      // If we can pop, just pop (normal navigation)
      router.pop();
      return;
    }

    // If we can't pop (at root), implement double-back-to-exit
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > widget.timeout) {
      // First back press or timeout expired - show message
      _lastBackPressTime = now;
      _showExitSnackBar();
    } else {
      // Second back press within timeout - exit app
      SystemNavigator.pop();
    }
  }

  void _showExitSnackBar() {
    if (_isShowingSnackBar) return;

    _isShowingSnackBar = true;
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message ?? 'Press back again to exit',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: widget.timeout,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.black87,
          ),
        )
        .closed
        .then((_) {
      if (mounted) {
        setState(() {
          _isShowingSnackBar = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: widget.child,
    );
  }
}
