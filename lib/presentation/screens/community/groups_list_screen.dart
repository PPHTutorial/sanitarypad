import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/group_model.dart';
import '../../../services/group_service.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  final String category; // 'pregnancy', 'fertility', 'skincare', 'all'

  const GroupsListScreen({
    super.key,
    this.category = 'all',
  });

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  final _groupService = GroupService();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final groupsStream = widget.category == 'all'
        ? _groupService.getAllPublicGroups()
        : _groupService.getGroupsByCategory(widget.category);

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.category == 'all'
                ? 'All Groups'
                : '${widget.category[0].toUpperCase()}${widget.category.substring(1)} Groups',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push(
                '/groups/create',
                extra: widget.category == 'all' ? null : widget.category,
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<GroupModel>>(
          stream: groupsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final groups = snapshot.data ?? [];

            if (groups.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'No groups yet',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      'Be the first to create a group!',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    ResponsiveConfig.heightBox(24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/groups/create',
                          extra: widget.category == 'all'
                              ? null
                              : widget.category),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Group'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: ResponsiveConfig.padding(all: 16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  margin: ResponsiveConfig.margin(bottom: 12),
                  child: ListTile(
                    contentPadding: ResponsiveConfig.padding(all: 16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
                      child: Icon(
                        Icons.groups,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                    title: Text(
                      group.name,
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        weight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveConfig.heightBox(4),
                        Text(
                          group.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        ResponsiveConfig.heightBox(8),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 16,
                              color: AppTheme.mediumGray,
                            ),
                            ResponsiveConfig.widthBox(4),
                            Text(
                              '${group.memberCount} members',
                              style: ResponsiveConfig.textStyle(
                                size: 12,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () => context.push('/groups/${group.id}'),
                    ),
                    onTap: () => context.push('/groups/${group.id}'),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(
            '/groups/create',
            extra: widget.category == 'all' ? null : widget.category,
          ),
          icon: const Icon(Icons.add),
          label: const Text('Create Group'),
        ),
      ),
    );
  }
}
