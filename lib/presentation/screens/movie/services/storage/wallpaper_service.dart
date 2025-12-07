import 'dart:io';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import '../../core/utils/logger.dart';

/// Wallpaper location enum
enum WallpaperLocation {
  homeScreen,
  lockScreen,
  both,
}

/// Wallpaper service for setting device wallpapers
class WallpaperService {
  static WallpaperService? _instance;
  
  WallpaperService._();
  
  static WallpaperService get instance {
    _instance ??= WallpaperService._();
    return _instance!;
  }
  
  /// Set wallpaper from file path
  Future<bool> setWallpaperFromFile({
    required String filePath,
    WallpaperLocation location = WallpaperLocation.both,
  }) async {
    try {
      AppLogger.i('Setting wallpaper from file: $filePath');
      
      if (Platform.isAndroid) {
        return await _setWallpaperAndroid(filePath, location);
      } else if (Platform.isIOS) {
        return await _setWallpaperIOS(filePath);
      }
      
      return false;
    } catch (e, stackTrace) {
      AppLogger.e('Error setting wallpaper', e, stackTrace);
      return false;
    }
  }
  
  /// Set wallpaper from URL
  Future<bool> setWallpaperFromUrl({
    required String imageUrl,
    WallpaperLocation location = WallpaperLocation.both,
  }) async {
    try {
      AppLogger.i('Setting wallpaper from URL: $imageUrl');
      
      if (Platform.isAndroid) {
        return await _setWallpaperFromUrlAndroid(imageUrl, location);
      } else if (Platform.isIOS) {
        // iOS doesn't support direct wallpaper setting
        // User needs to set manually from Photos
        AppLogger.w('iOS does not support direct wallpaper setting');
        return false;
      }
      
      return false;
    } catch (e, stackTrace) {
      AppLogger.e('Error setting wallpaper from URL', e, stackTrace);
      return false;
    }
  }
  
  /// Set wallpaper on Android from file
  Future<bool> _setWallpaperAndroid(
    String filePath,
    WallpaperLocation location,
  ) async {
    try {
      int wallpaperLocation;
      
      switch (location) {
        case WallpaperLocation.homeScreen:
          wallpaperLocation = WallpaperManager.HOME_SCREEN;
          break;
        case WallpaperLocation.lockScreen:
          wallpaperLocation = WallpaperManager.LOCK_SCREEN;
          break;
        case WallpaperLocation.both:
          wallpaperLocation = WallpaperManager.BOTH_SCREEN;
          break;
      }
      
      final result = await WallpaperManager.setWallpaperFromFile(
        filePath,
        wallpaperLocation,
      );
      
      AppLogger.i('Wallpaper set successfully: $result');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Error setting Android wallpaper', e, stackTrace);
      return false;
    }
  }
  
  /// Set wallpaper on Android from URL
  Future<bool> _setWallpaperFromUrlAndroid(
    String url,
    WallpaperLocation location,
  ) async {
    try {
      int wallpaperLocation;
      
      switch (location) {
        case WallpaperLocation.homeScreen:
          wallpaperLocation = AsyncWallpaper.HOME_SCREEN;
          break;
        case WallpaperLocation.lockScreen:
          wallpaperLocation = AsyncWallpaper.LOCK_SCREEN;
          break;
        case WallpaperLocation.both:
          wallpaperLocation = AsyncWallpaper.BOTH_SCREENS;
          break;
      }
      
      final result = await AsyncWallpaper.setWallpaper(
        url: url,
        wallpaperLocation: wallpaperLocation,
        goToHome: true,
      );
      
      AppLogger.i('Wallpaper set from URL: $result');
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Error setting Android wallpaper from URL', e, stackTrace);
      return false;
    }
  }
  
  /// Set wallpaper on iOS (saves to Photos, user sets manually)
  Future<bool> _setWallpaperIOS(String filePath) async {
    try {
      // On iOS, we can only save to Photos
      // User needs to set wallpaper manually from Settings > Wallpaper
      
      // TODO: Implement gallery save for iOS
      // Use image_gallery_saver or similar package
      
      AppLogger.w('iOS: Image should be saved to Photos. User sets wallpaper manually.');
      return false;
    } catch (e, stackTrace) {
      AppLogger.e('Error on iOS wallpaper', e, stackTrace);
      return false;
    }
  }
  
  /// Show instructions for iOS users
  String getIOSInstructions() {
    return 'To set wallpaper on iOS:\n'
        '1. Open Photos app\n'
        '2. Find the downloaded image\n'
        '3. Tap Share → Use as Wallpaper\n'
        '4. Adjust and Set';
  }
}

