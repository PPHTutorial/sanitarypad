import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../app/themes/app_colors.dart';
import '../../../app/themes/app_text_styles.dart';
import '../../../app/themes/app_dimensions.dart';
import '../../../core/constants/app_constants.dart';
/// Pro upgrade screen
class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  int _selectedPlanIndex = 1; // Default to yearly (best value)

  final List<Map<String, dynamic>> _plans = [
    {
      'id': AppConstants.iapMonthly,
      'name': 'Monthly',
      'price': '\$10.99',
      'period': '/month',
      'badge': null,
    },
    {
      'id': AppConstants.iapYearly,
      'name': 'Yearly',
      'price': '\$99.99',
      'period': '/year',
      'subtext': '\$8.33/month',
      'badge': 'SAVE 33%',
      'badgeColor': AppColors.success,
    },
    {
      'id': AppConstants.iapLifetime,
      'name': 'Lifetime',
      'price': '\$254.99',
      'period': 'one-time',
      'badge': 'BEST VALUE',
      'badgeColor': AppColors.goldColor,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'Go Pro',
          style: AppTextStyles.headline4,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppDimensions.space24),
                children: [
                  // Pro icon
                  Center(
                    child: Container(
                      width: AppDimensions.proIconSize,
                      height: AppDimensions.proIconSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.proGradientStart,
                            AppColors.proGradientEnd,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        size: 40.w,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: AppDimensions.space24),

                  // Title
                  Text(
                    'Unlock Premium Features',
                    style: AppTextStyles.headline3,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: AppDimensions.space32),

                  // Pricing plans
                  ..._buildPricingPlans(),

                  SizedBox(height: AppDimensions.space32),

                  // Benefits list
                  ..._buildBenefits(),
                ],
              ),
            ),

            // Bottom action area
            Container(
              padding: EdgeInsets.all(AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusLarge),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subscribe button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: AppDimensions.space16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMedium,
                          ),
                        ),
                      ),
                      child: Text(
                        'Subscribe Now',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),

                  SizedBox(height: AppDimensions.space12),

                  // Restore purchases
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Restore Purchases',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentColor,
                      ),
                    ),
                  ),

                  // Terms & Privacy
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefits() {
    final benefits = [
      {'icon': Icons.check_circle, 'text': 'No Watermarks'},
      {'icon': Icons.check_circle, 'text': 'Original Quality Images'},
      {'icon': Icons.check_circle, 'text': 'Ad-Free Experience'},
      {'icon': Icons.check_circle, 'text': 'Unlimited Downloads'},
      {'icon': Icons.check_circle, 'text': 'Exclusive Collections'},
      {'icon': Icons.check_circle, 'text': 'Priority Support'},
    ];

    return benefits.map((benefit) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppDimensions.space12),
        child: Row(
          children: [
            Icon(
              benefit['icon'] as IconData,
              color: AppColors.success,
              size: AppDimensions.proBenefitIconSize,
            ),
            SizedBox(width: AppDimensions.space12),
            Text(
              benefit['text'] as String,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildPricingPlans() {
    return _plans.asMap().entries.map((entry) {
      final index = entry.key;
      final plan = entry.value;
      final isSelected = _selectedPlanIndex == index;

      return GestureDetector(
        onTap: () => setState(() => _selectedPlanIndex = index),
        child: Container(
          margin: EdgeInsets.only(bottom: AppDimensions.space12),
          padding: EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkCard : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.accentColor : AppColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            children: [
              // Radio button
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? AppColors.accentColor : AppColors.textDisabled,
              ),

              SizedBox(width: AppDimensions.space12),

              // Plan info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'],
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (plan['subtext'] != null)
                      Text(
                        plan['subtext'],
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan['price'],
                    style: AppTextStyles.priceMain.copyWith(
                      fontSize: 20.sp,
                    ),
                  ),
                  Text(
                    plan['period'],
                    style: AppTextStyles.caption,
                  ),
                ],
              ),

              // Badge
              if (plan['badge'] != null) ...[
                SizedBox(width: AppDimensions.space8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.space8,
                    vertical: AppDimensions.space4,
                  ),
                  decoration: BoxDecoration(
                    color: plan['badgeColor'],
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Text(
                    plan['badge'],
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  }
