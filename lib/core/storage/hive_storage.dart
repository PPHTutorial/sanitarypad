import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Hive local storage service
class HiveStorage {
  static Box? _box;

  /// Initialize Hive
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(AppConstants.hiveBoxName);
  }

  /// Get box instance
  static Box get box {
    if (_box == null) {
      throw Exception('Hive not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// Save data
  static Future<void> save(String key, dynamic value) async {
    await box.put(key, value);
  }

  /// Get data
  static T? get<T>(String key) {
    return box.get(key) as T?;
  }

  /// Delete data
  static Future<void> delete(String key) async {
    await box.delete(key);
  }

  /// Clear all data
  static Future<void> clear() async {
    await box.clear();
  }

  /// Check if key exists
  static bool containsKey(String key) {
    return box.containsKey(key);
  }

  /// Get all keys
  static Iterable<dynamic> getKeys() {
    return box.keys;
  }

  /// Get all values
  static Iterable<dynamic> getValues() {
    return box.values;
  }
}
