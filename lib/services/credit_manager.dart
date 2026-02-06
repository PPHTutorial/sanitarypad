import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanitarypad/core/constants/app_constants.dart';
import 'package:sanitarypad/core/providers/auth_provider.dart';
import 'package:sanitarypad/presentation/widgets/subscription/subscription_widgets.dart';
import 'package:sanitarypad/services/ads_service.dart';
import 'package:go_router/go_router.dart';
import 'package:sanitarypad/data/models/transaction_model.dart';
import 'package:sanitarypad/data/models/user_model.dart';

enum ActionType {
  pregnancy(AppConstants.costPregnancy),
  fertility(AppConstants.costFertility),
  skincare(AppConstants.costSkincare),
  wellness(AppConstants.costWellness),
  logPeriod(AppConstants.costLogPeriod),
  padChange(AppConstants.costPadChange),
  notification(AppConstants.costNotification),
  cycleSettings(0),
  aiChat(AppConstants.costAIChat),
  movie(AppConstants.costMovie),
  createGroup(AppConstants.costCreateGroup),
  createEvent(AppConstants.costCreateEvent),
  dermatologist(AppConstants.costDermatologist),
  export(AppConstants.costExport),
  emergencyNumber(AppConstants.costEmergencyNumber);

  final double cost;
  const ActionType(this.cost);
}

final creditManagerProvider = Provider<CreditManager>((ref) {
  return CreditManager(ref);
});

class CreditManager {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CreditManager(this._ref);

  /// Check if user has enough credits for the action
  /// Returns [true] if allowed, [false] if blocked (insufficient credits)
  /// Triggers a dialog if blocked.
  Future<bool> requestCredit(BuildContext context, ActionType action,
      {bool showDialog = true}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;

    // 1. Check & Reset Daily Credits if needed
    // We do this check first to ensure the user has their fresh batch if it's a new day
    await _checkAndResetDailyCredits(user.userId);

    // 2. Re-fetch user to get updated credits after potential reset
    // We can just listen to the stream, but for this blocking check, a fresh fetch or
    // relying on the stream wrapper update is safer.
    // optimization: The stream in UI will update, but inside this sync/async flow,
    // we want reliable data.
    final userDoc = await _firestore
        .collection(AppConstants.collectionSubscriptions)
        .doc(user.userId)
        .get();
    if (!userDoc.exists) return false;

    final data = userDoc.data()!;
    double credits = (data['dailyCreditsRemaining'] as num?)?.toDouble() ?? 0.0;

    // Unlimited check (Yearly tier gets 9999, so effectively unlimited, but we still track)
    // If credits are unreasonably high (e.g. > 1000), we just allow it but still deduct for stats?
    // User requirement: "Once credit is exhausted... 3 ads = 5 credits extra."
    // So we don't grant unlimited unless they BOUGHT unlimited.
    // If they have 9999, they will practically never run out.

    if (credits >= action.cost) {
      // Allow
      return true;
    } else {
      // Insufficient credits
      if (showDialog && context.mounted) {
        _showInsufficientCreditsDialog(context, action);
      }
      return false;
    }
  }

  /// Consumes credits for an action.
  /// Call this ONLY after [requestCredit] returns true.
  Future<void> consumeCredits(ActionType action) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(user.userId)
          .update({
        'dailyCreditsRemaining': FieldValue.increment(-action.cost),
        'totalActionsToday': FieldValue.increment(1),
        'lastActivityTime': FieldValue.serverTimestamp(),
      });

      await logTransaction(TransactionModel(
        userId: user.userId,
        amount: action.cost,
        action: action.name,
        type: TransactionType.debit,
        timestamp: DateTime.now(),
        description: 'Spent ${action.cost} credits for ${action.name}',
      ));

