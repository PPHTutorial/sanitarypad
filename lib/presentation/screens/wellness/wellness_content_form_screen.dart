import 'package:cloud_functions/cloud_functions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/wellness_content_service.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/credit_manager.dart';

/// Screen for adding/editing wellness content
class WellnessContentFormScreen extends ConsumerStatefulWidget {
  final WellnessContent? content; // For editing
  final bool isAutoGenerate; // For AI generation trigger

  const WellnessContentFormScreen(
      {super.key, this.content, this.isAutoGenerate = false});

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
  final _priceController = TextEditingController();

  // State
  String _selectedType = AppConstants.contentTypeTip;
  bool _isPremium = false;
  bool _isPaid = false;
  bool _isLoading = false;
  bool _isAIGenerating = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _loadContentData(widget.content!);
    } else if (widget.isAutoGenerate) {
      // Small delay to ensure UI is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGenerateDialog();
      });
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
    _isPaid = content.isPaid;
    _priceController.text = content.price?.toString() ?? '';
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
    _priceController.dispose();
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

  Future<void> _generateAIContent() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title first')),
      );
      return;
    }

    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager
        .requestCredit(context, ActionType.aiGeneration, showDialog: true);

    if (!hasCredits) return;

    setState(() => _isAIGenerating = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateWellnessContent');

      final result = await callable.call({
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'category': _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        'tags': _tags,
      });

      final data = result.data as Map<String, dynamic>;
      final content = data['content'] as String;
      final suggestedTags = List<String>.from(data['suggestedTags'] ?? []);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm AI Content'),
            content: SingleChildScrollView(
              child: Text(content),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Reject'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _contentController.text = content;
                    if (suggestedTags.isNotEmpty) {
                      _tags.addAll(suggestedTags);
                      _tags = _tags.toSet().toList(); // Unique tags
                      _tagsController.text = _tags.join(', ');
                    }
                  });
                  Navigator.pop(context);
                  creditManager.consumeCredits(ActionType.aiGeneration);
                },
                child: const Text('Apply Content'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAIGenerating = false);
      }
    }
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Content Assistant'),
        content: const Text(
          'Confirm to start AI generation based on the title and type. This will cost 10 credits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAIContent();
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;

    _parseTags();

    setState(() => _isLoading = true);

    try {
      final readTime = _readTimeController.text.trim().isEmpty
          ? null
          : int.tryParse(_readTimeController.text.trim());
      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());

      final now = DateTime.now();

      if (widget.content != null) {
        // Update existing content
        final updated = WellnessContent(
          id: widget.content!.id,
          userId: widget.content!.userId,
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
          isPaid: _isPaid,
          price: price,
          isAIGenerated: widget.content!.isAIGenerated ||
              _contentController.text.isNotEmpty &&
                  !widget.content!.content
                      .contains(_contentController.text), // Simple check
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
        final user = ref.read(authServiceProvider).currentUser;

        final content = WellnessContent(
          userId: user?.uid,
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
          isPaid: _isPaid,
          price: price,
          isAIGenerated: _contentController.text.isNotEmpty,
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
      fallbackRoute: '/wellness',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.content != null ? 'Edit Content' : 'Add Content'),
          actions: [
            if (!_isAIGenerating)
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles),
                tooltip: 'Generate with AI',
                onPressed: _showGenerateDialog,
              )
            else
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
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

                // Paid Toggle
                SwitchListTile(
                  title: const Text('Paid Post'),
                  subtitle: const Text('Users must pay a price to access'),
                  value: _isPaid,
                  onChanged: (value) {
                    setState(() {
                      _isPaid = value;
                    });
                  },
                ),

                if (_isPaid) ...[
                  ResponsiveConfig.heightBox(8),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (optional)',
                      hintText: 'e.g., 5.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
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
      showCheckmark: false,
      checkmarkColor: Colors.white,
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
