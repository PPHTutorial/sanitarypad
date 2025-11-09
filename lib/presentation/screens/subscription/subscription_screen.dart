import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/subscription_service.dart';

/// Subscription screen
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final subscriptionService = SubscriptionService();
    final plans = subscriptionService.getSubscriptionPlans();
    final features = subscriptionService.getPremiumFeatures();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
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
              return Padding(
                padding: ResponsiveConfig.padding(vertical: 8),
                child: _buildPlanCard(
                  context,
                  planId: entry.key,
                  planData: entry.value,
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

  Widget _buildPlanCard(
    BuildContext context, {
    required String planId,
    required Map<String, dynamic> planData,
    required bool isSelected,
  }) {
    final hasDiscount = planData['discount'] != null;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.lightPink : null,
      child: InkWell(
        onTap: () {
          _handlePlanSelection(context, planId, planData);
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

  void _handlePlanSelection(
    BuildContext context,
    String planId,
    Map<String, dynamic> planData,
  ) {
    // TODO: Implement payment processing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe to Premium'),
        content: Text(
          'You selected ${planData['name']} plan for \$${planData['price']}.\n\n'
          'Payment processing will be implemented with your payment provider.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment integration coming soon'),
                ),
              );
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}
