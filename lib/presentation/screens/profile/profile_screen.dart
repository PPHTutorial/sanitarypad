import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../services/data_export_service.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: Colors.transparent, // Use theme background
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        bottomNavigationBar: const FemCareBottomNav(currentRoute: '/profile'),
        body: user == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: ResponsiveConfig.padding(all: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    _buildProfileHeader(context, user),
                    ResponsiveConfig.heightBox(16),

                    // Subscription Card
                    _buildSubscriptionCard(context, user),
                    ResponsiveConfig.heightBox(16),

                    // Settings Sections
                    _buildSettingsSection(context, ref),
                    ResponsiveConfig.heightBox(16),

                    // Account Actions
                    _buildAccountActions(context, ref),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.lightPink,
              child: Text(
                user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: ResponsiveConfig.textStyle(
                  size: 24,
                  weight: FontWeight.bold,
                  color: AppTheme.primaryPink,
                ),
              ),
            ),
            ResponsiveConfig.widthBox(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: ResponsiveConfig.textStyle(
                      size: 20,
                      weight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveConfig.heightBox(4),
                  Text(
                    user.email,
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, user) {
    final isPremium = user.subscription.isActive;
    return SizedBox(
      width: double.infinity,
      child: Card(
        shadowColor: Colors.black.withValues(alpha: 0.08),
        margin: const EdgeInsets.only(bottom: 0),
        color: isPremium ? AppTheme.lightPink : null,
        child: Padding(
          padding: ResponsiveConfig.padding(all: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'FemCare+ Premium' : 'Free Plan',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveConfig.heightBox(4),
                  Text(
                    isPremium
                        ? 'Active until ${user.subscription.endDate?.toString().split(' ')[0] ?? 'N/A'}'
                        : 'Upgrade to unlock premium features',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(16),
              if (!isPremium)
                ElevatedButton(
                  onPressed: () {
                    context.push('/subscription');
                  },
                  child: const Text('Upgrade'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.calendar_today,
            title: 'Cycle Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Advanced cycle settings coming soon')),
              );
            },
          ),
          const Divider(),
          _buildThemeToggleTile(context, ref),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              context.push('/notification-settings');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy & Security',
            onTap: () {
              _showSecurityOptions(context);
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.storage_outlined,
            title: 'Data Management',
            onTap: () {
              _showDataManagementOptions(context, ref);
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.phone_outlined,
            title: 'Emergency Contacts',
            onTap: () {
              context.push('/emergency-contacts');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.warning_amber,
            title: 'Health Alerts',
            onTap: () {
              context.push('/red-flag-alerts');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: 'Health Reports',
            onTap: () {
              context.push('/health-report');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.article_outlined,
            title: 'Manage Wellness Content',
            onTap: () {
              context.push('/wellness-content-management');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support: support@femcare.app')),
              );
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryPink),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    IconData themeIcon;
    String themeLabel;

    switch (themeMode) {
      case ThemeMode.light:
        themeIcon = Icons.light_mode;
        themeLabel = 'Light Mode';
        break;
      case ThemeMode.dark:
        themeIcon = Icons.dark_mode;
        themeLabel = 'Dark Mode';
        break;
      case ThemeMode.system:
        themeIcon = Icons.brightness_auto;
        themeLabel = 'System Default';
        break;
    }

    return ListTile(
      leading: Icon(themeIcon, color: AppTheme.primaryPink),
      title: const Text('Theme'),
      subtitle: Text(themeLabel),
      trailing: Switch(
        value: themeMode == ThemeMode.dark,
        onChanged: (value) {
          if (value) {
            themeNotifier.setThemeMode(ThemeMode.dark);
          } else {
            themeNotifier.setThemeMode(ThemeMode.light);
          }
        },
        activeColor: AppTheme.primaryPink,
      ),
      onTap: () {
        // Show theme mode selection dialog
        _showThemeModeDialog(context, ref);
      },
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Theme',
          style: ResponsiveConfig.textStyle(
            size: 20,
            weight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPink,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPink,
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeNotifier.setThemeMode(value);
                  Navigator.of(context).pop();
                }
              },
              activeColor: AppTheme.primaryPink,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, WidgetRef ref) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorRed),
            title: Text(
              'Sign Out',
              style: ResponsiveConfig.textStyle(
                size: 16,
                color: AppTheme.errorRed,
              ),
            ),
            onTap: () => _handleSignOut(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
            title: Text(
              'Delete Account',
              style: ResponsiveConfig.textStyle(
                size: 16,
                color: AppTheme.errorRed,
              ),
            ),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showSecurityOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Privacy & Security',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('PIN Lock'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                context.push('/pin-setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Lock'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                context.push('/biometric-setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Anonymous Mode'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anonymous mode coming soon')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDataManagementOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Data Management',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Data'),
              onTap: () {
                Navigator.pop(context);
                _exportUserData(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: Text(
                'Delete All Data',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  color: AppTheme.errorRed,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDataConfirmation(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDataConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your cycle data, wellness entries, and pad history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Delete all data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Data deletion feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = ref.read(authServiceProvider);
                await authService.deleteAccount();
                if (context.mounted) {
                  Navigator.pop(context);
                  context.go('/onboarding');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FemCare+'),
        content: const Text(
          'FemCare+ v1.0.0\n\n'
          'Your trusted wellness companion for menstrual health, cycle tracking, and self-care.\n\n'
          'Built with ❤️ for women\'s health and wellness.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportUserData(BuildContext context, WidgetRef ref) async {
    final userAsync = ref.read(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Exporting data...'),
                ],
              ),
            ),
          ),
        ),
      );

      final exportService = DataExportService();
      final jsonData = await exportService.exportUserData(user.userId);
      final fileName = exportService.generateExportFileName(user.userId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        await exportService.saveAndShareExport(jsonData, fileName);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (context.mounted) {
          context.go('/onboarding');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: ${e.toString()}')),
          );
        }
      }
    }
  }
}
