import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/security_service.dart';

/// PIN setup screen
class PinSetupScreen extends StatefulWidget {
  final bool isSetup; // true for setup, false for change

  const PinSetupScreen({super.key, this.isSetup = true});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _securityService = SecurityService();
  String _currentStep = 'enter'; // 'enter', 'confirm'

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handlePINEntry() async {
    if (_pinController.text.length != AppConstants.pinLength) {
      return;
    }

    if (_currentStep == 'enter') {
      setState(() => _currentStep = 'confirm');
      _pinController.clear();
    } else {
      if (_pinController.text != _confirmPinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs do not match. Please try again.')),
        );
        setState(() {
          _currentStep = 'enter';
          _pinController.clear();
          _confirmPinController.clear();
        });
        return;
      }

      try {
        final success = await _securityService.setPIN(_pinController.text);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN set successfully')),
          );
          Navigator.of(context).pop();
        } else {
          throw Exception('Failed to set PIN');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? 'Set PIN' : 'Change PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: ResponsiveConfig.padding(all: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pin,
                size: ResponsiveConfig.iconSize(64),
                color: Theme.of(context).colorScheme.primary,
              ),
              ResponsiveConfig.heightBox(32),
              Text(
                _currentStep == 'enter' ? 'Enter your PIN' : 'Confirm your PIN',
                style: ResponsiveConfig.textStyle(
                  size: 24,
                  weight: FontWeight.bold,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                _currentStep == 'enter'
                    ? 'Choose a 4-digit PIN'
                    : 'Re-enter your PIN to confirm',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveConfig.heightBox(32),
              // PIN Input
              TextField(
                controller: _currentStep == 'enter'
                    ? _pinController
                    : _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: AppConstants.pinLength,
                textAlign: TextAlign.center,
                style: ResponsiveConfig.textStyle(
                  size: 32,
                  weight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                  hintText: '••••',
                  hintStyle: ResponsiveConfig.textStyle(
                    size: 32,
                    letterSpacing: 12,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.length == AppConstants.pinLength) {
                    _handlePINEntry();
                  }
                },
              ),
              ResponsiveConfig.heightBox(24),
              // PIN Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AppConstants.pinLength, (index) {
                  final currentController = _currentStep == 'enter'
                      ? _pinController
                      : _confirmPinController;
                  final isFilled = currentController.text.length > index;
                  return Container(
                    margin: ResponsiveConfig.margin(horizontal: 4),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
