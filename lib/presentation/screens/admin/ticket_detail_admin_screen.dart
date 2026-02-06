import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/support_ticket_model.dart';
import '../../../../services/support_service.dart';

class TicketDetailAdminScreen extends ConsumerStatefulWidget {
  final SupportTicketModel ticket;

  const TicketDetailAdminScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailAdminScreen> createState() =>
      _TicketDetailAdminScreenState();
}

class _TicketDetailAdminScreenState
    extends ConsumerState<TicketDetailAdminScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await ref.read(supportServiceProvider).replyToTicket(
            ticketId: widget.ticket.id,
            reply: _replyController.text.trim(),
            adminId: user.userId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
        Navigator.pop(context); // Go back after reply
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _markResolved() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Ticket?'),
        content: const Text('This will mark the ticket as resolved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close Ticket'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(supportServiceProvider).closeTicket(widget.ticket.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error closing ticket: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
        actions: [
          if (ticket.status != TicketStatus.resolved)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: _markResolved,
              tooltip: 'Mark as Resolved',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(ticket.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _getStatusColor(ticket.status)),
                        ),
                        child: Text(
                          ticket.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(ticket.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMd().format(ticket.createdAt),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.subject,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${ticket.category.name}',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  const Divider(height: 32),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(ticket.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),

                  // Images
                  if (ticket.imageUrls.isNotEmpty) ...[
                    const Text('Attachments:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ticket.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(ticket.imageUrls[index]);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ticket.imageUrls[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Previous Admin Reply
                  if (ticket.adminReply != null) ...[
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.support_agent, size: 20),
                              const SizedBox(width: 8),
                              const Text('Support Response',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (ticket.adminRepliedAt != null)
                                Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(ticket.adminRepliedAt!),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(ticket.adminReply!),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Reply Input Area
          if (ticket.status != TicketStatus.resolved &&
              ticket.adminReply == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reply to User',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _replyController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your response here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSending ? null : _sendReply,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Send Reply'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }
}
