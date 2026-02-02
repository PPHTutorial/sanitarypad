import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';

class PolicyViewerScreen extends StatelessWidget {
  final String title;
  final String markdownContent;

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.markdownContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: MarkdownBody(
          data: markdownContent,
          styleSheet: MarkdownStyleSheet(
            h1: ResponsiveConfig.textStyle(
              size: 24,
              weight: FontWeight.bold,
              color: AppTheme.primaryPink,
            ),
            h2: ResponsiveConfig.textStyle(
              size: 20,
              weight: FontWeight.bold,
              color: Colors.black87,
            ).copyWith(height: 1.5),
            h3: ResponsiveConfig.textStyle(
              size: 16,
              weight: FontWeight.bold,
              color: Colors.black87,
            ).copyWith(height: 1.4),
            p: ResponsiveConfig.textStyle(
              size: 14,
              color: AppTheme.mediumGray,
            ).copyWith(height: 1.5),
            listBullet: ResponsiveConfig.textStyle(
              size: 14,
              color: AppTheme.mediumGray,
            ),
            strong: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTapLink: (text, href, title) {
            // Handle link taps if any
            // launchUrl(Uri.parse(href!));
          },
        ),
      ),
    );
  }
}
