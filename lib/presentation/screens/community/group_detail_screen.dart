import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/responsive_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/group_message_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/user_model.dart';
import '../../../services/event_service.dart';
import '../../../services/group_message_service.dart';
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

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final _groupService = GroupService();
  final _messageService = GroupMessageService();
  final _eventService = EventService();
  late TabController _tabController;
  bool _isProcessingMembership = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: StreamBuilder<GroupModel?>(
        stream: _groupService.watchGroup(widget.groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Group Details'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups, size: 64, color: Colors.redAccent),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'Group not found',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      'This group might have been deleted or is no longer available.',
                      textAlign: TextAlign.center,
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    ResponsiveConfig.heightBox(20),
                    ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final group = snapshot.data!;
          final isOwner = group.adminId == user.userId;

          return StreamBuilder<bool>(
            stream: _groupService.isMemberStream(widget.groupId, user.userId),
            builder: (context, memberSnapshot) {
              final isMember =
                  memberSnapshot.data ?? (group.adminId == user.userId);

              return Scaffold(
                appBar: AppBar(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name),
                      Text(
                        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'} • ${group.isPublic ? 'Public' : 'Private'}',
                        style: ResponsiveConfig.textStyle(
                          size: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    if (isOwner)
                      IconButton(
                        icon: const Icon(Icons.edit_note_outlined),
                        tooltip: 'Edit group (coming soon)',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Group editing is coming soon. Hang tight!',
                              ),
                            ),
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'Group info',
                      onPressed: () => _showGroupInfoSheet(context, group),
                    ),
                  ],
                  bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                          text: 'Overview',
                          icon: Icon(Icons.dashboard_outlined)),
                      Tab(text: 'Discussion', icon: Icon(Icons.forum_outlined)),
                      Tab(
                          text: 'Events',
                          icon: Icon(Icons.event_available_outlined)),
                    ],
                  ),
                ),
                floatingActionButton: isMember
                    ? FloatingActionButton.extended(
                        onPressed: () =>
                            _showQuickActions(context, group, isOwner),
                        icon: const Icon(Icons.bolt),
                        label: const Text('Quick actions'),
                      )
                    : null,
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _OverviewTab(
                      group: group,
                      isMember: isMember,
                      isOwner: isOwner,
                      onJoinPressed: () =>
                          _toggleMembership(context, user, isMember),
                      groupService: _groupService,
                      eventService: _eventService,
                    ),
                    _DiscussionTab(
                      group: group,
                      isMember: isMember,
                      onOpenChat: () => context.push(
                        '/groups/${group.id}/chat',
                        extra: group.name,
                      ),
                      messageService: _messageService,
                    ),
                    _EventsTab(
                      group: group,
                      isOwner: isOwner,
                      eventService: _eventService,
                      onCreateEvent: () => context.push(
                        '/events/create',
                        extra: {
                          'category': group.category,
                          'groupId': group.id,
                          'groupName': group.name,
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleMembership(
    BuildContext context,
    UserModel user,
    bool isMember,
  ) async {
    if (_isProcessingMembership) return;
    setState(() => _isProcessingMembership = true);
    try {
      if (isMember) {
        await _groupService.leaveGroup(widget.groupId, user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You left the group.')),
          );
        }
      } else {
        await _groupService.joinGroup(widget.groupId, user.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Welcome! You joined the group.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingMembership = false);
      }
    }
  }

  void _showQuickActions(
    BuildContext context,
    GroupModel group,
    bool isOwner,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  'Group quick actions',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(16),
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('Open full discussion'),
                  subtitle: const Text('Chat, share wins, ask questions'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/groups/${group.id}/chat', extra: group.name);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.groups_2_outlined),
                  title: const Text('View members'),
                  subtitle: const Text('See who else is here and connect'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMembersSheet(context, group.id!);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('View upcoming events'),
                  subtitle: const Text('Workshops, meetups, challenges'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _tabController.animateTo(2);
                  },
                ),
                if (isOwner)
                  ListTile(
                    leading: const Icon(Icons.add_alert_outlined),
                    title: const Text('Create group event'),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/events/create', extra: {
                        'category': group.category,
                        'groupId': group.id,
                        'groupName': group.name,
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGroupInfoSheet(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  group.name,
                  style: ResponsiveConfig.textStyle(
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.widthBox(8),
                    Text(
                      'Created by • ${group.createdBy}',
                      style: ResponsiveConfig.textStyle(
                        size: 13,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.widthBox(8),
                    Text(
                      'Created on • ${DateFormat('MMM d, y').format(group.createdAt)}',
                      style: ResponsiveConfig.textStyle(
                        size: 13,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(16),
                Text(
                  group.description,
                  style: ResponsiveConfig.textStyle(size: 14),
                ),
                ResponsiveConfig.heightBox(16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text(group.category.toUpperCase()),
                    ),
                    Chip(
                      avatar: Icon(
                        group.isPublic
                            ? Icons.lock_open_outlined
                            : Icons.lock_outline,
                        size: 16,
                      ),
                      label: Text(group.isPublic
                          ? 'Public community'
                          : 'Private community'),
                    ),
                    if (group.tags.isNotEmpty)
                      ...group.tags.map((tag) => Chip(label: Text('#$tag'))),
                  ],
                ),
                ResponsiveConfig.heightBox(8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMembersSheet(BuildContext context, String groupId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: _MembersList(groupId: groupId, groupService: _groupService),
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.group,
    required this.isMember,
    required this.isOwner,
    required this.onJoinPressed,
    required this.groupService,
    required this.eventService,
  });

  final GroupModel group;
  final bool isMember;
  final bool isOwner;
  final VoidCallback onJoinPressed;
  final GroupService groupService;
  final EventService eventService;

  @override
  Widget build(BuildContext context) {
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
                        radius: 36,
                        backgroundColor: AppTheme.primaryPink.withOpacity(0.12),
                        child: Icon(
                          Icons.groups,
                          size: 32,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                      ResponsiveConfig.widthBox(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: ResponsiveConfig.textStyle(
                                size: 20,
                                weight: FontWeight.bold,
                              ),
                            ),
                            ResponsiveConfig.heightBox(6),
                            Wrap(
                              spacing: 8,
                              children: [
                                _BadgeChip(
                                  icon: Icons.people_outline,
                                  label:
                                      '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                                ),
                                _BadgeChip(
                                  icon: group.isPublic
                                      ? Icons.lock_open_outlined
                                      : Icons.lock_outline,
                                  label: group.isPublic ? 'Public' : 'Private',
                                ),
                                _BadgeChip(
                                  icon: Icons.calendar_month_outlined,
                                  label:
                                      'Since ${DateFormat('MMM y').format(group.createdAt)}',
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
                      children: group.tags
                          .map((tag) => Chip(label: Text('#$tag')))
                          .toList(),
                    ),
                  ],
                  ResponsiveConfig.heightBox(20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onJoinPressed,
                      icon: Icon(
                          isMember ? Icons.logout : Icons.person_add_alt_1),
                      label: Text(
                          isMember ? 'Leave community' : 'Join this community'),
                    ),
                  ),
                  if (!isMember)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Join to post, react, attend events, and meet other members.',
                        style: ResponsiveConfig.textStyle(
                          size: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ResponsiveConfig.heightBox(16),
          _SectionHeader(
            title: 'Featured members',
            actionLabel: 'See all',
            onAction: () => _openMembersSheet(context, group.id!, groupService),
          ),
          ResponsiveConfig.heightBox(8),
          _MembersPreview(groupId: group.id!, groupService: groupService),
          ResponsiveConfig.heightBox(24),
          _SectionHeader(
            title: 'Upcoming happenings',
            actionLabel: 'View calendar',
            onAction: () {
              final TabController? controller =
                  DefaultTabController.of(context);
              if (controller != null) {
                controller.animateTo(2);
              }
            },
          ),
          ResponsiveConfig.heightBox(8),
          _GroupEventsPreview(
            groupId: group.id!,
            eventService: eventService,
            isOwner: isOwner,
          ),
        ],
      ),
    );
  }

  void _openMembersSheet(
    BuildContext context,
    String groupId,
    GroupService groupService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: _MembersList(groupId: groupId, groupService: groupService),
          ),
        );
      },
    );
  }
}

class _DiscussionTab extends StatelessWidget {
  const _DiscussionTab({
    required this.group,
    required this.isMember,
    required this.onOpenChat,
    required this.messageService,
  });

  final GroupModel group;
  final bool isMember;
  final VoidCallback onOpenChat;
  final GroupMessageService messageService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<GroupMessage>>(
            stream: messageService.streamMessages(group.id!, limit: 30),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return Padding(
                  padding: ResponsiveConfig.padding(all: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 72,
                        color: AppTheme.primaryPink.withOpacity(0.35),
                      ),
                      ResponsiveConfig.heightBox(16),
                      Text(
                        'Conversations will appear here',
                        style: ResponsiveConfig.textStyle(
                          size: 18,
                          weight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveConfig.heightBox(8),
                      Text(
                        isMember
                            ? 'Say hi and kick off the first discussion!'
                            : 'Join the community to start chatting with others.',
                        textAlign: TextAlign.center,
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: ResponsiveConfig.padding(all: 16),
                itemCount: messages.length.clamp(0, 15),
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _MessagePreviewTile(message: message);
                },
              );
            },
          ),
        ),
        Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: ElevatedButton.icon(
            onPressed: onOpenChat,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(isMember ? 'Open discussion' : 'Join to participate'),
          ),
        ),
      ],
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.group,
    required this.isOwner,
    required this.eventService,
    required this.onCreateEvent,
  });

  final GroupModel group;
  final bool isOwner;
  final EventService eventService;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<EventModel>>(
            stream: eventService.getEventsForGroup(group.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return Padding(
                  padding: ResponsiveConfig.padding(all: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 72,
                        color: AppTheme.primaryPink.withOpacity(0.3),
                      ),
                      ResponsiveConfig.heightBox(16),
                      Text(
                        'No upcoming events yet',
                        style: ResponsiveConfig.textStyle(
                          size: 18,
                          weight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveConfig.heightBox(8),
                      Text(
                        isOwner
                            ? 'Plan a workshop, circle, or meetup for the community.'
                            : 'Check back soon, or ask the admin to plan something fun!',
                        textAlign: TextAlign.center,
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: ResponsiveConfig.padding(all: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _EventTile(event: event);
                },
              );
            },
          ),
        ),
        if (isOwner)
          Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: ElevatedButton.icon(
              onPressed: onCreateEvent,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create group event'),
            ),
          ),
      ],
    );
  }
}

