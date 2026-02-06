import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';
import 'iap_service.dart';

/// Subscription service for managing premium subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final IAPService _iapService = IAPService();

  /// Get user subscription
  Future<UserSubscription> getUserSubscription(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return const UserSubscription(
          tier: 'economy',
          status: 'expired',
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserSubscription.fromMap(data);
    } catch (e) {
      return const UserSubscription(
        tier: 'economy',
        status: 'expired',
      );
    }
  }

  /// Create or update subscription
  Future<void> createSubscription({
    required String userId,
    required String tier,
    required String plan,
    required DateTime startDate,
    required DateTime endDate,
    String? transactionId,
  }) async {
    try {
      // User request: "unlimited for yearly subs"
      // If plan is yearly, give virtually unlimited credits (e.g., 999990)
      // Otherwise use tier default.
      final isYearlyCheck = plan.toLowerCase().contains('yearly') ||
          endDate.difference(startDate).inDays > 300;
      final defaultCredits =
          _getInitialCreditsForTier(tier, isYearly: isYearlyCheck);

      await _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(userId)
          .set({
        'userId': userId,
        'tier': tier,
        'plan': plan,
        'status': 'active',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'transactionId': transactionId,
        'dailyCreditsRemaining': defaultCredits,
        'adCreditsEarnedToday': 0,
        'totalActionsToday': 0,
        'lastResetDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  double _getInitialCreditsForTier(String tier, {bool isYearly = false}) {
    if (isYearly) return AppConstants.creditsYearly;

    switch (tier) {
      case AppConstants.tierEconomy:
        return AppConstants.creditsEco;
      case AppConstants.tierPremiumPro:
        return AppConstants.creditsPro;
      case AppConstants.tierPremiumAdvance:
        return AppConstants.creditsAdv;
      case AppConstants.tierPremiumPlus:
        return AppConstants.creditsPlus;
      default:
        return AppConstants.creditsDefault;
    }
  }

  /// Check if a user can perform an action based on credits and tier
  Future<bool> canPerformAction(String userId, String feature) async {
    try {
      final sub = await getUserSubscription(userId);

      // 1. Check if reset is needed
      if (sub.shouldResetDaily) {
        await _resetDailyCredits(userId, sub.tier, isYearly: sub.isYearly);
        return true;
      }

      // 2. Check "No Ads" features for paid tiers (Still valid for pure ad experience)
      if (feature == 'ads' && sub.tier != AppConstants.tierEconomy) {
        return false; // Paid tiers don't show ads
      }

      // Feature access is now purely credit-based.
      // Individual tiers can still have different credit balances, but
      // we don't hard-block 'pregnancy' or 'movies' anymore.
      // The CreditManager will handle specific costs.

      return sub.dailyCreditsRemaining > 0;
    } catch (e) {
      return false;
    }
  }

  /// Consume a credit for an action
  Future<void> consumeCredit(String userId) async {
    try {
      final docRef = _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final currentCredits =
            (data['dailyCreditsRemaining'] as num? ?? 0.0).toDouble();
        final currentActions = (data['totalActionsToday'] as num? ?? 0).toInt();

        transaction.update(docRef, {
          'dailyCreditsRemaining': currentCredits > 0 ? currentCredits - 1 : 0,
          'totalActionsToday': currentActions + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error consuming credit: $e');
    }
  }

  Future<void> _resetDailyCredits(String userId, String tier,
      {bool isYearly = false}) async {
    final defaultCredits = _getInitialCreditsForTier(tier, isYearly: isYearly);
    await _firestore
        .collection(AppConstants.collectionSubscriptions)
        .doc(userId)
        .update({
      'dailyCreditsRemaining': defaultCredits,
      'adCreditsEarnedToday': 0,
      'totalActionsToday': 0,
      'status': 'active',
      'lastResetDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Proactive check for daily reset (externally called)
  Future<void> checkDailyReset(String userId) async {
    try {
      final sub = await getUserSubscription(userId);
      if (sub.shouldResetDaily) {
        await _resetDailyCredits(userId, sub.tier, isYearly: sub.isYearly);
      }
    } catch (e) {
      debugPrint('Error checking daily reset: $e');
    }
  }

  /// Create subscription from IAP purchase
  Future<void> createSubscriptionFromIAP({
    required String userId,
    required String productId,
    required String transactionId,
    required DateTime transactionDate,
  }) async {
    try {
      final plan = _getPlanFromProductId(productId);
      final tier = _getTierFromProductId(productId);
      final startDate = transactionDate;
      final endDate = _calculateEndDate(startDate, plan);

      await createSubscription(
        userId: userId,
        tier: tier,
        plan: plan,
        startDate: startDate,
        endDate: endDate,
        transactionId: transactionId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get tier from product ID
  String _getTierFromProductId(String productId) {
    final lowerId = productId.toLowerCase();
    if (lowerId.contains('_pro_')) {
      return AppConstants.tierPremiumPro;
    } else if (lowerId.contains('_adv_')) {
      return AppConstants.tierPremiumAdvance;
    } else if (lowerId.contains('_plu_')) {
      return AppConstants.tierPremiumPlus;
    } else if (lowerId.contains('_eco_')) {
      return AppConstants.tierEconomy;
    }
    return AppConstants.tierPremiumPro; // Default to Pro
  }

  /// Get plan from product ID
  String _getPlanFromProductId(String productId) {
    if (productId.contains('monthly')) {
      return AppConstants.planMonthly;
    } else if (productId.contains('quarterly')) {
      return AppConstants.planQuarterly;
    } else if (productId.contains('yearly')) {
      return AppConstants.planYearly;
    }
    return AppConstants.planMonthly;
  }

  /// Calculate end date based on plan
  DateTime _calculateEndDate(DateTime startDate, String plan) {
    switch (plan) {
      case AppConstants.planMonthly:
        return startDate.add(const Duration(days: 30));
      case AppConstants.planQuarterly:
        return startDate.add(const Duration(days: 90));
      case AppConstants.planYearly:
        return startDate.add(const Duration(days: 365));
      default:
        return startDate.add(const Duration(days: 30));
    }
  }

  /// Initialize IAP service
  Future<void> initializeIAP() async {
    await _iapService.initialize();
  }

  /// Get IAP service
  IAPService get iapService => _iapService;

  /// Cancel subscription
  Future<void> cancelSubscription(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(userId)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Check if subscription is active
  Future<bool> isSubscriptionActive(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (!subscription.isActive) return false;

      if (subscription.endDate != null) {
        return subscription.endDate!.isAfter(DateTime.now());
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get subscription plans
  Map<String, Map<String, dynamic>> getSubscriptionPlans() {
    // Order: Eco, Pro, Advance (Most Popular), Plus
    return {
      AppConstants.tierEconomy: {
        'name': 'Eco (Economy)',
        'price': AppConstants.priceEco,
        'credit': AppConstants.creditsEco,
        'tier': AppConstants.tierEconomy,
        'productId': 'femcare_eco_forever',
        'productIdYearly': 'femcare_eco_forever', // Eco is free/forever
        'isPopular': false,
        'features': [
          'Journal & Calendar',
          'Menstrual & Fertility Health',
          'Wellness & Mental Health',
          'Health Report & Community',
          '${AppConstants.creditsEco.toInt()} daily free credits',
          'Contains Ads',
        ],
      },
      AppConstants.tierPremiumPro: {
        'name': 'Pro (Premium Pro)',
        'price': AppConstants.pricePro,
        'credit': AppConstants.creditsPro,
        'tier': AppConstants.tierPremiumPro,
        'productId': 'femcare_pro_monthly',
        'productIdYearly': 'femcare_pro_yearly',
        'isPopular': false,
        'features': [
          'Everything in Eco',
          'Skincare & Dermatology',
          'Safety & Medical Alerts',
          'Movies & AI Chat',
          '${AppConstants.creditsPro.toInt()} daily free credits',
          'No Ads',
        ],
      },
      AppConstants.tierPremiumAdvance: {
        'name': 'Adv (Premium Advance)',
        'price': AppConstants.priceAdv,
        'credit': AppConstants.creditsAdv,
        'tier': AppConstants.tierPremiumAdvance,
        'productId': 'femcare_adv_monthly',
        'productIdYearly': 'femcare_adv_yearly',
        'isPopular': true,
        'features': [
          'Everything in Pro',
          'Pregnancy Companion',
          'Pro AI Chat features',
          '${AppConstants.creditsAdv.toInt()} daily free credits',
          'No Ads',
        ],
      },
      AppConstants.tierPremiumPlus: {
        'name': 'Plu (Premium Plus)',
        'price': AppConstants.pricePlus,
        'credit': AppConstants.creditsPlus,
        'tier': AppConstants.tierPremiumPlus,
        'productId': 'femcare_plu_monthly',
        'productIdYearly': 'femcare_plu_yearly',
        'isPopular': false,
        'features': [
          'Everything in Advance',
          'Priority AI access',
          '${AppConstants.creditsPlus.toInt()} daily free credits',
          'No Ads',
        ],
      },
    };
  }

  /// Get premium features
  List<String> getPremiumFeatures() {
    return [
      'Cycle & Fertility Tracking',
      'Wellness & Mental Health',
      'Health Reports',
      'Skincare & Dermatology',
      'Safety & Medical Alerts',
      'High Quality Movies',
      'AI Wellness Chat',
      'Pregnancy Mode',
      'Ad-free Experience',
    ];
  }
}
