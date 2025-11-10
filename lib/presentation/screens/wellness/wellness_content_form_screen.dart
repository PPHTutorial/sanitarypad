import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/wellness_content_service.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Screen for adding/editing wellness content
class WellnessContentFormScreen extends ConsumerStatefulWidget {
  final WellnessContent? content; // For editing

  const WellnessContentFormScreen({super.key, this.content});

  @override
  ConsumerState<WellnessContentFormScreen> createState() =>
      _WellnessContentFormScreenState();
}

class _WellnessContentFormScreenState
    extends ConsumerState<WellnessContentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentService = WellnessContentService();

  // Controllers
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _readTimeController = TextEditingController();
  final _tagsController = TextEditingController();

  // State
  String _selectedType = AppConstants.contentTypeTip;
  bool _isPremium = false;
  bool _isLoading = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _loadContentData(widget.content!);
    }
  }

  void _loadContentData(WellnessContent content) {
    _titleController.text = content.title;
    _contentController.text = content.content;
    _selectedType = content.type;
    _categoryController.text = content.category ?? '';
    _imageUrlController.text = content.imageUrl ?? '';
    _readTimeController.text = content.readTime?.toString() ?? '';
    _isPremium = content.isPremium;
    _tags = List.from(content.tags ?? []);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _readTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _parseTags() {
    final tagsText = _tagsController.text.trim();
    if (tagsText.isEmpty) {
      _tags = [];
    } else {
      _tags = tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    _parseTags();

    setState(() => _isLoading = true);

    try {
      final readTime = _readTimeController.text.trim().isEmpty
          ? null
          : int.tryParse(_readTimeController.text.trim());

      final now = DateTime.now();

      if (widget.content != null) {
        // Update existing content
        final updated = WellnessContent(
          id: widget.content!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          tags: _tags.isEmpty ? null : _tags,
          isPremium: _isPremium,
          readTime: readTime,
          createdAt: widget.content!.createdAt,
          updatedAt: now,
        );

        await _contentService.updateContent(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content updated successfully')),
          );
          context.pop();
        }
      } else {
        // Create new content
        final content = WellnessContent(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          type: _selectedType,
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          tags: _tags.isEmpty ? null : _tags,
          isPremium: _isPremium,
          readTime: readTime,
          createdAt: now,
        );

        await _contentService.createContent(content);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content created successfully')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
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
      fallbackRoute: '/wellness-content-management',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.content != null ? 'Edit Content' : 'Add Content'),
        ),
        body: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter content title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                ResponsiveConfig.heightBox(16),

                // Content Type
                Text(
                  'Content Type *',
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
                    _buildTypeChip(AppConstants.contentTypeTip, 'Tip'),
                    _buildTypeChip(AppConstants.contentTypeArticle, 'Article'),
                    _buildTypeChip(
                        AppConstants.contentTypeMeditation, 'Meditation'),
                    _buildTypeChip(
                        AppConstants.contentTypeAffirmation, 'Affirmation'),
                    _buildTypeChip(
                        AppConstants.contentTypeMythFact, 'Myth & Fact'),
                  ],
                ),
                ResponsiveConfig.heightBox(16),

                // Content
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Content *',
                    hintText: 'Enter content text',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Content is required';
                    }
                    return null;
                  },
                ),
                ResponsiveConfig.heightBox(16),

                // Category
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., menstrual_health, pregnancy',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ResponsiveConfig.heightBox(16),

                // Image URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/image.jpg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.url,
                ),
                ResponsiveConfig.heightBox(16),

                // Read Time
                TextFormField(
                  controller: _readTimeController,
                  decoration: InputDecoration(
                    labelText: 'Read Time (minutes)',
                    hintText: 'e.g., 5',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                ResponsiveConfig.heightBox(16),

                // Tags
                TextFormField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    hintText: 'e.g., hydration, period, health',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ResponsiveConfig.heightBox(16),

                // Premium Toggle
                SwitchListTile(
                  title: const Text('Premium Content'),
                  subtitle:
                      const Text('Only premium users can access this content'),
                  value: _isPremium,
                  onChanged: (value) {
                    setState(() {
                      _isPremium = value;
                    });
                  },
                ),
                ResponsiveConfig.heightBox(24),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveContent,
                  style: ElevatedButton.styleFrom(
                    padding: ResponsiveConfig.padding(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.content != null
                              ? 'Update Content'
                              : 'Create Content',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
        });
      },
      selectedColor: AppTheme.primaryPink,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.mediumGray,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
