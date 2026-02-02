import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/wellness_model.dart';
import '../../../services/wellness_service.dart';
import '../../../services/storage_service.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../core/widgets/back_button_handler.dart';

/// Wellness journal screen
class WellnessJournalScreen extends ConsumerStatefulWidget {
  final WellnessModel? entry; // For editing existing entry

  const WellnessJournalScreen({super.key, this.entry});

  @override
  ConsumerState<WellnessJournalScreen> createState() =>
      _WellnessJournalScreenState();
}

class _WellnessJournalScreenState extends ConsumerState<WellnessJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wellnessService = WellnessService();
  DateTime _selectedDate = DateTime.now();
  WellnessModel? _existingEntry;
  bool _isLoadingEntry = false;

  // Hydration
  int _waterGlasses = 0;
  final int _hydrationGoal = 8;

  // Sleep
  double _sleepHours = 7.0;
  int _sleepQuality = 3;

  // Appetite
  String _appetiteLevel = 'normal';

  // Mood - Enhanced
  String _moodEmoji = '😊';
  int _energyLevel = 3;
  final _moodDescriptionController = TextEditingController();
  List<String> _selectedEmotions = [];
  int? _stressLevel;
  int? _anxietyLevel;
  int? _depressionLevel;
  final _mentalHealthNotesController = TextEditingController();
  bool? _pmsRelated;

  // Exercise
  String? _exerciseType;
  int? _exerciseDuration;
  String? _exerciseIntensity;

  // Journal & Photos
  final _journalController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  List<String> _photoUrls = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If editing, populate form with existing entry data
    // Check if entry has entryId to determine if it's an existing entry
    if (widget.entry != null && widget.entry!.entryId.isNotEmpty) {
      _existingEntry = widget.entry;
      _selectedDate = widget.entry!.date;
      _loadEntryData(widget.entry!);
    } else {
      // Check if entry exists for selected date
      _checkExistingEntry();
    }
  }

  Future<void> _checkExistingEntry() async {
    setState(() => _isLoadingEntry = true);
    try {
      final entry =
          await _wellnessService.getWellnessEntryForDate(_selectedDate);
      if (entry != null && mounted) {
        setState(() {
          _existingEntry = entry;
          _loadEntryData(entry);
        });
      }
    } catch (e) {
      // Entry doesn't exist, continue with create
    } finally {
      if (mounted) {
        setState(() => _isLoadingEntry = false);
      }
    }
  }

  void _loadEntryData(WellnessModel entry) {
    _waterGlasses = entry.hydration.waterGlasses;
    _sleepHours = entry.sleep.hours;
    _sleepQuality = entry.sleep.quality;
    _appetiteLevel = entry.appetite.level;
    _moodEmoji = entry.mood.emoji;
    _energyLevel = entry.mood.energyLevel;
    _moodDescriptionController.text = entry.mood.description ?? '';
    _selectedEmotions = List.from(entry.mood.emotions);
    _stressLevel = entry.mood.stressLevel;
    _anxietyLevel = entry.mood.anxietyLevel;
    _depressionLevel = entry.mood.depressionLevel;
    _mentalHealthNotesController.text = entry.mood.mentalHealthNotes ?? '';
    _pmsRelated = entry.mood.pmsRelated;
    if (entry.exercise != null) {
      _exerciseType = entry.exercise!.type;
      _exerciseDuration = entry.exercise!.duration;
      _exerciseIntensity = entry.exercise!.intensity;
    }
    _journalController.text = entry.journal ?? '';
    _photoUrls = List.from(entry.photoUrls ?? []);
  }

  @override
  void dispose() {
    _moodDescriptionController.dispose();
    _mentalHealthNotesController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        try {
          final user = ref.read(currentUserStreamProvider).value;
          if (user != null) {
            final file = File(image.path);
            final uploadResult = await _storageService.uploadFile(
              file: file,
              path:
                  'wellness/${user.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            setState(() {
              _photoUrls.add(uploadResult.downloadUrl);
              _isLoading = false;
            });
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error uploading image: ${e.toString()}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _existingEntry = null; // Reset existing entry
        // Clear form data
        _waterGlasses = 0;
        _sleepHours = 7.0;
        _sleepQuality = 3;
        _appetiteLevel = 'normal';
        _moodEmoji = '😊';
        _energyLevel = 3;
        _moodDescriptionController.clear();
        _selectedEmotions = [];
        _stressLevel = null;
        _anxietyLevel = null;
        _depressionLevel = null;
        _mentalHealthNotesController.clear();
        _pmsRelated = null;
        _exerciseType = null;
        _exerciseDuration = null;
        _exerciseIntensity = null;
        _journalController.clear();
        _photoUrls = [];
      });
      // Check if entry exists for new date
      await _checkExistingEntry();
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
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
        emotions: _selectedEmotions,
        stressLevel: _stressLevel,
        anxietyLevel: _anxietyLevel,
        depressionLevel: _depressionLevel,
        mentalHealthNotes: _mentalHealthNotesController.text.isEmpty
            ? null
            : _mentalHealthNotesController.text,
        pmsRelated: _pmsRelated,
      );

      WellnessExercise? exercise;
      if (_exerciseType != null && _exerciseDuration != null) {
        exercise = WellnessExercise(
          type: _exerciseType!,
          duration: _exerciseDuration!,
          intensity: _exerciseIntensity ?? 'moderate',
        );
      }

      // Check if entry has an entryId to determine if it's an update or create
      if (_existingEntry != null && _existingEntry!.entryId.isNotEmpty) {
        // Update existing entry (has entryId)
        final updated = WellnessModel(
          entryId: _existingEntry!.entryId,
          userId: _existingEntry!.userId,
          date: _selectedDate,
          hydration: hydration,
          sleep: sleep,
          appetite: appetite,
          mood: mood,
          exercise: exercise,
          journal:
              _journalController.text.isEmpty ? null : _journalController.text,
          photoUrls: _photoUrls.isEmpty ? null : _photoUrls,
          createdAt: _existingEntry!.createdAt,
        );
        await _wellnessService.updateWellnessEntry(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Wellness entry updated successfully')),
          );
        }
      } else {
        // Create new entry
        await _wellnessService.createWellnessEntry(
          date: _selectedDate,
          hydration: hydration,
          sleep: sleep,
          appetite: appetite,
          mood: mood,
          exercise: exercise,
          journal:
              _journalController.text.isEmpty ? null : _journalController.text,
          photoUrls: _photoUrls.isEmpty ? null : _photoUrls,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wellness entry saved successfully')),
          );
        }
      }

      if (mounted) {
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
    return BackButtonHandler(
        fallbackRoute: '/home',
        child: Scaffold(
          appBar: AppBar(
            title: Text(_existingEntry != null
                ? 'Edit Wellness Entry'
                : 'Wellness Journal'),
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

                  // Photo Diary
                  _buildPhotoDiarySection(),
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
                    onPressed:
                        (_isLoading || _isLoadingEntry) ? null : _saveEntry,
                    child: (_isLoading || _isLoadingEntry)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_existingEntry != null
                            ? 'Update Entry'
                            : 'Save Entry'),
                  ),
                ],
              ),
            ),
          ),
        ));
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
            ResponsiveConfig.heightBox(16),

            // Enhanced Mood Tracking
            Text(
              'Emotions (Select all that apply)',
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'happy',
                'sad',
                'anxious',
                'angry',
                'calm',
                'excited',
                'tired',
                'focused',
                'irritable',
                'peaceful'
              ].map((emotion) {
                final isSelected = _selectedEmotions.contains(emotion);
                return FilterChip(
                  label: Text(emotion),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEmotions.add(emotion);
                      } else {
                        _selectedEmotions.remove(emotion);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            ResponsiveConfig.heightBox(16),

            // Mental Health Levels
            Text(
              'Mental Health Levels (Optional)',
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stress Level',
                        style: ResponsiveConfig.textStyle(size: 12),
                      ),
                      if (_stressLevel != null)
                        Text(
                          '$_stressLevel/10',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            weight: FontWeight.bold,
                          ),
                        ),
                      Slider(
                        value: _stressLevel?.toDouble() ?? 5.0,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _stressLevel != null ? '$_stressLevel' : null,
                        onChanged: (value) =>
                            setState(() => _stressLevel = value.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anxiety Level',
                        style: ResponsiveConfig.textStyle(size: 12),
                      ),
                      if (_anxietyLevel != null)
                        Text(
                          '$_anxietyLevel/10',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            weight: FontWeight.bold,
                          ),
                        ),
                      Slider(
                        value: _anxietyLevel?.toDouble() ?? 5.0,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _anxietyLevel != null ? '$_anxietyLevel' : null,
                        onChanged: (value) =>
                            setState(() => _anxietyLevel = value.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Depression Level',
                        style: ResponsiveConfig.textStyle(size: 12),
                      ),
                      if (_depressionLevel != null)
                        Text(
                          '$_depressionLevel/10',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            weight: FontWeight.bold,
                          ),
                        ),
                      Slider(
                        value: _depressionLevel?.toDouble() ?? 5.0,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _depressionLevel != null
                            ? '$_depressionLevel'
                            : null,
                        onChanged: (value) =>
                            setState(() => _depressionLevel = value.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            TextFormField(
              controller: _mentalHealthNotesController,
              decoration: const InputDecoration(
                labelText: 'Mental Health Notes (Optional)',
                hintText: 'Any additional notes about your mental health...',
              ),
              maxLines: 2,
            ),
            ResponsiveConfig.heightBox(12),
            SwitchListTile(
              title: const Text('PMS Related'),
              subtitle: const Text('Is this mood related to PMS?'),
              value: _pmsRelated ?? false,
              onChanged: (value) => setState(() => _pmsRelated = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoDiarySection() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo Diary (Optional)',
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._photoUrls.map((url) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: ResponsiveConfig.borderRadius(8),
                        child: Image.network(
                          url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() => _photoUrls.remove(url));
                          },
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.mediumGray,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: ResponsiveConfig.borderRadius(8),
                    ),
                    child: const Icon(Icons.add_photo_alternate),
                  ),
                ),
              ],
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
