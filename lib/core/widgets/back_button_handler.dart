import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wrapper widget that handles back button navigation properly
/// Prevents app from closing when back button is pressed
class BackButtonHandler extends StatelessWidget {
  final Widget child;
  final String? fallbackRoute;

  const BackButtonHandler({
    super.key,
    required this.child,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Check if we can pop the navigation stack
        final router = GoRouter.of(context);
        if (router.canPop()) {
          // Pop the current route (normal navigation)
          router.pop();
        } else {
          // If we can't pop, navigate to fallback route or home
          final route = fallbackRoute ?? '/home';
          String currentPath = '/';
          try {
            currentPath = router.routerDelegate.currentConfiguration.uri.path;
            if (currentPath.isEmpty) currentPath = '/';
          } catch (e) {
            currentPath = '/';
          }

          // Only navigate if not already on the fallback route
          if (currentPath != route && currentPath != '/home') {
            router.go(route);
          }
          // If already on fallback route or home, let DoubleBackToExit handle it
          // Don't do anything here - let the parent DoubleBackToExit widget handle exit
        }
      },
      child: child,
    );
  }
}
