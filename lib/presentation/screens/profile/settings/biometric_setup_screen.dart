import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../services/security_service.dart';
import '../../../../core/providers/auth_provider.dart';

/// Biometric setup screen
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _isAvailable = false;
  bool _isEnabled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final securityService = ref.read(securityServiceProvider);
    final isAvailable = await securityService.isBiometricAvailable();
    final isEnabled = await securityService.isBiometricEnabled();

    setState(() {
      _isAvailable = isAvailable;
      _isEnabled = isEnabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _isLoading = true);
    try {
      final securityService = ref.read(securityServiceProvider);
      final user = ref.read(currentUserStreamProvider).value;
      if (user == null || !user.subscription.isActive) {
        throw Exception('Premium required for Biometric lock');
      }

      if (value) {
        // Test biometric first
        final authenticated = await securityService.authenticateBiometric();
        if (authenticated) {
          await securityService.setBiometricEnabled(true);

          // Update Firestore
          final updatedUser = user.copyWith(
            settings: user.settings.copyWith(biometricLock: true),
          );
          await ref.read(authServiceProvider).updateUserData(updatedUser);

          setState(() => _isEnabled = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric lock enabled')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric authentication failed')),
            );
          }
        }
      } else {
        await securityService.setBiometricEnabled(false);

        // Update Firestore
        final updatedUser = user.copyWith(
          settings: user.settings.copyWith(biometricLock: false),
        );
        await ref.read(authServiceProvider).updateUserData(updatedUser);

        setState(() => _isEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric lock disabled')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Lock'),
      ),
      body: SafeArea(
        child: Padding(
          padding: ResponsiveConfig.padding(all: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.fingerprint,
                size: ResponsiveConfig.iconSize(80),
                color: Theme.of(context).colorScheme.primary,
              ),
              ResponsiveConfig.heightBox(24),
              Text(
                'Biometric Authentication',
                style: ResponsiveConfig.textStyle(
                  size: 24,
                  weight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveConfig.heightBox(16),
              if (!_isAvailable)
                Card(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  child: Padding(
                    padding: ResponsiveConfig.padding(all: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        ResponsiveConfig.widthBox(12),
                        Expanded(
                          child: Text(
                            'Biometric authentication is not available on this device.',
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ResponsiveConfig.heightBox(24),
                Card(
                  child: SwitchListTile(
                    title: const Text('Enable Biometric Lock'),
                    subtitle: const Text(
                      'Use your fingerprint or face to unlock the app',
                    ),
                    value: _isEnabled,
                    onChanged: _isLoading ? null : _toggleBiometric,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
