import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/support_ticket_model.dart';
import '../../../../services/support_service.dart';
import '../ticket_detail_admin_screen.dart';

class AdminSupportSection extends ConsumerStatefulWidget {
  const AdminSupportSection({super.key});

  @override
  ConsumerState<AdminSupportSection> createState() =>
      _AdminSupportSectionState();
}

class _AdminSupportSectionState extends ConsumerState<AdminSupportSection> {
  bool _showResolved = false;

  @override
  Widget build(BuildContext context) {
    final supportService = ref.watch(supportServiceProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Support Tickets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilterChip(
                label: const Text('Show Resolved'),
                selected: _showResolved,
                onSelected: (value) {
                  setState(() {
                    _showResolved = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<SupportTicketModel>>(
            stream: supportService.getAllTickets(showResolved: _showResolved),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final tickets = snapshot.data ?? [];

              if (tickets.isEmpty) {
                return const Center(
                  child: Text('No tickets found.'),
                );
              }

              return ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return _AdminTicketTile(ticket: ticket);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminTicketTile extends StatelessWidget {
  final SupportTicketModel ticket;

  const _AdminTicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isResolved = ticket.status == TicketStatus.resolved;
    final color = isResolved ? Colors.grey : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.confirmation_number, color: color),
        title: Text(
          ticket.subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${ticket.category.name.toUpperCase()} • ${DateFormat.yMMMd().format(ticket.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket.userId.isNotEmpty)
              Text('User ID: ${ticket.userId.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 10)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isResolved ? Icons.check_circle : Icons.pending,
              color: color,
            ),
            Text(
              ticket.status.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TicketDetailAdminScreen(ticket: ticket),
            ),
          );
        },
      ),
    );
  }
}
