import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for onboarding status
/// Initialized with override in main.dart
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);
