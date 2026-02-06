import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/security_service.dart';

/// App lock screen (PIN/Biometric)
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricAvailability();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final securityService = ref.read(securityServiceProvider);
    final isAvailable = await securityService.isBiometricAvailable();
    final isEnabled = await securityService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
      });
      if (isAvailable && isEnabled) {
        _tryBiometricAuth();
      }
    }
  }

  Future<void> _tryBiometricAuth() async {
    final securityService = ref.read(securityServiceProvider);
    final authenticated = await securityService.authenticateBiometric();
    if (authenticated && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _verifyPIN() async {
    final pin = _pinController.text;
    if (pin.length != AppConstants.pinLength) {
      return;
    }

    final securityService = ref.read(securityServiceProvider);
    final isValid = await securityService.verifyPin(pin);
    if (isValid) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _failedAttempts++;
        _pinController.clear();
      });

      if (_failedAttempts >= _maxAttempts) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Too many failed attempts. Please try again later.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incorrect PIN. ${_maxAttempts - _failedAttempts} attempts remaining.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: ResponsiveConfig.padding(all: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outlined,
                size: ResponsiveConfig.iconSize(80),
                color: colorScheme.primary,
              ),
              ResponsiveConfig.heightBox(32),
              Text(
                'Unlock FemCare+',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                'Enter your PIN to continue',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              ResponsiveConfig.heightBox(32),
              // PIN Input (hidden)
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: AppConstants.pinLength,
                textAlign: TextAlign.center,
                style: ResponsiveConfig.textStyle(
                  size: 24,
                  weight: FontWeight.bold,
                  letterSpacing: 8,
                ).copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '••••',
                  hintStyle: ResponsiveConfig.textStyle(
                    size: 24,
                    letterSpacing: 8,
                  ).copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                ),
                onChanged: (value) {
                  if (value.length == AppConstants.pinLength) {
                    _verifyPIN();
                  }
                },
              ),
              ResponsiveConfig.heightBox(24),
              // Biometric button
              if (_isBiometricAvailable && _isBiometricEnabled)
                TextButton.icon(
                  onPressed: _tryBiometricAuth,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ResponsiveConfig.heightBox(16),
              if (_failedAttempts > 0)
                Text(
                  'Failed attempts: $_failedAttempts/$_maxAttempts',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
