import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
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

    return PopScope(
      canPop: false, // Prevent bypassing lock screen via back button
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Optionally show exit confirmation if they really want to leave
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: ResponsiveConfig.padding(all: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: ResponsiveConfig.iconSize(64),
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  ResponsiveConfig.heightBox(32),
                  Text(
                    'Welcome Back',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  ResponsiveConfig.heightBox(8),
                  Text(
                    'Enter PIN to unlock FemCare+',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  ResponsiveConfig.heightBox(48),
                  // PIN Dots (Visual Feedback)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(AppConstants.pinLength, (index) {
                      final isFilled = _pinController.text.length > index;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? AppTheme.primaryPink
                              : colorScheme.outlineVariant,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isFilled
                                ? AppTheme.primaryPink
                                : colorScheme.outline.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color:
                                        AppTheme.primaryPink.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Invisible TextField for focus
                  SizedBox(
                    height: 0,
                    width: 0,
                    child: TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      obscureText: true,
                      maxLength: AppConstants.pinLength,
                      decoration: const InputDecoration(
                          border: InputBorder.none, counterText: ''),
                      onChanged: (value) {
                        setState(() {}); // Update dots
                        if (value.length == AppConstants.pinLength) {
                          _verifyPIN();
                        }
                      },
                    ),
                  ),
                  // Biometric button
                  if (_isBiometricAvailable && _isBiometricEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: TextButton.icon(
                        onPressed: _tryBiometricAuth,
                        icon: const Icon(Icons.fingerprint, size: 32),
                        label: const Text('Use Biometric',
                            style: TextStyle(fontSize: 16)),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ),
                  if (_failedAttempts > 0)
                    Text(
                      'Failed attempts: $_failedAttempts/$_maxAttempts',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ResponsiveConfig.heightBox(32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
