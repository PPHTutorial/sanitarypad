import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class AdminContentSection extends ConsumerStatefulWidget {
  const AdminContentSection({super.key});

  @override
  ConsumerState<AdminContentSection> createState() =>
      _AdminContentSectionState();
}

class _AdminContentSectionState extends ConsumerState<AdminContentSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _wellnessCount = 0;
  int _aiChatCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        db.collection('wellnessContent').count().get(),
        db.collection('aiChatMessages').count().get(),
      ]);
      if (mounted) {
        setState(() {
          _wellnessCount = results[0].count ?? 0;
          _aiChatCount = results[1].count ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching content stats: $e');
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
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickStat(
                  label: 'Content Items',
                  value: _wellnessCount,
                  color: Colors.green,
                  isLoading: _isLoading),
              _QuickStat(
                  label: 'AI Messages',
                  value: _aiChatCount,
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
            Tab(text: 'Wellness Content'),
            Tab(text: 'AI Chat Logs'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _WellnessContentTab(
                  cardColor: cardColor, borderColor: borderColor),
              _AIChatLogsTab(cardColor: cardColor, borderColor: borderColor),
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

class _WellnessContentTab extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;

  const _WellnessContentTab(
      {required this.cardColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add New Content'),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('wellnessContent')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No wellness content found. Add some!'));
              }
              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Untitled';
                  final type = data['type'] ?? 'tip';

                  return Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor)),
                    child: ListTile(
                      leading: Icon(_getTypeIcon(type), color: Colors.green),
                      title: Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Type: $type'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.blue),
                              onPressed: () => _showEditDialog(context, doc)),
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _confirmDelete(context, doc.reference)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'tip':
        return FontAwesomeIcons.lightbulb;
      case 'article':
        return FontAwesomeIcons.newspaper;
      case 'meditation':
        return FontAwesomeIcons.spa;
      case 'affirmation':
        return FontAwesomeIcons.heart;
      default:
        return FontAwesomeIcons.bookOpen;
    }
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String type = 'tip';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Wellness Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 4),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'tip', child: Text('Tip')),
                  DropdownMenuItem(value: 'article', child: Text('Article')),
                  DropdownMenuItem(
                      value: 'meditation', child: Text('Meditation')),
                  DropdownMenuItem(
                      value: 'affirmation', child: Text('Affirmation')),
                ],
                onChanged: (val) => type = val ?? 'tip',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('wellnessContent')
                  .add({
                'title': titleController.text,
                'content': contentController.text,
                'type': type,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content created!')));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title']);
    final contentController = TextEditingController(text: data['content']);
    String type = data['type'] ?? 'tip';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Wellness Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Content'),
                  maxLines: 4),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'tip', child: Text('Tip')),
                  DropdownMenuItem(value: 'article', child: Text('Article')),
                  DropdownMenuItem(
                      value: 'meditation', child: Text('Meditation')),
                  DropdownMenuItem(
                      value: 'affirmation', child: Text('Affirmation')),
                ],
                onChanged: (val) => type = val ?? 'tip',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await doc.reference.update({
                'title': titleController.text,
                'content': contentController.text,
                'type': type,
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content updated!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Content?'),
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

class _AIChatLogsTab extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;

  const _AIChatLogsTab({required this.cardColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('aiChatMessages')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No AI chat logs found.'));
        }
        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final content = data['content'] ?? data['message'] ?? '';
            final role = data['role'] ?? 'user';
            final timestamp = data['timestamp'] is Timestamp
                ? DateFormat.yMMMd()
                    .add_jm()
                    .format((data['timestamp'] as Timestamp).toDate())
                : 'N/A';

            return Card(
              color: cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor)),
              child: ListTile(
                leading: Icon(
                    role == 'user'
                        ? FontAwesomeIcons.user
                        : FontAwesomeIcons.robot,
                    color: role == 'user' ? Colors.blue : Colors.cyan),
                title:
                    Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('$role • $timestamp'),
              ),
            );
          },
        );
      },
    );
  }
}
