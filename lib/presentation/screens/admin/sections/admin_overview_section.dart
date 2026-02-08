import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AdminOverviewSection extends ConsumerStatefulWidget {
  const AdminOverviewSection({super.key});

  @override
  ConsumerState<AdminOverviewSection> createState() =>
      _AdminOverviewSectionState();
}

class _AdminOverviewSectionState extends ConsumerState<AdminOverviewSection> {
  // Core Metrics
  int _totalUsers = 0;
  int _activeSubs = 0;
  int _openTickets = 0;
  double _mrr = 0.0; // Monthly Recurring Revenue (Est)

  // Growth Data (Last 7 Days)
  List<int> _dailyUserRegistrations = List.filled(7, 0);
  List<String> _dayLabels = [];

  // Health Metrics
  int _totalCycles = 0;
  int _activePregnancies = 0;
  int _skincareEntries = 0;
  int _fertilityEntries = 0;

  // Community & Engagement
  int _totalGroups = 0;
  int _totalEvents = 0;
  int _aiMessages = 0;

  // Content
  int _wellnessContent = 0;

  // Breakdowns
  Map<String, int> _ticketCategories = {};
  Map<String, int> _tierBreakdown = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();

      // 1. Calculate Date Range for Chart
      List<DateTime> last7Days = [];
      for (int i = 6; i >= 0; i--) {
        last7Days.add(now.subtract(Duration(days: i)));
      }
      _dayLabels = last7Days.map((d) => DateFormat('E').format(d)).toList();

      // 2. Fetch Core Counts
      final coreFutures = await Future.wait([
        db.collection('users').count().get(),
        db
            .collection('subscriptions')
            .where('status', isEqualTo: 'active')
            .count()
            .get(),
        db
            .collection('support_tickets')
            .where('status', isEqualTo: 'open')
            .count()
            .get(),
      ]);

      // 3. Fetch Revenue Logic (MRR based on Tiers)
      // Note: In a real large-scale app, use an aggregation function.
      // Here we fetch metadata or assume counts.
      final ecoCount = await db
          .collection('subscriptions')
          .where('tier', isEqualTo: 'economy')
          .count()
          .get();
      final proCount = await db
          .collection('subscriptions')
          .where('tier', isEqualTo: 'premium_pro')
          .count()
          .get();
      final advCount = await db
          .collection('subscriptions')
          .where('tier', isEqualTo: 'premium_advance')
          .count()
          .get();
      final plusCount = await db
          .collection('subscriptions')
          .where('tier', isEqualTo: 'premium_plus')
          .count()
          .get();

      // Store tier breakdown for chart
      final Map<String, int> tierData = {
        'Economy': ecoCount.count ?? 0,
        'Pro': proCount.count ?? 0,
        'Advance': advCount.count ?? 0,
        'Plus': plusCount.count ?? 0,
      };

