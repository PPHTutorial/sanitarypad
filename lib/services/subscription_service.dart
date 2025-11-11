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
          tier: 'free',
          status: 'expired',
        );
      }

      final data = doc.data() as Map<String, dynamic>;
      return UserSubscription.fromMap(data);
    } catch (e) {
      return const UserSubscription(
        tier: 'free',
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
      await _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(userId)
          .set({
        'userId': userId,
        'tier': tier,
        'status': 'active',
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'transactionId': transactionId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
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
      final startDate = transactionDate;
      final endDate = _calculateEndDate(startDate, plan);

      await createSubscription(
        userId: userId,
        tier: AppConstants.tierPremium,
        plan: plan,
        startDate: startDate,
        endDate: endDate,
        transactionId: transactionId,
      );
    } catch (e) {
      rethrow;
    }
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
    return {
      AppConstants.planMonthly: {
        'name': 'Monthly',
        'price': 24.99,
        'currency': 'USD',
        'duration': 1, // months
        'features': [
          'Unlimited cycle tracking',
          'Advanced insights',
          'Wellness content library',
          'Priority support',
        ],
      },
      AppConstants.planQuarterly: {
        'name': 'Quarterly',
        'price': 69.99,
        'currency': 'USD',
        'duration': 3, // months
        'discount': 13, // percentage
        'features': [
          'Unlimited cycle tracking',
          'Advanced insights',
          'Wellness content library',
          'Priority support',
          'Save 13%',
        ],
      },
      AppConstants.planSemiAnnual: {
        'name': 'Semi-Annual',
        'price': 119.99,
        'currency': 'USD',
        'duration': 6, // months
        'discount': 25, // percentage
        'features': [
          'Unlimited cycle tracking',
          'Advanced insights',
          'Wellness content library',
          'Priority support',
          'Save 25%',
        ],
      },
      
      AppConstants.planYearly: {
        'name': 'Yearly',
        'price': 239.99,
        'currency': 'USD',
        'duration': 12, // months
        'discount': 33, // percentage
        'features': [
          'Unlimited cycle tracking',
          'Advanced insights',
          'Wellness content library',
          'Priority support',
          'Save 33%',
        ],
      },
    };
  }

  /// Get premium features
  List<String> getPremiumFeatures() {
    return [
      'Unlimited cycle tracking',
      'Advanced cycle insights & predictions',
      'Wellness content library',
      'Personalized health recommendations',
      'Priority customer support',
      'Ad-free experience',
      'Data export & backup',
      'Multiple device sync',
    ];
  }
}
