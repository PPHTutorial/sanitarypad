import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';

/// Security service for PIN and biometric authentication
class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Authenticate to access FemCare+',
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Set PIN
  Future<bool> setPIN(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinHash = _hashPIN(pin);
      return await prefs.setString(AppConstants.prefsKeyPinHash, pinHash);
    } catch (e) {
      return false;
    }
  }

  /// Verify PIN
  Future<bool> verifyPIN(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString(AppConstants.prefsKeyPinHash);
      if (storedHash == null) return false;

      final inputHash = _hashPIN(pin);
      return storedHash == inputHash;
    } catch (e) {
      return false;
    }
  }

  /// Check if PIN is set
  Future<bool> isPINSet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(AppConstants.prefsKeyPinHash);
    } catch (e) {
      return false;
    }
  }

  /// Remove PIN
  Future<bool> removePIN() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(AppConstants.prefsKeyPinHash);
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric lock
  Future<bool> enableBiometricLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(AppConstants.prefsKeyBiometricEnabled, true);
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric lock
  Future<bool> disableBiometricLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(AppConstants.prefsKeyBiometricEnabled, false);
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric lock is enabled
  Future<bool> isBiometricLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.prefsKeyBiometricEnabled) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Hash PIN using SHA-256
  String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if app should be locked
  Future<bool> shouldLockApp() async {
    final pinSet = await isPINSet();
    final biometricEnabled = await isBiometricLockEnabled();
    return pinSet || biometricEnabled;
  }

  /// Authenticate (PIN or biometric)
  Future<bool> authenticate({
    String? pin,
    bool useBiometric = false,
  }) async {
    if (useBiometric) {
      return await authenticateWithBiometrics();
    } else if (pin != null) {
      return await verifyPIN(pin);
    }
    return false;
  }
}
