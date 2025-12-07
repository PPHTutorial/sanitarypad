import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/iap/subscription_manager.dart';

/// Subscription manager provider
final subscriptionManagerProvider = Provider((ref) {
  return SubscriptionManager.instance;
});

/// Pro status provider
final isProUserProvider = StateProvider<bool>((ref) {
  final subscriptionManager = ref.watch(subscriptionManagerProvider);
  return subscriptionManager.isProUser;
});

/// Subscription type provider
final subscriptionTypeProvider = Provider<String>((ref) {
  final subscriptionManager = ref.watch(subscriptionManagerProvider);
  return subscriptionManager.subscriptionType;
});

/// Subscription active provider
final isSubscriptionActiveProvider = Provider<bool>((ref) {
  final subscriptionManager = ref.watch(subscriptionManagerProvider);
  return subscriptionManager.isSubscriptionActive;
});

