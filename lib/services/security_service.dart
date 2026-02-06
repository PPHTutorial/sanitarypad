 import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

class SecurityService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const String _pinKey = 'user_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _anonymousModeKey = 'anonymous_mode';

  // --- PIN Management ---

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }

  Future<void> removePin() async {
    await _storage.delete(key: _pinKey);
    // If PIN is removed, biometric should likely be disabled too as fallback
    await setBiometricEnabled(false);
  }

  // --- Biometric Management ---

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> authenticateBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access FemCare+',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // --- Anonymous Mode ---

  Future<bool> isAnonymousModeEnabled() async {
    final val = await _storage.read(key: _anonymousModeKey);
    return val == 'true';
  }

  Future<void> setAnonymousMode(bool enabled) async {
    await _storage.write(key: _anonymousModeKey, value: enabled.toString());
  }
}