      debugPrint('Consumed ${action.cost} credits for ${action.name}');
    } catch (e) {
      debugPrint('Failed to consume credits locally: $e');
    }
  }

  /// Show ad to earn credits
  Future<void> showAdForCredits(BuildContext context) async {
    final adsService = AdsService();

    if (!adsService.isRewardedAdAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Ad is loading, please wait...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    await adsService.showRewardedAd(
      onUserEarnedReward: (reward) async {
        await _incrementAdProgress();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reward earned!')),
          );
        }
      },
      onAdFailedToLoad: (error) {
        if (context.mounted) {
          _showAdNotReadyDialog(context);
        }
      },
    );
  }

  Future<void> _incrementAdProgress() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final docRef = _firestore
        .collection(AppConstants.collectionSubscriptions)
        .doc(user.userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      int currentProgress =
          (snapshot.data()?['adProgress'] as num?)?.toInt() ?? 0;
      int nextProgress = currentProgress + 1;
      double creditsToGrant = 0.0;

      if (nextProgress >= AppConstants.adsNeededForReward) {
        nextProgress = 0;
        creditsToGrant = AppConstants.creditsPerAdReward;
      }

      transaction.update(docRef, {
        'adProgress': nextProgress,
        if (creditsToGrant > 0)
          'dailyCreditsRemaining': FieldValue.increment(creditsToGrant),
        if (creditsToGrant > 0)
          'adCreditsEarnedToday': FieldValue.increment(creditsToGrant),
      });

      // Log progress
      await logTransaction(TransactionModel(
        userId: user.userId,
        amount: 0,
        action: 'ad_progress',
        type: TransactionType.credit,
        timestamp: DateTime.now(),
        description:
            'Watched ad ($nextProgress/${AppConstants.adsNeededForReward} progress)',
      ));

      if (creditsToGrant > 0) {
        await logTransaction(TransactionModel(
          userId: user.userId,
          amount: creditsToGrant,
          action: 'ad_reward',
          type: TransactionType.credit,
          timestamp: DateTime.now(),
          description:
              'Earned $creditsToGrant credits from watching ${AppConstants.adsNeededForReward} ads',
        ));
      }
    });
  }

  void _showAdNotReadyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ads Not Ready'),
        content: const Text(
            'We are having trouble loading an ad right now. Please try again in a few moments or subscribe for an ad-free experience.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subscription');
            },
            child: const Text('See Plans'),
          ),
        ],
      ),
    );
  }

  /// Specialized method for Dermatologist access: 3 ads per screen open if credits are low
  Future<bool> showTripleAdsForAccess(BuildContext context) async {
    final adsService = AdsService();
    int adsWatched = 0;

    for (int i = 0; i < AppConstants.adsNeededForReward; i++) {
      final completer = Completer<bool>();

      await adsService.showRewardedAd(
        onUserEarnedReward: (reward) {
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      final result = await completer.future;

      if (result) {
        await _incrementAdProgress();
        adsWatched++;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Ads watched: $adsWatched/${AppConstants.adsNeededForReward}')),
          );
        }
      } else {
        if (context.mounted) {
          _showAdNotReadyDialog(context);
        }
        return false;
      }
    }
    return adsWatched == AppConstants.adsNeededForReward;
  }

  Future<void> _checkAndResetDailyCredits(String userId) async {
    // We rely on the server timestamp stored in the doc vs current client time
    // If the day changed, we reset.
    // Ideally this is a Cloud Function, but we do client-side triggered reset + server write.

    final doc = await _firestore
        .collection(AppConstants.collectionSubscriptions)
        .doc(userId)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    // Use model for robust parsing (handles dates, nulls, plan check)
    final sub = UserSubscription.fromMap(data);

    if (sub.shouldResetDaily) {
      // It's a new day (or first run). Reset.
      // Fetch default credits based on tier & plan (monthly vs yearly)
      final defaultCredits =
          _getDefaultCreditsForTier(sub.tier, isYearly: sub.isYearly);

      await _firestore
          .collection(AppConstants.collectionSubscriptions)
          .doc(userId)
          .update({
        'dailyCreditsRemaining': defaultCredits,
        'adCreditsEarnedToday': 0.0,
        'totalActionsToday': 0,
        'lastResetDate': FieldValue.serverTimestamp(),
      });

      await logTransaction(TransactionModel(
        userId: userId,
        amount: defaultCredits,
        action: 'daily_reset',
        type: TransactionType.credit,
        timestamp: DateTime.now(),
        description: 'Daily credit reset ($defaultCredits credits)',
      ));

      debugPrint('Daily credits reset to $defaultCredits for tier ${sub.tier}');
    }
  }

  double _getDefaultCreditsForTier(String tier, {bool isYearly = false}) {
    // If user is Yearly, `SubscriptionService` set credits to 999990.
    // We should respect that "Max" capacity.
    if (isYearly) {
      return AppConstants.creditsYearly;
    }

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

  void _showInsufficientCreditsDialog(BuildContext context, ActionType action) {
    showDialog(
      context: context,
      builder: (ctx) => OutOfCreditsDialog(
        onWatchAd: () => showAdForCredits(context),
        onUpgrade: () => context.push('/subscription'),
      ),
    );
  }

  Future<void> logTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());
      debugPrint(
          'Logged ${transaction.type.name} transaction: ${transaction.description}');
    } catch (e) {
      debugPrint('Failed to log transaction: $e');
    }
  }
}
