import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _cachedMapsApiKey;

  /// Initializes the config by attempting to load the API key from secure storage
  Future<void> initialize() async {
    try {
      _cachedMapsApiKey = await _secureStorage.read(key: 'google_maps_api_key');
      if (_cachedMapsApiKey == null) {
        await getMapsApiKey(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Error initializing ConfigService: $e');
    }
  }

  /// Gets the Google Maps API key from memory, secure storage, or Firestore
  Future<String?> getMapsApiKey({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMapsApiKey != null) {
      return _cachedMapsApiKey;
    }

    try {
      // Fetch from Firestore
      final doc =
          await _firestore.collection('app_config').doc('maps_api').get();
      if (doc.exists && doc.data()?.containsKey('key') == true) {
        final key = doc.data()!['key'] as String;

        // Cache in memory and secure storage
        _cachedMapsApiKey = key;
        await _secureStorage.write(key: 'google_maps_api_key', value: key);

        return key;
      }
    } catch (e) {
      debugPrint('Error fetching Maps API Key from Firestore: $e');
    }

    return _cachedMapsApiKey;
  }
}
