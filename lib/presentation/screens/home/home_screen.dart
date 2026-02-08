import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';
import '../../../services/ads_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/subscription_provider.dart';

/// Home screen - Blank dashboard for users to add their data
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Proactive check for daily credits reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(subscriptionServiceProvider).checkDailyReset(user.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCycle = ref.watch(activeCycleProvider);

    return Scaffold(
      extendBodyBehindAppBar: false, // Keep AppBar on top but transparent
      backgroundColor: Colors.transparent, // Use theme background
      appBar: AppBar(
        leading: Row(
          children: [
            ResponsiveConfig.widthBox(16),
            Image.asset('assets/images/logo.png',
                height: ResponsiveConfig.height(30)),
          ],
        ),
        leadingWidth: ResponsiveConfig.width(48),
        title: Text(
          'FemCare+',
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(24),
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryPink,
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.bell),
            onPressed: () {
              context.go('/red-flag-alerts');
            },
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.gear),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            //_buildWelcomeCard(context),
            //ResponsiveConfig.heightBox(16),

            // Cycle Status Card (only if cycle exists)
            if (activeCycle != null) ...[
              _buildCycleStatusCard(context, ref, activeCycle),
              ResponsiveConfig.heightBox(16),
            ],

            // Quick Actions
            _buildQuickActions(context, ref),
            ResponsiveConfig.heightBox(16),

            // Get Started Section (if no data)
            if (activeCycle == null) _buildGetStartedSection(context),
          ],
        ),
      ),
      bottomNavigationBar: const FemCareBottomNav(currentRoute: '/home'),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to FemCare+',
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
                color: AppTheme.primaryPink,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Start tracking your health and wellness journey today.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleStatusCard(
    BuildContext context,
    WidgetRef ref,
    cycle,
  ) {
    final now = DateTime.now();
    final cycleDay = cycle.getCycleDay(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Cycle',
          style: ResponsiveConfig.textStyle(
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        ResponsiveConfig.heightBox(12),
        Card(
          shadowColor: Colors.black.withValues(alpha: 0.08),
          margin: const EdgeInsets.only(bottom: 0),
          child: Padding(
            padding: ResponsiveConfig.padding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Most Recent Cycle',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.penToSquare),
                      onPressed: () {
                        // Navigate to edit current cycle
                        context.push('/log-period', extra: cycle);
                      },
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.calendar,
                      color: AppTheme.primaryPink,
                      size: ResponsiveConfig.iconSize(24),
                    ),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day $cycleDay of Cycle',
                            style: ResponsiveConfig.textStyle(
                              size: 16,
                              weight: FontWeight.w600,
                            ),
                          ),
                          ResponsiveConfig.heightBox(4),
                          Text(
                            'Started ${_formatDate(cycle.startDate)}',
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final cyclesAsync = ref.watch(cyclesStreamProvider);
                        final cycles = cyclesAsync.value ?? [];
                        if (cycles.length > 1) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => context.push('/cycles-list'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View All',
                                    style: ResponsiveConfig.textStyle(
                                      size: 14,
                                      color: AppTheme.primaryPink,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppTheme.primaryPink,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: ResponsiveConfig.textStyle(
            size: 18,
            weight: FontWeight.w600,
          ),
        ),
        ResponsiveConfig.heightBox(12),
        // First Row: Period & Pad
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.personPregnant,
                label: 'Pregnancy',
                onTap: () {
                  AdsService().showInterstitialAd();
                  context.go('/pregnancy-tracking');
                },
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.egg,
                label: 'Fertility',
                onTap: () => context.go('/fertility-tracking'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Second Row: Wellness & Calendar
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.faceGrinBeamSweat,
                label: 'Skincare',
                onTap: () => context.go('/skincare-tracking'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.heartCirclePlus,
                label: 'Wellness',
                onTap: () => context.go('/wellness-journal-list'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Third Row: Movies & Entertainment
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.film,
                label: 'Movies & Entertainment',
                onTap: () => context.push('/movies'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Fourth Row: Nutrition & Workout
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.appleWhole,
                label: 'Nutrition',
                onTap: () => context.go('/nutrition-tracking'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.dumbbell,
                label: 'Workout',
                onTap: () => context.go('/workout-tracking'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Fifth Row: Pregnancy & Fertility
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.droplet,
                label: 'Log Period',
                onTap: () => context.go('/log-period'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: FontAwesomeIcons.toiletPaper,
                label: 'Pad Change',
                onTap: () => context.go('/pad-management'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Sixth Row: Community
        const _CommunityCard(),
        ResponsiveConfig.heightBox(16),
        const Center(child: BannerAdWidget()),
      ],
    );
  }

  Widget _buildGetStartedSection(BuildContext context) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.rocket,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(28),
                ),
                ResponsiveConfig.widthBox(12),
                Text(
                  'Get Started',
                  style: ResponsiveConfig.textStyle(
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              'Start tracking your menstrual cycle to unlock personalized insights and predictions.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            ElevatedButton.icon(
              onPressed: () => context.go('/log-period'),
              icon: const FaIcon(FontAwesomeIcons.plus),
              label: const Text('Log Your First Period'),
              style: ElevatedButton.styleFrom(
                padding: ResponsiveConfig.padding(vertical: 16, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ResponsiveConfig.borderRadius(12),
      child: Container(
        padding: ResponsiveConfig.padding(all: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : AppTheme.palePink,
          borderRadius: ResponsiveConfig.borderRadius(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkGray
                : AppTheme.lightPink,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            FaIcon(
              icon,
              color: AppTheme.primaryPink,
              size: ResponsiveConfig.iconSize(32),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              label,
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
                color: AppTheme.primaryPink,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: ResponsiveConfig.margin(all: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community & Support Forum',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Share progress, ask dermatologists, join climate-based skincare groups, Pregnancy women and mothers and more...',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/groups', extra: "all"),
                  icon: const FaIcon(FontAwesomeIcons.users),
                  label: const Text('Join forum'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/events', extra: 'all'),
                  icon: const FaIcon(FontAwesomeIcons.calendarCheck),
                  label: const Text('Upcoming events'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
