import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../services/auth_service.dart';

class CycleSettingsScreen extends ConsumerStatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  ConsumerState<CycleSettingsScreen> createState() =>
      _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends ConsumerState<CycleSettingsScreen> {
  int _cycleLength = 28;
  int _periodLength = 5;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserStreamProvider).value;
    if (user != null) {
      _cycleLength = user.settings.cycleLength;
      _periodLength = user.settings.periodLength;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserStreamProvider).value;
      if (user == null) return;

      final updatedSettings = user.settings.copyWith(
        cycleLength: _cycleLength,
        periodLength: _periodLength,
      );

      final updatedUser = user.copyWith(settings: updatedSettings);

      final authService = ref.read(authServiceProvider);
      await authService.updateUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cycle settings saved')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cycle Settings'),
        actions: [
          if (_isLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            ResponsiveConfig.heightBox(24),
            _buildSectionTitle('Standard Cycle Intervals'),
            ResponsiveConfig.heightBox(16),
            _buildLengthSelector(
              title: 'Average Cycle Length',
              subtitle: 'Usually between 21-35 days',
              value: _cycleLength,
              min: 15,
              max: 45,
              onChanged: (val) => setState(() => _cycleLength = val),
            ),
            ResponsiveConfig.heightBox(16),
            _buildLengthSelector(
              title: 'Average Period Length',
              subtitle: 'Usually between 3-7 days',
              value: _periodLength,
              min: 1,
              max: 15,
              onChanged: (val) => setState(() => _periodLength = val),
            ),
            ResponsiveConfig.heightBox(32),
            _buildSectionTitle('Reminders & Alerts'),
            ResponsiveConfig.heightBox(16),
            _buildToggleTile(
              title: 'Period Prediction',
              subtitle: 'Get notified 2 days before your period starts',
              icon: FontAwesomeIcons.bell,
              value: true, // TODO: Link to settings
              onChanged: (val) {},
            ),
            _buildToggleTile(
              title: 'Ovulation Prediction',
              subtitle: 'Get notified during your fertile window',
              icon: FontAwesomeIcons.heartPulse,
              value: true,
              onChanged: (val) {},
            ),
            _buildToggleTile(
              title: 'Daily Log Prompt',
              subtitle: 'Gentle reminder to log your symptoms',
              icon: FontAwesomeIcons.penToSquare,
              value: false,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: ResponsiveConfig.padding(all: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.circleInfo,
              color: AppTheme.primaryPink),
          ResponsiveConfig.widthBox(16),
          const Expanded(
            child: Text(
              'These values are used to calculate your predictions. The more you log, the more accurate they become!',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: ResponsiveConfig.textStyle(
        size: 18,
        weight: FontWeight.bold,
        color: AppTheme.primaryPink,
      ),
    );
  }

  Widget _buildLengthSelector({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle,
                        style: TextStyle(
                            color: AppTheme.mediumGray, fontSize: 12)),
                  ],
                ),
                Text(
                  '$value days',
                  style: const TextStyle(
                    color: AppTheme.primaryPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              activeColor: AppTheme.primaryPink,
              inactiveColor: AppTheme.lightPink,
              onChanged: (val) => onChanged(val.round()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: FaIcon(icon, color: AppTheme.primaryPink, size: 20),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryPink,
      ),
    );
  }
}
