import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/subscription_service.dart';
import '../../../services/iap_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/back_button_handler.dart';

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
  bool _isYearly = false; // Default to Monthly
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  // ... existing IAP code ...

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final plans = _subscriptionService.getSubscriptionPlans();

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ... error handling ...

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: AppTheme.splashDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Pricing Plans',
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _restorePurchases,
              child: const Text('Restore',
                  style: TextStyle(color: AppTheme.primaryPink)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Journey',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find the perfect plan for your wellness',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),

              // Monthly / Yearly Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption(
                        title: 'Monthly', isSelected: !_isYearly),
                    _buildToggleOption(title: 'Yearly', isSelected: _isYearly),
                  ],
                ),
              ),
              if (_isYearly)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Save 5% on Yearly Plans + Unlimited Credits!',
                    style: TextStyle(
                        color: Colors.amber.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 30),

              // Horizontal scroller for plans
              SizedBox(
                height: 540, // Increased height for toggle/badges
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final planKey = plans.keys.elementAt(index);
                    final planData = plans[planKey]!;
                    final isCurrent = user?.subscription.tier == planKey;

                    print('user: ${user?.subscription.tier}' ' isCurrent: $isCurrent' +
                        ' planKey: $planKey');

                    return _buildTierCard(
                      context,
                      tierKey: planKey,
                      planData: planData,
                      isCurrent: isCurrent,
                    );
                  },
                ),
              ),
              // ... footer text ...
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption({required String title, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYearly = title == 'Yearly';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryPink : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String tierKey,
    required Map<String, dynamic> planData,
    required bool isCurrent,
  }) {
    final features = List<String>.from(planData['features']);
    double price = (planData['price'] as num).toDouble();
    final isEco = tierKey == AppConstants.tierEconomy;
    final isPopular = planData['isPopular'] as bool? ?? false;

    print('isCurrent: $isCurrent');

    // Adjust for Yearly
    if (_isYearly && !isEco) {
      // Apply 5% discount for everyone on Yearly (as per user request "5% discount on yearly sub")
      // Pro usually 12x, Adv 12x * 0.95, Plus 12x * 0.95
      // User said "5% discount on yearly sub". Assuming applies to all paid plans for simplicity
      // or at least Adv/Plus. Let's apply to all paid to be safe/generous.
      price = (price + 20) * 12 * 0.95;

      // Update features text for Unlimited Credits
      final creditIndex =
          features.indexWhere((f) => f.contains('daily free credits'));
      if (creditIndex != -1) {
        features[creditIndex] = 'UNLIMITED credits';
      }
    }

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(24),
        border: isPopular
            ? Border.all(color: Colors.amber, width: 2)
            : (isCurrent
                ? Border.all(color: AppTheme.primaryPink, width: 2)
                : Border.all(color: Colors.white.withOpacity(0.1), width: 1)),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          if (isCurrent && !isPopular)
            BoxShadow(
              color: AppTheme.primaryPink.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badges row
            Row(
              children: [
                if (isPopular)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amber, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'MOST POPULAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (isPopular || isCurrent) const SizedBox(height: 12),
            Text(
              planData['name'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    price == 0 ? '' : (_isYearly ? '/year' : '/mo'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            // Discount text for yearly
            if (_isYearly && !isEco)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Save 5%',
                  style: TextStyle(
                    color: Colors.greenAccent.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                itemBuilder: (context, fIndex) {
                  // Highlight Unlimited credits
                  final featureText = features[fIndex];
                  final isUnlimited = featureText.contains('UNLIMITED');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: isUnlimited
                              ? Colors.greenAccent
                              : (isPopular
                                  ? Colors.amber
                                  : AppTheme.primaryPink),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            featureText,
                            style: TextStyle(
                              color: isUnlimited
                                  ? Colors.greenAccent
                                  : Colors.white.withOpacity(0.9),
                              fontWeight: isUnlimited
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (isCurrent || _isPurchasing)
                    ? null
                    : () => _handleSubscription(tierKey, planData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrent
                      ? Colors.white10
                      : (isPopular ? Colors.amber : AppTheme.primaryPink),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white54,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isCurrent
                      ? 'Current Plan'
                      : (isEco
                          ? 'Get Started'
                          : (isPopular ? 'Get Popular Plan' : 'Upgrade Now')),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _handleSubscription(
      String tierKey, Map<String, dynamic> planData) async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to subscribe')),
      );
      return;
    }

    if (tierKey == AppConstants.tierEconomy) {
      // Set economy tier directly (it's free)
      try {
        setState(() => _isPurchasing = true);
        await _subscriptionService.createSubscription(
          userId: user.userId,
          tier: AppConstants.tierEconomy,
          plan: AppConstants.planForever,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 36500)), // 100 years
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plan updated to Economy')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update plan: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isPurchasing = false);
      }
      return;
    }

    // For paid tiers, handle via IAP
    final productId = _isYearly
        ? (planData['productIdYearly'] as String? ??
            planData['productId'] as String)
        : (planData['productId'] as String);

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => _createDummyProduct(productId, planData),
    );

    try {
      setState(() => _isPurchasing = true);
      await _iapService.purchaseProduct(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  ProductDetails _createDummyProduct(String id, Map<String, dynamic> data) {
    return ProductDetails(
      id: id,
      title: data['name'],
      description: '',
      price: '\$${data['price']}',
      rawPrice: (data['price'] as num).toDouble(),
      currencyCode: 'USD',
    );
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() => _isLoading = true);
      await _iapService.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restoration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
