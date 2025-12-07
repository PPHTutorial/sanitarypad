import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Subscription manager for tracking Pro status
class SubscriptionManager {
  static SubscriptionManager? _instance;
  SharedPreferences? _prefs;
  
  bool _isProUser = false;
  String? _activeProductId;
  DateTime? _subscriptionExpiry;
  
  SubscriptionManager._();
  
  static SubscriptionManager get instance {
    _instance ??= SubscriptionManager._();
    return _instance!;
  }
  
  /// Initialize subscription manager
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // Pro version - always set as pro user
      await _setProStatus(true);
      _activeProductId = AppConstants.iapLifetime; // Set as lifetime pro
      AppLogger.i('Subscription manager initialized - Pro: $_isProUser (Pro Version - Always Enabled)');
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing subscription manager', e, stackTrace);
    }
  }
  
  
  /// Update subscription status
  Future<void> updateSubscriptionStatus({
    required String productId,
    required bool isActive,
  }) async {
    try {
      await _setProStatus(isActive);
      
      if (isActive) {
        _activeProductId = productId;
        await _prefs?.setString('active_product_id', productId);
        
        // Set expiry based on product type
        if (productId == AppConstants.iapMonthly) {
          _subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
        } else if (productId == AppConstants.iapYearly) {
          _subscriptionExpiry = DateTime.now().add(const Duration(days: 365));
        } else if (productId == AppConstants.iapLifetime) {
          // Lifetime subscription - set expiry to far future
          _subscriptionExpiry = DateTime.now().add(const Duration(days: 36500)); // 100 years
        }
        
        if (_subscriptionExpiry != null) {
          await _prefs?.setInt(
            'subscription_expiry',
            _subscriptionExpiry!.millisecondsSinceEpoch,
          );
        }
        
        AppLogger.i('Subscription activated: $productId');
      } else {
        _activeProductId = null;
        _subscriptionExpiry = null;
        await _prefs?.remove('active_product_id');
        await _prefs?.remove('subscription_expiry');
        AppLogger.i('Subscription deactivated');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error updating subscription status', e, stackTrace);
    }
  }
  
  /// Set Pro status
  Future<void> _setProStatus(bool isPro) async {
    _isProUser = isPro;
    await _prefs?.setBool(AppConstants.keyProStatus, isPro);
  }
  
  /// Check if user is Pro (always true for pro version)
  bool get isProUser => true; // Always pro in pro version
  
  /// Get active product ID
  String? get activeProductId => _activeProductId;
  
  /// Get subscription expiry
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  
  /// Check if subscription is active
  bool get isSubscriptionActive {
    if (!_isProUser) return false;
    
    if (_subscriptionExpiry == null) return true; // Lifetime
    
    return DateTime.now().isBefore(_subscriptionExpiry!);
  }
  
  /// Get days until expiry
  int? get daysUntilExpiry {
    if (_subscriptionExpiry == null) return null;
    
    final difference = _subscriptionExpiry!.difference(DateTime.now());
    return difference.inDays;
  }
  
  /// Get subscription type display name
  String get subscriptionType {
    // Pro version - always lifetime
    return 'Pro Lifetime';
  }
}

