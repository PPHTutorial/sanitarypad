import 'package:dio/dio.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart';
import 'package:sanitarypad/services/config_service.dart';

class Dermatologist {
  final String name;
  final String? address;
  final String? rating;
  final String? reviewsCount;
  final String? phone;
  final String? website;
  final String? hours;
  final bool? isOpen;
  final String? distance;
  final String? placeId;
  final String? photoReference;

  Dermatologist({
    required this.name,
    this.address,
    this.rating,
    this.reviewsCount,
    this.phone,
    this.website,
    this.hours,
    this.isOpen,
    this.distance,
    this.placeId,
    this.photoReference,
  });

  String? getPhotoUrl(String apiKey) {
    if (photoReference == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=$photoReference'
        '&key=$apiKey';
  }
}

class DermatologistService {
  final Location _location = Location();
  final Dio _dio = Dio();
  final ConfigService _config = ConfigService();

  Future<List<Dermatologist>> findNearbyDermatologists() async {
    try {
      // 1. Get Location
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service disabled');
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission denied');
        }
      }

      final locData = await _location.getLocation();
      if (locData.latitude == null || locData.longitude == null) {
        throw Exception('Could not fetch location');
      }

      final lat = locData.latitude!;
      final lng = locData.longitude!;

      final apiKey = await _config.getMapsApiKey();
      if (apiKey == null) {
        debugPrint('Google Maps API key not found');
        return [];
      }

      // 2. Call Google Places Nearby Search API directly
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lng'
          '&radius=10000'
          '&type=doctor'
          '&keyword=dermatologist'
          '&key=$apiKey';

      final response = await _dio.get(url);
      final data = response.data as Map<String, dynamic>;

      if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
        return _parseResults(data['results'] as List);
      } else {
        debugPrint(
            'Places API Error: ${data['status']} - ${data['error_message']}');
        return [];
      }
    } catch (e) {
      debugPrint('Error finding dermatologists: $e');
      return [];
    }
  }

  /// Fetches detailed information for a specific place (phone, website, etc.)
  Future<Dermatologist?> getPlaceDetails(String placeId) async {
    try {
      final apiKey = await _config.getMapsApiKey();
      if (apiKey == null) return null;

      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,rating,user_ratings_total,formatted_phone_number,website,opening_hours,photos'
          '&key=$apiKey';

      final response = await _dio.get(url);
      final data = response.data as Map<String, dynamic>;
      if (data['status'] == 'OK') {
        final resultData = data['result'];
        return Dermatologist(
          name: resultData['name'] ?? '',
          address: resultData['formatted_address'],
          rating: resultData['rating']?.toString(),
          reviewsCount: resultData['user_ratings_total']?.toString(),
          phone: resultData['formatted_phone_number'],
          website: resultData['website'],
          isOpen: resultData['opening_hours']?['open_now'],
          placeId: placeId,
          photoReference: (resultData['photos'] as List?)?.isNotEmpty == true
              ? resultData['photos'][0]['photo_reference']
              : null,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching place details: $e');
      return null;
    }
  }

  List<Dermatologist> _parseResults(List<dynamic> jsonResults) {
    final results = <Dermatologist>[];

    for (final item in jsonResults) {
      try {
        results.add(Dermatologist(
          name: item['name'] ?? '',
          address: item['vicinity'], // Nearby search provides vicinity
          rating: item['rating']?.toString(),
          reviewsCount: item['user_ratings_total']?.toString(),
          isOpen: item['opening_hours']?['open_now'],
          placeId: item['place_id'],
          photoReference: (item['photos'] as List?)?.isNotEmpty == true
              ? item['photos'][0]['photo_reference']
              : null,
        ));
      } catch (e) {
        debugPrint('Error parsing an individual result: $e');
      }
    }

    return results;
  }

  Future<List<Dermatologist>> findNearbyDermatologistsViaTextSearch() async {
    return findNearbyDermatologists();
  }

  /// Gets the Google Maps API key via ConfigService
  Future<String?> getMapsApiKey() async {
    return _config.getMapsApiKey();
  }
}
