import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../../services/permissions/permission_service.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../image_processing/watermark_service.dart';
import '../image_processing/image_optimizer_service.dart';

/// Download status enum
enum DownloadStatus {
  idle,
  downloading,
  processing,
  completed,
  failed,
  cancelled,
}

/// Download task model
class DownloadTask {
  final String url;
  final String fileName;
  final bool isPro;
  final ImageQuality quality;
  DownloadStatus status;
  double progress;
  String? error;
  String? filePath;
  
  DownloadTask({
    required this.url,
    required this.fileName,
    this.isPro = false,
    this.quality = ImageQuality.hd,
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.error,
    this.filePath,
  });
}

/// Download service for managing wallpaper downloads
class DownloadService {
  static DownloadService? _instance;
  final Dio _dio = Dio(); // <--- Add this
  final WatermarkService _watermarkService;
  final ImageOptimizerService _imageOptimizer;
  
  final Map<String, DownloadTask> _activeTasks = {};
  final List<DownloadTask> _downloadHistory = [];
  final Set<String> _downloadedUrls = {}; // Track downloaded URLs to avoid duplicates
  int _activeDownloads = 0;
  
  DownloadService._()
      : _watermarkService = WatermarkService.instance,
        _imageOptimizer = ImageOptimizerService.instance;
  
  static DownloadService get instance {
    _instance ??= DownloadService._();
    return _instance!;
  }
  
