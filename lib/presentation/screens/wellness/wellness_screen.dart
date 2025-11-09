import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/wellness_content_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';

/// Wellness screen with content library
class WellnessScreen extends ConsumerWidget {
  const WellnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final isPremium = user?.subscription.isActive ?? false;
    final contentService = WellnessContentService();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Use theme background
        appBar: AppBar(
          title: const Text('Wellness'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Tips'),
              Tab(text: 'Articles'),
              Tab(text: 'Meditation'),
            ],
          ),
        ),
        bottomNavigationBar: const FemCareBottomNav(currentRoute: '/wellness'),
        body: TabBarView(
          children: [
            _buildContentList(context, contentService, null, isPremium),
            _buildContentList(
              context,
              contentService,
              AppConstants.contentTypeTip,
              isPremium,
            ),
            _buildContentList(
              context,
              contentService,
              AppConstants.contentTypeArticle,
              isPremium,
            ),
            _buildContentList(
              context,
              contentService,
              AppConstants.contentTypeMeditation,
              isPremium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(
    BuildContext context,
    WellnessContentService service,
    String? type,
    bool isPremium,
  ) {
    final stream = type != null
        ? service.getContentByType(type, isPremium: isPremium ? null : false)
        : service.getAllContent(isPremium: isPremium ? null : false);

    return StreamBuilder<List<WellnessContent>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final contents = snapshot.data ?? [];

        if (contents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: ResponsiveConfig.iconSize(64),
                  color: AppTheme.mediumGray,
                ),
                ResponsiveConfig.heightBox(16),
                Text(
                  'No content available',
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            return _buildContentCard(context, content, isPremium);
          },
        );
      },
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    WellnessContent content,
    bool isPremium,
  ) {
    // Show premium badge if content is premium and user is not premium
    final showPremiumBadge = content.isPremium && !isPremium;

    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: InkWell(
        onTap: () {
          if (content.isPremium && !isPremium) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This content requires a premium subscription'),
              ),
            );
            return;
          }
          context.push('/wellness-content/${content.id}');
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
                  if (showPremiumBadge)
                    Container(
                      padding: ResponsiveConfig.padding(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink,
                        borderRadius: ResponsiveConfig.borderRadius(4),
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
              if (content.category != null) ...[
                ResponsiveConfig.heightBox(8),
                Text(
                  content.category!,
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ],
              ResponsiveConfig.heightBox(8),
              Text(
                content.content.length > 150
                    ? '${content.content.substring(0, 150)}...'
                    : content.content,
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (content.readTime != null) ...[
                ResponsiveConfig.heightBox(8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: ResponsiveConfig.iconSize(14),
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.widthBox(4),
                    Text(
                      '${content.readTime} min read',
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
