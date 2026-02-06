import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/core/constants/app_constants.dart';
import 'package:sanitarypad/data/models/user_model.dart';

class AdminUsersSection extends ConsumerStatefulWidget {
  const AdminUsersSection({super.key});

  @override
  ConsumerState<AdminUsersSection> createState() => _AdminUsersSectionState();
}

class _AdminUsersSectionState extends ConsumerState<AdminUsersSection> {
  final TextEditingController _searchController = TextEditingController();
  final int _limit = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  List<UserModel> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers({bool isRefresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (isRefresh) {
        _users.clear();
        _lastDocument = null;
        _hasMore = true;
      }

      Query query = FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      // Note: Firestore search is limited. Use a proper search service like Algolia for production.
      // Here we implement basic client-side filtering logic if query is short, or precise backend query if simple.
      // But for "User Management", "orderBy createdAt" is standard standard default.

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final newUsers = snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) {
          if (_searchQuery.isEmpty) return true;
          return (user.email
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (user.displayName ?? '')
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));
        }).toList();

        // If we filtered out everything but fetched query had docs, we might need to fetch more recursively
        // ignoring that complexity for MVP

        setState(() {
          _users.addAll(newUsers);
          if (snapshot.docs.length < _limit) _hasMore = false;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    // Trigger refresh to apply filter (limited effectiveness in Firestore without dedicated index/service)
    // For now, we will perform client side filtering on the fetched batch or reset.
    // Ideally, for Admin, searching by exact email is most common.
    if (query.isNotEmpty) {
      _performSearch(query);
    } else {
      _fetchUsers(isRefresh: true);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _users.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThan: query + 'z')
          .limit(_limit)
          .get();

      final newUsers =
          snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      setState(() {
        _users = newUsers;
        _hasMore = false; // Search results are finite usually
      });
    } catch (e) {
      // Fallback or ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
                labelText: 'Search Users (Email)',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )),
            onSubmitted: _onSearchChanged,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchUsers(isRefresh: true),
            child: ListView.builder(
              itemCount: _users.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  return _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TextButton(
                          onPressed: () => _fetchUsers(),
                          child: const Text('Load More'),
                        );
                }

                final user = _users[index];
                return _UserListTile(user: user);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserModel user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = user.subscription.tier != AppConstants.tierEconomy
        ? Colors.green
        : Colors.grey;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null ? Text(user.email[0].toUpperCase()) : null,
      ),
      title: Text(user.displayName ?? user.email,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          Text(
            'Joined: ${DateFormat.yMMMd().format(user.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              user.subscription.tier.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (user.isAdmin)
            const Text('ADMIN',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
        ],
      ),
      onTap: () => _showUserDetailSheet(context, user),
    );
  }

  void _showUserDetailSheet(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Avatar & Name
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(user.email[0].toUpperCase(),
                                style: const TextStyle(fontSize: 24))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.displayName ?? 'No Name',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(user.email,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Details Grid
                  _DetailRow(label: 'User ID', value: user.userId),
                  _DetailRow(label: 'Role', value: user.role),
                  _DetailRow(label: 'Tier', value: user.subscription.tier),
                  _DetailRow(
                      label: 'Credits',
                      value: user.subscription.dailyCreditsRemaining
                          .toStringAsFixed(1)),
                  _DetailRow(
                      label: 'Joined',
                      value: DateFormat.yMMMd().format(user.createdAt)),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Actions
                  Text('Actions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings,
                        color: Colors.orange),
                    title: const Text('Toggle Admin Role'),
                    subtitle:
                        Text(user.isAdmin ? 'Revoke Admin' : 'Grant Admin'),
                    onTap: () => _toggleRole(context, user),
                  ),
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blue),
                    title: const Text('Reset Credits'),
                    subtitle: const Text('Reset to tier default'),
                    onTap: () => _resetCredits(context, user),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete User',
                        style: TextStyle(color: Colors.red)),
                    subtitle: const Text('Permanently remove this account'),
                    onTap: () => _confirmDeleteUser(context, user),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleRole(BuildContext context, UserModel user) async {
    Navigator.pop(context);
    final newRole = user.isAdmin ? 'user' : 'admin';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.userId)
        .update({'role': newRole});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Role updated to $newRole')));
  }

  void _resetCredits(BuildContext context, UserModel user) async {
    Navigator.pop(context);
    double defaultCredits = AppConstants.creditsDefault;
    if (user.subscription.tier == AppConstants.tierPremiumPro)
      defaultCredits = AppConstants.creditsPro;
    if (user.subscription.tier == AppConstants.tierPremiumAdvance)
      defaultCredits = AppConstants.creditsAdv;
    if (user.subscription.tier == AppConstants.tierPremiumPlus)
      defaultCredits = AppConstants.creditsPlus;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.userId)
        .update({
      'subscription.credits': defaultCredits,
      'subscription.lastCreditReset': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Credits reset to ${defaultCredits.toInt()}')));
  }

  void _confirmDeleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
            'This will permanently delete ${user.email}. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close sheet
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.userId)
                  .delete();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('User deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
