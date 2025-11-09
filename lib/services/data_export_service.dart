import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../core/constants/app_constants.dart';

/// Data export service
class DataExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export all user data
  Future<String> exportUserData(String userId) async {
    try {
      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'cycles': await _exportCycles(userId),
        'pads': await _exportPads(userId),
        'wellnessEntries': await _exportWellnessEntries(userId),
        'emergencyContacts': await _exportEmergencyContacts(userId),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      return jsonString;
    } catch (e) {
      rethrow;
    }
  }

  /// Export cycles
  Future<List<Map<String, dynamic>>> _exportCycles(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionCycles)
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'startDate':
            (data['startDate'] as Timestamp).toDate().toIso8601String(),
        'endDate': data['endDate'] != null
            ? (data['endDate'] as Timestamp).toDate().toIso8601String()
            : null,
        'cycleLength': data['cycleLength'],
        'periodLength': data['periodLength'],
        'flowIntensity': data['flowIntensity'],
        'symptoms': data['symptoms'],
        'mood': data['mood'],
        'notes': data['notes'],
      };
    }).toList();
  }

  /// Export pads
  Future<List<Map<String, dynamic>>> _exportPads(String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionPads)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'timestamp':
            (data['timestamp'] as Timestamp).toDate().toIso8601String(),
        'padType': data['padType'],
        'changeReason': data['changeReason'],
        'notes': data['notes'],
      };
    }).toList();
  }

  /// Export wellness entries
  Future<List<Map<String, dynamic>>> _exportWellnessEntries(
      String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionWellnessEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'date': (data['date'] as Timestamp).toDate().toIso8601String(),
        'hydration': data['hydration'],
        'sleep': data['sleep'],
        'appetite': data['appetite'],
        'mood': data['mood'],
        'exercise': data['exercise'],
        'journal': data['journal'],
      };
    }).toList();
  }

  /// Export emergency contacts
  Future<List<Map<String, dynamic>>> _exportEmergencyContacts(
      String userId) async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionSupportContacts)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'],
        'phoneNumber': data['phoneNumber'],
        'email': data['email'],
        'relationship': data['relationship'],
        'isPrimary': data['isPrimary'],
      };
    }).toList();
  }

  /// Save export to file and share
  Future<void> saveAndShareExport(String jsonData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.json');
      await file.writeAsString(jsonData);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'FemCare+ Data Export');
    } catch (e) {
      rethrow;
    }
  }

  /// Generate export file name
  String generateExportFileName(String userId) {
    final date = DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'femcare_export_${userId.substring(0, 8)}_$dateStr';
  }
}
