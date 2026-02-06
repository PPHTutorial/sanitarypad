import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';
import 'firebase_provider.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user stream provider
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  // CRITICAL: Wait for Firebase to be ready before accessing auth
  final isFirebaseReady = ref.watch(firebaseReadyProvider);
  if (!isFirebaseReady) {
    return Stream.value(null);
  }

  try {
    final authService = ref.watch(authServiceProvider);

    return authService.authStateChanges.asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      } else {
        // Use asyncExpand to switch streams when auth state changes
        return authService.getUserStream(user.uid);
      }
    });
  } catch (e) {
    // If accessing auth service fails, return null stream
    return Stream.value(null);
  }
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.valueOrNull; // Use valueOrNull for safety
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.valueOrNull != null;
});
