import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/security_service.dart';

/// Biometric setup screen
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _securityService = SecurityService();
  bool _isAvailable = false;
  bool _isEnabled = false;
  List<BiometricType> _availableTypes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final isAvailable = await _securityService.isBiometricAvailable();
    final isEnabled = await _securityService.isBiometricLockEnabled();
    final types = await _securityService.getAvailableBiometrics();

    setState(() {
      _isAvailable = isAvailable;
      _isEnabled = isEnabled;
      _availableTypes = types;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    setState(() => _isLoading = true);
    try {
      if (value) {
        // Test biometric first
        final authenticated = await _securityService.authenticateWithBiometrics(
          localizedReason: 'Enable biometric lock for FemCare+',
        );
        if (authenticated) {
          await _securityService.enableBiometricLock();
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
        await _securityService.disableBiometricLock();
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

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Authentication';
      case BiometricType.weak:
        return 'Weak Authentication';
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
                color: AppTheme.primaryPink,
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
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  child: Padding(
                    padding: ResponsiveConfig.padding(all: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.warningOrange,
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
                if (_availableTypes.isNotEmpty) ...[
                  Text(
                    'Available methods:',
                    style: ResponsiveConfig.textStyle(
                      size: 16,
                      weight: FontWeight.w600,
                    ),
                  ),
                  ResponsiveConfig.heightBox(8),
                  ..._availableTypes.map((type) {
                    return Padding(
                      padding: ResponsiveConfig.padding(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successGreen,
                            size: ResponsiveConfig.iconSize(20),
                          ),
                          ResponsiveConfig.widthBox(8),
                          Text(
                            _getBiometricTypeName(type),
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  ResponsiveConfig.heightBox(24),
                ],
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
