import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/baby_model.dart';
import '../../../services/baby_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BabyDashboardScreen extends ConsumerStatefulWidget {
  final String babyId;

  const BabyDashboardScreen({super.key, required this.babyId});

  @override
  ConsumerState<BabyDashboardScreen> createState() =>
      _BabyDashboardScreenState();
}

class _BabyDashboardScreenState extends ConsumerState<BabyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BabyService _babyService = BabyService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final days = difference.inDays;

    if (days < 7) return '$days days old';
    if (days < 30) {
      final weeks = (days / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} old';
    }
    final months = (days / 30.44).floor();
    if (months < 12) return '$months ${months == 1 ? 'month' : 'months'} old';

    final years = (months / 12).floor();
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return '$years ${years == 1 ? 'year' : 'years'} old';
    }
    return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'} old';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Baby?>(
      future: _babyService.getBaby(widget.babyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final baby = snapshot.data;
        if (baby == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Baby profile not found')),
          );
        }

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryPink, AppTheme.palePink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Icon(
                                baby.gender == 'boy'
                                    ? Icons.face_retouching_natural
                                    : Icons
                                        .face_retouching_natural, // Icons.child_care
                                size: 50,
                                color: baby.gender == 'boy'
                                    ? Colors.blue
                                    : AppTheme.primaryPink,
                              ),
                            ),
                            ResponsiveConfig.heightBox(12),
                            Text(
                              baby.name,
                              style: ResponsiveConfig.textStyle(
                                size: 24,
                                weight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _calculateAge(baby.birthDate),
                              style: ResponsiveConfig.textStyle(
                                size: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppTheme.primaryPink,
                      unselectedLabelColor: AppTheme.mediumGray,
                      indicatorColor: AppTheme.primaryPink,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Growth'),
                        Tab(text: 'Milestones'),
                        Tab(text: 'Gallery'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _BabyOverviewTab(baby: baby),
                _BabyGrowthTab(baby: baby),
                _BabyMilestonesTab(baby: baby),
                _BabyGalleryTab(baby: baby),
              ],
            ),
          ),
          floatingActionButton: _buildActionButton(),
        );
      },
    );
  }

  Widget? _buildActionButton() {
    // Show different action depending on tab
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: AppTheme.primaryPink,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// --- Sub-Tabs ---

class _BabyOverviewTab extends StatelessWidget {
  final Baby baby;
  const _BabyOverviewTab({required this.baby});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        children: [
          _buildInfoCard(),
          ResponsiveConfig.heightBox(16),
          _buildNextMilestoneCard(),
          ResponsiveConfig.heightBox(16),
          _buildAIGuidanceCard(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          children: [
            _InfoRow(
                label: 'Birth Weight',
                value: '${baby.weightAtBirth ?? '--'} kg'),
            const Divider(),
            _InfoRow(
                label: 'Birth Height',
                value: '${baby.heightAtBirth ?? '--'} cm'),
            const Divider(),
            _InfoRow(label: 'Gender', value: baby.gender.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMilestoneCard() {
    return Container(
      padding: ResponsiveConfig.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.blue, size: 32),
          ResponsiveConfig.widthBox(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upcoming Milestone',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('First smile',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAIGuidanceCard(BuildContext context) {
    return Card(
      color: AppTheme.primaryPink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Go to AI Chat with Baby category
          context.pushNamed('ai-chat',
              pathParameters: {'category': 'baby_care'},
              extra: {'babyName': baby.name});
        },
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Row(
            children: [
              const Icon(Icons.assistant, color: Colors.white, size: 32),
              ResponsiveConfig.widthBox(16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ask FemCare+ Guide',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Get expert advice on newborn care',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.mediumGray)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BabyGrowthTab extends ConsumerWidget {
  final Baby baby;
  const _BabyGrowthTab({required this.baby});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final babyService = BabyService();

    return StreamBuilder<List<GrowthEntry>>(
      stream: babyService.watchGrowthEntries(baby.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildChartCard(
                title: 'Weight Tracking',
                unit: 'kg',
                entries: entries,
                getData: (e) => e.weight,
                color: Colors.blue,
              ),
              ResponsiveConfig.heightBox(16),
              _buildChartCard(
                title: 'Height Tracking',
                unit: 'cm',
                entries: entries,
                getData: (e) => e.height,
                color: Colors.green,
              ),
              ResponsiveConfig.heightBox(16),
              _buildRecentEntriesList(entries),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required List<GrowthEntry> entries,
    required double? Function(GrowthEntry) getData,
    required Color color,
  }) {
    final validEntries = entries
        .where((e) => getData(e) != null)
        .toList()
        .reversed
        .toList(); // Chronological

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ResponsiveConfig.heightBox(24),
            SizedBox(
              height: 200,
              child: validEntries.isEmpty
                  ? const Center(child: Text('No data yet'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: validEntries.asMap().entries.map((entry) {
                              return FlSpot(
                                  entry.key.toDouble(), getData(entry.value)!);
                            }).toList(),
                            isCurved: true,
                            color: color,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntriesList(List<GrowthEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Recent Logs',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ResponsiveConfig.heightBox(8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.take(5).length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              title: Text(DateFormat('MMM dd, yyyy').format(entry.date)),
              subtitle: Text(entry.notes ?? 'Periodic checkup'),
              trailing: Text(
                '${entry.weight} kg / ${entry.height} cm',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BabyMilestonesTab extends StatelessWidget {
  final Baby baby;
  const _BabyMilestonesTab({required this.baby});

  @override
  Widget build(BuildContext context) {
    final babyService = BabyService();

    return StreamBuilder<List<BabyDevelopmentMilestone>>(
      stream: babyService.watchMilestones(baby.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final milestones = snapshot.data ?? [];

        if (milestones.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_outline, size: 48, color: Colors.grey),
                ResponsiveConfig.heightBox(16),
                const Text('No milestones recorded yet'),
                ResponsiveConfig.heightBox(16),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Add First Milestone'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: milestones.length,
          itemBuilder: (context, index) {
            final milestone = milestones[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
                  child: const Icon(Icons.check, color: AppTheme.primaryPink),
                ),
                title: Text(milestone.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(milestone.achievedDate)),
                onTap: () {
                  // Show details
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _BabyGalleryTab extends StatelessWidget {
  final Baby baby;
  const _BabyGalleryTab({required this.baby});

  @override
  Widget build(BuildContext context) {
    final babyService = BabyService();

    return StreamBuilder<List<BabyGalleryItem>>(
      stream: babyService.watchGalleryItems(baby.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 48, color: Colors.grey),
                ResponsiveConfig.heightBox(16),
                const Text('Your gallery is empty'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return GestureDetector(
              onTap: () {
                // Show full image
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
