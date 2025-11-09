import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/pregnancy_service.dart';
import '../../../data/models/pregnancy_model.dart';

/// Pregnancy form screen
class PregnancyFormScreen extends ConsumerStatefulWidget {
  final Pregnancy? pregnancy;

  const PregnancyFormScreen({super.key, this.pregnancy});

  @override
  ConsumerState<PregnancyFormScreen> createState() =>
      _PregnancyFormScreenState();
}

class _PregnancyFormScreenState extends ConsumerState<PregnancyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pregnancyService = PregnancyService();
  DateTime? _lastMenstrualPeriod;
  double? _weight;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.pregnancy != null) {
      _lastMenstrualPeriod = widget.pregnancy!.lastMenstrualPeriod;
      _weight = widget.pregnancy!.weight;
      _notesController.text = widget.pregnancy!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePregnancy() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_lastMenstrualPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select your last menstrual period date')),
      );
      return;
    }

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final weekDay = Pregnancy.calculateCurrentWeek(_lastMenstrualPeriod!);
      final dueDate = Pregnancy.calculateDueDate(_lastMenstrualPeriod!);

      if (widget.pregnancy != null) {
        // Update existing
        final updated = widget.pregnancy!.copyWith(
          lastMenstrualPeriod: _lastMenstrualPeriod,
          dueDate: dueDate,
          weight: _weight,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _pregnancyService.updatePregnancy(updated);
      } else {
        // Create new
        final pregnancy = Pregnancy(
          userId: user.userId,
          lastMenstrualPeriod: _lastMenstrualPeriod!,
          dueDate: dueDate,
          currentWeek: weekDay['week']!,
          currentDay: weekDay['day']!,
          weight: _weight,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _pregnancyService.createPregnancy(pregnancy);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.pregnancy != null
                  ? 'Pregnancy updated'
                  : 'Pregnancy tracking started',
            ),
          ),
        );
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

  Future<void> _selectLMPDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastMenstrualPeriod ??
          DateTime.now().subtract(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 280)),
      lastDate: DateTime.now(),
      helpText: 'Select Last Menstrual Period',
    );

    if (picked != null) {
      setState(() => _lastMenstrualPeriod = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.pregnancy != null ? 'Edit Pregnancy' : 'Start Tracking'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LMP Date
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Last Menstrual Period (LMP)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                  hintText: 'Select date',
                ),
                controller: TextEditingController(
                  text: _lastMenstrualPeriod != null
                      ? DateFormat('yyyy-MM-dd').format(_lastMenstrualPeriod!)
                      : '',
                ),
                onTap: _selectLMPDate,
                validator: (value) {
                  if (_lastMenstrualPeriod == null) {
                    return 'Please select your last menstrual period date';
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Due Date Preview
              if (_lastMenstrualPeriod != null)
                Card(
                  color: AppTheme.lightPink,
                  child: Padding(
                    padding: ResponsiveConfig.padding(all: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Due Date',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        ResponsiveConfig.heightBox(4),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(
                            Pregnancy.calculateDueDate(_lastMenstrualPeriod!),
                          ),
                          style: ResponsiveConfig.textStyle(
                            size: 20,
                            weight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ResponsiveConfig.heightBox(16),

              // Weight (Optional)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Current Weight (kg) - Optional',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                initialValue: _weight?.toString(),
                onChanged: (value) {
                  _weight = value.isEmpty ? null : double.tryParse(value);
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                maxLines: 4,
              ),
              ResponsiveConfig.heightBox(24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _savePregnancy,
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveConfig.padding(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.pregnancy != null
                            ? 'Update Pregnancy'
                            : 'Start Tracking',
                        style: ResponsiveConfig.textStyle(
                          size: 16,
                          weight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
