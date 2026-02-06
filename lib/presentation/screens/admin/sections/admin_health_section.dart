import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AdminHealthSection extends ConsumerStatefulWidget {
  const AdminHealthSection({super.key});

  @override
  ConsumerState<AdminHealthSection> createState() => _AdminHealthSectionState();
}

class _AdminHealthSectionState extends ConsumerState<AdminHealthSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stats
  int _totalCycles = 0;
  int _activePregnancies = 0;
  int _fertilityEntries = 0;
  int _skincareEntries = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final results = await Future.wait([
        db.collection('cycles').count().get(),
        db
            .collection('pregnancies')
            .where('isActive', isEqualTo: true)
            .count()
            .get(),
        db.collection('fertilityEntries').count().get(),
        db.collection('skincareEntries').count().get(),
      ]);
      if (mounted) {
        setState(() {
          _totalCycles = results[0].count ?? 0;
          _activePregnancies = results[1].count ?? 0;
          _fertilityEntries = results[2].count ?? 0;
          _skincareEntries = results[3].count ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching health stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Column(
      children: [
        // Stats Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStat(
                  label: 'Cycles',
                  value: _totalCycles,
                  color: Colors.pink,
                  isLoading: _isLoading),
              _QuickStat(
                  label: 'Pregnancies',
                  value: _activePregnancies,
                  color: Colors.purple,
                  isLoading: _isLoading),
              _QuickStat(
                  label: 'Fertility',
                  value: _fertilityEntries,
                  color: Colors.orange,
                  isLoading: _isLoading),
              _QuickStat(
                  label: 'Skincare',
                  value: _skincareEntries,
                  color: Colors.teal,
                  isLoading: _isLoading),
            ],
          ),
        ),
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Cycles'),
            Tab(text: 'Pregnancy'),
            Tab(text: 'Fertility'),
            Tab(text: 'Skincare'),
          ],
        ),
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _HealthListView(
                  collection: 'cycles',
                  titleField: 'startDate',
                  cardColor: cardColor,
                  borderColor: borderColor),
              _HealthListView(
                  collection: 'pregnancies',
                  titleField: 'dueDate',
                  cardColor: cardColor,
                  borderColor: borderColor),
              _HealthListView(
                  collection: 'fertilityEntries',
                  titleField: 'date',
                  cardColor: cardColor,
                  borderColor: borderColor),
              _HealthListView(
                  collection: 'skincareEntries',
                  titleField: 'date',
                  cardColor: cardColor,
                  borderColor: borderColor),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool isLoading;

  const _QuickStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text(
                value.toString(),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _HealthListView extends StatelessWidget {
  final String collection;
  final String titleField;
  final Color cardColor;
  final Color borderColor;

  const _HealthListView(
      {required this.collection,
      required this.titleField,
      required this.cardColor,
      required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy(titleField, descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No $collection data found.'));
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] ?? 'N/A';
            final dateRaw = data[titleField];
            String dateStr = 'N/A';
            if (dateRaw is Timestamp) {
              dateStr = DateFormat.yMMMd().format(dateRaw.toDate());
            }

            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor),
              ),
              child: ListTile(
                leading:
                    Icon(_getIcon(collection), color: _getColor(collection)),
                title: Text('Entry: $dateStr'),
                subtitle: Text('User: ${userId.toString().substring(0, 8)}...'),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, doc.reference),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIcon(String collection) {
    switch (collection) {
      case 'cycles':
        return FontAwesomeIcons.droplet;
      case 'pregnancies':
        return FontAwesomeIcons.baby;
      case 'fertilityEntries':
        return FontAwesomeIcons.chartLine;
      case 'skincareEntries':
        return FontAwesomeIcons.faceGrin;
      default:
        return FontAwesomeIcons.database;
    }
  }

  Color _getColor(String collection) {
    switch (collection) {
      case 'cycles':
        return Colors.pink;
      case 'pregnancies':
        return Colors.purple;
      case 'fertilityEntries':
        return Colors.orange;
      case 'skincareEntries':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
