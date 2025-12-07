import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  Future<String> getFormattedCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      int totalBytes = 0;
      totalBytes += await _dirSize(tempDir);
      totalBytes += await _dirSize(cacheDir);
      // Network cache size not directly exposed; rely on OS cache dirs
      return _formatBytes(totalBytes);
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      await _safeDelete(tempDir);
      await _safeDelete(cacheDir);
    } catch (_) {
      // swallow errors silently
    }
  }

  Future<int> _dirSize(Directory dir) async {
    int total = 0;
    if (!await dir.exists()) return 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _safeDelete(Directory dir) async {
    if (!await dir.exists()) return;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes > 0) ? (math.log(bytes) / math.log(1024)).floor() : 0;
    final value = (bytes / math.pow(1024, i)).toStringAsFixed(2);
    return '$value ${suffixes[i]}';
  }
}
