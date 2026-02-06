import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../../data/models/user_model.dart';
import '../../data/models/transaction_model.dart';
import '../../presentation/widgets/subscription/subscription_widgets.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService());

final userSubscriptionProvider = Provider<UserSubscription?>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  return user?.subscription;
});

final subscriptionActionProvider = Provider((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  final user = ref.watch(currentUserStreamProvider).value;

  return SubscriptionActionHandler(service, user);
});

class SubscriptionActionHandler {
  final SubscriptionService _service;
  final UserModel? _user;

  SubscriptionActionHandler(this._service, this._user);

  /// Check if user can perform action and show dialog if not
  Future<bool> handleFeatureAccess(
    BuildContext context, {
    required String feature,
    required VoidCallback onAuthorized,
    String? paywallTitle,
    String? paywallMessage,
    List<String>? paywallFeatures,
  }) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to access this feature')),
      );
      return false;
    }

    final canAccess = await _service.canPerformAction(_user!.userId, feature);

    if (canAccess) {
      // Consume credit (logic depending on tier and feature)
      // For now, we consume 1 credit for any restricted feature
      if (_needsCreditConsumption(feature)) {
        await _service.consumeCredit(_user!.userId);
      }
      onAuthorized();
      return true;
    } else {
      // Feature access denied (either out of credits or logic block)
      // Per user request, we offer options to watch ads/upgrade instead of a hard limit.
      _showOutOfCreditsDialog(context);
      return false;
    }
  }

  bool _needsCreditConsumption(String feature) {
    // Economy usage always consumes credits for premium-like features
    if (_user?.subscription.tier == 'economy') {
      return true; // Simple: Eco consumes credits for everything
    }
    // Paid tiers don't consume credits for these (they have high/unlimited limits)
    return false;
  }

  void _showOutOfCreditsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OutOfCreditsDialog(),
    );
  }
}

final userTransactionsProvider =
    StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('transactions')
      .where('userId', isEqualTo: userId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList());
});
