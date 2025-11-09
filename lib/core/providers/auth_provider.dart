import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user stream provider
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) async* {
  final authService = ref.watch(authServiceProvider);

  await for (final user in authService.authStateChanges) {
    if (user == null) {
      yield null;
    } else {
      try {
        final userData = await authService.getUserData(user.uid);
        yield userData;
      } catch (e) {
        yield null;
      }
    }
  }
});

/// Current user provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final userAsync = ref.watch(currentUserStreamProvider);
  return userAsync.value;
});

/// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
