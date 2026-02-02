import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/red_flag_alert_service.dart';
import '../../../data/models/red_flag_alert_model.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Red flag alerts screen
class RedFlagAlertsScreen extends ConsumerStatefulWidget {
  const RedFlagAlertsScreen({super.key});

  @override
  ConsumerState<RedFlagAlertsScreen> createState() =>
      _RedFlagAlertsScreenState();
}

class _RedFlagAlertsScreenState extends ConsumerState<RedFlagAlertsScreen> {
  final _alertService = RedFlagAlertService();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BackButtonHandler(
        fallbackRoute: '/home',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Health Alerts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showInfoDialog(context);
                },
              ),
            ],
          ),
          body: StreamBuilder<List<RedFlagAlert>>(
            stream: _alertService.getUserAlerts(user.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = snapshot.data ?? [];

              if (alerts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: ResponsiveConfig.padding(all: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: ResponsiveConfig.iconSize(80),
                          color: AppTheme.successGreen,
                        ),
                        ResponsiveConfig.heightBox(24),
                        Text(
                          'No Health Alerts',
                          style: ResponsiveConfig.textStyle(
                            size: 24,
                            weight: FontWeight.bold,
                          ),
                        ),
                        ResponsiveConfig.heightBox(8),
                        Text(
                          'Your health indicators look good!',
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            color: AppTheme.mediumGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: ResponsiveConfig.padding(all: 16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  return _buildAlertCard(context, alerts[index]);
                },
              );
            },
          ),
        ));
  }

  Widget _buildAlertCard(BuildContext context, RedFlagAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);
    final alertIcon = _getAlertIcon(alert.alertType);

    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      color: alert.severity == 'critical'
          ? AppTheme.errorRed.withOpacity(0.1)
          : null,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severityColor,
          child: Icon(alertIcon, color: Colors.white),
        ),
        title: Text(
          alert.title,
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveConfig.heightBox(4),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(alert.detectedAt),
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.mediumGray,
              ),
            ),
            if (alert.acknowledged)
              Container(
                margin: ResponsiveConfig.margin(top: 4),
                padding: ResponsiveConfig.padding(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: ResponsiveConfig.borderRadius(4),
                ),
                child: Text(
                  'ACKNOWLEDGED',
                  style: ResponsiveConfig.textStyle(
                    size: 10,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: ResponsiveConfig.padding(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: severityColor,
            borderRadius: ResponsiveConfig.borderRadius(4),
          ),
          child: Text(
            alert.severity.toUpperCase(),
            style: ResponsiveConfig.textStyle(
              size: 10,
              weight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        children: [
          Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.description,
                  style: ResponsiveConfig.textStyle(size: 14),
                ),
                ResponsiveConfig.heightBox(16),
                Text(
                  'Indicators:',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(8),
                ...alert.indicators.entries.map((entry) {
                  return Padding(
                    padding: ResponsiveConfig.padding(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppTheme.primaryPink,
                        ),
                        ResponsiveConfig.widthBox(8),
                        Expanded(
                          child: Text(
                            '${entry.key.replaceAll('_', ' ').toUpperCase()}: ${entry.value}',
                            style: ResponsiveConfig.textStyle(size: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ResponsiveConfig.heightBox(16),
                if (!alert.acknowledged)
                  ElevatedButton.icon(
                    onPressed: () => _acknowledgeAlert(context, alert),
                    icon: const Icon(Icons.check),
                    label: const Text('Acknowledge Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (alert.actionTaken != null) ...[
                  ResponsiveConfig.heightBox(8),
                  Text(
                    'Action Taken: ${alert.actionTaken}',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppTheme.errorRed;
      case 'high':
        return AppTheme.warningOrange;
      case 'medium':
        return Colors.orange;
      case 'low':
        return AppTheme.infoBlue;
      default:
        return AppTheme.mediumGray;
    }
  }

  IconData _getAlertIcon(String alertType) {
    switch (alertType) {
      case RedFlagAlertTypes.pcos:
        return Icons.warning;
      case RedFlagAlertTypes.anemia:
        return Icons.bloodtype;
      case RedFlagAlertTypes.infection:
        return Icons.medical_services;
      case RedFlagAlertTypes.severeSymptom:
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _acknowledgeAlert(
    BuildContext context,
    RedFlagAlert alert,
  ) async {
    final actionController = TextEditingController();
    final actionTaken = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Acknowledge Alert'),
        content: TextField(
          controller: actionController,
          decoration: const InputDecoration(
            labelText: 'Action Taken (Optional)',
            hintText: 'What did you do about this alert?',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(actionController.text),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );

    if (alert.id != null && actionTaken != null) {
      await _alertService.acknowledgeAlert(
        alert.id!,
        actionTaken: actionTaken.isEmpty ? null : actionTaken,
      );
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Health Alerts'),
        content: const Text(
          'Health alerts are automatically generated based on your tracked data. '
          'These alerts are for informational purposes only and should not replace '
          'professional medical advice. Always consult with a healthcare provider '
          'for medical concerns.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
