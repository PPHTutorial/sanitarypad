import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/support_service.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supportService = ref.watch(supportServiceProvider);
    final faqs = supportService.getFAQs();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Frequently Asked Questions'),
            ResponsiveConfig.heightBox(8),
            ...faqs.map((faq) =>
                _buildFAQTile(context, faq['question']!, faq['answer']!)),
            ResponsiveConfig.heightBox(24),
            _buildSectionHeader(context, 'Contact Us'),
            ResponsiveConfig.heightBox(8),
            _buildContactCard(
              context,
              icon: FontAwesomeIcons.envelope,
              title: 'Email Support',
              subtitle: 'support@femcare.app',
              onTap: () => _launchEmail('support@femcare.app'),
            ),
            ResponsiveConfig.heightBox(12),
            _buildContactCard(
              context,
              icon: FontAwesomeIcons.ticket,
              title: 'Submit a Ticket',
              subtitle: 'Report an issue or request a feature',
              onTap: () => context.push('/create-ticket'),
              isAction: true,
            ),
            ResponsiveConfig.heightBox(24),
            Center(
              child: Text(
                'Version 26.08.49',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            ResponsiveConfig.heightBox(32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPink,
          ),
    );
  }

  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAction = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isAction ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: ListTile(
        leading: FaIcon(
          icon,
          color: AppTheme.primaryPink,
          size: 20,
        ),
        title: Text(
          title,
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request - FemCare+',
    );
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    }
  }
}
