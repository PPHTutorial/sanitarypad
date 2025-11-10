import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../services/fertility_service.dart';
import '../../../data/models/fertility_model.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Fertility tracking screen
class FertilityTrackingScreen extends ConsumerStatefulWidget {
  const FertilityTrackingScreen({super.key});

  @override
  ConsumerState<FertilityTrackingScreen> createState() =>
      _FertilityTrackingScreenState();
}

class _FertilityTrackingScreenState
    extends ConsumerState<FertilityTrackingScreen> {
  final _fertilityService = FertilityService();
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  final DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final cyclesAsync = ref.watch(cyclesStreamProvider);
    final cycles = cyclesAsync.value ?? [];

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fertility Tracking'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddEntryDialog(context, user.userId);
              },
            ),
          ],
        ),
        body: StreamBuilder<List<FertilityEntry>>(
          stream: _fertilityService.getFertilityEntries(
            user.userId,
            _startDate,
            _endDate,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = snapshot.data ?? [];

            return FutureBuilder<FertilityPrediction>(
              future: _fertilityService.predictOvulation(
                user.userId,
                cycles,
                entries,
              ),
              builder: (context, predictionSnapshot) {
                final prediction = predictionSnapshot.data;

                return SingleChildScrollView(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fertility Window Card
                      if (prediction != null)
                        _buildFertilityWindowCard(prediction),
                      ResponsiveConfig.heightBox(16),

                      // Today's Entry
                      _buildTodaysEntryCard(context, user.userId, entries),
                      ResponsiveConfig.heightBox(16),

                      // Recent Entries
                      Text(
                        'Recent Entries',
                        style: ResponsiveConfig.textStyle(
                          size: 20,
                          weight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveConfig.heightBox(12),
                      if (entries.isEmpty)
                        Card(
                          child: Padding(
                            padding: ResponsiveConfig.padding(all: 24),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.thermostat,
                                    size: ResponsiveConfig.iconSize(48),
                                    color: AppTheme.mediumGray,
                                  ),
                                  ResponsiveConfig.heightBox(16),
                                  Text(
                                    'No fertility entries yet',
                                    style: ResponsiveConfig.textStyle(
                                      size: 16,
                                      color: AppTheme.mediumGray,
                                    ),
                                  ),
                                  ResponsiveConfig.heightBox(8),
                                  ElevatedButton(
                                    onPressed: () {
                                      _showAddEntryDialog(context, user.userId);
                                    },
                                    child: const Text('Add Entry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...entries.take(7).map((entry) {
                          return _buildEntryCard(context, entry);
                        }).toList(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFertilityWindowCard(FertilityPrediction prediction) {
    final isInWindow = prediction.isInFertileWindow(DateTime.now());
    final daysUntilOvulation =
        prediction.predictedOvulation.difference(DateTime.now()).inDays;

    return Card(
      color: isInWindow ? AppTheme.lightPink : null,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInWindow ? Icons.favorite : Icons.favorite_border,
                  color:
                      isInWindow ? AppTheme.primaryPink : AppTheme.mediumGray,
                ),
                ResponsiveConfig.widthBox(8),
                Text(
                  isInWindow ? 'Fertile Window' : 'Predicted Ovulation',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              isInWindow
                  ? 'You are in your fertile window!'
                  : daysUntilOvulation > 0
                      ? '$daysUntilOvulation days until ovulation'
                      : 'Ovulation predicted: ${DateFormat('MMM dd').format(prediction.predictedOvulation)}',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Fertile window: ${DateFormat('MMM dd').format(prediction.fertileWindowStart)} - ${DateFormat('MMM dd').format(prediction.fertileWindowEnd)}',
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.mediumGray,
              ),
            ),
            if (prediction.methods.isNotEmpty) ...[
              ResponsiveConfig.heightBox(8),
              Wrap(
                spacing: 4,
                children: prediction.methods.map((method) {
                  return Chip(
                    label: Text(
                      method.replaceAll('_', ' ').toUpperCase(),
                      style: ResponsiveConfig.textStyle(size: 10),
                    ),
                    backgroundColor: AppTheme.accentCoral,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysEntryCard(
    BuildContext context,
    String userId,
    List<FertilityEntry> entries,
  ) {
    final today = DateTime.now();
    final todayEntry = entries.firstWhere(
      (e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day,
      orElse: () => FertilityEntry(
        userId: userId,
        date: today,
        createdAt: today,
      ),
    );

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/fertility-entry-form', extra: todayEntry);
        },
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Entry',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    if (todayEntry.basalBodyTemperature != null)
                      _buildInfoRow(
                        Icons.thermostat,
                        'BBT: ${todayEntry.basalBodyTemperature!.toStringAsFixed(1)}°C',
                      ),
                    if (todayEntry.cervicalMucus != null)
                      _buildInfoRow(
                        Icons.water_drop,
                        'CM: ${todayEntry.cervicalMucus}',
                      ),
                    if (todayEntry.lhTestPositive == true)
                      _buildInfoRow(
                        Icons.check_circle,
                        'LH Test: Positive',
                        color: AppTheme.successGreen,
                      ),
                    if (todayEntry.basalBodyTemperature == null &&
                        todayEntry.cervicalMucus == null &&
                        todayEntry.lhTestPositive == null)
                      Text(
                        'Tap to add fertility data',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.mediumGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: ResponsiveConfig.padding(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveConfig.iconSize(16),
            color: color ?? AppTheme.primaryPink,
          ),
          ResponsiveConfig.widthBox(8),
          Expanded(
            child: Text(
              text,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, FertilityEntry entry) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightPink,
          child: Text(
            DateFormat('d').format(entry.date),
            style: ResponsiveConfig.textStyle(
              size: 14,
              weight: FontWeight.bold,
              color: AppTheme.primaryPink,
            ),
          ),
        ),
        title: Text(
          DateFormat('MMM dd, yyyy').format(entry.date),
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.basalBodyTemperature != null)
              Text('BBT: ${entry.basalBodyTemperature!.toStringAsFixed(1)}°C'),
            if (entry.cervicalMucus != null) Text('CM: ${entry.cervicalMucus}'),
            if (entry.lhTestPositive == true)
              Text(
                'LH Test: Positive',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.successGreen,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            context.push('/fertility-entry-form', extra: entry);
          },
        ),
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context, String userId) {
    final todayEntry = FertilityEntry(
      userId: userId,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    context.push('/fertility-entry-form', extra: todayEntry);
  }
}
