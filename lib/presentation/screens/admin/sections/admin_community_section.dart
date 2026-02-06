import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AdminCommunitySection extends ConsumerStatefulWidget {
  const AdminCommunitySection({super.key});

  @override
  ConsumerState<AdminCommunitySection> createState() =>
      _AdminCommunitySectionState();
}

class _AdminCommunitySectionState extends ConsumerState<AdminCommunitySection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _totalGroups = 0;
  int _totalEvents = 0;
  int _totalMessages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        db.collection('groups').count().get(),
        db.collection('events').count().get(),
        db.collection('groupMessages').count().get(),
      ]);
      if (mounted) {
        setState(() {
          _totalGroups = results[0].count ?? 0;
          _totalEvents = results[1].count ?? 0;
          _totalMessages = results[2].count ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching community stats: $e');
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
                  label: 'Groups',
                  value: _totalGroups,
                  color: Colors.indigo,
                  isLoading: _isLoading),
              _QuickStat(
                  label: 'Events',
                  value: _totalEvents,
                  color: Colors.blue,
                  isLoading: _isLoading),
              _QuickStat(
                  label: 'Messages',
                  value: _totalMessages,
                  color: Colors.cyan,
                  isLoading: _isLoading),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Groups'),
            Tab(text: 'Events'),
            Tab(text: 'Messages'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _EntityListView(
                  collection: 'groups',
                  titleField: 'name',
                  subtitleField: 'description',
                  icon: FontAwesomeIcons.usersRectangle,
                  color: Colors.indigo,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _EntityListView(
                  collection: 'events',
                  titleField: 'title',
                  subtitleField: 'description',
                  icon: FontAwesomeIcons.calendarDay,
                  color: Colors.blue,
                  cardColor: cardColor,
                  borderColor: borderColor),
              _MessagesListView(cardColor: cardColor, borderColor: borderColor),
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
            : Text(value.toString(),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _EntityListView extends StatelessWidget {
  final String collection;
  final String titleField;
  final String subtitleField;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color borderColor;

  const _EntityListView({
    required this.collection,
    required this.titleField,
    required this.subtitleField,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No $collection found.'));
        }
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data[titleField] ?? 'Untitled';
            final subtitle = data[subtitleField] ?? '';

            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor)),
              child: ListTile(
                leading: Icon(icon, color: color),
                title:
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () =>
                      _confirmDelete(context, doc.reference, collection),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, DocumentReference ref, String type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $type?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$type deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MessagesListView extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;

  const _MessagesListView({required this.cardColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groupMessages')
          .orderBy('sentAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No messages found.'));
        }
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final text = data['text'] ?? '';
            final sentAt = data['sentAt'] is Timestamp
                ? DateFormat.yMMMd()
                    .add_jm()
                    .format((data['sentAt'] as Timestamp).toDate())
                : 'N/A';

            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor)),
              child: ListTile(
                leading:
                    const Icon(FontAwesomeIcons.message, color: Colors.cyan),
                title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(sentAt),
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

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This will remove the message for all users.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
