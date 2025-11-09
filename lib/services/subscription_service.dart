import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/user_model.dart';

/// Subscription service for managing premium subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        'price': 4.99,
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
        'price': 12.99,
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
      AppConstants.planYearly: {
        'name': 'Yearly',
        'price': 39.99,
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