class _MembersPreview extends StatelessWidget {
  const _MembersPreview({
    required this.groupId,
    required this.groupService,
  });

  final String groupId;
  final GroupService groupService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupMember>>(
      stream: groupService.streamGroupMembers(groupId),
      builder: (context, snapshot) {
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return Card(
            child: Padding(
              padding: ResponsiveConfig.padding(all: 16),
              child: Text(
                'Members will appear here once the community grows.',
                style: ResponsiveConfig.textStyle(
                  size: 13,
                  color: AppTheme.mediumGray,
                ),
              ),
            ),
          );
        }

        final displayMembers = members.take(6).toList();

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: displayMembers
              .map(
                (member) => _MemberAvatar(userId: member.userId),
              )
              .toList(),
        );
      },
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({
    required this.groupId,
    required this.groupService,
  });

  final String groupId;
  final GroupService groupService;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return SizedBox(
      height: maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.mediumGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Text(
            'Community members',
            style: ResponsiveConfig.textStyle(
              size: 18,
              weight: FontWeight.bold,
            ),
          ),
          ResponsiveConfig.heightBox(16),
          Expanded(
            child: StreamBuilder<List<GroupMember>>(
              stream: groupService.streamGroupMembers(groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return Center(
                    child: Text(
                      'No members yet. Invite friends to join!',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      leading: _MemberAvatar(userId: member.userId),
                      title: _MemberName(userId: member.userId),
                      subtitle: Text(
                        member.role == 'admin' ? 'Community admin' : 'Member',
                        style: ResponsiveConfig.textStyle(
                          size: 13,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      trailing: Text(
                        DateFormat('MMM d, y').format(member.joinedAt),
                        style: ResponsiveConfig.textStyle(
                          size: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupEventsPreview extends StatelessWidget {
  const _GroupEventsPreview({
    required this.groupId,
    required this.eventService,
    required this.isOwner,
  });

  final String groupId;
  final EventService eventService;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: eventService.getEventsForGroup(groupId),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return Card(
            child: Padding(
              padding: ResponsiveConfig.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No upcoming events yet',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      weight: FontWeight.w600,
                    ),
                  ),
                  ResponsiveConfig.heightBox(4),
                  Text(
                    isOwner
                        ? 'Create your first event to bring members together.'
                        : 'Ask the host to plan an event or meetup.',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children:
              events.take(3).map((event) => _EventTile(event: event)).toList(),
        );
      },
    );
  }
}

class _MessagePreviewTile extends StatelessWidget {
  const _MessagePreviewTile({required this.message});

  final GroupMessage message;

  @override
  Widget build(BuildContext context) {
    final preview = message.isDeleted
        ? 'Message removed'
        : (message.text?.isNotEmpty == true
            ? message.text!
            : message.attachments.isNotEmpty
                ? '[${message.attachments.first.type.toUpperCase()} attachment]'
                : '');

    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPink.withOpacity(0.12),
          child: const Icon(Icons.person_outline, color: AppTheme.primaryPink),
        ),
        title: Text(
          message.senderName,
          style: ResponsiveConfig.textStyle(
            size: 14,
            weight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveConfig.heightBox(4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ResponsiveConfig.textStyle(size: 13),
            ),
            ResponsiveConfig.heightBox(6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppTheme.mediumGray),
                ResponsiveConfig.widthBox(4),
                Text(
                  DateFormat('MMM d • h:mm a').format(message.sentAt),
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
                if (message.reactions.isNotEmpty) ...[
                  ResponsiveConfig.widthBox(12),
                  Icon(Icons.favorite, size: 14, color: AppTheme.primaryPink),
                  ResponsiveConfig.widthBox(4),
                  Text(
                    message.reactions.values
                        .fold<int>(0, (prev, list) => prev + list.length)
                        .toString(),
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: ListTile(
        contentPadding: ResponsiveConfig.padding(all: 16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
          child: const Icon(Icons.event_outlined, color: AppTheme.primaryPink),
        ),
        title: Text(
          event.title,
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
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ResponsiveConfig.textStyle(
                size: 13,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(6),
            Row(
              children: [
                Icon(Icons.calendar_month,
                    size: 14, color: AppTheme.mediumGray),
                ResponsiveConfig.widthBox(4),
                Text(
                  DateFormat('EEE, MMM d • h:mm a').format(event.startDate),
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.mediumGray),
                    ResponsiveConfig.widthBox(4),
                    Flexible(
                      child: Text(
                        event.location!,
                        style: ResponsiveConfig.textStyle(
                          size: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberAvatar extends ConsumerWidget {
  const _MemberAvatar({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserModel?>(
      future: ref.read(currentUserStreamProvider.future).then((value) {
        // If the requested user is the current user, return directly
        if (value != null && value.userId == userId) {
          return value;
        }
        return _fetchUser(userId);
      }),
      builder: (context, snapshot) {
        final initials = _initials(snapshot.data?.displayName ?? userId);
        return CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryPink.withOpacity(0.12),
          child: Text(
            initials,
            style: ResponsiveConfig.textStyle(
              size: 16,
              weight: FontWeight.bold,
              color: AppTheme.primaryPink,
            ),
          ),
        );
      },
    );
  }

  Future<UserModel?> _fetchUser(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  String _initials(String value) {
    final parts = value.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _MemberName extends StatelessWidget {
  const _MemberName({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            userId,
            style: ResponsiveConfig.textStyle(size: 14),
          );
        }
        final user = UserModel.fromFirestore(snapshot.data!);
        return Text(
          user.displayName ?? user.email,
          style: ResponsiveConfig.textStyle(size: 14, weight: FontWeight.w600),
        );
      },
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryPink),
      backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
      label: Text(
        label,
        style:
            ResponsiveConfig.textStyle(size: 12, color: AppTheme.primaryPink),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.w700,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
