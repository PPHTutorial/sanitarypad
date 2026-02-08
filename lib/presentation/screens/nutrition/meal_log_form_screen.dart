// Meal Log Form Screen - For adding/editing meal entries

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/models/nutrition_models.dart';
import 'package:sanitarypad/services/nutrition_service.dart';
import 'package:uuid/uuid.dart';

class MealLogFormScreen extends ConsumerStatefulWidget {
  final String userId;
  final MealEntry? existingMeal;

  const MealLogFormScreen({super.key, required this.userId, this.existingMeal});

  @override
  ConsumerState<MealLogFormScreen> createState() => _MealLogFormScreenState();
}

class _MealLogFormScreenState extends ConsumerState<MealLogFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late MealType _selectedType;
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _descriptionController;
  late DateTime _selectedTime;

  bool _isSaving = false;

  // Common food presets for quick entry
  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Banana',
      'calories': 105,
      'protein': 1.3,
      'carbs': 27,
      'fat': 0.4
    },
    {'name': 'Apple', 'calories': 95, 'protein': 0.5, 'carbs': 25, 'fat': 0.3},
    {'name': 'Egg', 'calories': 78, 'protein': 6, 'carbs': 0.6, 'fat': 5},
    {
      'name': 'Chicken Breast (100g)',
      'calories': 165,
      'protein': 31,
      'carbs': 0,
      'fat': 3.6
    },
    {
      'name': 'Rice (1 cup)',
      'calories': 206,
      'protein': 4.3,
      'carbs': 45,
      'fat': 0.4
    },
    {
      'name': 'Oatmeal (1 cup)',
      'calories': 154,
      'protein': 5.4,
      'carbs': 27,
      'fat': 2.6
    },
    {
      'name': 'Greek Yogurt',
      'calories': 100,
      'protein': 17,
      'carbs': 6,
      'fat': 0.7
    },
    {
      'name': 'Almonds (28g)',
      'calories': 164,
      'protein': 6,
      'carbs': 6,
      'fat': 14
    },
    {
      'name': 'Salmon (100g)',
      'calories': 208,
      'protein': 20,
      'carbs': 0,
      'fat': 13
    },
    {
      'name': 'Avocado (half)',
      'calories': 161,
      'protein': 2,
      'carbs': 9,
      'fat': 15
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingMeal?.type ?? MealType.lunch;
    _nameController =
        TextEditingController(text: widget.existingMeal?.name ?? '');
    _caloriesController = TextEditingController(
        text: widget.existingMeal?.calories.toString() ?? '');
    _proteinController = TextEditingController(
        text: widget.existingMeal?.protein.toInt().toString() ?? '');
    _carbsController = TextEditingController(
        text: widget.existingMeal?.carbs.toInt().toString() ?? '');
    _fatController = TextEditingController(
        text: widget.existingMeal?.fat.toInt().toString() ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingMeal?.description ?? '');
    _selectedTime = widget.existingMeal?.loggedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingMeal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Meal' : 'Log Meal'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: _deleteMeal,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Meal Type Selector
            const Text('Meal Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _MealTypeSelector(
              selectedType: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),
            const SizedBox(height: 24),

            // Quick Presets
            const Text('Quick Add',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(preset['name'] as String),
                      onPressed: () => _applyPreset(preset),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Food Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Food Name',
                hintText: 'e.g., Grilled Chicken Salad',
                prefixIcon: const Icon(FontAwesomeIcons.utensils, size: 18),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Please enter a food name' : null,
            ),
            const SizedBox(height: 16),

            // Calories
            TextFormField(
              controller: _caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calories',
                suffixText: 'cal',
                prefixIcon: Icon(FontAwesomeIcons.fire,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Please enter calories' : null,
            ),
            const SizedBox(height: 16),

            // Macros Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Fat',
                      suffixText: 'g',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time Picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(FontAwesomeIcons.clock, size: 20),
              title: const Text('Time'),
              trailing: Text(DateFormat('h:mm a').format(_selectedTime),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any additional details...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeal,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Update Meal' : 'Log Meal',
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameController.text = preset['name'] as String;
      _caloriesController.text = preset['calories'].toString();
      _proteinController.text = preset['protein'].toString();
      _carbsController.text = preset['carbs'].toString();
      _fatController.text = preset['fat'].toString();
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_selectedTime));
    if (time != null) {
      setState(() {
        _selectedTime = DateTime(_selectedTime.year, _selectedTime.month,
            _selectedTime.day, time.hour, time.minute);
      });
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final meal = MealEntry(
        id: widget.existingMeal?.id ?? const Uuid().v4(),
        type: _selectedType,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        calories: int.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        loggedAt: _selectedTime,
        createdAt: widget.existingMeal?.createdAt ?? DateTime.now(),
      );

      final service = ref.read(nutritionServiceProvider);

      if (widget.existingMeal != null) {
        await service.updateMeal(widget.userId, meal);
      } else {
        await service.logMeal(widget.userId, meal);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.existingMeal != null
                  ? 'Meal updated!'
                  : 'Meal logged!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteMeal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );

    if (confirm == true && widget.existingMeal != null) {
      await ref
          .read(nutritionServiceProvider)
          .deleteMeal(widget.userId, widget.existingMeal!.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Meal deleted')));
      }
    }
  }
}

class _MealTypeSelector extends StatelessWidget {
  final MealType selectedType;
  final ValueChanged<MealType> onChanged;

  const _MealTypeSelector(
      {required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MealType.values.map((type) {
        final isSelected = type == selectedType;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(type.icon, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
