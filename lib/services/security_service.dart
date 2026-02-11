import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../core/providers/auth_provider.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  final service = SecurityService(ref);

  // Automatically sync when user data is available
  ref.listen<AsyncValue<UserModel?>>(
    currentUserStreamProvider,
    (previous, next) {
      final user = next.value;
      if (user != null) {
        service.syncWithUserModel(user);
      }
    },
    fireImmediately: true,
  );

  return service;
});

class SecurityService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  SecurityService(Ref ref);

  static const String _pinKey = 'user_pin';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _anonymousModeKey = 'anonymous_mode';

  // --- Sync Management ---

  /// Sync local security settings with cloud user model.
  /// This helps detect if a features should be enabled/setup on this device.
  Future<void> syncWithUserModel(UserModel user) async {
    // If Firestore says biometric is enabled but local storage doesn't know,
    // we still need a local 'true' to trigger the prompt, but the user
    // might need to re-authenticate to "enroll" this specific device.
    if (user.settings.biometricLock) {
      final localEnabled = await isBiometricEnabled();
      if (!localEnabled && await isBiometricAvailable()) {
        // We tentatively enable it locally if it's available,
        // next resume will trigger biometric auth.
        await setBiometricEnabled(true);
      }
    } else {
      await setBiometricEnabled(false);
    }

    // If Firestore says PIN is set but we don't have one locally,
    // we can't "sync" the PIN itself (it's local only),
    // but we can prompt the user that a PIN is required as per their cloud settings.
    final localPin = await hasPin();
    if (user.settings.pinHash != null && !localPin) {
      // PIN is required by account but not set on this device
      // This is a state that should trigger a PIN setup prompt
    }
  }

  // --- PIN Management ---

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
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
      if (!isAvailable) {
        throw Exception(
            'Biometric authentication not available on this device');
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access FemCare+',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow Windows PIN/Hello
          useErrorDialogs: true,
        ),
      );

      return authenticated;
    } catch (e) {
      // Re-throw to allow UI to show specific error
      rethrow;
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
