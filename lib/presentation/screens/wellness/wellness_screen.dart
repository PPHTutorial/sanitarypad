import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/wellness_content_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';
import 'package:sanitarypad/presentation/widgets/ads/eco_ad_wrapper.dart';

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
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plus),
              onPressed: () {
                context.push('/wellness-content-form');
              },
              tooltip: 'Add Content',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: TabBar(
              dividerColor: AppTheme.darkGray.withOpacity(0.2),
              labelStyle: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w600,
              ),
              unselectedLabelStyle: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primaryPink,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryPink,
              unselectedLabelColor: AppTheme.mediumGray,
              tabs: const [
                Tab(text: 'All', icon: Icon(Icons.grid_view_outlined)),
                Tab(text: 'Tips', icon: Icon(Icons.lightbulb_outline)),
                Tab(text: 'Articles', icon: Icon(Icons.description_outlined)),
                Tab(
                    text: 'Meditation',
                    icon: Icon(Icons.self_improvement_outlined)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const FemCareBottomNav(currentRoute: '/wellness'),
        body: Column(
          children: [
            const EcoAdWrapper(adType: AdType.banner),
            Expanded(
              child: TabBarView(
                children: [
                  _buildContentList(
                      context, ref, contentService, null, isPremium),
                  _buildContentList(
                    context,
                    ref,
                    contentService,
                    AppConstants.contentTypeTip,
                    isPremium,
                  ),
                  _buildContentList(
                    context,
                    ref,
                    contentService,
                    AppConstants.contentTypeArticle,
                    isPremium,
                  ),
                  _buildContentList(
                    context,
                    ref,
                    contentService,
                    AppConstants.contentTypeMeditation,
                    isPremium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(
    BuildContext context,
    WidgetRef ref,
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
                FaIcon(
                  FontAwesomeIcons.newspaper,
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
            return _buildContentCard(context, ref, content, isPremium);
          },
        );
      },
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    WidgetRef ref,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: ResponsiveConfig.textStyle(
                            size: 18,
                            weight: FontWeight.bold,
                          ),
                        ),
                        if (content.category != null) ...[
                          ResponsiveConfig.heightBox(4),
                          Text(
                            content.category!,
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showPremiumBadge) ...[
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
                    ResponsiveConfig.widthBox(8),
                  ],
                  if (content.userId ==
                      ref.read(authServiceProvider).currentUser?.uid) ...[
                    IconButton(
                      icon:
                          const FaIcon(FontAwesomeIcons.penToSquare, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        context.push('/wellness-content-form', extra: content);
                      },
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.trashCan,
                          size: 20, color: AppTheme.errorRed),
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _showDeleteConfirmation(context, ref, content),
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
              ResponsiveConfig.heightBox(12),
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
                    FaIcon(
                      FontAwesomeIcons.clock,
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

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, WellnessContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await WellnessContentService().deleteContent(content.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Content deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}
