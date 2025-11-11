import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/group_message_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/user_model.dart';
import '../../../services/group_message_service.dart';
import '../../../services/group_service.dart';
import '../../../services/storage_service.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _messageService = GroupMessageService();
  final _groupService = GroupService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();

  GroupMessage? _replyTo;
  bool _isSending = false;
  bool _showScrollToBottom = false;

  final List<_PendingAttachment> _pendingAttachments = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow =
        _scrollController.offset > 400 && !_scrollController.position.atEdge;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
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
      fallbackRoute: '/groups',
      child: StreamBuilder<GroupModel?>(
        stream: _groupService.watchGroup(widget.groupId),
        builder: (context, groupSnapshot) {
          final group = groupSnapshot.data;
          final title = group?.name ?? widget.groupName ?? 'Community chat';

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    group?.category ?? '',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: group == null
                      ? null
                      : () => context.push('/groups/${widget.groupId}'),
                ),
              ],
            ),
            body: StreamBuilder<bool>(
              stream: _groupService.isMemberStream(widget.groupId, user.userId),
              builder: (context, membershipSnapshot) {
                final isMember = membershipSnapshot.data ??
                    (group != null && group.adminId == user.userId);

                if (!isMember) {
                  return _JoinGroupPrompt(
                    groupName: title,
                    onJoin: () =>
                        _handleJoinGroup(context: context, user: user),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<GroupMessage>>(
                        stream: _messageService.streamMessages(
                          widget.groupId,
                          limit: 200,
                        ),
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? [];
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              messages.isEmpty) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (messages.isEmpty) {
                            return _EmptyChatState(onStartConversation: () {
                              _inputFocusNode.requestFocus();
                            });
                          }

                          final orderedMessages =
                              List<GroupMessage>.from(messages);
                          orderedMessages.sort(
                            (a, b) => b.sentAt.compareTo(a.sentAt),
                          );

                          return Stack(
                            children: [
                              ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: ResponsiveConfig.padding(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: orderedMessages.length,
                                itemBuilder: (context, index) {
                                  final message = orderedMessages[index];
                                  final isOwnMessage =
                                      message.senderId == user.userId;
                                  return _MessageBubble(
                                    message: message,
                                    isOwnMessage: isOwnMessage,
                                    onReply: () =>
                                        setState(() => _replyTo = message),
                                    onReact: (reaction) =>
                                        _handleReaction(message, reaction),
                                    onDelete: isOwnMessage
                                        ? () => _handleDeleteMessage(message)
                                        : null,
                                  );
                                },
                              ),
                              if (_showScrollToBottom)
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: FloatingActionButton.small(
                                    heroTag: 'scroll-bottom',
                                    onPressed: _scrollToBottom,
                                    child: const Icon(Icons.arrow_downward),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    _MessageComposer(
                      controller: _messageController,
                      focusNode: _inputFocusNode,
                      isSending: _isSending,
                      onSend: () => _handleSendMessage(user),
                      onPickImage: _pickImage,
                      attachments: _pendingAttachments,
                      onRemoveAttachment: (attachment) {
                        setState(() {
                          _pendingAttachments.remove(attachment);
                        });
                      },
                      replyTo: _replyTo,
                      onCancelReply: () => setState(() => _replyTo = null),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleJoinGroup({
    required BuildContext context,
    required UserModel user,
  }) async {
    try {
      await _groupService.joinGroup(widget.groupId, user.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome! You can now chat.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join group: $e')),
        );
      }
    }
  }

  Future<void> _handleSendMessage(UserModel user) async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) {
      return;
    }

    setState(() => _isSending = true);

    try {
      final attachments = <MessageAttachment>[];
      for (final attachment in _pendingAttachments) {
        final file = attachment.file;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
        final storagePath = 'groups/${widget.groupId}/${user.userId}/$fileName';
        final uploadResult = await _storageService.uploadFile(
          path: storagePath,
          file: file,
        );
        attachments.add(
          MessageAttachment(
            url: uploadResult.downloadUrl,
            storagePath: uploadResult.storagePath,
            type: attachment.type,
            name: attachment.name,
            size: attachment.size,
            mimeType: attachment.mimeType,
          ),
        );
      }

      await _messageService.sendMessage(
        groupId: widget.groupId,
        senderId: user.userId,
        senderName: user.displayName ?? user.email,
        text: text.isNotEmpty ? text : null,
        attachments: attachments,
        replyToMessageId: _replyTo?.id,
        replyToSender: _replyTo?.senderName,
        replyPreviewText: _replyTo?.text,
      );

      setState(() {
        _messageController.clear();
        _pendingAttachments.clear();
        _replyTo = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;

      for (final xfile in picked.take(6 - _pendingAttachments.length)) {
        final file = File(xfile.path);
        final size = await file.length();
        setState(() {
          _pendingAttachments.add(
            _PendingAttachment(
              file: file,
              type: 'image',
              name: p.basename(file.path),
              size: size,
              mimeType: xfile.mimeType,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to pick image: $e')),
        );
      }
    }
  }

  Future<void> _handleReaction(GroupMessage message, String reaction) async {
    if (message.id == null) return;
    try {
      final user = ref.read(currentUserStreamProvider).value;
      if (user == null) return;
      await _messageService.toggleReaction(
        messageId: message.id!,
        reaction: reaction,
        userId: user.userId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not react: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteMessage(GroupMessage message) async {
    try {
      await _messageService.deleteMessage(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
    required this.onPickImage,
    required this.attachments,
    required this.onRemoveAttachment,
    required this.replyTo,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final List<_PendingAttachment> attachments;
  final ValueChanged<_PendingAttachment> onRemoveAttachment;
  final GroupMessage? replyTo;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: ResponsiveConfig.padding(
            vertical: 12,
            horizontal: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (replyTo != null)
                _ReplyPreview(
                  message: replyTo!,
                  onCancel: onCancelReply,
                ),
              if (attachments.isNotEmpty)
                _AttachmentPreviewRow(
                  attachments: attachments,
                  onRemove: onRemoveAttachment,
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_outlined),
                    onPressed: onPickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Share something supportive…',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                    onPressed: isSending ? null : onSend,
                    color: AppTheme.primaryPink,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwnMessage,
    required this.onReply,
    required this.onReact,
    this.onDelete,
  });

  final GroupMessage message;
  final bool isOwnMessage;
  final VoidCallback onReply;
  final ValueChanged<String> onReact;
  final VoidCallback? onDelete;

  static const _reactions = ['❤️', '👏', '😊', '🔥', '👍'];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isOwnMessage
                ? AppTheme.primaryPink.withOpacity(0.18)
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft:
                  isOwnMessage ? const Radius.circular(18) : Radius.zero,
              bottomRight:
                  isOwnMessage ? Radius.zero : const Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: isOwnMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isOwnMessage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                ),
              if (message.replyToSender != null)
                _QuotedMessage(
                  sender: message.replyToSender!,
                  snippet: message.replyPreviewText ?? '[Attachment]',
                  alignment: isOwnMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                ),
              if (message.text != null && message.text!.trim().isNotEmpty)
                Text(message.text!),
              if (message.attachments.isNotEmpty)
                ...message.attachments.map(
                  (attachment) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _AttachmentTile(attachment: attachment),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(message.sentAt),
                      style: ResponsiveConfig.textStyle(
                        size: 11,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    if (message.reactions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.reactions.entries
                              .map((entry) =>
                                  '${entry.key}${entry.value.length > 1 ? ' ${entry.value.length}' : ''}')
                              .join('  '),
                          style: ResponsiveConfig.textStyle(
                            size: 11,
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
      ),
    );
  }

  Future<void> _showMessageOptions(BuildContext context) async {
    await showModalBottomSheet(
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
                  'Engage with message',
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(16),
                Wrap(
                  spacing: 8,
                  children: _reactions
                      .map(
                        (emoji) => ChoiceChip(
                          label:
                              Text(emoji, style: const TextStyle(fontSize: 20)),
                          selected: false,
                          onSelected: (_) {
                            Navigator.of(context).pop();
                            onReact(emoji);
                          },
                        ),
                      )
                      .toList(),
                ),
                ResponsiveConfig.heightBox(12),
                ListTile(
                  leading: const Icon(Icons.reply_outlined),
                  title: const Text('Reply'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onReply();
                  },
                ),
                if (onDelete != null)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Delete'),
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete!.call();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _FullScreenImage(url: attachment.url),
            ),
          ),
          child: Image.network(
            attachment.url,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => launchUrl(attachment.url),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file_outlined),
            ResponsiveConfig.widthBox(8),
            Expanded(
              child: Text(
                attachment.name ?? attachment.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ResponsiveConfig.textStyle(size: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({
    required this.message,
    required this.onCancel,
  });

  final GroupMessage message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.senderName,
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ),
                Text(
                  message.text?.trim().isNotEmpty == true
                      ? message.text!
                      : '[Attachment]',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ResponsiveConfig.textStyle(size: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreviewRow extends StatelessWidget {
  const _AttachmentPreviewRow({
    required this.attachments,
    required this.onRemove,
  });

  final List<_PendingAttachment> attachments;
  final ValueChanged<_PendingAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  attachment.file,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: InkWell(
                  onTap: () => onRemove(attachment),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JoinGroupPrompt extends StatelessWidget {
  const _JoinGroupPrompt({
    required this.groupName,
    required this.onJoin,
  });

  final String groupName;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 96,
              color: AppTheme.primaryPink.withOpacity(0.35),
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              'Join $groupName',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Become part of the discussion, share experiences, and connect with the community.',
              textAlign: TextAlign.center,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(24),
            ElevatedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Join community'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onStartConversation});

  final VoidCallback onStartConversation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 96,
              color: AppTheme.primaryPink.withOpacity(0.35),
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              'Start the conversation',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Share a win, ask a question, or drop a kind note to begin the discussion.',
              textAlign: TextAlign.center,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(24),
            ElevatedButton.icon(
              onPressed: onStartConversation,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Say hello'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAttachment {
  final File file;
  final String type;
  final String? name;
  final int size;
  final String? mimeType;

  const _PendingAttachment({
    required this.file,
    required this.type,
    required this.size,
    this.name,
    this.mimeType,
  });
}

class _QuotedMessage extends StatelessWidget {
  const _QuotedMessage({
    required this.sender,
    required this.snippet,
    required this.alignment,
  });

  final String sender;
  final String snippet;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: alignment,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sender,
            style: ResponsiveConfig.textStyle(
              size: 11,
              weight: FontWeight.bold,
              color: AppTheme.primaryPink,
            ),
          ),
          Text(
            snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ResponsiveConfig.textStyle(
              size: 11,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: url,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

void launchUrl(String url) {
  debugPrint('Attempting to open $url');
}
