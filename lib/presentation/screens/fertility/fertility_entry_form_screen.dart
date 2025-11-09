import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/fertility_service.dart';
import '../../../data/models/fertility_model.dart';

/// Fertility entry form screen
class FertilityEntryFormScreen extends ConsumerStatefulWidget {
  final FertilityEntry? entry;

  const FertilityEntryFormScreen({super.key, this.entry});

  @override
  ConsumerState<FertilityEntryFormScreen> createState() =>
      _FertilityEntryFormScreenState();
}

class _FertilityEntryFormScreenState
    extends ConsumerState<FertilityEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fertilityService = FertilityService();
  DateTime? _selectedDate;
  final _bbtController = TextEditingController();
  String? _selectedCervicalMucus;
  String? _selectedCervicalPosition;
  bool? _lhTestPositive;
  bool? _intercourse;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _cervicalMucusOptions = [
    'dry',
    'sticky',
    'creamy',
    'watery',
    'egg-white',
  ];

  final List<String> _cervicalPositionOptions = [
    'low',
    'medium',
    'high',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _selectedDate = widget.entry!.date;
      _bbtController.text =
          widget.entry!.basalBodyTemperature?.toStringAsFixed(1) ?? '';
      _selectedCervicalMucus = widget.entry!.cervicalMucus;
      _selectedCervicalPosition = widget.entry!.cervicalPosition;
      _lhTestPositive = widget.entry!.lhTestPositive;
      _intercourse = widget.entry!.intercourse;
      _notesController.text = widget.entry!.notes ?? '';
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _bbtController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')),
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
      final bbt = _bbtController.text.trim().isEmpty
          ? null
          : double.tryParse(_bbtController.text.trim());

      if (widget.entry != null) {
        // Update existing
        final updated = widget.entry!.copyWith(
          date: _selectedDate,
          basalBodyTemperature: bbt,
          cervicalMucus: _selectedCervicalMucus,
          cervicalPosition: _selectedCervicalPosition,
          lhTestPositive: _lhTestPositive,
          intercourse: _intercourse,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await _fertilityService.updateFertilityEntry(updated);
      } else {
        // Create new
        final entry = FertilityEntry(
          userId: user.userId,
          date: _selectedDate!,
          basalBodyTemperature: bbt,
          cervicalMucus: _selectedCervicalMucus,
          cervicalPosition: _selectedCervicalPosition,
          lhTestPositive: _lhTestPositive,
          intercourse: _intercourse,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        await _fertilityService.createFertilityEntry(entry);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry != null ? 'Entry updated' : 'Entry added',
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry != null ? 'Edit Entry' : 'Add Entry'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                      : '',
                ),
                onTap: _selectDate,
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // BBT
              TextFormField(
                controller: _bbtController,
                decoration: InputDecoration(
                  labelText: 'Basal Body Temperature (°C) - Optional',
                  prefixIcon: const Icon(Icons.thermostat),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                  helperText: 'Take temperature first thing in the morning',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final temp = double.tryParse(value.trim());
                    if (temp == null) {
                      return 'Please enter a valid temperature';
                    }
                    if (temp < 35.0 || temp > 40.0) {
                      return 'Temperature should be between 35°C and 40°C';
                    }
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Cervical Mucus
              DropdownButtonFormField<String>(
                value: _selectedCervicalMucus,
                decoration: InputDecoration(
                  labelText: 'Cervical Mucus - Optional',
                  prefixIcon: const Icon(Icons.water_drop),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._cervicalMucusOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option.replaceAll('-', ' ').toUpperCase()),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedCervicalMucus = value);
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Cervical Position
              DropdownButtonFormField<String>(
                value: _selectedCervicalPosition,
                decoration: InputDecoration(
                  labelText: 'Cervical Position - Optional',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None'),
                  ),
                  ..._cervicalPositionOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(option.toUpperCase()),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedCervicalPosition = value);
                },
              ),
              ResponsiveConfig.heightBox(16),

              // LH Test
              Card(
                child: SwitchListTile(
                  title: const Text('LH Test Positive'),
                  subtitle: const Text('Ovulation predictor test result'),
                  value: _lhTestPositive ?? false,
                  onChanged: (value) {
                    setState(() => _lhTestPositive = value);
                  },
                ),
              ),
              ResponsiveConfig.heightBox(8),

              // Intercourse
              Card(
                child: SwitchListTile(
                  title: const Text('Intercourse'),
                  subtitle: const Text('Track intercourse for conception'),
                  value: _intercourse ?? false,
                  onChanged: (value) {
                    setState(() => _intercourse = value);
                  },
                ),
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
                maxLines: 3,
              ),
              ResponsiveConfig.heightBox(24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEntry,
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
                        widget.entry != null ? 'Update Entry' : 'Save Entry',
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
