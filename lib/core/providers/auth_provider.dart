import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user stream provider
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);

  return authService.authStateChanges.asyncExpand((user) {
    if (user == null) {
      return Stream.value(null);
    } else {
      // Use asyncExpand to switch streams when auth state changes
      return authService.getUserStream(user.uid);
    }
  });
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.value;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);

  // Use synchronous check if stream is still loading or has no value yet
  if (!userAsync.hasValue) {
    return ref.watch(authServiceProvider).currentUser != null;
  }

  return userAsync.value != null;
});
