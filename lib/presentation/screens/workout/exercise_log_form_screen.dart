import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sanitarypad/models/workout_models.dart';
import 'package:sanitarypad/services/workout_service.dart';
import 'package:uuid/uuid.dart';

class ExerciseLogFormScreen extends ConsumerStatefulWidget {
  final String userId;
  final ExerciseEntry? initialExercise;
  final String? sessionId;

  const ExerciseLogFormScreen(
      {super.key, required this.userId, this.initialExercise, this.sessionId});

  @override
  ConsumerState<ExerciseLogFormScreen> createState() =>
      _ExerciseLogFormScreenState();
}

class _ExerciseLogFormScreenState extends ConsumerState<ExerciseLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _durationController;
  late TextEditingController _caloriesController;
  ExerciseCategory _selectedCategory = ExerciseCategory.other;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialExercise?.exerciseName);
    _setsController = TextEditingController(
        text: widget.initialExercise?.sets?.toString() ?? '');
    _repsController = TextEditingController(
        text: widget.initialExercise?.reps?.toString() ?? '');
    _weightController = TextEditingController(
        text: widget.initialExercise?.weight?.toString() ?? '');
    _durationController = TextEditingController(
        text: widget.initialExercise?.duration.inMinutes.toString() ?? '');
    _caloriesController = TextEditingController(
        text: widget.initialExercise?.caloriesBurned.toString() ?? '');
    _selectedCategory =
        widget.initialExercise?.category ?? ExerciseCategory.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final durationMinutes = int.tryParse(_durationController.text) ?? 30;
      final exercise = ExerciseEntry(
        id: widget.initialExercise?.id ?? const Uuid().v4(),
        sessionId: widget.sessionId ?? widget.initialExercise?.sessionId,
        exerciseName: _nameController.text.trim(),
        category: _selectedCategory,
        muscleGroups: const [], // Default to empty for now or add a selector
        sets: int.tryParse(_setsController.text),
        reps: int.tryParse(_repsController.text),
        weight: double.tryParse(_weightController.text),
        duration: Duration(minutes: durationMinutes),
        caloriesBurned: int.tryParse(_caloriesController.text) ?? 200,
        notes: null,
        loggedAt: widget.initialExercise?.loggedAt ?? DateTime.now(),
        createdAt: widget.initialExercise?.createdAt ?? DateTime.now(),
      );

      final service = ref.read(workoutServiceProvider);
      if (widget.initialExercise == null) {
        await service.logExercise(widget.userId, exercise);
      } else {
        await service.updateExercise(widget.userId, exercise);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise logged! 💪')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: Text(
            widget.initialExercise == null ? 'Log Exercise' : 'Edit Exercise'),
        actions: [
          if (_isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveExercise),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Selector
            const Text('Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ExerciseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${cat.icon} ${cat.displayName}'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Squats, Running, Yoga',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (min)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Calories Burned',
                      suffixText: 'kcal',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveExercise,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.initialExercise == null
                    ? 'Log Exercise'
                    : 'Save Changes',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
