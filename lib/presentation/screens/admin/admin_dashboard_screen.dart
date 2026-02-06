import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'sections/admin_overview_section.dart';
import 'sections/admin_users_section.dart';
import 'sections/admin_health_section.dart';
import 'sections/admin_community_section.dart';
import 'sections/admin_content_section.dart';
import 'sections/admin_support_section.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: FontAwesomeIcons.chartPie, label: 'Overview'),
    _NavItem(icon: FontAwesomeIcons.users, label: 'Users'),
    _NavItem(icon: FontAwesomeIcons.heartPulse, label: 'Health'),
    _NavItem(icon: FontAwesomeIcons.usersRectangle, label: 'Community'),
    _NavItem(icon: FontAwesomeIcons.bookOpen, label: 'Content'),
    _NavItem(icon: FontAwesomeIcons.headset, label: 'Support'),
  ];

  Widget _getSection(int index) {
    switch (index) {
      case 0:
        return const AdminOverviewSection();
      case 1:
        return const AdminUsersSection();
      case 2:
        return const AdminHealthSection();
      case 3:
        return const AdminCommunitySection();
      case 4:
        return const AdminContentSection();
      case 5:
        return const AdminSupportSection();
      default:
        return const AdminOverviewSection();
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isWide) {
      // Desktop/Tablet: Use NavigationRail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor:
                  isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              extended: MediaQuery.of(context).size.width > 1100,
              labelType: MediaQuery.of(context).size.width > 1100
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(FontAwesomeIcons.shieldHalved,
                        color: theme.colorScheme.primary, size: 28),
                    const SizedBox(height: 8),
                    if (MediaQuery.of(context).size.width > 1100)
                      Text('Admin',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary)),
                  ],
                ),
              ),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: FaIcon(item.icon, size: 20),
                        selectedIcon: FaIcon(item.icon,
                            size: 20, color: theme.colorScheme.primary),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Column(
                children: [
                  // Custom AppBar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border(
                          bottom: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _navItems[_currentIndex].label,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {}),
                        IconButton(
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () {}),
                      ],
                    ),
                  ),
                  Expanded(child: _getSection(_currentIndex)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile: Use BottomNavigationBar
      return Scaffold(
        appBar: AppBar(
          title: Text(_navItems[_currentIndex].label),
          actions: [
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
        body: _getSection(_currentIndex),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          height: 60,
          destinations: _navItems
              .map((item) => NavigationDestination(
                    icon: FaIcon(item.icon, size: 18),
                    selectedIcon: FaIcon(item.icon,
                        size: 18, color: theme.colorScheme.primary),
                    label: item.label,
                  ))
              .toList(),
        ),
      );
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
