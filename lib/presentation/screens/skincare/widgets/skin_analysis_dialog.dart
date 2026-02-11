import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import 'package:sanitarypad/data/models/skincare_model.dart';
import 'package:sanitarypad/services/skincare_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanitarypad/services/storage_service.dart';
import 'package:sanitarypad/services/ai_service.dart';
import 'package:sanitarypad/services/credit_manager.dart';

class SkinAnalysisDialog extends ConsumerStatefulWidget {
  final String userId;

  const SkinAnalysisDialog({super.key, required this.userId});

  @override
  ConsumerState<SkinAnalysisDialog> createState() => _SkinAnalysisDialogState();
}

class _SkinAnalysisDialogState extends ConsumerState<SkinAnalysisDialog> {
  final _notesController = TextEditingController();
  File? _imageFile;
  bool _isAnalyzing = false;
  SkinAnalysisEntry? _result;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality:
          100, // Lossless as requested (though JPEG is lossy, 100 is max quality)
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _result = null; // Reset result on new image
      });
    }
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final storageService = StorageService();
      final aiService = AIService();

      final service =
          SkincareAnalysisService(firestore, storageService, aiService);

      // Credit Check
      final creditManager = ref.read(creditManagerProvider);
      final hasCredits = await creditManager.requestCredit(
        context,
        ActionType.skincareAnalysis,
      );

      if (!hasCredits) {
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      final result = await service.analyzeSkinCondition(
        userId: widget.userId,
        imageFile: _imageFile!,
        notes: _notesController.text,
      );

      // Credit consumption is already handled if needed,
      // but SkincareAnalysisService doesn't consume credits itself.
      // We consume them HERE after successful analysis to be safe.
      await creditManager.consumeCredits(ActionType.skincareAnalysis);

      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FemCare+ Skin Analysis',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_result != null) _buildResultView() else _buildInputView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _showImageSourceSheet(),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: _imageFile == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to upload photo',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Describe your concerns...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        if (_isAnalyzing)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton(
            onPressed: _imageFile != null ? _analyze : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Analyze Now',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildResultView() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Analysis Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSection('Identified Concerns', r.identifiedConcerns),
        _buildSection('Recommended Remedies', r.recommendedRemedies),
        _buildSection('Recommended Products', r.recommendedProducts),
        _buildSection('Precautions', r.precautions),
        _buildSection('Routine Recommendations', r.routineRecommendations),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Close & Save'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppTheme.primaryPink)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