  /// Download wallpaper
  Future<String?> downloadWallpaper({
    required String imageUrl,
    required String movieTitle,
    required bool isPro,
    ImageQuality quality = ImageQuality.hd,
    Function(double)? onProgress,
  }) async {
    // Check if already downloaded
    if (_downloadedUrls.contains(imageUrl)) {
      AppLogger.i('Image already downloaded, skipping: $imageUrl');
      // Find existing download
      final existingTask = _downloadHistory
          .where((task) => task.url == imageUrl && task.filePath != null)
          .firstOrNull;
      if (existingTask?.filePath != null) {
        return existingTask!.filePath;
      }
    }
    
    // Check concurrent downloads limit
    if (_activeDownloads >= AppConstants.maxConcurrentDownloads) {
      throw Exception('Maximum concurrent downloads reached. Please wait.');
    }
    
    // Check permissions
    final status = await PermissionService.instance.hasStoragePermission();
    
    if (!status) {
      throw Exception('Storage permission denied');
    }
    
    final fileName = _generateFileName(movieTitle, quality);
    final task = DownloadTask(
      url: imageUrl,
      fileName: fileName,
      isPro: isPro,
      quality: quality,
    );
    
    _activeTasks[imageUrl] = task;
    _activeDownloads++;
    
    try {
      // Update status
      task.status = DownloadStatus.downloading;
      AppLogger.download('Starting download', details: fileName);
      
      // Download image
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total);
            task.progress = progress;
            onProgress?.call(progress);
          }
        },
      );
      
      if (response.data == null) {
        throw Exception('Failed to download image');
      }
      
      Uint8List imageBytes = Uint8List.fromList(response.data!);
      
      // Process image: add watermark if user is not pro
      task.status = DownloadStatus.processing;
      onProgress?.call(0.7); // 70% downloaded, 30% processing
      
      imageBytes = await _watermarkService.processImage(
        imageBytes: imageBytes,
        isPro: isPro,
        quality: 'original',
      );
      
      // Save to device
      onProgress?.call(0.9);
      final filePath = await _saveToDevice(imageBytes, fileName);
      
      // Update status - completed
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task.filePath = filePath;
      
      // Track downloaded URL to avoid re-downloading
      _downloadedUrls.add(imageUrl);
      
      _downloadHistory.add(task);
      AppLogger.download('Download completed', details: filePath);
      
      return filePath;
    } catch (e, stackTrace) {
      AppLogger.e('Download failed', e, stackTrace);
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      throw Exception('Download failed: $e');
    } finally {
      _activeTasks.remove(imageUrl);
      _activeDownloads--;
    }
  }
  
  /// Save a locally available image file (already downloaded/generated) to device storage
  Future<String?> saveLocalImageFile({
    required String sourcePath,
    required String movieTitle,
    required bool isPro,
    ImageQuality quality = ImageQuality.hd,
  }) async {
    // Check concurrent downloads limit
    if (_activeDownloads >= AppConstants.maxConcurrentDownloads) {
      throw Exception('Maximum concurrent downloads reached. Please wait.');
    }

    final status = await PermissionService.instance.hasStoragePermission();
    if (!status) {
      throw Exception('Storage permission denied');
    }

    final fileName = _generateFileName(movieTitle, quality);
    final task = DownloadTask(
      url: sourcePath,
      fileName: fileName,
      isPro: isPro,
      quality: quality,
    );

    _activeTasks[sourcePath] = task;
    _activeDownloads++;

    try {
      task.status = DownloadStatus.processing;
      final file = File(sourcePath);
      if (!await file.exists()) throw Exception('Source file missing');
      Uint8List imageBytes = await file.readAsBytes();

      // Optimize
      imageBytes = await _imageOptimizer.optimizeImage(
        imageBytes: imageBytes,
        quality: quality,
      );

      // Watermark if free
      imageBytes = await _watermarkService.processImage(
        imageBytes: imageBytes,
        isPro: isPro,
        quality: quality.name,
      );

      final saved = await _saveToDevice(imageBytes, fileName);
      task.status = DownloadStatus.completed;
      task.progress = 1.0;
      task.filePath = saved;
      _downloadHistory.add(task);
      return saved;
    } catch (e, st) {
      AppLogger.e('Save local image failed', e, st);
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      throw Exception('Save failed: $e');
    } finally {
      _activeTasks.remove(sourcePath);
      _activeDownloads--;
    }
  }
  
  /// Save image bytes to device storage (Downloads folder)
  Future<String> _saveToDevice(Uint8List bytes, String fileName) async {
    try {
      if (Platform.isAndroid) {
        // Use native method to save via MediaStore (Android 10+) or direct save (Android 9-)
        try {
          const platform = MethodChannel('com.movieposters.media_scanner');
          final result = await platform.invokeMethod('saveImageToDownloads', {
            'fileName': fileName,
            'bytes': bytes,
          }) as Map<dynamic, dynamic>;
          
          final filePath = result['path'] as String?;
          if (filePath != null && filePath.isNotEmpty) {
            AppLogger.i('File saved to: $filePath');
            return filePath;
          } else {
            throw Exception('Native method returned empty path');
          }
        } catch (e) {
          AppLogger.e('Native save failed, trying fallback', e);
          // Fallback to old method for older Android versions
          return await _saveToDeviceLegacy(bytes, fileName);
        }
      } else if (Platform.isIOS) {
        // iOS: Save to app's Documents directory
        final directory = await getApplicationDocumentsDirectory();
        final targetDirectory = Directory(directory.path);
        final filePath = '${targetDirectory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        AppLogger.i('File saved to: $filePath');
        return filePath;
      } else {
        throw UnsupportedError('Platform not supported');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error saving file', e, stackTrace);
      rethrow;
    }
  }

  /// Legacy save method for older Android versions or fallback
  Future<String> _saveToDeviceLegacy(Uint8List bytes, String fileName) async {
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw Exception('Failed to get external storage directory');
    }
    
    // Navigate to Downloads folder
    String downloadsPath;
    if (externalDir.path.contains('Android')) {
      final List<String> pathParts = externalDir.path.split('/');
      final emulatedIndex = pathParts.indexWhere((part) => part == 'emulated' || part == 'sdcard');
      if (emulatedIndex != -1) {
        final basePath = pathParts.sublist(0, emulatedIndex + 2).join('/');
        downloadsPath = '$basePath/Download';
      } else {
        downloadsPath = '/storage/emulated/0/Download';
      }
    } else {
      downloadsPath = '/storage/emulated/0/Download';
    }
    
    final targetDirectory = Directory(downloadsPath);
    if (!await targetDirectory.exists()) {
      // Try alternative paths
      final altPaths = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
        '${externalDir.parent.path}/Download',
      ];
      
      for (final path in altPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          downloadsPath = path;
          break;
        }
      }
    }
    
    final filePath = '$downloadsPath/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    
    // Scan file for older Android
    try {
      const platform = MethodChannel('com.movieposters.media_scanner');
      await platform.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      AppLogger.e('Failed to scan file', e);
    }
    
    AppLogger.i('File saved to (legacy): $filePath');
    return filePath;
  }
  
  /// Generate filename
  String _generateFileName(String movieTitle, ImageQuality quality) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedTitle = movieTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    return '${sanitizedTitle}_${quality.name}_$timestamp.jpg';
  }
  
  
  
  /// Get download history
  List<DownloadTask> getDownloadHistory() => _downloadHistory;
  
  /// Get active downloads count
  int get activeDownloadsCount => _activeDownloads;
  
  /// Check if download is in progress
  bool isDownloading(String url) => _activeTasks.containsKey(url);
  
  /// Get download task
  DownloadTask? getTask(String url) => _activeTasks[url];
  
  /// Cancel download
  void cancelDownload(String url) {
    final task = _activeTasks[url];
    if (task != null) {
      task.status = DownloadStatus.cancelled;
      _activeTasks.remove(url);
      _activeDownloads--;
      AppLogger.download('Download cancelled', details: task.fileName);
    }
  }
  
  /// Clear download history
  void clearHistory() {
    _downloadHistory.clear();
    _downloadedUrls.clear();
    AppLogger.i('Download history cleared');
  }

  /// Download multiple wallpapers with progress tracking
  Future<Map<String, String?>> downloadAllWallpapers({
    required List<String> imageUrls,
    required String movieTitle,
    required bool isPro,
    required Function(double totalProgress, int completed, int total, String? currentItem) onProgress,
  }) async {
    final results = <String, String?>{};
    final total = imageUrls.length;
    int completed = 0;

    for (int i = 0; i < imageUrls.length; i++) {
      final url = imageUrls[i];
      try {
        onProgress(i / total, completed, total, 'Downloading ${i + 1}/$total...');
        
        final filePath = await downloadWallpaper(
          imageUrl: url,
          movieTitle: movieTitle,
          isPro: isPro,
          quality: ImageQuality.original,
          onProgress: (progress) {
            // Calculate overall progress
            final overallProgress = (i + progress) / total;
            onProgress(overallProgress, completed, total, 'Downloading ${i + 1}/$total...');
          },
        );
        
        results[url] = filePath;
        completed++;
        onProgress((i + 1) / total, completed, total, 'Downloaded ${i + 1}/$total');
      } catch (e) {
        AppLogger.e('Failed to download: $url', e);
        results[url] = null;
      }
    }
    
    return results;
  }

  /// Check if URL is already downloaded
  bool isAlreadyDownloaded(String url) {
    return _downloadedUrls.contains(url);
  }
}

