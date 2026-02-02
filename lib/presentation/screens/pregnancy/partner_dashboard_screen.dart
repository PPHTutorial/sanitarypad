import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/responsive_config.dart';
import '../../../services/pregnancy_service.dart';
import '../../../data/models/pregnancy_model.dart';
import 'pregnancy_tracking_screen.dart';

class PartnerDashboardScreen extends ConsumerWidget {
  const PartnerDashboardScreen({super.key, required this.pregnancyId});

  final String pregnancyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyService = PregnancyService();

    return Scaffold(
      body: FutureBuilder<Pregnancy?>(
        future: pregnancyService.getPregnancyById(pregnancyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState(context);
          }

          final pregnancy = snapshot.data!;
          final userId = pregnancy.userId;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryPink, AppTheme.lightPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.white, size: 48),
                          ResponsiveConfig.heightBox(8),
                          Text(
                            "Our Pregnancy Journey",
                            style: ResponsiveConfig.textStyle(
                              size: 24,
                              weight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Week ${pregnancy.currentWeek}, Day ${pregnancy.currentDay}",
                            style: ResponsiveConfig.textStyle(
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/home'),
                ),
              ),
              SliverPadding(
                padding: ResponsiveConfig.padding(all: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPartnerGreeting(pregnancy),
                    ResponsiveConfig.heightBox(16),
                    OverviewTab(
                      pregnancy: pregnancy,
                      kickStream:
                          pregnancyService.getKickEntries(userId, pregnancyId),
                      appointmentStream:
                          pregnancyService.getAppointments(userId, pregnancyId),
                      medicationStream:
                          pregnancyService.getMedications(userId, pregnancyId),
                      onScheduleKickReminder: null,
                      onAddAppointment: null,
                      onAddMedication: null,
                      isReadOnly: true,
                    ),
                    ResponsiveConfig.heightBox(16),
                    _buildSupportTipsCard(),
                    ResponsiveConfig.heightBox(24),
                    _buildAppDownloadCTA(context),
                    ResponsiveConfig.heightBox(32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPartnerGreeting(Pregnancy pregnancy) {
    return Card(
      color: AppTheme.lightPink.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.lightPink.withOpacity(0.3)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, Partner! 👋",
              style:
                  ResponsiveConfig.textStyle(size: 18, weight: FontWeight.bold),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              "You're viewing the live dashboard. Follow along with kicks, appointments, and reminders to stay connected throughout this journey.",
              style: ResponsiveConfig.textStyle(
                  size: 14, color: AppTheme.mediumGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTipsCard() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Partner Support Tips",
              style:
                  ResponsiveConfig.textStyle(size: 18, weight: FontWeight.bold),
            ),
            ResponsiveConfig.heightBox(12),
            _tipItem(Icons.volunteer_activism_outlined,
                "Offer a gentle massage or help with daily chores."),
            _tipItem(Icons.restaurant_outlined,
                "Keep healthy snacks and water nearby."),
            _tipItem(Icons.event_outlined,
                "Sync these appointments to your own calendar."),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryPink),
          ResponsiveConfig.widthBox(12),
          Expanded(
              child: Text(text, style: ResponsiveConfig.textStyle(size: 14))),
        ],
      ),
    );
  }

  Widget _buildAppDownloadCTA(BuildContext context) {
    return Container(
      padding: ResponsiveConfig.padding(all: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "Want to track your own journey?",
            style: ResponsiveConfig.textStyle(
              size: 16,
              weight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          ResponsiveConfig.heightBox(8),
          Text(
            "Download FemCare+ to get personalized insights, habit tracking, and more.",
            style: ResponsiveConfig.textStyle(
              size: 13,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          ResponsiveConfig.heightBox(16),
          ElevatedButton(
            onPressed: () {
              final platform = Theme.of(context).platform;
              final url = platform == TargetPlatform.iOS
                  ? AppConstants.appStoreUrl
                  : AppConstants.playStoreUrl;
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: const Text("Get the App"),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.mediumGray),
            ResponsiveConfig.heightBox(16),
            const Text(
              'Dashboard Not Found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ResponsiveConfig.heightBox(8),
            const Text(
              'The link might be expired or invalid. Please ask your partner to share it again.',
              textAlign: TextAlign.center,
            ),
            ResponsiveConfig.heightBox(24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    );
  }
}
