import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() =>
      _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  bool _isLoading = false;
  String _profileVisibility = 'private';
  bool _showFullName = false;
  bool _showUsername = true;
  bool _showPhoto = true;
  bool _showAddress = false;
  bool _showGender = false;
  bool _showAge = false;
  bool _showHealthStats = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserStreamProvider).value;
    if (user != null) {
      _profileVisibility = user.privacy.profileVisibility;
      _showFullName = user.privacy.showFullName;
      _showUsername = user.privacy.showUsername;
      _showPhoto = user.privacy.showPhoto;
      _showAddress = user.privacy.showAddress;
      _showGender = user.privacy.showGender;
      _showAge = user.privacy.showAge;
      _showHealthStats = user.privacy.showHealthStats;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserStreamProvider).value;
      if (user == null) return;

      final updatedPrivacy = user.privacy.copyWith(
        profileVisibility: _profileVisibility,
        showFullName: _showFullName,
        showUsername: _showUsername,
        showPhoto: _showPhoto,
        showAddress: _showAddress,
        showGender: _showGender,
        showAge: _showAge,
        showHealthStats: _showHealthStats,
      );

      final updatedUser = user.copyWith(privacy: updatedPrivacy);
      final authService = ref.read(authServiceProvider);
      await authService.updateUserData(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved')),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveSettings,
              child: const Text('Save',
                  style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Profile Visibility'),
            ResponsiveConfig.heightBox(16),
            _buildVisibilitySelector(),
            ResponsiveConfig.heightBox(32),
            _buildSectionTitle('Who can see my...'),
            ResponsiveConfig.heightBox(16),
            _buildToggleTile(
              title: 'Full Name',
              value: _showFullName,
              onChanged: (val) => setState(() => _showFullName = val),
            ),
            _buildToggleTile(
              title: 'Username',
              value: _showUsername,
              onChanged: (val) => setState(() => _showUsername = val),
            ),
            _buildToggleTile(
              title: 'Profile Picture',
              value: _showPhoto,
              onChanged: (val) => setState(() => _showPhoto = val),
            ),
            _buildToggleTile(
              title: 'Home Address',
              value: _showAddress,
              onChanged: (val) => setState(() => _showAddress = val),
            ),
            _buildToggleTile(
              title: 'Gender',
              value: _showGender,
              onChanged: (val) => setState(() => _showGender = val),
            ),
            _buildToggleTile(
              title: 'Age / Date of Birth',
              value: _showAge,
              onChanged: (val) => setState(() => _showAge = val),
            ),
            _buildToggleTile(
              title: 'Health Statistics',
              value: _showHealthStats,
              onChanged: (val) => setState(() => _showHealthStats = val),
            ),
            ResponsiveConfig.heightBox(32),
            _buildInfoCard(),
          ],
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

  Widget _buildVisibilitySelector() {
    return Column(
      children: [
        _buildVisibilityRadio(
            'public', 'Public', 'Visible to everyone in the community'),
        _buildVisibilityRadio(
            'protected', 'Protected', 'Only visible to friends'),
        _buildVisibilityRadio('private', 'Private', 'Only visible to you'),
      ],
    );
  }

  Widget _buildVisibilityRadio(String value, String title, String subtitle) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _profileVisibility,
      activeColor: AppTheme.primaryPink,
      onChanged: (val) => setState(() => _profileVisibility = val!),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryPink,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: ResponsiveConfig.padding(all: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryPink.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          FaIcon(FontAwesomeIcons.shieldHalved, color: AppTheme.primaryPink),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Your health data is encrypted and never shared without your permission. Private mode prevents your profile from appearing in community searches.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
