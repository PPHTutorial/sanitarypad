import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/wellness_content_service.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/widgets/empty_state.dart';

/// Admin screen for managing wellness content
class WellnessContentManagementScreen extends ConsumerStatefulWidget {
  const WellnessContentManagementScreen({super.key});

  @override
  ConsumerState<WellnessContentManagementScreen> createState() =>
      _WellnessContentManagementScreenState();
}

class _WellnessContentManagementScreenState
    extends ConsumerState<WellnessContentManagementScreen> {
  final _contentService = WellnessContentService();
  String _selectedType = 'all';

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      fallbackRoute: '/wellness',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Manage Wellness Content'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/wellness-content-form');
              },
              tooltip: 'Add Content',
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter Tabs
            /* Container(
              margin: ResponsiveConfig.margin(all: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: ResponsiveConfig.padding(all: 4),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All'),
                    _buildFilterChip(AppConstants.contentTypeTip, 'Tips'),
                    _buildFilterChip(
                        AppConstants.contentTypeArticle, 'Articles'),
                    _buildFilterChip(
                        AppConstants.contentTypeMeditation, 'Meditation'),
                    _buildFilterChip(
                        AppConstants.contentTypeAffirmation, 'Affirmation'),
                    _buildFilterChip(
                        AppConstants.contentTypeMythFact, 'Myth & Fact'),
                  ],
                ),
              ),
            ), */
            // Content List
            Expanded(
              child: _buildContentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: ResponsiveConfig.padding(horizontal: 4),
      child: FilterChip(
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
      ),
    );
  }

  Widget _buildContentList() {
    final stream = _selectedType == 'all'
        ? _contentService.getAllContent()
        : _contentService.getContentByType(_selectedType);

    return StreamBuilder<List<WellnessContent>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: ResponsiveConfig.iconSize(64),
                  color: AppTheme.errorRed,
                ),
                ResponsiveConfig.heightBox(16),
                Text(
                  'Error: ${snapshot.error}',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          );
        }

        final contents = snapshot.data ?? [];

        if (contents.isEmpty) {
          return EmptyState(
            title: 'No Content Available',
            icon: Icons.article_outlined,
            message: 'No content available',
            actionLabel: 'Add Content',
            onAction: () {
              context.push('/wellness-content-form');
            },
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            return _buildContentCard(content);
          },
        );
      },
    );
  }

  Widget _buildContentCard(WellnessContent content) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/wellness-content-form', extra: content);
        },
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      content.title,
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (content.isPremium)
                    Container(
                      padding: ResponsiveConfig.padding(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Premium',
                        style: ResponsiveConfig.textStyle(
                          size: 10,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              ResponsiveConfig.heightBox(8),
              Row(
                children: [
                  Container(
                    padding: ResponsiveConfig.padding(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      content.type.toUpperCase(),
                      style: ResponsiveConfig.textStyle(
                        size: 11,
                        weight: FontWeight.w600,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ),
                  ResponsiveConfig.widthBox(8),
                  if (content.category != null)
                    Text(
                      content.category!,
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  const Spacer(),
                  if (content.readTime != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                        ResponsiveConfig.widthBox(4),
                        Text(
                          '${content.readTime} min',
                          style: ResponsiveConfig.textStyle(
                            size: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (content.tags != null && content.tags!.isNotEmpty) ...[
                ResponsiveConfig.heightBox(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: content.tags!.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: ResponsiveConfig.textStyle(size: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              ResponsiveConfig.heightBox(8),
              Text(
                content.content.length > 100
                    ? '${content.content.substring(0, 100)}...'
                    : content.content,
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ResponsiveConfig.heightBox(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      context.push('/wellness-content-form', extra: content);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                  ResponsiveConfig.widthBox(8),
                  TextButton.icon(
                    onPressed: () => _deleteContent(content),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteContent(WellnessContent content) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _contentService.deleteContent(content.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting content: ${e.toString()}'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }
}
