import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/skincare_service.dart';
import '../../../data/models/skincare_model.dart';
import '../../../services/storage_service.dart';

/// Skincare routine form screen
class SkincareRoutineFormScreen extends ConsumerStatefulWidget {
  final SkincareEntry? entry;

  const SkincareRoutineFormScreen({super.key, this.entry});

  @override
  ConsumerState<SkincareRoutineFormScreen> createState() =>
      _SkincareRoutineFormScreenState();
}

class _SkincareRoutineFormScreenState
    extends ConsumerState<SkincareRoutineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skincareService = SkincareService();
  final _storageService = StorageService();
  final _imagePicker = ImagePicker();
  DateTime? _selectedDate;
  String _selectedTimeOfDay = 'morning';
  String? _selectedSkinCondition;
  final _notesController = TextEditingController();
  List<String> _selectedProductIds = [];
  List<String> _photoUrls = [];
  bool _isLoading = false;

  final List<String> _timeOfDayOptions = ['morning', 'evening', 'both'];
  final List<String> _skinConditionOptions = [
    'dry',
    'oily',
    'combination',
    'normal',
    'sensitive',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _selectedDate = widget.entry!.date;
      _selectedTimeOfDay = widget.entry!.timeOfDay;
      _selectedSkinCondition = widget.entry!.skinCondition;
      _selectedProductIds = List.from(widget.entry!.productsUsed);
      _photoUrls = List.from(widget.entry!.photoUrls ?? []);
      _notesController.text = widget.entry!.notes ?? '';
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
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
          // Upload image to Firebase Storage
          final user = ref.read(currentUserStreamProvider).value;
          if (user != null) {
            final file = File(image.path);
            final url = await _storageService.uploadFile(
              file: file,
              path:
                  'skincare/${user.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            setState(() {
              _photoUrls.add(url);
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
      if (widget.entry != null) {
        // Update existing
        final updated = widget.entry!.copyWith(
          date: _selectedDate,
          timeOfDay: _selectedTimeOfDay,
          productsUsed: _selectedProductIds,
          skinCondition: _selectedSkinCondition,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          photoUrls: _photoUrls.isEmpty ? null : _photoUrls,
          updatedAt: DateTime.now(),
        );
        await _skincareService.updateEntry(updated);
      } else {
        // Create new
        final entry = SkincareEntry(
          userId: user.userId,
          date: _selectedDate!,
          timeOfDay: _selectedTimeOfDay,
          productsUsed: _selectedProductIds,
          skinCondition: _selectedSkinCondition,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          photoUrls: _photoUrls.isEmpty ? null : _photoUrls,
          createdAt: DateTime.now(),
        );
        await _skincareService.createEntry(entry);
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
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry != null ? 'Edit Routine' : 'Log Routine'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<SkincareProduct>>(
              stream: _skincareService.getUserProducts(user.userId),
              builder: (context, productsSnapshot) {
                final products = productsSnapshot.data ?? [];

                return SingleChildScrollView(
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
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_selectedDate!)
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

                        // Time of Day
                        DropdownButtonFormField<String>(
                          value: _selectedTimeOfDay,
                          decoration: InputDecoration(
                            labelText: 'Time of Day',
                            prefixIcon: const Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveConfig.borderRadius(12),
                            ),
                          ),
                          items: _timeOfDayOptions.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(option.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedTimeOfDay = value!);
                          },
                        ),
                        ResponsiveConfig.heightBox(16),

                        // Products Used
                        Text(
                          'Products Used',
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            weight: FontWeight.bold,
                          ),
                        ),
                        ResponsiveConfig.heightBox(8),
                        if (products.isEmpty)
                          Card(
                            color: AppTheme.palePink,
                            child: Padding(
                              padding: ResponsiveConfig.padding(all: 12),
                              child: Text(
                                'No products added yet. Add products first.',
                                style: ResponsiveConfig.textStyle(size: 14),
                              ),
                            ),
                          )
                        else
                          ...products.map((product) {
                            return CheckboxListTile(
                              title: Text(product.name),
                              subtitle: product.brand != null
                                  ? Text(product.brand!)
                                  : null,
                              value: _selectedProductIds.contains(product.id),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedProductIds.add(product.id!);
                                  } else {
                                    _selectedProductIds.remove(product.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ResponsiveConfig.heightBox(16),

                        // Skin Condition
                        DropdownButtonFormField<String>(
                          value: _selectedSkinCondition,
                          decoration: InputDecoration(
                            labelText: 'Skin Condition (Optional)',
                            prefixIcon: const Icon(Icons.face),
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveConfig.borderRadius(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
                            ),
                            ..._skinConditionOptions.map((option) {
                              return DropdownMenuItem(
                                value: option,
                                child: Text(option.toUpperCase()),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedSkinCondition = value);
                          },
                        ),
                        ResponsiveConfig.heightBox(16),

                        // Photos
                        Text(
                          'Photos',
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            weight: FontWeight.bold,
                          ),
                        ),
                        ResponsiveConfig.heightBox(8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._photoUrls.map((url) {
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        ResponsiveConfig.borderRadius(8),
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
                            }).toList(),
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
                                  borderRadius:
                                      ResponsiveConfig.borderRadius(8),
                                ),
                                child: const Icon(Icons.add_photo_alternate),
                              ),
                            ),
                          ],
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  widget.entry != null
                                      ? 'Update Routine'
                                      : 'Save Routine',
                                  style: ResponsiveConfig.textStyle(
                                    size: 16,
                                    weight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
