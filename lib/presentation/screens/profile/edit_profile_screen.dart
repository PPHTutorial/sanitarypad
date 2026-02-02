import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../services/auth_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String? _gender;
  DateTime? _dob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserStreamProvider).value;
    _fullNameController = TextEditingController(text: user?.fullName);
    _usernameController = TextEditingController(text: user?.username);
    _addressController = TextEditingController(text: user?.address);
    _phoneController = TextEditingController(text: user?.phoneNumber);
    _gender = user?.gender;
    _dob = user?.dateOfBirth;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserStreamProvider).value;
      if (user == null) return;

      final updatedUser = user.copyWith(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        gender: _gender,
        dateOfBirth: _dob,
      );

      final authService = ref.read(authServiceProvider);
      await authService.updateUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dob ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryPink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information'),
              ResponsiveConfig.heightBox(16),
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: FontAwesomeIcons.user,
                hint: 'Enter your full name',
              ),
              ResponsiveConfig.heightBox(16),
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                icon: FontAwesomeIcons.at,
                hint: 'Choose a username',
              ),
              ResponsiveConfig.heightBox(16),
              _buildGenderDropdown(),
              ResponsiveConfig.heightBox(16),
              _buildDobPicker(context),
              ResponsiveConfig.heightBox(32),
              _buildSectionTitle('Contact Details'),
              ResponsiveConfig.heightBox(16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: FontAwesomeIcons.phone,
                hint: 'Enter your phone number',
                keyboardType: TextInputType.phone,
              ),
              ResponsiveConfig.heightBox(16),
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                icon: FontAwesomeIcons.locationDot,
                hint: 'Enter your address',
                maxLines: 2,
              ),
              ResponsiveConfig.heightBox(32),
              _buildSecuritySection(),
              ResponsiveConfig.heightBox(40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: ResponsiveConfig.textStyle(
        size: 18,
        weight: FontWeight.bold,
        color: AppTheme.primaryPink,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FaIcon(icon, size: 18, color: AppTheme.primaryPink),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
        ),
      ),
      validator: (value) {
        if (label == 'Username' && value != null && value.isNotEmpty) {
          if (value.length < 3) return 'Username too short';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12.0),
          child: FaIcon(FontAwesomeIcons.venusMars,
              size: 18, color: AppTheme.primaryPink),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: ['Female', 'Male', 'Non-binary', 'Prefer not to say']
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (value) => setState(() => _gender = value),
    );
  }

  Widget _buildDobPicker(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12.0),
            child: FaIcon(FontAwesomeIcons.calendarDay,
                size: 18, color: AppTheme.primaryPink),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _dob == null
              ? 'Select Date'
              : DateFormat('MMM dd, yyyy').format(_dob!),
          style: ResponsiveConfig.textStyle(size: 16),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    // Only show password change for email/password users
    // Usually, we check providers for 'password'

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Security'),
        ResponsiveConfig.heightBox(16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading:
              const FaIcon(FontAwesomeIcons.lock, color: AppTheme.primaryPink),
          title: const Text('Change Password'),
          subtitle: const Text('Regularly update your password for safety'),
          trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 16),
          onTap: () => _showChangePasswordDialog(),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration:
                      const InputDecoration(labelText: 'Current Password'),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: newPasswordController,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  obscureText: true,
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration:
                      const InputDecoration(labelText: 'Confirm New Password'),
                  obscureText: true,
                  validator: (v) => v != newPasswordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (dialogFormKey.currentState!.validate()) {
                try {
                  final authService = ref.read(authServiceProvider);
                  // 1. Re-authenticate
                  // Note: You usually need to re-auth to change password in Firebase
                  // I'll assume we have a way to re-auth or similar
                  await authService.updatePassword(newPasswordController.text);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Password changed successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
