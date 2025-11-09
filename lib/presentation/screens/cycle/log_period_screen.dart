import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../services/cycle_service.dart';

/// Log period screen
class LogPeriodScreen extends ConsumerStatefulWidget {
  const LogPeriodScreen({super.key});

  @override
  ConsumerState<LogPeriodScreen> createState() => _LogPeriodScreenState();
}

class _LogPeriodScreenState extends ConsumerState<LogPeriodScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String _flowIntensity = AppConstants.flowMedium;
  final List<String> _selectedSymptoms = [];
  String? _mood;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date first')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _savePeriod() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cycleService = CycleService();
      final cycleLength = _endDate != null
          ? _endDate!.difference(_startDate!).inDays + 1
          : AppConstants.defaultCycleLength;
      final periodLength = _endDate != null
          ? _endDate!.difference(_startDate!).inDays + 1
          : AppConstants.defaultPeriodLength;

      await cycleService.createCycle(
        startDate: _startDate!,
        endDate: _endDate,
        cycleLength: cycleLength,
        periodLength: periodLength,
        flowIntensity: _flowIntensity,
        symptoms: _selectedSymptoms,
        mood: _mood,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period logged successfully')),
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
        title: const Text('Log Period'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Selection
              _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onTap: _selectStartDate,
              ),
              ResponsiveConfig.heightBox(16),
              _buildDateField(
                label: 'End Date (Optional)',
                date: _endDate,
                onTap: _selectEndDate,
              ),
              ResponsiveConfig.heightBox(24),

              // Flow Intensity
              Text(
                'Flow Intensity',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              _buildFlowIntensitySelector(),
              ResponsiveConfig.heightBox(24),

              // Symptoms
              Text(
                'Symptoms',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              _buildSymptomsSelector(),
              ResponsiveConfig.heightBox(24),

              // Mood
              Text(
                'Mood',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              _buildMoodSelector(),
              ResponsiveConfig.heightBox(24),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional notes...',
                ),
                maxLines: 3,
              ),
              ResponsiveConfig.heightBox(32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _savePeriod,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Period'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? app_date_utils.DateUtils.formatDate(date)
              : 'Select date',
          style: TextStyle(
            color: date != null
                ? Theme.of(context).textTheme.bodyLarge?.color
                : AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }

  Widget _buildFlowIntensitySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFlowOption(
            label: 'Light',
            value: AppConstants.flowLight,
            icon: Icons.water_drop_outlined,
          ),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child: _buildFlowOption(
            label: 'Medium',
            value: AppConstants.flowMedium,
            icon: Icons.water_drop,
          ),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child: _buildFlowOption(
            label: 'Heavy',
            value: AppConstants.flowHeavy,
            icon: Icons.water_drop,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowOption({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _flowIntensity == value;
    return InkWell(
      onTap: () => setState(() => _flowIntensity = value),
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
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryPink : AppTheme.mediumGray,
              size: ResponsiveConfig.iconSize(24),
            ),
            ResponsiveConfig.heightBox(4),
            Text(
              label,
              style: ResponsiveConfig.textStyle(
                size: 12,
                weight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryPink : AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.symptomTypes.map((symptom) {
        final isSelected = _selectedSymptoms.contains(symptom);
        return FilterChip(
          label: Text(symptom.replaceAll('_', ' ').toUpperCase()),
          selected: isSelected,
          onSelected: (_) => _toggleSymptom(symptom),
          selectedColor: AppTheme.lightPink,
          checkmarkColor: AppTheme.primaryPink,
        );
      }).toList(),
    );
  }

  Widget _buildMoodSelector() {
    final moods = ['😊', '😢', '😡', '😴', '😌', '😰', '😍', '😔'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: moods.map((emoji) {
        final isSelected = _mood == emoji;
        return InkWell(
          onTap: () => setState(() => _mood = isSelected ? null : emoji),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.lightPink : AppTheme.palePink,
              borderRadius: ResponsiveConfig.borderRadius(25),
              border: Border.all(
                color: isSelected ? AppTheme.primaryPink : Colors.transparent,
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
    );
  }
}
