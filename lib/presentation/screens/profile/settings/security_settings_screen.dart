import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../services/security_service.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          final isPremium = user.subscription.isActive;

          return SingleChildScrollView(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'App Protection'),
                ResponsiveConfig.heightBox(12),
                _buildSecurityCard(context, [
                  FutureBuilder<bool>(
                    future: ref.watch(securityServiceProvider).hasPin(),
                    builder: (context, snapshot) {
                      final hasPin = snapshot.data ?? false;
                      return _buildSecurityTile(
                        context,
                        icon: FontAwesomeIcons.key,
                        title: 'PIN Lock',
                        subtitle: hasPin
                            ? 'PIN is set. Tap to change.'
                            : 'Secure app access with a 4-digit PIN',
                        isPremium: isPremium,
                        onTap: () => context.push('/pin-setup'),
                      );
                    },
                  ),
                  const Divider(),
                  _buildBiometricTile(context, ref, isPremium),
                ]),
                ResponsiveConfig.heightBox(24),
                _buildSectionTitle(context, 'Privacy'),
                ResponsiveConfig.heightBox(12),
                _buildSecurityCard(context, [
                  _buildAnonymousModeTile(context, ref, isPremium),
                  const Divider(),
                  _buildSecurityTile(
                    context,
                    icon: FontAwesomeIcons.shieldHalved,
                    title: 'Profile Visibility',
                    subtitle: 'Manage what others can see',
                    onTap: () => context.push('/privacy-settings'),
                  ),
                ]),
                if (!isPremium) ...[
                  ResponsiveConfig.heightBox(32),
                  _buildPremiumUpsell(context),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildSecurityCard(BuildContext context, List<Widget> children) {
    return Card(
      child: Column(children: children),
    );
  }

  Widget _buildSecurityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPremium = true,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: FaIcon(icon,
          color: isPremium ? colorScheme.primary : Colors.grey, size: 20),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isPremium
          ? const FaIcon(FontAwesomeIcons.chevronRight, size: 14)
          : const FaIcon(FontAwesomeIcons.lock, size: 14, color: Colors.amber),
      onTap: isPremium ? onTap : () => _showPremiumDialog(context),
    );
  }

  Widget _buildBiometricTile(
      BuildContext context, WidgetRef ref, bool isPremium) {
    final securityService = ref.watch(securityServiceProvider);
    final user = ref.read(currentUserStreamProvider).value;
    final effectivePremium = isPremium || (user?.isAdmin ?? false);

    return FutureBuilder<bool>(
      future: securityService.isBiometricAvailable(),
      builder: (context, snapshot) {
        final available = snapshot.data ?? false;
        if (!available) return const SizedBox.shrink();

        return FutureBuilder<bool>(
          future: securityService.isBiometricEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            return ListTile(
              leading: FaIcon(FontAwesomeIcons.fingerprint,
                  color: effectivePremium
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 20),
              title: const Text('Biometric Lock'),
              subtitle: const Text('Use Fingerprint/FaceID to unlock'),
              trailing: effectivePremium
                  ? Switch(
                      value: enabled,
                      onChanged: (val) async {
                        try {
                          if (val) {
                            final authenticated =
                                await securityService.authenticateBiometric();
                            if (authenticated) {
                              await securityService.setBiometricEnabled(true);

                              // Update Firestore
                              if (user != null) {
                                final updatedUser = user.copyWith(
                                  settings: user.settings
                                      .copyWith(biometricLock: true),
                                );
                                await ref
                                    .read(authServiceProvider)
                                    .updateUserData(updatedUser);
                              }
                              ref.invalidate(securityServiceProvider);
                            }
                          } else {
                            await securityService.setBiometricEnabled(false);

                            // Update Firestore
                            if (user != null) {
                              final updatedUser = user.copyWith(
                                settings: user.settings
                                    .copyWith(biometricLock: false),
                              );
                              await ref
                                  .read(authServiceProvider)
                                  .updateUserData(updatedUser);
                            }
                            ref.invalidate(securityServiceProvider);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      },
                    )
                  : const FaIcon(FontAwesomeIcons.lock,
                      size: 14, color: Colors.amber),
              onTap:
                  effectivePremium ? null : () => _showPremiumDialog(context),
            );
          },
        );
      },
    );
  }

  Widget _buildAnonymousModeTile(
      BuildContext context, WidgetRef ref, bool isPremium) {
    final securityService = ref.watch(securityServiceProvider);
    final user = ref.read(currentUserStreamProvider).value;
    final effectivePremium = isPremium || (user?.isAdmin ?? false);

    return FutureBuilder<bool>(
      future: securityService.isAnonymousModeEnabled(),
      builder: (context, snapshot) {
        final enabled = snapshot.data ?? false;
        return ListTile(
          leading: FaIcon(FontAwesomeIcons.eyeSlash,
              color: effectivePremium
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              size: 20),
          title: const Text('Anonymous Mode'),
          subtitle: const Text('Hide your identity in community features'),
          trailing: effectivePremium
              ? Switch(
                  value: enabled,
                  onChanged: (val) async {
                    // Update locally
                    await securityService.setAnonymousMode(val);

                    // Update in Firestore
                    if (user != null) {
                      final updatedUser = user.copyWith(
                        settings: user.settings.copyWith(anonymousMode: val),
                      );
                      await ref
                          .read(authServiceProvider)
                          .updateUserData(updatedUser);
                    }

                    ref.invalidate(securityServiceProvider);
                  },
                )
              : const FaIcon(FontAwesomeIcons.lock,
                  size: 14, color: Colors.amber),
          onTap: effectivePremium ? null : () => _showPremiumDialog(context),
        );
      },
    );
  }

  Widget _buildPremiumUpsell(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: ResponsiveConfig.padding(all: 20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: ResponsiveConfig.borderRadius(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.crown,
                  color: Colors.amber[700], size: 24),
              ResponsiveConfig.widthBox(16),
              Expanded(
                child: Text(
                  'Unlock Advanced Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          ResponsiveConfig.heightBox(12),
          Text(
            'PIN Lock, Biometric Authentication, and Anonymous Mode are exclusive to FemCare+ Premium members.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          ResponsiveConfig.heightBox(16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/subscription'),
              child: const Text('Upgrade Now'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.crown, color: Colors.amber, size: 20),
            SizedBox(width: 12),
            Text('Premium Feature'),
          ],
        ),
        content: const Text(
            'Security locks and Anonymous mode are available for Premium users only. Upgrade now to secure your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}
