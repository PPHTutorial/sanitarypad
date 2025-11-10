import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/group_model.dart';
import '../../../services/group_service.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _groupService = GroupService();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Details'),
        ),
        body: FutureBuilder<GroupModel?>(
          future: _groupService.getGroup(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'Group not found',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final group = snapshot.data!;

            return FutureBuilder<bool>(
              future: _groupService.isMember(widget.groupId, user.userId),
              builder: (context, memberSnapshot) {
                final isMember = memberSnapshot.data ?? false;

                return SingleChildScrollView(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: ResponsiveConfig.padding(all: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor:
                                        AppTheme.primaryPink.withOpacity(0.1),
                                    child: Icon(
                                      Icons.groups,
                                      size: 32,
                                      color: AppTheme.primaryPink,
                                    ),
                                  ),
                                  ResponsiveConfig.widthBox(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.name,
                                          style: ResponsiveConfig.textStyle(
                                            size: 20,
                                            weight: FontWeight.bold,
                                          ),
                                        ),
                                        ResponsiveConfig.heightBox(4),
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
                                                size: 14,
                                                color: AppTheme.mediumGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveConfig.heightBox(16),
                              Text(
                                group.description,
                                style: ResponsiveConfig.textStyle(size: 14),
                              ),
                              if (group.tags.isNotEmpty) ...[
                                ResponsiveConfig.heightBox(16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: group.tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      backgroundColor:
                                          AppTheme.primaryPink.withOpacity(0.1),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isJoining
                              ? null
                              : () async {
                                  setState(() => _isJoining = true);
                                  try {
                                    if (isMember) {
                                      await _groupService.leaveGroup(
                                        widget.groupId,
                                        user.userId,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Left group successfully'),
                                          ),
                                        );
                                        setState(() {});
                                      }
                                    } else {
                                      await _groupService.joinGroup(
                                        widget.groupId,
                                        user.userId,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Joined group successfully'),
                                          ),
                                        );
                                        setState(() {});
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isJoining = false);
                                    }
                                  }
                                },
                          icon: Icon(
                              isMember ? Icons.exit_to_app : Icons.person_add),
                          label: Text(_isJoining
                              ? 'Processing...'
                              : isMember
                                  ? 'Leave Group'
                                  : 'Join Group'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
