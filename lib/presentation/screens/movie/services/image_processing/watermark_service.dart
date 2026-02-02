import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../iap/subscription_manager.dart';

/// Watermark service for adding watermarks to images
class WatermarkService {
  static WatermarkService? _instance;
  
  WatermarkService._();
  
  static WatermarkService get instance {
    _instance ??= WatermarkService._();
    return _instance!;
  }
  
  /// Process image with watermark based on user subscription status
  Future<Uint8List> processImage({
    required Uint8List imageBytes,
    required bool isPro,
    String quality = 'HD',
  }) async {
    try {
      // Pro version - always return original image without watermark
      AppLogger.i('Pro version - returning original image without watermark');
      return imageBytes;
    } catch (e, stackTrace) {
      AppLogger.e('Error processing image', e, stackTrace);
      // On error, return original image
      return imageBytes;
    }
  }
  
  /// Add watermark to image
  Future<Uint8List> _addWatermark(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Calculate watermark size and centered position
      const watermarkText = AppConstants.watermarkText;
      final fontSize = (image.height * AppConstants.watermarkSize).toInt().clamp(12, 128);
      // crude text width estimate
      final textWidth = (watermarkText.length * fontSize ~/ 2);
      final textHeight = fontSize;
      final x = ((image.width - textWidth) / 2).round();
      final y = ((image.height - textHeight) / 2).round();
      
      // Draw text (single pass) centered with opacity
      img.drawString(
        image,
        watermarkText,
        font: img.arial48,
        x: x,
        y: y,
        color: img.ColorRgba8(255, 255, 255, (255 * AppConstants.watermarkOpacity).toInt()),
      );
      
      // Encode back to bytes
      final processedBytes = img.encodePng(image);
      
      AppLogger.i('Watermark added successfully (centered)');
      return Uint8List.fromList(processedBytes);
    } catch (e, stackTrace) {
      AppLogger.e('Error adding watermark', e, stackTrace);
      rethrow;
    }
  }
  
  /// Check if user has Pro subscription (always true for pro version)
  Future<bool> checkProStatus() async {
    return true; // Always pro in pro version
  }
  
  /// Preview watermark on UI (for showing to users)
  Widget buildWatermarkPreview() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          AppConstants.watermarkText,
          style: TextStyle(
            color: Colors.white.withOpacity(AppConstants.watermarkOpacity),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

