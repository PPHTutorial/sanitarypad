import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/emergency_contact_service.dart';
import '../../../data/models/emergency_contact_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emergency contact form screen
class EmergencyContactFormScreen extends ConsumerStatefulWidget {
  final EmergencyContact? contact;

  const EmergencyContactFormScreen({
    super.key,
    this.contact,
  });

  @override
  ConsumerState<EmergencyContactFormScreen> createState() =>
      _EmergencyContactFormScreenState();
}

class _EmergencyContactFormScreenState
    extends ConsumerState<EmergencyContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRelationship = 'family';
  bool _isPrimary = false;
  final _contactService = EmergencyContactService();

  final List<String> _relationships = [
    'family',
    'friend',
    'doctor',
    'partner',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phoneNumber;
      _emailController.text = widget.contact!.email ?? '';
      _selectedRelationship = widget.contact!.relationship;
      _isPrimary = widget.contact!.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    try {
      if (widget.contact != null) {
        // Update existing contact
        final updatedContact = widget.contact!.copyWith(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          relationship: _selectedRelationship,
          isPrimary: _isPrimary,
          updatedAt: DateTime.now(),
        );
        await _contactService.updateContact(updatedContact);
      } else {
        // Create new contact
        final newContact = EmergencyContact(
          userId: user.userId,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          relationship: _selectedRelationship,
          isPrimary: _isPrimary,
          createdAt: DateTime.now(),
        );
        await _contactService.createContact(newContact);

        // If set as primary, update primary status
        if (_isPrimary) {
          await _contactService.setPrimaryContact(user.userId, newContact.id!);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.contact != null ? 'Contact updated' : 'Contact added',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact != null ? 'Edit Contact' : 'Add Contact'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Relationship dropdown
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: InputDecoration(
                  labelText: 'Relationship',
                  prefixIcon: const Icon(Icons.people),
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(12),
                  ),
                ),
                items: _relationships.map((relationship) {
                  return DropdownMenuItem(
                    value: relationship,
                    child: Text(
                      relationship[0].toUpperCase() + relationship.substring(1),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRelationship = value!);
                },
              ),
              ResponsiveConfig.heightBox(16),

              // Primary contact switch
              Card(
                child: SwitchListTile(
                  title: const Text('Set as Primary Contact'),
                  subtitle: const Text(
                    'Primary contact will be used for emergency notifications',
                  ),
                  value: _isPrimary,
                  onChanged: (value) {
                    setState(() => _isPrimary = value);
                  },
                ),
              ),
              ResponsiveConfig.heightBox(24),

              // Save button
              ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveConfig.padding(vertical: 16),
                ),
                child: Text(
                  widget.contact != null ? 'Update Contact' : 'Add Contact',
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
