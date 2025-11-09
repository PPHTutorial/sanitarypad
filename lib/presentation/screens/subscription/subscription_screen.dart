import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/subscription_service.dart';
import '../../../services/iap_service.dart';
import '../../../core/constants/app_constants.dart';

/// Subscription screen
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  final _iapService = IAPService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await _subscriptionService.initializeIAP();
      _iapService.productsStream.listen((products) {
        if (mounted) {
          setState(() {
            _products = products;
            _isLoading = false;
          });
        }
      });

      // Load initial products
      await _iapService.loadProducts();
      if (mounted) {
        setState(() {
          _products = _iapService.products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load subscription options: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final plans = _subscriptionService.getSubscriptionPlans();
    final features = _subscriptionService.getPremiumFeatures();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upgrade to Premium'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _products.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Upgrade to Premium'),
        ),
        body: Center(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: ResponsiveConfig.iconSize(64),
                  color: AppTheme.errorRed,
                ),
                ResponsiveConfig.heightBox(16),
                Text(
                  _errorMessage!,
                  style: ResponsiveConfig.textStyle(size: 16),
                  textAlign: TextAlign.center,
                ),
                ResponsiveConfig.heightBox(24),
                ElevatedButton(
                  onPressed: _initializeIAP,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore Purchases',
            onPressed: _restorePurchases,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Header
            _buildPremiumHeader(context),
            ResponsiveConfig.heightBox(24),

            // Features List
            _buildFeaturesList(context, features),
            ResponsiveConfig.heightBox(24),

            // Subscription Plans
            Text(
              'Choose Your Plan',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            ...plans.entries.map((entry) {
              // Find matching IAP product
              final productId = _getProductIdForPlan(entry.key);
              final product = _products.firstWhere(
                (p) => p.id == productId,
                orElse: () => _createDummyProduct(entry.key, entry.value),
              );

              return Padding(
                padding: ResponsiveConfig.padding(vertical: 8),
                child: _buildPlanCard(
                  context,
                  planId: entry.key,
                  planData: entry.value,
                  product: product,
                  isSelected: false,
                ),
              );
            }).toList(),

            ResponsiveConfig.heightBox(24),

            // Current Plan Status
            if (user?.subscription.isActive == true)
              Card(
                color: AppTheme.lightPink,
                child: Padding(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successGreen,
                          ),
                          ResponsiveConfig.widthBox(8),
                          Text(
                            'Premium Active',
                            style: ResponsiveConfig.textStyle(
                              size: 18,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ResponsiveConfig.heightBox(8),
                      Text(
                        'Your subscription is active until ${user?.subscription.endDate?.toString().split(' ')[0] ?? 'N/A'}',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ResponsiveConfig.heightBox(16),

            // Terms & Privacy
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy.',
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: ResponsiveConfig.padding(all: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryPink, AppTheme.deepPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: ResponsiveConfig.borderRadius(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star,
            size: ResponsiveConfig.iconSize(48),
            color: Colors.white,
          ),
          ResponsiveConfig.heightBox(16),
          Text(
            'FemCare+ Premium',
            style: ResponsiveConfig.textStyle(
              size: 28,
              weight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          ResponsiveConfig.heightBox(8),
          Text(
            'Unlock all features and take control of your wellness journey',
            style: ResponsiveConfig.textStyle(
              size: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context, List<String> features) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Premium Features',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            ...features.map((feature) {
              return Padding(
                padding: ResponsiveConfig.padding(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                      size: ResponsiveConfig.iconSize(20),
                    ),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: Text(
                        feature,
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _getProductIdForPlan(String planId) {
    switch (planId) {
      case AppConstants.planMonthly:
        return IAPProductIds.monthly;
      case AppConstants.planQuarterly:
        return IAPProductIds.quarterly;
      case AppConstants.planYearly:
        return IAPProductIds.yearly;
      default:
        return IAPProductIds.monthly;
    }
  }

  ProductDetails _createDummyProduct(
    String planId,
    Map<String, dynamic> planData,
  ) {
    // Create a dummy product for display when IAP product is not available
    return ProductDetails(
      id: _getProductIdForPlan(planId),
      title: planData['name'] as String,
      description: '',
      price: '\$${planData['price']}',
      rawPrice: (planData['price'] as num).toDouble(),
      currencyCode: 'USD',
    );
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() => _isLoading = true);
      await _iapService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchases restored successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore purchases: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String planId,
    required Map<String, dynamic> planData,
    required ProductDetails product,
    required bool isSelected,
  }) {
    final hasDiscount = planData['discount'] != null;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.lightPink : null,
      child: InkWell(
        onTap: _isPurchasing
            ? null
            : () {
                _handlePlanSelection(context, planId, planData, product);
              },
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planData['name'],
                        style: ResponsiveConfig.textStyle(
                          size: 20,
                          weight: FontWeight.bold,
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          margin: ResponsiveConfig.margin(top: 4),
                          padding: ResponsiveConfig.padding(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: ResponsiveConfig.borderRadius(4),
                          ),
                          child: Text(
                            'Save ${planData['discount']}%',
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              weight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '\$${planData['price']}',
                    style: ResponsiveConfig.textStyle(
                      size: 24,
                      weight: FontWeight.bold,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                'per ${planData['duration']} ${planData['duration'] == 1 ? 'month' : 'months'}',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlanSelection(
    BuildContext context,
    String planId,
    Map<String, dynamic> planData,
    ProductDetails product,
  ) async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to subscribe')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${planData['name']}'),
            ResponsiveConfig.heightBox(8),
            Text('Price: ${product.price}'),
            ResponsiveConfig.heightBox(8),
            Text(
              'Your subscription will be managed through ${_getPlatformName()} and will auto-renew unless cancelled.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isPurchasing = true);

      // Initiate purchase
      final success = await _iapService.purchaseProduct(product);

      if (success) {
        // Purchase flow initiated - the IAP service will handle the rest
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing purchase...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  String _getPlatformName() {
    // This would be determined at runtime
    return 'App Store / Google Play';
  }
}
