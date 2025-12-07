import 'dart:typed_data';
import 'dart:io';
import 'image_pipeline_service.dart';

class ImageProcessingService {
  ImageProcessingService._();
  static final ImageProcessingService instance = ImageProcessingService._();

  Future<File?> getPoster(String pathOrUrl, {String size = 'w780', bool isPro = true}) async {
    return ImagePipelineService.instance.getLocalVariant(
      rawPathOrUrl: pathOrUrl,
      size: size,
      isBackdrop: false,
      watermark: !isPro,
      isPro: isPro,
    );
  }

  Future<File?> getBackdrop(String pathOrUrl, {String size = 'w1280', bool isPro = true}) async {
    return ImagePipelineService.instance.getLocalVariant(
      rawPathOrUrl: pathOrUrl,
      size: size,
      isBackdrop: true,
      watermark: !isPro,
      isPro: isPro,
    );
  }

  Future<Uint8List> getBytes(String pathOrUrl, {required String size, required bool isBackdrop, bool isPro = true}) async {
    return ImagePipelineService.instance.getLocalVariantBytes(
      rawPathOrUrl: pathOrUrl,
      size: size,
      isBackdrop: isBackdrop,
      watermark: !isPro,
      isPro: isPro,
    );
  }
}
