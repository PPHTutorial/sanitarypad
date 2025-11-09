import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/wellness_model.dart';
import '../../../services/wellness_service.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

/// Wellness journal screen
class WellnessJournalScreen extends ConsumerStatefulWidget {
  const WellnessJournalScreen({super.key});

  @override
  ConsumerState<WellnessJournalScreen> createState() =>
      _WellnessJournalScreenState();
}

class _WellnessJournalScreenState extends ConsumerState<WellnessJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();

  // Hydration
  int _waterGlasses = 0;
  final int _hydrationGoal = 8;

  // Sleep
  double _sleepHours = 7.0;
  int _sleepQuality = 3;

  // Appetite
  String _appetiteLevel = 'normal';

  // Mood
  String _moodEmoji = '😊';
  int _energyLevel = 3;
  final _moodDescriptionController = TextEditingController();

  // Exercise
  String? _exerciseType;
  int? _exerciseDuration;
  String? _exerciseIntensity;

  // Journal
  final _journalController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _moodDescriptionController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final wellnessService = WellnessService();

      final hydration = WellnessHydration(
        waterGlasses: _waterGlasses,
        goal: _hydrationGoal,
      );

      final sleep = WellnessSleep(
        hours: _sleepHours,
        quality: _sleepQuality,
      );

      final appetite = WellnessAppetite(
        level: _appetiteLevel,
      );

      final mood = WellnessMood(
        emoji: _moodEmoji,
        description: _moodDescriptionController.text.isEmpty
            ? null
            : _moodDescriptionController.text,
        energyLevel: _energyLevel,
      );

      WellnessExercise? exercise;
      if (_exerciseType != null && _exerciseDuration != null) {
        exercise = WellnessExercise(
          type: _exerciseType!,
          duration: _exerciseDuration!,
          intensity: _exerciseIntensity ?? 'moderate',
        );
      }

      await wellnessService.createWellnessEntry(
        date: _selectedDate,
        hydration: hydration,
        sleep: sleep,
        appetite: appetite,
        mood: mood,
        exercise: exercise,
        journal:
            _journalController.text.isEmpty ? null : _journalController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wellness entry saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness Journal'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Selector
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    app_date_utils.DateUtils.formatDate(_selectedDate),
                  ),
                ),
              ),
              ResponsiveConfig.heightBox(24),

              // Mood Tracker
              _buildMoodSection(),
              ResponsiveConfig.heightBox(24),

              // Hydration
              _buildHydrationSection(),
              ResponsiveConfig.heightBox(24),

              // Sleep
              _buildSleepSection(),
              ResponsiveConfig.heightBox(24),

              // Appetite
              _buildAppetiteSection(),
              ResponsiveConfig.heightBox(24),

              // Exercise (Optional)
              _buildExerciseSection(),
              ResponsiveConfig.heightBox(24),

              // Journal Entry
              TextFormField(
                controller: _journalController,
                decoration: const InputDecoration(
                  labelText: 'Journal Entry (Optional)',
                  hintText: 'How are you feeling today?',
                ),
                maxLines: 5,
              ),
              ResponsiveConfig.heightBox(32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEntry,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    final moods = ['😊', '😢', '😡', '😴', '😌', '😰', '😍', '😔'];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: moods.map((emoji) {
                final isSelected = _moodEmoji == emoji;
                return InkWell(
                  onTap: () => setState(() => _moodEmoji = emoji),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppTheme.lightPink : AppTheme.palePink,
                      borderRadius: ResponsiveConfig.borderRadius(25),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryPink
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              'Energy Level',
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Row(
              children: List.generate(5, (index) {
                final level = index + 1;
                final isSelected = _energyLevel >= level;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _energyLevel = level),
                    child: Container(
                      margin: ResponsiveConfig.margin(horizontal: 2),
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryPink
                            : AppTheme.palePink,
                        borderRadius: ResponsiveConfig.borderRadius(8),
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            weight: FontWeight.w600,
                            color:
                                isSelected ? Colors.white : AppTheme.mediumGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            ResponsiveConfig.heightBox(12),
            TextFormField(
              controller: _moodDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Mood Description (Optional)',
                hintText: 'Describe how you\'re feeling...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationSection() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydration',
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(8, (index) {
                final glass = index + 1;
                final isFilled = _waterGlasses >= glass;
                return InkWell(
                  onTap: () => setState(() => _waterGlasses = glass),
                  child: Icon(
                    Icons.water_drop,
                    size: ResponsiveConfig.iconSize(32),
                    color: isFilled ? AppTheme.infoBlue : AppTheme.mediumGray,
                  ),
                );
              }),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              '$_waterGlasses / $_hydrationGoal glasses',
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepSection() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep',
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              'Hours: ${_sleepHours.toStringAsFixed(1)}',
              style: ResponsiveConfig.textStyle(
                size: 14,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Slider(
              value: _sleepHours,
              min: 0,
              max: 12,
              divisions: 24,
              label: '${_sleepHours.toStringAsFixed(1)} hours',
              onChanged: (value) => setState(() => _sleepHours = value),
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              'Quality',
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Row(
              children: List.generate(5, (index) {
                final quality = index + 1;
                final isSelected = _sleepQuality >= quality;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _sleepQuality = quality),
                    child: Container(
                      margin: ResponsiveConfig.margin(horizontal: 2),
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryPink
                            : AppTheme.palePink,
                        borderRadius: ResponsiveConfig.borderRadius(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.star,
                          color:
                              isSelected ? Colors.white : AppTheme.mediumGray,
                          size: ResponsiveConfig.iconSize(20),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppetiteSection() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appetite',
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Row(
              children: [
                Expanded(
                  child: _buildAppetiteOption('Low', 'low'),
                ),
                ResponsiveConfig.widthBox(8),
                Expanded(
                  child: _buildAppetiteOption('Normal', 'normal'),
                ),
                ResponsiveConfig.widthBox(8),
                Expanded(
                  child: _buildAppetiteOption('High', 'high'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppetiteOption(String label, String value) {
    final isSelected = _appetiteLevel == value;
    return InkWell(
      onTap: () => setState(() => _appetiteLevel = value),
      child: Container(
        padding: ResponsiveConfig.padding(all: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightPink : AppTheme.palePink,
          borderRadius: ResponsiveConfig.borderRadius(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: ResponsiveConfig.textStyle(
            size: 14,
            weight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryPink : AppTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildExerciseSection() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercise (Optional)',
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
                Switch(
                  value: _exerciseType != null,
                  onChanged: (value) {
                    setState(() {
                      if (value) {
                        _exerciseType = 'Walking';
                        _exerciseDuration = 30;
                        _exerciseIntensity = 'moderate';
                      } else {
                        _exerciseType = null;
                        _exerciseDuration = null;
                        _exerciseIntensity = null;
                      }
                    });
                  },
                ),
              ],
            ),
            if (_exerciseType != null) ...[
              ResponsiveConfig.heightBox(16),
              TextFormField(
                initialValue: _exerciseType,
                decoration: const InputDecoration(labelText: 'Exercise Type'),
                onChanged: (value) => setState(() => _exerciseType = value),
              ),
              ResponsiveConfig.heightBox(16),
              TextFormField(
                initialValue: _exerciseDuration?.toString(),
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                onChanged: (value) {
                  setState(() => _exerciseDuration = int.tryParse(value));
                },
              ),
              ResponsiveConfig.heightBox(16),
              DropdownButtonFormField<String>(
                value: _exerciseIntensity,
                decoration: const InputDecoration(labelText: 'Intensity'),
                items: ['light', 'moderate', 'vigorous']
                    .map((intensity) => DropdownMenuItem(
                          value: intensity,
                          child: Text(intensity.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _exerciseIntensity = value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
