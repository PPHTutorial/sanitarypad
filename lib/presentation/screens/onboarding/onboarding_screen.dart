import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';

/// Onboarding screen with multiple pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to FemCare+',
      description:
          'Your trusted companion for menstrual health, cycle tracking, and wellness.',
      icon: Icons.favorite,
      color: AppTheme.primaryPink,
    ),
    OnboardingPage(
      title: 'Track Your Cycle',
      description:
          'Log your periods, track symptoms, and get accurate cycle predictions.',
      icon: Icons.calendar_today,
      color: AppTheme.deepPink,
    ),
    OnboardingPage(
      title: 'Manage Your Wellness',
      description:
          'Monitor your health, track pad usage, and access wellness content.',
      icon: Icons.health_and_safety,
      color: AppTheme.lavender,
    ),
    OnboardingPage(
      title: 'Privacy First',
      description:
          'Your data is encrypted and secure. Take control of your privacy.',
      icon: Icons.lock,
      color: AppTheme.primaryPink,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save the onboarding completion flag
      await prefs.setBool(AppConstants.prefsKeyOnboardingComplete, true);

      // Clear the router cache to force a fresh check
      AppRouter.clearOnboardingCache();

      // Verify it was saved correctly
      final saved = prefs.getBool(AppConstants.prefsKeyOnboardingComplete);
      if (saved == true) {
        // Small delay to ensure SharedPreferences is fully committed
        await Future.delayed(const Duration(milliseconds: 200));

        if (mounted) {
          // Navigate to login - router will verify onboarding is complete
          context.go('/login');
        }
      } else {
        // Retry if verification failed
        await prefs.setBool(AppConstants.prefsKeyOnboardingComplete, true);
        AppRouter.clearOnboardingCache();
        await Future.delayed(const Duration(milliseconds: 200));

        if (mounted) {
          context.go('/login');
        }
      }
    } catch (e) {
      // If there's an error, still try to navigate (user shouldn't be stuck)
      AppRouter.clearOnboardingCache();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildPageIndicator(index == _currentPage),
              ),
            ),

            ResponsiveConfig.heightBox(32),

            // Next/Get Started button
            Padding(
              padding: ResponsiveConfig.padding(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: ResponsiveConfig.padding(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: ResponsiveConfig.borderRadius(12),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: ResponsiveConfig.textStyle(
                      size: 16,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            ResponsiveConfig.heightBox(32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: ResponsiveConfig.padding(all: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveConfig.screenWidth * 0.6,
            height: ResponsiveConfig.screenWidth * 0.6,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: ResponsiveConfig.iconSize(80),
              color: page.color,
            ),
          ),
          ResponsiveConfig.heightBox(48),
          Text(
            page.title,
            style: ResponsiveConfig.textStyle(
              size: 28,
              weight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          ResponsiveConfig.heightBox(16),
          Text(
            page.description,
            style: ResponsiveConfig.textStyle(
              size: 16,
              color: AppTheme.mediumGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: ResponsiveConfig.margin(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryPink : AppTheme.palePink,
        borderRadius: ResponsiveConfig.borderRadius(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
