import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/core/providers/auth_provider.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/data/models/user_model.dart';
import 'package:go_router/go_router.dart';

class FullProfileScreen extends ConsumerWidget {
  const FullProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: userAsync.when(
          data: (user) => user == null
              ? const Center(child: Text('User not found'))
              : _buildContent(context, user),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserModel user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with Hero-like Profile Image
          _buildHeader(context, user),

          Padding(
            padding: ResponsiveConfig.padding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Personal Information'),
                ResponsiveConfig.heightBox(12),
                _buildInfoCard(context, [
                  _buildInfoTile(context, FontAwesomeIcons.user, 'Full Name',
                      user.fullName ?? 'Not set'),
                  _buildInfoTile(context, FontAwesomeIcons.at, 'Username',
                      user.username ?? 'Not set'),
                  _buildInfoTile(context, FontAwesomeIcons.venus, 'Gender',
                      user.gender ?? 'Not set'),
                  _buildInfoTile(
                      context,
                      FontAwesomeIcons.calendar,
                      'Date of Birth',
                      user.dateOfBirth != null
                          ? DateFormat('MMMM dd, yyyy')
                              .format(user.dateOfBirth!)
                          : 'Not set'),
                ]),
                ResponsiveConfig.heightBox(24),
                _buildSectionTitle(context, 'Contact Details'),
                ResponsiveConfig.heightBox(12),
                _buildInfoCard(context, [
                  _buildInfoTile(
                      context, FontAwesomeIcons.envelope, 'Email', user.email),
                  _buildInfoTile(context, FontAwesomeIcons.phone, 'Phone',
                      user.phoneNumber ?? 'Not set'),
                  _buildInfoTile(context, FontAwesomeIcons.mapLocationDot,
                      'Address', user.address ?? 'Not set'),
                ]),
                ResponsiveConfig.heightBox(24),
                _buildSectionTitle(context, 'Account Details'),
                ResponsiveConfig.heightBox(12),
                _buildInfoCard(context, [
                  _buildInfoTile(context, FontAwesomeIcons.crown,
                      'Subscription', user.subscription.tier.toUpperCase(),
                      valueColor: Theme.of(context).colorScheme.primary),
                  _buildInfoTile(
                      context,
                      FontAwesomeIcons.shieldHalved,
                      'Privacy Level',
                      user.privacy.profileVisibility.toUpperCase()),
                  _buildInfoTile(context, FontAwesomeIcons.clock, 'Joined',
                      DateFormat('MMM yyyy').format(user.createdAt)),
                ]),
                ResponsiveConfig.heightBox(32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/edit-profile'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: ResponsiveConfig.padding(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: ResponsiveConfig.borderRadius(12),
                      ),
                    ),
                  ),
                ),
                ResponsiveConfig.heightBox(20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(vertical: 24),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: user.photoUrl != null
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Icon(Icons.person, size: 60, color: colorScheme.primary)
                  : null,
            ),
            ResponsiveConfig.heightBox(16),

            // Names
            Text(
              user.fullName ?? user.displayName ?? 'FemCare User',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(4),
            Text(
              '@${user.username ?? "user"}',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      // Elevation and color handled by CardTheme
      margin: EdgeInsets.zero,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: ResponsiveConfig.padding(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          FaIcon(icon, size: 20, color: colorScheme.primary),
          ResponsiveConfig.widthBox(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