      // 4. Fetch User Growth Chart Data (Iterative Count)
      // Optimized: Fetch all users from last 7 days once, then bucket them.
      final weekAgo = now.subtract(const Duration(days: 7));
      final recentUsersSnapshot = await db
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: weekAgo)
          .get();

      List<int> dailyCounts = List.filled(7, 0);
      for (var doc in recentUsersSnapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        for (int i = 0; i < 7; i++) {
          final day = last7Days[i];
          if (createdAt.year == day.year &&
              createdAt.month == day.month &&
              createdAt.day == day.day) {
            dailyCounts[i]++;
            break;
          }
        }
      }

      // 5. Fetch Detail Metrics
      final detailsFutures = await Future.wait([
        db.collection('cycles').count().get(),
        db
            .collection('pregnancies')
            .where('isActive', isEqualTo: true)
            .count()
            .get(),
        db.collection('skincareEntries').count().get(),
        db.collection('fertilityEntries').count().get(),
        db.collection('groups').count().get(),
        db.collection('events').count().get(),
        db.collection('aiChatMessages').count().get(),
        db.collection('wellnessContent').count().get(),
      ]);

      // 6. Ticket Breakdown
      final ticketsDocs =
          await db.collection('support_tickets').limit(50).get();
      final Map<String, int> categories = {};
      for (var doc in ticketsDocs.docs) {
        final cat = doc.data()['category'] as String? ?? 'General';
        categories[cat] = (categories[cat] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _totalUsers = coreFutures[0].count ?? 0;
          _activeSubs = coreFutures[1].count ?? 0;
          _openTickets = coreFutures[2].count ?? 0;

          // Calculate MRR (Est)
          double mrr = 0;
          mrr += (ecoCount.count ?? 0) * 0.0;
          mrr += (proCount.count ?? 0) * 19.99;
          mrr += (advCount.count ?? 0) * 29.99;
          mrr += (plusCount.count ?? 0) * 59.99;
          _mrr = mrr;

          _dailyUserRegistrations = dailyCounts;

          _totalCycles = detailsFutures[0].count ?? 0;
          _activePregnancies = detailsFutures[1].count ?? 0;
          _skincareEntries = detailsFutures[2].count ?? 0;
          _fertilityEntries = detailsFutures[3].count ?? 0;
          _totalGroups = detailsFutures[4].count ?? 0;
          _totalEvents = detailsFutures[5].count ?? 0;
          _aiMessages = detailsFutures[6].count ?? 0;
          _wellnessContent = detailsFutures[7].count ?? 0;

          _ticketCategories = categories.isEmpty ? {'No Data': 1} : categories;
          _tierBreakdown = tierData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time Platform Analytics',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                  onPressed: _fetchStats, icon: const Icon(Icons.refresh)),
            ],
          ),

          const SizedBox(height: 24),

          // --- 1. CORE METRICS (2x2 Grid) ---
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.0, // Wider, shorter cards
            children: [
              _StatCard(
                title: 'Total Users',
                value: NumberFormat.compact().format(_totalUsers),
                icon: FontAwesomeIcons.users,
                color: Colors.blue[700]!,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              _StatCard(
                title: 'Est. MRR',
                value:
                    NumberFormat.simpleCurrency(decimalDigits: 0).format(_mrr),
                icon: FontAwesomeIcons.sackDollar,
                color: Colors.green[700]!,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              _StatCard(
                title: 'Active Subs',
                value: NumberFormat.compact().format(_activeSubs),
                icon: FontAwesomeIcons.crown,
                color: Colors.amber[700]!,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              _StatCard(
                title: 'Pending Tickets',
                value: _openTickets.toString(),
                icon: FontAwesomeIcons.ticket,
                color: _openTickets > 0 ? Colors.red[700]! : Colors.green[700]!,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- 2. Collection Metrics (Grid) ---
          Text('Platform Data Collections',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4, // More dense grid
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Responsive fallback within GridView can be tricky, consider switching count based on width if needed
            // For mobile this might overflow. Let's use LayoutBuilder inside.
            childAspectRatio: 1.0,
            children: [
              _MiniStat(
                  label: 'Cycles',
                  value: _totalCycles,
                  icon: FontAwesomeIcons.droplet,
                  color: Colors.pink,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'Pregnancy',
                  value: _activePregnancies,
                  icon: FontAwesomeIcons.baby,
                  color: Colors.purple,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'Skincare',
                  value: _skincareEntries,
                  icon: FontAwesomeIcons.faceGrin,
                  color: Colors.teal,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'Fertility',
                  value: _fertilityEntries,
                  icon: FontAwesomeIcons.chartLine,
                  color: Colors.orange,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'Groups',
                  value: _totalGroups,
                  icon: FontAwesomeIcons.usersRectangle,
                  color: Colors.indigo,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'Events',
                  value: _totalEvents,
                  icon: FontAwesomeIcons.calendarDay,
                  color: Colors.blue,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'AI Chat',
                  value: _aiMessages,
                  icon: FontAwesomeIcons.robot,
                  color: Colors.cyan,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MiniStat(
                  label: 'Content',
                  value: _wellnessContent,
                  icon: FontAwesomeIcons.bookOpen,
                  color: Colors.green,
                  cardColor: cardColor,
                  borderColor: borderColor),
            ],
          ),

          const SizedBox(height: 24),

          // --- 3. CHARTS (Registrations & Tickets) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _ChartCard(
                  title: 'New User Registrations (7 Days)',
                  cardColor: cardColor,
                  borderColor: borderColor,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < _dayLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(_dayLabels[value.toInt()],
                                      style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(_dailyUserRegistrations.length,
                          (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: _dailyUserRegistrations[index].toDouble(),
                              color: theme.colorScheme.primary,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _ChartCard(
                  title: 'Tickets by Category',
                  cardColor: cardColor,
                  borderColor: borderColor,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: _ticketCategories.entries.map((e) {
                        final index =
                            _ticketCategories.keys.toList().indexOf(e.key);
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          title: '', // Tooltip preferrable, or Legend
                          color:
                              Colors.primaries[index % Colors.primaries.length],
                          radius: 40,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ticket Legend
          Wrap(
            spacing: 12,
            children: _ticketCategories.entries.map((e) {
              final index = _ticketCategories.keys.toList().indexOf(e.key);
              final color = Colors.primaries[index % Colors.primaries.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: color),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value})',
                      style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // --- 4. SUBSCRIPTION BREAKDOWN ---
          Text('Subscription Tiers',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: _buildTierSections(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _tierBreakdown.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getTierColor(e.key),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text('${e.value}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildTierSections() {
    final total = _tierBreakdown.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(value: 1, title: '', color: Colors.grey, radius: 35)
      ];
    }
    return _tierBreakdown.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '',
        color: _getTierColor(e.key),
        radius: 35,
      );
    }).toList();
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Economy':
        return Colors.grey;
      case 'Pro':
        return Colors.blue;
      case 'Advance':
        return Colors.purple;
      case 'Plus':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color borderColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color borderColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value.toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color cardColor;
  final Color borderColor;

  const _ChartCard(
      {required this.title,
      required this.child,
      required this.cardColor,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
