import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../data/models/skincare_model.dart';
import '../../../../services/credit_manager.dart';
import '../../../../services/skincare_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/auth_provider.dart';
import 'skincare_tracking_screen.dart' show BeautyTipsCard;

class SkinAnalysisReportScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const SkinAnalysisReportScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<SkinAnalysisReportScreen> createState() =>
      _SkinAnalysisReportScreenState();
}

class _SkinAnalysisReportScreenState
    extends ConsumerState<SkinAnalysisReportScreen> {
  bool _isLoading = true;
  String? _error;
  SkinAnalysisEntry? _result;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    try {
      final skincareService = SkincareAnalysisService(
        FirebaseFirestore.instance,
        StorageService(),
        AIService(),
      );

      // 1. Credit Check
      final hasCredit = await ref
          .read(creditManagerProvider)
          .requestCredit(context, ActionType.skincareAnalysis);
      if (!hasCredit) {
        if (mounted) context.pop();
        return;
      }

      // 2. Perform Analysis via Service
      // The service now handles uploading and AI call
      final entry = await skincareService.analyzeSkinCondition(
        userId: ref.read(currentUserProvider)!.userId,
        imageFile: File(widget.imagePath),
      );

      // 3. Consume Credits upon success
      await ref
          .read(creditManagerProvider)
          .consumeCredits(ActionType.skincareAnalysis);

      if (mounted) {
        setState(() {
          _result = entry;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Analysis Error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              ResponsiveConfig.heightBox(24),
              Text(
                'Analyzing your skin...',
                style: ResponsiveConfig.textStyle(
                    size: 18, weight: FontWeight.bold),
              ),
              ResponsiveConfig.heightBox(8),
              const Text('This may take a few moments'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analysis Failed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                ResponsiveConfig.heightBox(16),
                Text(_error!),
                ResponsiveConfig.heightBox(24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Health Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildInteractiveHeader(),
            _buildScoreGrid(),
            _buildDetailedAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveHeader() {
    return Container(
      height: 350,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: CachedNetworkImage(
              imageUrl: _result!.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          if (_selectedCategory != null &&
              _result!.regionData?[_selectedCategory] != null)
            _buildRegionMask(_result!.regionData![_selectedCategory]!),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryPink,
                    child: Text(
                      _result!.overallScore?[0] ?? 'A',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ResponsiveConfig.widthBox(16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Condition: ${_result!.overallScore}',
                        style: ResponsiveConfig.textStyle(
                            size: 16, weight: FontWeight.bold),
                      ),
                      Text(
                        '${DateFormat('MMMM d, y').format(_result!.date)}',
                        style: ResponsiveConfig.textStyle(
                            size: 12, color: AppTheme.mediumGray),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionMask(List<dynamic> coords) {
    // Coords are [x1, y1, x2, y2] normalized
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = coords[0] * constraints.maxWidth;
        final top = coords[1] * constraints.maxHeight;
        final width = (coords[2] - coords[0]) * constraints.maxWidth;
        final height = (coords[3] - coords[1]) * constraints.maxHeight;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryPink, width: 2),
              color: AppTheme.primaryPink.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Criteria',
            style:
                ResponsiveConfig.textStyle(size: 18, weight: FontWeight.bold),
          ),
          ResponsiveConfig.heightBox(16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _result!.criteriaScores!.length,
            itemBuilder: (context, index) {
              final key = _result!.criteriaScores!.keys.elementAt(index);
              final score = _result!.criteriaScores![key]!;
              final isSelected = _selectedCategory == key;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : key;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryPink.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryPink
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${score.toInt()}',
                        style: ResponsiveConfig.textStyle(
                          size: 20,
                          weight: FontWeight.bold,
                          color: score > 80
                              ? Colors.green
                              : score > 60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      ResponsiveConfig.heightBox(4),
                      Text(
                        key,
                        textAlign: TextAlign.center,
                        style: ResponsiveConfig.textStyle(size: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisSection('Identified Concerns',
              _result!.identifiedConcerns, FontAwesomeIcons.circleExclamation),
          _buildAnalysisSection('Recommended Remedies',
              _result!.recommendedRemedies, FontAwesomeIcons.kitMedical),
          _buildAnalysisSection('Routine Steps',
              _result!.routineRecommendations, FontAwesomeIcons.listCheck),
          _buildAnalysisSection('Precautions', _result!.precautions,
              FontAwesomeIcons.shieldHalved),
          ResponsiveConfig.heightBox(24),
          const BeautyTipsCard(),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
      String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveConfig.heightBox(24),
        Row(
          children: [
            FaIcon(icon, size: 18, color: AppTheme.primaryPink),
            ResponsiveConfig.widthBox(12),
            Text(
              title,
              style:
                  ResponsiveConfig.textStyle(size: 16, weight: FontWeight.bold),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
      ],
    );
  }
}
