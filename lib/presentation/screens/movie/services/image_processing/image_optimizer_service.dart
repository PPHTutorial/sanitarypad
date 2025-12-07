import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../core/utils/logger.dart';

/// Image quality enum
enum ImageQuality {
  thumbnail(342, 70),
  hd(780, 85),
  fullHd(1080, 90),
  fourK(2160, 95),
  original(0, 100);
  
  const ImageQuality(this.maxSize, this.quality);
  final int maxSize;
  final int quality;
}

/// Image optimizer service for compressing and resizing images
class ImageOptimizerService {
  static ImageOptimizerService? _instance;
  
  ImageOptimizerService._();
  
  static ImageOptimizerService get instance {
    _instance ??= ImageOptimizerService._();
    return _instance!;
  }
  
  /// Optimize image based on quality level
  Future<Uint8List> optimizeImage({
    required Uint8List imageBytes,
    ImageQuality quality = ImageQuality.hd,
  }) async {
    try {
      // If original quality requested, return as is
      if (quality == ImageQuality.original) {
        return imageBytes;
      }
      
      AppLogger.i('Optimizing image to ${quality.name}');
      
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize if needed
      img.Image processedImage = image;
      if (quality.maxSize > 0) {
        final maxDimension = quality.maxSize;
        if (image.width > maxDimension || image.height > maxDimension) {
          if (image.width > image.height) {
            processedImage = img.copyResize(
              image,
              width: maxDimension,
            );
          } else {
            processedImage = img.copyResize(
              image,
              height: maxDimension,
            );
          }
        }
      }
      
      // Encode with quality
      final optimizedBytes = img.encodeJpg(
        processedImage,
        quality: quality.quality,
      );
      
      final originalSize = imageBytes.length / 1024; // KB
      final optimizedSize = optimizedBytes.length / 1024; // KB
      final reduction = ((1 - (optimizedSize / originalSize)) * 100).toStringAsFixed(1);
      
      AppLogger.i(
        'Image optimized: ${originalSize.toStringAsFixed(2)} KB → ${optimizedSize.toStringAsFixed(2)} KB ($reduction% reduction)',
      );
      
      return Uint8List.fromList(optimizedBytes);
    } catch (e, stackTrace) {
      AppLogger.e('Error optimizing image', e, stackTrace);
      // On error, return original image
      return imageBytes;
    }
  }
  
  /// Resize image to specific dimensions
  Future<Uint8List> resizeImage({
    required Uint8List imageBytes,
    int? width,
    int? height,
    bool maintainAspectRatio = true,
  }) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      final resized = img.copyResize(
        image,
        width: width,
        height: height,
        maintainAspect: maintainAspectRatio,
      );
      
      return Uint8List.fromList(img.encodePng(resized));
    } catch (e, stackTrace) {
      AppLogger.e('Error resizing image', e, stackTrace);
      return imageBytes;
    }
  }
  
  /// Optimize for wallpaper (maintain device screen dimensions)
  Future<Uint8List> optimizeForWallpaper({
    required Uint8List imageBytes,
    required double screenWidth,
    required double screenHeight,
    required double devicePixelRatio,
  }) async {
    try {
      final targetWidth = (screenWidth * devicePixelRatio).toInt();
      final targetHeight = (screenHeight * devicePixelRatio).toInt();
      
      AppLogger.i('Optimizing for wallpaper: ${targetWidth}x$targetHeight');
      
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize to fit screen while maintaining aspect ratio
      img.Image processed = image;
      if (image.width > targetWidth || image.height > targetHeight) {
        processed = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          maintainAspect: true,
        );
      }
      
      // Encode with high quality for wallpaper
      final optimizedBytes = img.encodeJpg(processed, quality: 95);
      
      return Uint8List.fromList(optimizedBytes);
    } catch (e, stackTrace) {
      AppLogger.e('Error optimizing for wallpaper', e, stackTrace);
      return imageBytes;
    }
  }
  
  /// Get image dimensions
  Future<Map<String, int>?> getImageDimensions(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;
      
      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e, stackTrace) {
      AppLogger.e('Error getting image dimensions', e, stackTrace);
      return null;
    }
  }
  
  /// Calculate estimated file size for quality
  String getEstimatedSize(ImageQuality quality, int originalSizeKB) {
    double estimatedKB;
    switch (quality) {
      case ImageQuality.thumbnail:
        estimatedKB = originalSizeKB * 0.1;
        break;
      case ImageQuality.hd:
        estimatedKB = originalSizeKB * 0.3;
        break;
      case ImageQuality.fullHd:
        estimatedKB = originalSizeKB * 0.5;
        break;
      case ImageQuality.fourK:
        estimatedKB = originalSizeKB * 0.8;
        break;
      case ImageQuality.original:
        estimatedKB = originalSizeKB.toDouble();
        break;
    }
    
    if (estimatedKB < 1024) {
      return '${estimatedKB.toStringAsFixed(0)} KB';
    } else {
      return '${(estimatedKB / 1024).toStringAsFixed(2)} MB';
    }
  }
}

