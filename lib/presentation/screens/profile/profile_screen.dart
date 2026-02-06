import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../services/health_report_service.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/constants/legal_constants.dart';
import '../../../core/constants/export_constants.dart';
import '../../../services/data_backup_service.dart';
import '../../../services/credit_manager.dart';
import 'package:sanitarypad/core/providers/subscription_provider.dart';
import 'package:sanitarypad/data/models/transaction_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import '../admin/admin_dashboard_screen.dart';
import 'policy_viewer_screen.dart';

/// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        // Remove manual background color to use theme's scaffoldBackgroundColor
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        bottomNavigationBar: const FemCareBottomNav(currentRoute: '/profile'),
        body: userAsync.when(
          data: (user) => user == null
              ? const Center(child: Text('User not found'))
              : SingleChildScrollView(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, user),
                      _buildSubscriptionCard(context, user),
                      ResponsiveConfig.heightBox(16),
                      _buildTransactionLedger(context, ref, user.userId),
                      ResponsiveConfig.heightBox(24),
                      _buildSectionLabel(context, 'PREFERENCES & HEALTH'),
                      _buildSettingsSection(context, ref),
                      ResponsiveConfig.heightBox(24),
                      _buildSectionLabel(context, 'LEGAL & COMPLIANCE'),
                      _buildLegalSection(context),
                      ResponsiveConfig.heightBox(24),
                      _buildSectionLabel(context, 'COMMUNITY & SUPPORT'),
                      _buildSocialSection(context),
                      ResponsiveConfig.heightBox(24),
                      _buildSectionLabel(context, 'ACCOUNT ACTIONS'),
                      _buildAccountActions(context, ref),
                      ResponsiveConfig.heightBox(32),
                    ],
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Error loading profile',
                    style: ResponsiveConfig.textStyle(
                        size: 16, weight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(currentUserStreamProvider),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => context.push('/profile-details'),
      child: Card(
        // shadowColor handled by CardTheme
        margin: const EdgeInsets.only(bottom: 0),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: user.photoUrl != null
                    ? CachedNetworkImageProvider(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(
                        user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: ResponsiveConfig.textStyle(
                          size: 24,
                          weight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              ResponsiveConfig.widthBox(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user.fullName != null && user.fullName!.isNotEmpty)
                          ? user.fullName!
                          : (user.displayName ?? 'User'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(4),
                    Text(
                      '@${user.username ?? 'user'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPremium = user.subscription.isActive;

    return SizedBox(
      width: double.infinity,
      child: Card(
        // shadowColor handled by CardTheme
        margin: const EdgeInsets.only(top: 16),
        color: isPremium ? colorScheme.primaryContainer : null,
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/credit-history'),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isPremium ? 'FemCare+ Premium' : 'Free Plan',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPremium ? colorScheme.onSurface : null,
                          fontSize: ResponsiveConfig.fontSize(20),
                        ),
                      ),
                      ResponsiveConfig.heightBox(4),
                      Text(
                        isPremium
                            ? 'Active ${user.subscription.tier == 'economy' ? 'Forever' : 'until ${user.subscription.endDate?.toString().split(' ')[0] ?? 'N/A'}'}'
                            : 'Upgrade to unlock premium features',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isPremium
                              ? colorScheme.onSurface.withOpacity(0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      ResponsiveConfig.heightBox(12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? colorScheme.onPrimaryContainer.withOpacity(0.12)
                              : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.coins,
                              size: 14,
                              color: isPremium
                                  ? colorScheme.onSurface
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${user.subscription.dailyCreditsRemaining} Credits Remaining',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPremium
                                    ? colorScheme.onSurface
                                    : colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
    final userAsync = ref.watch(currentUserStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.calendar,
            title: 'Cycle Settings',
            onTap: () {
              context.push('/cycle-settings');
            },
          ),
          const Divider(),
          _buildThemeToggleTile(context, ref),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.bell,
            title: 'Notifications',
            onTap: () {
              context.push('/notification-settings');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.lock,
            title: 'Privacy & Security',
            onTap: () {
              context.push('/security-settings');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.shieldHalved,
            title: 'Privacy Settings',
            onTap: () {
              context.push('/privacy-settings');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.database,
            title: 'Data Management',
            onTap: () {
              _showDataManagementOptions(context, ref);
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.phone,
            title: 'Emergency Contacts',
            onTap: () {
              context.push('/emergency-contacts');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.triangleExclamation,
            title: 'Health Alerts',
            onTap: () {
              context.push('/red-flag-alerts');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.fileMedical,
            title: 'Health Reports',
            onTap: () {
              context.push('/health-report');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.newspaper,
            title: 'Manage Wellness Content',
            onTap: () {
              context.push('/wellness-content-management');
            },
          ),
          const Divider(),
          // Help & Support
          _buildSettingsTile(
            context,
            title: 'Help & Support',
            icon: Icons.help_outline,
            onTap: () => context.push('/help-support'),
          ),

          // Admin Dashboard
          if (userAsync.value?.isAdmin == true) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings,
                  color: Colors.redAccent, size: 24),
              title: const Text('Professional Dashboard',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              trailing: FaIcon(FontAwesomeIcons.chevronRight,
                  size: 16, color: colorScheme.onSurfaceVariant),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AdminDashboardScreen()),
              ),
            ),
          ],

          const SizedBox(height: 32),

          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.circleInfo,
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
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: FaIcon(icon, color: colorScheme.primary, size: 20),
      title: Text(title),
      trailing: FaIcon(FontAwesomeIcons.chevronRight,
          size: 16, color: colorScheme.onSurfaceVariant),
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
        themeIcon = FontAwesomeIcons.sun;
        themeLabel = 'Light Mode';
        break;
      case ThemeMode.dark:
        themeIcon = FontAwesomeIcons.moon;
        themeLabel = 'Dark Mode';
        break;
      case ThemeMode.system:
        themeIcon = FontAwesomeIcons.circleHalfStroke;
        themeLabel = 'System Default';
        break;
    }

    return ListTile(
      leading: FaIcon(themeIcon,
          color: Theme.of(context).colorScheme.primary, size: 20),
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
        activeColor: Theme.of(context).colorScheme.primary,
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
              activeColor: Theme.of(context).colorScheme.primary,
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
              activeColor: Theme.of(context).colorScheme.primary,
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
              activeColor: themeMode == ThemeMode.system
                  ? Theme.of(context).colorScheme.primary
                  : null,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          ListTile(
            leading: FaIcon(FontAwesomeIcons.rightFromBracket,
                color: colorScheme.error, size: 20),
            title: Text(
              'Sign Out',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
            onTap: () => _handleSignOut(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: FaIcon(FontAwesomeIcons.trash,
                color: colorScheme.error, size: 20),
            title: Text(
              'Delete Account',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDataManagementOptions(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

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
              leading: const FaIcon(FontAwesomeIcons.fileArrowDown, size: 20),
              title: const Text('Export Health Report'),
              subtitle: const Text('PDF, Text or Word Doc'),
              onTap: () {
                Navigator.pop(context);
                _exportUserData(context, ref);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.cloudArrowUp, size: 20),
              title: const Text('Backup Data (JSON)'),
              subtitle: const Text('Save a copy of all your data'),
              onTap: () {
                Navigator.pop(context);
                _handleBackup(context, ref);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.cloudArrowDown, size: 20),
              title: const Text('Restore Data (JSON)'),
              subtitle: const Text('Import from a previous backup'),
              onTap: () {
                Navigator.pop(context);
                _handleRestore(context, ref);
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.trashCan, size: 20),
              title: Text(
                'Delete All Data',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  color: colorScheme.error,
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

  Widget _buildLegalSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.shieldHalved,
            title: 'Privacy Policy',
            onTap: () => _navigateToPolicy(
                context, 'Privacy Policy', LegalConstants.privacyPolicy),
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.fileContract,
            title: 'Terms of Service',
            onTap: () => _navigateToPolicy(
                context, 'Terms of Service', LegalConstants.termsOfService),
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.scaleBalanced,
            title: 'EULA',
            onTap: () => _navigateToPolicy(
                context, 'End User License Agreement', LegalConstants.eula),
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.userDoctor,
            title: 'Medical Disclaimer',
            onTap: () => _navigateToPolicy(context, 'Medical Disclaimer',
                LegalConstants.medicalDisclaimer),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.userPlus,
            title: 'Invite Friends',
            onTap: () {
              Share.share(
                  'Join me on FemCare+! The smart assistant for women\'s health and wellness.\nDownload now: https://femcare.app/download',
                  subject: 'Invite to FemCare+');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.shareNodes,
            title: 'Share App',
            onTap: () {
              Share.share(
                  'Check out FemCare+, it is amazing for tracking health and cycle!\nhttps://femcare.app',
                  subject: 'FemCare+ App');
            },
          ),
          const Divider(),
          _buildSettingsTile(
            context,
            icon: FontAwesomeIcons.solidStar,
            title: 'Rate App',
            onTap: () async {
              final InAppReview inAppReview = InAppReview.instance;
              if (await inAppReview.isAvailable()) {
                await inAppReview.requestReview();
              } else {
                // Fallback: Open store listing manually
                await inAppReview.openStoreListing(
                  // Replace with actual app ID once published
                  appStoreId: 'com.femcare.app', // iOS App Store ID
                  // microsoftStoreId: '...' // Optional for Windows
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToPolicy(BuildContext context, String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PolicyViewerScreen(
          title: title,
          markdownContent: content,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    // Navigate to full About screen policy
    _navigateToPolicy(context, 'About FemCare+', LegalConstants.about);
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

  Future<void> _exportUserData(BuildContext context, WidgetRef ref) async {
    final userAsync = ref.read(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in.')),
      );
      return;
    }

    // Credit Check
    final hasCredit = await ref
        .read(creditManagerProvider)
        .requestCredit(context, ActionType.export);
    if (!hasCredit) return;

    // Show format selection dialog
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data Format'),
        content: const Text('Choose your preferred file format for export:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ExportFormat.pdf),
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ExportFormat.txt),
            child: const Text('Text (TXT)'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ExportFormat.docx),
            child: const Text('Word (DOCX)'),
          ),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    // Show modal loading dialog
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
                Text('Preparing your data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final reportService = HealthReportService();
      await reportService.generateReport(
        userId: user.userId,
        format: format,
      );

      await ref.read(creditManagerProvider).consumeCredits(ActionType.export);

      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Failed'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
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

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    try {
      final backupService = DataBackupService();
      await backupService.backupUserData(user.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup shared successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Warning: Restoring data will merge backup data with your current data. It is recommended to backup your current data first.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final backupService = DataBackupService();
      await backupService.restoreUserData(user.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data restored successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildTransactionLedger(
      BuildContext context, WidgetRef ref, String userId) {
    final transactionsAsync = ref.watch(userTransactionsProvider(userId));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/credit-history'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No transactions yet.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              // Show only last 5
              final displayList = transactions.take(3).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tx = displayList[index];
                  final isCredit = tx.type == TransactionType.credit;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCredit
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: FaIcon(
                        isCredit
                            ? FontAwesomeIcons.arrowUp
                            : FontAwesomeIcons.arrowDown,
                        size: 10,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(tx.description),
                    subtitle: Text(
                      DateFormat('MMM d, h:mm a').format(tx.timestamp),
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: Text(
                      '${isCredit ? '+' : '-'}${tx.amount}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }
}
