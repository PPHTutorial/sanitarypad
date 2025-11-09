import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/security_service.dart';

/// App lock screen (PIN/Biometric)
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinController = TextEditingController();
  final _securityService = SecurityService();
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  int _failedAttempts = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _securityService.isBiometricAvailable();
    final isEnabled = await _securityService.isBiometricLockEnabled();
    setState(() {
      _isBiometricAvailable = isAvailable;
      _isBiometricEnabled = isEnabled;
    });
  }

  Future<void> _tryBiometricAuth() async {
    if (_isBiometricEnabled && _isBiometricAvailable) {
      final authenticated = await _securityService.authenticateWithBiometrics();
      if (authenticated && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _verifyPIN() async {
    final pin = _pinController.text;
    if (pin.length != AppConstants.pinLength) {
      return;
    }

    final isValid = await _securityService.verifyPIN(pin);
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
                color: AppTheme.primaryPink,
              ),
              ResponsiveConfig.heightBox(32),
              Text(
                'Unlock FemCare+',
                style: ResponsiveConfig.textStyle(
                  size: 24,
                  weight: FontWeight.bold,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                'Enter your PIN to continue',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  color: AppTheme.mediumGray,
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
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                  hintText: '••••',
                  hintStyle: ResponsiveConfig.textStyle(
                    size: 24,
                    letterSpacing: 8,
                  ),
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
                ),
              ResponsiveConfig.heightBox(16),
              if (_failedAttempts > 0)
                Text(
                  'Failed attempts: $_failedAttempts/$_maxAttempts',
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    color: AppTheme.errorRed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
