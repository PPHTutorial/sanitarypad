import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/wellness_content_service.dart';
import '../../../core/providers/auth_provider.dart';

/// Wellness content detail screen
class WellnessContentDetailScreen extends ConsumerStatefulWidget {
  final String contentId;

  const WellnessContentDetailScreen({
    super.key,
    required this.contentId,
  });

  @override
  ConsumerState<WellnessContentDetailScreen> createState() =>
      _WellnessContentDetailScreenState();
}

class _WellnessContentDetailScreenState
    extends ConsumerState<WellnessContentDetailScreen> {
  final _contentService = WellnessContentService();
  WellnessContent? _content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final content = await _contentService.getContentById(widget.contentId);
      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading content: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final isPremium = user?.subscription.isActive ?? false;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_content == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Content not found')),
      );
    }

    // Check premium access
    if (_content!.isPremium && !isPremium) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: ResponsiveConfig.iconSize(64),
                color: AppTheme.primaryPink,
              ),
              ResponsiveConfig.heightBox(16),
              Text(
                'Premium Content',
                style: ResponsiveConfig.textStyle(
                  size: 24,
                  weight: FontWeight.bold,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                'This content requires a premium subscription',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  color: AppTheme.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveConfig.heightBox(24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to subscription
                },
                child: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_content!.title),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_content!.category != null)
              Container(
                padding: ResponsiveConfig.padding(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightPink,
                  borderRadius: ResponsiveConfig.borderRadius(8),
                ),
                child: Text(
                  _content!.category!,
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    weight: FontWeight.bold,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ),
            ResponsiveConfig.heightBox(16),
            Text(
              _content!.title,
              style: ResponsiveConfig.textStyle(
                size: 28,
                weight: FontWeight.bold,
              ),
            ),
            if (_content!.readTime != null) ...[
              ResponsiveConfig.heightBox(8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: ResponsiveConfig.iconSize(16),
                    color: AppTheme.mediumGray,
                  ),
                  ResponsiveConfig.widthBox(4),
                  Text(
                    '${_content!.readTime} min read',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ],
            ResponsiveConfig.heightBox(24),
            Text(
              _content!.content,
              style: ResponsiveConfig.textStyle(
                size: 16,
                height: 1.6,
              ),
            ),
            if (_content!.tags != null && _content!.tags!.isNotEmpty) ...[
              ResponsiveConfig.heightBox(24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _content!.tags!.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppTheme.palePink,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
