import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/group_model.dart';
import '../../../services/group_service.dart';

class GroupFormScreen extends ConsumerStatefulWidget {
  final String? category;

  const GroupFormScreen({
    super.key,
    this.category,
  });

  @override
  ConsumerState<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends ConsumerState<GroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _groupService = GroupService();
  String _selectedCategory = 'general';
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final group = GroupModel(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        createdBy: user.userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublic: _isPublic,
      );

      await _groupService.createGroup(group);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Group'),
        ),
        body: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter group name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your group',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                ResponsiveConfig.heightBox(16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(
                        value: 'pregnancy', child: Text('Pregnancy')),
                    DropdownMenuItem(
                        value: 'fertility', child: Text('Fertility')),
                    DropdownMenuItem(
                        value: 'skincare', child: Text('Skincare')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),
                SwitchListTile(
                  title: const Text('Public Group'),
                  subtitle: const Text('Anyone can find and join this group'),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
                ResponsiveConfig.heightBox(24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGroup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Group'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
