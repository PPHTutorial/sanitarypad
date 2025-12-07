import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';
import 'watermark_service.dart';

class ImagePipelineService {
  ImagePipelineService._();
  static final ImagePipelineService instance = ImagePipelineService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: AppConstants.requestTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ));

  Future<Directory> _cacheDir() async {
    final dir = await getTemporaryDirectory();
    final target = Directory(p.join(dir.path, 'image_pipeline_cache'));
    if (!await target.exists()) await target.create(recursive: true);
    return target;
  }

  String _hash(String input) => crypto.md5.convert(Uint8List.fromList(input.codeUnits)).toString();

  String _normalizeToOriginalUrl(String rawPathOrUrl) {
    if (rawPathOrUrl.startsWith('http')) {
      final idx = rawPathOrUrl.indexOf('/t/p/');
      if (idx != -1) {
        final after = rawPathOrUrl.substring(idx + '/t/p/'.length);
        final slash = after.indexOf('/');
        if (slash != -1) {
          final tail = after.substring(slash + 1);
          return 'https://media.themoviedb.org/t/p/original/$tail';
        }
      }
      return rawPathOrUrl;
    }
    final after = rawPathOrUrl.startsWith('/t/p/') ? rawPathOrUrl.substring('/t/p/'.length) : rawPathOrUrl;
    final slash = after.indexOf('/');
    final tail = slash != -1 ? after.substring(slash + 1) : after;
    return 'https://media.themoviedb.org/t/p/original/$tail';
  }

  Future<File> _originalFile(String key) async {
    final dir = await _cacheDir();
    return File(p.join(dir.path, '${key}_original.jpg'));
  }

  Future<File> _variantFile(String key, String size, {bool watermark = false}) async {
    final dir = await _cacheDir();
    final mark = watermark ? '_wm' : '';
    return File(p.join(dir.path, '${key}_$size$mark.jpg'));
  }

  Future<Uint8List> _downloadOriginal(String normalizedOriginalUrl) async {
    final resp = await _dio.get<List<int>>(
      normalizedOriginalUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    if (resp.data == null) throw Exception('Failed to download original');
    return Uint8List.fromList(resp.data!);
  }

  Future<Uint8List> getOriginalBytes(String rawPathOrUrl) async {
    final originalUrl = _normalizeToOriginalUrl(rawPathOrUrl);
    final key = _hash(originalUrl);
    final file = await _originalFile(key);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    final bytes = await _downloadOriginal(originalUrl);
    await file.writeAsBytes(bytes, flush: true);
    return bytes;
  }

  int _sizeToWidth(String size, bool isBackdrop) {
    switch (size) {
      case 'w500':
        return 500;
      case 'w780':
        return 780;
      case 'w900':
        return 900;
      case 'w1280':
        return 1280;
      case 'original':
        return 0;
      default:
        return isBackdrop ? 1280 : 780;
    }
  }

  Future<File> getLocalVariant({
    required String rawPathOrUrl,
    required String size,
    required bool isBackdrop,
    bool watermark = false,
    bool isPro = false,
  }) async {
    final originalUrl = _normalizeToOriginalUrl(rawPathOrUrl);
    final key = _hash(originalUrl);
    final variant = await _variantFile(key, size, watermark: watermark && !isPro);
    if (await variant.exists()) return variant;

    Uint8List bytes = await getOriginalBytes(rawPathOrUrl);

    final width = _sizeToWidth(size, isBackdrop);
    if (width > 0) {
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final resized = img.copyResize(decoded, width: width);
        bytes = Uint8List.fromList(img.encodeJpg(resized, quality: 90));
      }
    }

    if (watermark && !isPro) {
      bytes = await WatermarkService.instance.processImage(
        imageBytes: bytes,
        isPro: false,
        quality: size,
      );
    }

    await variant.writeAsBytes(bytes, flush: true);
    return variant;
  }

  Future<Uint8List> getLocalVariantBytes({
    required String rawPathOrUrl,
    required String size,
    required bool isBackdrop,
    bool watermark = false,
    bool isPro = false,
  }) async {
    final file = await getLocalVariant(
      rawPathOrUrl: rawPathOrUrl,
      size: size,
      isBackdrop: isBackdrop,
      watermark: watermark,
      isPro: isPro,
    );
    return await file.readAsBytes();
  }
}
