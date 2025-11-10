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

    // Get current location more reliably
    String currentLocation = '/';
    try {
      final location = router.routerDelegate.currentConfiguration.uri.path;
      currentLocation = location.isEmpty ? '/' : location;
    } catch (e) {
      currentLocation = '/';
    }

    // Always require double-back on home screen or root
    final isOnHome = currentLocation == '/home' || currentLocation == '/';

    // Check if we can pop the navigation stack (and not on home)
    if (router.canPop() && !isOnHome) {
      // If we can pop and not on home, just pop (normal navigation)
      router.pop();
      return;
    }

    // If we can't pop (at root) or on home, implement double-back-to-exit
    if (_isShowingSnackBar) {
      // Snackbar is already showing - exit immediately
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
      return;
    }

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
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message ?? 'Press back again to exit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
            action: SnackBarAction(
              label: 'EXIT',
              textColor: Colors.white,
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ),
        )
        .closed
        .then((_) {
      if (mounted) {
        setState(() {
          _isShowingSnackBar = false;
          _lastBackPressTime = null; // Reset timer when snackbar closes
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
