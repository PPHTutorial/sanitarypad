import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../services/baby_service.dart';
import '../../../services/pregnancy_service.dart';
import '../../../services/credit_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Birth types with their counts
enum BirthType {
  single(1, 'Single'),
  twins(2, 'Twins'),
  triplets(3, 'Triplets'),
  quadruplets(4, 'Quadruplets'),
  quintuplets(5, 'Quintuplets'),
  sextuplets(6, 'Sextuplets');

  final int count;
  final String label;
  const BirthType(this.count, this.label);
}

/// Data holder for each child's form
class _ChildFormData {
  TextEditingController nameController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();
  String gender = 'other';

  void dispose() {
    nameController.dispose();
    weightController.dispose();
    heightController.dispose();
  }
}

class ChildbirthFormScreen extends ConsumerStatefulWidget {
  final Pregnancy pregnancy;

  const ChildbirthFormScreen({super.key, required this.pregnancy});

  @override
  ConsumerState<ChildbirthFormScreen> createState() =>
      _ChildbirthFormScreenState();
}

class _ChildbirthFormScreenState extends ConsumerState<ChildbirthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  DateTime _birthDate = DateTime.now();
  BirthType _birthType = BirthType.single;
  final List<_ChildFormData> _childForms = [_ChildFormData()];
  bool _isSaving = false;

  final BabyService _babyService = BabyService();
  final PregnancyService _pregnancyService = PregnancyService();

  @override
  void dispose() {
    _notesController.dispose();
    for (final form in _childForms) {
      form.dispose();
    }
    super.dispose();
  }

  void _onBirthTypeChanged(BirthType? newType) {
    if (newType == null) return;
    setState(() {
      _birthType = newType;
      // Adjust form count
      while (_childForms.length < newType.count) {
        _childForms.add(_ChildFormData());
      }
      while (_childForms.length > newType.count) {
        _childForms.removeLast().dispose();
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: widget.pregnancy.createdAt,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveChildbirth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Credit check
      final hasCredit = await ref
          .read(creditManagerProvider)
          .requestCredit(context, ActionType.pregnancy);
      if (!hasCredit) {
        setState(() => _isSaving = false);
        return;
      }

      final List<String> createdBabyIds = [];

      // Create each baby record
      for (int i = 0; i < _childForms.length; i++) {
        final form = _childForms[i];
        final baby = Baby(
          userId: widget.pregnancy.userId,
          name: form.nameController.text.trim(),
          gender: form.gender,
          birthDate: _birthDate,
          birthType: _birthType.name,
          weightAtBirth: double.tryParse(form.weightController.text),
          heightAtBirth: double.tryParse(form.heightController.text),
          pregnancyId: widget.pregnancy.id,
          notes: i == 0 ? _notesController.text.trim() : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final babyId = await _babyService.createBaby(baby);
        createdBabyIds.add(babyId);

        // Log initial growth entry
        if (baby.weightAtBirth != null || baby.heightAtBirth != null) {
          await _babyService.logGrowth(GrowthEntry(
            babyId: babyId,
            date: _birthDate,
            weight: baby.weightAtBirth ?? 0.0,
            height: baby.heightAtBirth ?? 0.0,
            notes: 'Birth measurements',
            createdAt: DateTime.now(),
          ));
        }
      }

      // Update Pregnancy status with all baby IDs
      final updatedPregnancy = widget.pregnancy.copyWith(
        isCompleted: true,
        babyIds: createdBabyIds,
        updatedAt: DateTime.now(),
      );
      await _pregnancyService.updatePregnancy(updatedPregnancy);

      // Consume credit
      await ref
          .read(creditManagerProvider)
          .consumeCredits(ActionType.pregnancy);

      if (!mounted) return;

      // Navigate to first baby's dashboard
      context.goNamed('baby-dashboard',
          pathParameters: {'id': createdBabyIds.first});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdBabyIds.length == 1
                ? 'Congratulations! Baby profile created.'
                : 'Congratulations! ${createdBabyIds.length} baby profiles created.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Birth'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              ResponsiveConfig.heightBox(24),
              _buildBirthTypeSelector(),
              ResponsiveConfig.heightBox(16),
              _buildDateSelector(),
              ResponsiveConfig.heightBox(24),
              ..._buildChildForms(),
              ResponsiveConfig.heightBox(16),
              _buildNotesField(),
              ResponsiveConfig.heightBox(32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.child_care, size: 64, color: AppTheme.primaryPink),
        ResponsiveConfig.heightBox(16),
        Text(
          'Welcome Your Little One${_birthType.count > 1 ? 's' : ''}',
          style: ResponsiveConfig.textStyle(size: 20, weight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        ResponsiveConfig.heightBox(8),
        Text(
          'Enter birth details to start your newborn tracking journey.',
          style:
              ResponsiveConfig.textStyle(size: 14, color: AppTheme.mediumGray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBirthTypeSelector() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birth Type',
              style:
                  ResponsiveConfig.textStyle(size: 16, weight: FontWeight.bold),
            ),
            ResponsiveConfig.heightBox(12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: BirthType.values.map((type) {
                final isSelected = _birthType == type;
                return Material(
                  color: isSelected
                      ? AppTheme.primaryPink.withOpacity(0.15)
                      : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => _onBirthTypeChanged(type),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryPink
                              : Colors.grey.shade700,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          type.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primaryPink
                                : Colors.grey.shade300,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      title: const Text('Date of Birth'),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(_birthDate)),
      leading: const Icon(Icons.calendar_today, color: AppTheme.primaryPink),
      onTap: () => _selectDate(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
    );
  }

  List<Widget> _buildChildForms() {
    return List.generate(_childForms.length, (index) {
      final form = _childForms[index];
      final childNumber = index + 1;
      final isMultiple = _childForms.length > 1;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMultiple) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Baby $childNumber',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          weight: FontWeight.bold,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
              ],
              TextFormField(
                controller: form.nameController,
                decoration: InputDecoration(
                  labelText:
                      isMultiple ? 'Baby $childNumber\'s Name' : 'Baby\'s Name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              ResponsiveConfig.heightBox(12),
              DropdownButtonFormField<String>(
                value: form.gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'girl', child: Text('Girl')),
                  DropdownMenuItem(value: 'boy', child: Text('Boy')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => form.gender = value!),
              ),
              ResponsiveConfig.heightBox(12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: form.weightController,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        suffixText: 'kg',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  ResponsiveConfig.widthBox(16),
                  Expanded(
                    child: TextFormField(
                      controller: form.heightController,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        suffixText: 'cm',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes',
        alignLabelWithHint: true,
        prefixIcon: Icon(Icons.note_alt_outlined),
      ),
      maxLines: 3,
    );
  }

  Widget _buildSaveButton() {
    final buttonText = _childForms.length == 1
        ? 'Save & Start Baby Journey'
        : 'Save ${_childForms.length} Babies & Continue';

    return ElevatedButton(
      onPressed: _isSaving ? null : _saveChildbirth,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: Colors.white,
      ),
      child: _isSaving
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(buttonText),
    );
  }
}
