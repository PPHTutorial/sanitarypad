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

import '../../../services/wellness_service.dart';
import '../../../data/models/wellness_model.dart';
import 'package:intl/intl.dart';

/// Wellness screen with content library and journal tabs
class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({super.key});

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final isPremium = user?.subscription.isActive ?? false;
    final contentService = WellnessContentService();
    final wellnessService = WellnessService();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wellness Hub'),
          actions: [
            if (_tabController.index == 1)
              IconButton(
                icon:
                    const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 20),
                onPressed: () =>
                    context.push('/wellness-content-form', extra: true),
                tooltip: 'AI Auto Write',
              ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plus),
              onPressed: () => _showAddOptions(context),
              tooltip: 'Add Entry',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelStyle: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.bold,
              ),
              unselectedLabelStyle: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w500,
              ),
              indicatorColor: AppTheme.primaryPink,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryPink,
              unselectedLabelColor: AppTheme.mediumGray,
              tabs: const [
                Tab(text: 'Journal'),
                Tab(text: 'Articles'),
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
                controller: _tabController,
                children: [
                  _buildJournalList(
                      context, ref, wellnessService, user?.userId),
                  _ArticlesTabView(
                      contentService: contentService, isPremium: isPremium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppTheme.primaryPink),
              title: const Text('New Journal Entry'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wellness-journal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.post_add, color: AppTheme.primaryPink),
              title: const Text('Add Wellness Content'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wellness-content-form');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList(BuildContext context, WidgetRef ref,
      WellnessService service, String? userId) {
    if (userId == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<List<WellnessModel>>(
      stream: service.watchWellnessEntries(userId, limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.bookOpen,
                    size: 64, color: AppTheme.mediumGray),
                ResponsiveConfig.heightBox(16),
                const Text('No entries yet. Start journaling!'),
                ResponsiveConfig.heightBox(16),
                ElevatedButton(
                  onPressed: () => context.push('/wellness-journal'),
                  child: const Text('Add First Entry'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildJournalCard(context, entry);
          },
        );
      },
    );
  }

  Widget _buildJournalCard(BuildContext context, WellnessModel entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveConfig.borderRadius(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/wellness-journal', extra: entry),
        borderRadius: ResponsiveConfig.borderRadius(16),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPink,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(entry.date),
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ),
                  Text(
                    entry.mood.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(12),
              Text(
                entry.journal ?? 'No description',
                style: ResponsiveConfig.textStyle(
                  size: 15,
                  weight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ResponsiveConfig.heightBox(8),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppTheme.mediumGray),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('hh:mm a').format(entry.date),
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.mediumGray),
                ],
              ),
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

class _ContentCard extends ConsumerWidget {
  final WellnessContent content;
  final bool isPremium;
  final Function(WellnessContent) onDelete;

  const _ContentCard({
    required this.content,
    required this.isPremium,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        Row(
                          children: [
                            if (content.category != null)
                              Text(
                                content.category!,
                                style: ResponsiveConfig.textStyle(
                                  size: 12,
                                  color: AppTheme.primaryPink,
                                ),
                              ),
                            if (content.isPaid) ...[
                              if (content.category != null)
                                Text(' • ',
                                    style: TextStyle(
                                        color: AppTheme.mediumGray,
                                        fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PAID',
                                  style: ResponsiveConfig.textStyle(
                                    size: 10,
                                    weight: FontWeight.bold,
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ),
                            ],
                            if (content.isAIGenerated) ...[
                              Text(' • ',
                                  style: TextStyle(
                                      color: AppTheme.mediumGray,
                                      fontSize: 12)),
                              const FaIcon(FontAwesomeIcons.wandMagicSparkles,
                                  size: 10, color: AppTheme.mediumGray),
                            ],
                          ],
                        ),
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
                      onPressed: () => onDelete(content),
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
}

/// Helper widget for the Articles tab with filters
class _ArticlesTabView extends StatefulWidget {
  final WellnessContentService contentService;
  final bool isPremium;

  const _ArticlesTabView(
      {required this.contentService, required this.isPremium});

  @override
  State<_ArticlesTabView> createState() => _ArticlesTabViewState();
}

class _ArticlesTabViewState extends State<_ArticlesTabView> {
  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'label': 'All', 'value': null},
      {'label': 'Tips', 'value': AppConstants.contentTypeTip},
      {'label': 'Articles', 'value': AppConstants.contentTypeArticle},
      {'label': 'Meditation', 'value': AppConstants.contentTypeMeditation},
    ];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: filters.map((filter) {
              final isSelected = _selectedType == filter['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = filter['value'] as String?;
                    });
                  },
                  selectedColor: AppTheme.primaryPink.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppTheme.primaryPink : AppTheme.darkGray,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryPink
                          : AppTheme.mediumGray.withOpacity(0.3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _WellnessScreenContentList(
            type: _selectedType,
            contentService: widget.contentService,
            isPremium: widget.isPremium,
          ),
        ),
      ],
    );
  }
}

/// Internal widget to build the content list
class _WellnessScreenContentList extends ConsumerWidget {
  final String? type;
  final WellnessContentService contentService;
  final bool isPremium;

  const _WellnessScreenContentList({
    this.type,
    required this.contentService,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = type != null
        ? contentService.getContentByType(type!,
            isPremium: isPremium ? null : false)
        : contentService.getAllContent(isPremium: isPremium ? null : false);

    return StreamBuilder<List<WellnessContent>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final contents = snapshot.data ?? [];

        if (contents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.newspaper,
                    size: 64, color: AppTheme.mediumGray),
                const SizedBox(height: 16),
                const Text('No content available'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            return _ContentCard(
              content: content,
              isPremium: isPremium,
              onDelete: (content) {
                // Accessing private method from _WellnessScreenState is not directly possible here
                // We'll use a hack or just move the delete confirmation logic if needed,
                // but let's see if we can just pass the confirmation logic.
                final state =
                    context.findAncestorStateOfType<_WellnessScreenState>();
                state?._showDeleteConfirmation(context, ref, content);
              },
            );
          },
        );
      },
    );
  }
}
