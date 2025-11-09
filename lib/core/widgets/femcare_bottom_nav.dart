import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import '../../core/theme/app_theme.dart';

/// FemCare+ Bottom Navigation Bar
///
/// Modern bottom navigation with animated active state indicator
/// Similar to Material Design 3 bottom navigation patterns
class FemCareBottomNav extends StatelessWidget {
  final String currentRoute;

  const FemCareBottomNav({
    super.key,
    required this.currentRoute,
  });

  // Main navigation routes
  static const List<NavItem> _navItems = [
    NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      route: '/home',
    ),
    NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'Calendar',
      route: '/calendar',
    ),
    NavItem(
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      label: 'Insights',
      route: '/insights',
    ),
    NavItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite_rounded,
      label: 'Wellness',
      route: '/wellness',
    ),
    NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: ResponsiveConfig.radius(12),
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: ResponsiveConfig.height(90),
          padding: ResponsiveConfig.padding(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _navItems.map((item) {
              final isActive = currentRoute == item.route;
              return _buildNavItem(
                context,
                item: item,
                isActive: isActive,
                isDark: isDark,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required NavItem item,
    required bool isActive,
    required bool isDark,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              context.go(item.route);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: ResponsiveConfig.padding(vertical: 4, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with animated background
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated background circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      width: isActive ? 48 : 0,
                      height: isActive ? 48 : 0,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Icon
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: isActive
                          ? AppTheme.primaryPink
                          : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      size: isActive ? 26 : 24,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Label with animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: isActive ? 11 : 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppTheme.primaryPink
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item model
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
