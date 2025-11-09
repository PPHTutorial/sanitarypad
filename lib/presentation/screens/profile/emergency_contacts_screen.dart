import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/emergency_contact_service.dart';
import '../../../data/models/emergency_contact_model.dart';

/// Emergency contacts screen
class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  final _contactService = EmergencyContactService();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/emergency-contact-form');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<EmergencyContact>>(
        stream: _contactService.getUserContacts(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: ResponsiveConfig.padding(all: 16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return _buildContactCard(context, contacts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emergency_outlined,
              size: ResponsiveConfig.iconSize(80),
              color: AppTheme.mediumGray,
            ),
            ResponsiveConfig.heightBox(24),
            Text(
              'No Emergency Contacts',
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Add trusted contacts who can help you in case of emergency',
              style: ResponsiveConfig.textStyle(
                size: 16,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveConfig.heightBox(32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/emergency-contact-form');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, EmergencyContact contact) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              contact.isPrimary ? AppTheme.primaryPink : AppTheme.lightPink,
          child: Text(
            contact.name.substring(0, 1).toUpperCase(),
            style: ResponsiveConfig.textStyle(
              size: 18,
              weight: FontWeight.bold,
              color: contact.isPrimary ? Colors.white : AppTheme.primaryPink,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            if (contact.isPrimary)
              Container(
                padding: ResponsiveConfig.padding(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: ResponsiveConfig.borderRadius(4),
                ),
                child: Text(
                  'Primary',
                  style: ResponsiveConfig.textStyle(
                    size: 10,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveConfig.heightBox(4),
            Text(
              contact.phoneNumber,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            if (contact.email != null)
              Text(
                contact.email!,
                style: ResponsiveConfig.textStyle(
                  size: 12,
                  color: AppTheme.mediumGray,
                ),
              ),
            ResponsiveConfig.heightBox(4),
            Text(
              contact.relationship,
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.primaryPink,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.phone, size: 20),
                  SizedBox(width: 8),
                  Text('Call'),
                ],
              ),
              onTap: () async {
                try {
                  await _contactService.callContact(contact);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            if (contact.email != null)
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.email, size: 20),
                    SizedBox(width: 8),
                    Text('Email'),
                  ],
                ),
                onTap: () async {
                  try {
                    await _contactService.sendEmailToContact(
                      contact,
                      'Emergency Contact',
                      'This is a message from FemCare+',
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.message, size: 20),
                  SizedBox(width: 8),
                  Text('SMS'),
                ],
              ),
              onTap: () async {
                try {
                  await _contactService.sendSMSToContact(
                    contact,
                    'This is a message from FemCare+',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
            if (!contact.isPrimary)
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 8),
                    Text('Set as Primary'),
                  ],
                ),
                onTap: () async {
                  try {
                    await _contactService.setPrimaryContact(
                      contact.userId,
                      contact.id!,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
              onTap: () {
                context.push('/emergency-contact-form', extra: contact);
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                ],
              ),
              onTap: () {
                _showDeleteDialog(context, contact);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _contactService.deleteContact(contact.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
