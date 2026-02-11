import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sanitarypad/presentation/screens/movie/presentation/widgets/responsive_grid.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AISkinWidget extends StatelessWidget {
  final VoidCallback onTap;

  const AISkinWidget({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Padding(
                padding: ResponsiveConfig.padding(all: 16.0),
                child: Text(
                  "Realtime Face Analyser",
                  style: ResponsiveConfig.textStyle(
                      size: 24,
                      color: AppTheme.primaryPink,
                      weight: FontWeight.w900),
                ),
              ),
              Container(
                width: ResponsiveConfig.screenWidth,
                padding: ResponsiveConfig.padding(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  /* gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPink,
                      AppTheme.primaryPink.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ), */
                ),
                child: Image.asset(
                  "assets/images/analyser.png",
                  height: ResponsiveConfig.height(220),
                  width: ResponsiveConfig.width(80),
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: ResponsiveConfig.padding(all: 16.0),
                child: Text(
                  "Tap to analyse your Facial conditions and skin problems in realtime",
                  textAlign: TextAlign.center,
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    color: AppTheme.primaryPink,
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
