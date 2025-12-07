import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/logger.dart';

/// Service to handle all app permissions
/// Uses permission_handler 12.0.1 latest API
class PermissionService {
  static PermissionService? _instance;

  PermissionService._();

  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }

  /// Check if we have storage/media permissions
  Future<bool> hasStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ uses photos permission
        final photosStatus = await Permission.photos.status;
        // Also check storage for Android 12 and below
        final storageStatus = await Permission.storage.status;

        return photosStatus.isGranted || storageStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        return photosStatus.isGranted;
      }
      return false;
    } catch (e) {
      AppLogger.e('Error checking storage permission', e);
      return false;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission({BuildContext? context}) async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ request photos permission
        final photosStatus = await Permission.photos.request();

        if (photosStatus.isGranted) {
          return true;
        }

        // Also request storage permission for older Android versions
        final storageStatus = await Permission.storage.request();

        if (storageStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          if (context != null && context.mounted) {
            await _showOpenSettingsDialog(context);
          }
          return false;
        }

        return photosStatus.isGranted || storageStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();

        if (photosStatus.isPermanentlyDenied) {
          if (context != null && context.mounted) {
            await _showOpenSettingsDialog(context);
          }
          return false;
        }

        return photosStatus.isGranted;
      }
      return false;
    } catch (e) {
      AppLogger.e('Error requesting storage permission', e);
      return false;
    }
  }

  /// Request all required permissions
  Future<bool> requestAllPermissions({BuildContext? context}) async {
    try {
      if (Platform.isAndroid) {
        // Request photos permission (Android 13+)
        final photosStatus = await Permission.photos.request();

        // Request storage permission (Android 12 and below)
        final storageStatus = await Permission.storage.request();

        // Check if either is granted
        final isGranted = photosStatus.isGranted || storageStatus.isGranted;

        if (!isGranted &&
            (photosStatus.isPermanentlyDenied ||
                storageStatus.isPermanentlyDenied)) {
          if (context != null && context.mounted) {
            await _showOpenSettingsDialog(context);
          }
          return false;
        }

        return isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();

        if (photosStatus.isPermanentlyDenied) {
          if (context != null && context.mounted) {
            await _showOpenSettingsDialog(context);
          }
          return false;
        }

        return photosStatus.isGranted;
      }
      return false;
    } catch (e) {
      AppLogger.e('Error requesting all permissions', e);
      return false;
    }
  }

  /// Show dialog to open settings
  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'We need permission to save wallpapers to your device.\n\nPlease grant this permission in settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if notification permission is granted (for downloads)
  Future<bool> hasNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ requires notification permission
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      return true; // iOS doesn't require explicit notification permission
    } catch (e) {
      AppLogger.e('Error checking notification permission', e);
      return true; // Default to true to not block app functionality
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return true;
    } catch (e) {
      AppLogger.e('Error requesting notification permission', e);
      return true;
    }
  }

  /// Check multiple permissions at once
  Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final Map<Permission, PermissionStatus> result = {};
      for (final permission in permissions) {
        final status = await permission.status;
        result[permission] = status;
      }
      return result;
    } catch (e) {
      AppLogger.e('Error checking multiple permissions', e);
      return {};
    }
  }

  /// Request multiple permissions at once
  Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      final Map<Permission, PermissionStatus> result = {};
      for (final permission in permissions) {
        final status = await permission.request();
        result[permission] = status;
      }
      return result;
    } catch (e) {
      AppLogger.e('Error requesting multiple permissions', e);
      return {};
    }
  }

  /// Open app settings
  Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      AppLogger.e('Error opening app settings', e);
      return false;
    }
  }

  /// Check if should show permission rationale
  Future<bool> shouldShowRequestRationale(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isDenied;
    } catch (e) {
      AppLogger.e('Error checking permission rationale', e);
      return false;
    }
  }
}
