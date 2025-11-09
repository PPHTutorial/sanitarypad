import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../core/constants/app_constants.dart';
import '../core/firebase/firebase_service.dart';

/// IAP Product IDs
class IAPProductIds {
  static const String monthly = 'femcare_premium_monthly';
  static const String quarterly = 'femcare_premium_quarterly';
  static const String yearly = 'femcare_premium_yearly';

  static const List<String> all = [monthly, quarterly, yearly];
}

/// IAP Service for handling in-app purchases
class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  final StreamController<List<ProductDetails>> _productsController =
      StreamController<List<ProductDetails>>.broadcast();

  /// Initialize IAP service
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => _handleError(error),
    );

    // Load products
    await loadProducts();
  }

  /// Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final productDetailsResponse = await _iap.queryProductDetails(
        IAPProductIds.all.toSet(),
      );

      if (productDetailsResponse.error != null) {
        throw Exception(productDetailsResponse.error!.message);
      }

      _products = productDetailsResponse.productDetails;
      _productsController.add(_products);

      // Log analytics
      await FirebaseService.logEvent(
        name: 'iap_products_loaded',
        parameters: {'count': _products.length},
      );
    } catch (e) {
      await FirebaseService.recordError(e, null, reason: 'loadProducts');
      rethrow;
    }
  }

  /// Get products stream
  Stream<List<ProductDetails>> get productsStream => _productsController.stream;

  /// Get available products
  List<ProductDetails> get products => _products;

  /// Check if IAP is available
  bool get isAvailable => _isAvailable;

  /// Get product by ID
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Purchase a product
  Future<bool> purchaseProduct(ProductDetails productDetails) async {
    if (!_isAvailable) {
      throw Exception('In-app purchases are not available');
    }

    try {
      final purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      // Platform-specific purchase handling
      if (productDetails is GooglePlayProductDetails) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else if (productDetails is AppStoreProductDetails) {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }

      // Log analytics
      await FirebaseService.logEvent(
        name: 'iap_purchase_initiated',
        parameters: {
          'product_id': productDetails.id,
          'price': productDetails.price,
        },
      );

      return true;
    } catch (e) {
      await FirebaseService.recordError(e, null, reason: 'purchaseProduct');
      rethrow;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();

      // Log analytics
      await FirebaseService.logEvent(
        name: 'iap_restore_initiated',
      );
    } catch (e) {
      await FirebaseService.recordError(e, null, reason: 'restorePurchases');
      rethrow;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _handlePendingPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _handleSuccessfulPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        _handleFailedPurchase(purchaseDetails);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle pending purchase
  void _handlePendingPurchase(PurchaseDetails purchaseDetails) {
    // Show loading state
    // This will be handled by the UI
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      // Verify purchase with backend
      final verified = await _verifyPurchase(purchaseDetails);

      if (verified) {
        // Update subscription in Firestore
        await _updateSubscriptionFromPurchase(purchaseDetails);

        // Log analytics
        await FirebaseService.logEvent(
          name: 'iap_purchase_success',
          parameters: {
            'product_id': purchaseDetails.productID,
            'transaction_date': purchaseDetails.transactionDate ?? '',
          },
        );
      } else {
        // Purchase verification failed
        await FirebaseService.recordError(
          Exception('Purchase verification failed'),
          null,
          reason: 'verifyPurchase',
        );
      }
    } catch (e) {
      await FirebaseService.recordError(
        e,
        null,
        reason: 'handleSuccessfulPurchase',
      );
    }
  }

  /// Handle failed purchase
  void _handleFailedPurchase(PurchaseDetails purchaseDetails) {
    final error = purchaseDetails.error;
    if (error != null) {
      FirebaseService.recordError(
        Exception(error.message),
        null,
        reason: 'purchaseFailed',
      );
    }
  }

  /// Verify purchase with backend
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: Implement server-side verification
    // For now, we'll trust the platform verification
    // In production, you should verify with your backend

    // Extract purchase data
    final productId = purchaseDetails.productID;
    final purchaseId = purchaseDetails.purchaseID;

    // Basic validation
    if (productId.isEmpty || purchaseId == null) {
      return false;
    }

    // Platform-specific verification
    if (purchaseDetails is GooglePlayPurchaseDetails) {
      // Verify Android purchase
      return _verifyAndroidPurchase(purchaseDetails);
    } else if (purchaseDetails is AppStorePurchaseDetails) {
      // Verify iOS purchase
      return _verifyIOSPurchase(purchaseDetails);
    }

    return true;
  }

  /// Verify Android purchase
  bool _verifyAndroidPurchase(GooglePlayPurchaseDetails purchaseDetails) {
    // TODO: Implement Android purchase verification
    // You can use the verification data from purchaseDetails.verificationData
    return true;
  }

  /// Verify iOS purchase
  bool _verifyIOSPurchase(AppStorePurchaseDetails purchaseDetails) {
    // TODO: Implement iOS purchase verification
    // You can use the verification data from purchaseDetails.verificationData
    return true;
  }

  /// Update subscription from purchase
  Future<void> _updateSubscriptionFromPurchase(
    PurchaseDetails purchaseDetails,
  ) async {
    try {
      final productId = purchaseDetails.productID;
      final transactionDate = purchaseDetails.transactionDate;

      // Map product ID to subscription plan
      final plan = _getPlanFromProductId(productId);
      final startDate = transactionDate is String
          ? DateTime.tryParse(transactionDate) ?? DateTime.now()
          : (transactionDate as DateTime?) ?? DateTime.now();
      final endDate = _calculateEndDate(startDate, plan);

      // This will be handled by the subscription service
      // We'll emit an event that the subscription service can listen to
      // For now, we'll just log it
      await FirebaseService.logEvent(
        name: 'subscription_updated_from_iap',
        parameters: {
          'product_id': productId,
          'plan': plan,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
    } catch (e) {
      await FirebaseService.recordError(
        e,
        null,
        reason: 'updateSubscriptionFromPurchase',
      );
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

  /// Handle errors
  void _handleError(dynamic error) {
    FirebaseService.recordError(
      error,
      null,
      reason: 'iap_service_error',
    );
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _productsController.close();
  }
}
