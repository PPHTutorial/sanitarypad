import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class DataBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Backup all user data to a JSON file and share it
  Future<void> backupUserData(String userId) async {
    try {
      final Map<String, dynamic> backupData = {
        'version': '1.0.0',
        'backupDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'data': {},
      };

      // Collections to backup
      final collections = [
        'users',
        'entries',
        'pad_logs',
        'log_entries',
        'events',
        'wellness_journal',
        'wellness_favorites',
        'social_posts',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore
            .collection(collection)
            .where('userId', isEqualTo: userId)
            .get();

        backupData['data'][collection] =
            snapshot.docs.map((doc) => doc.data()).toList();
      }

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'FemCare_Backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Share file
      await Share.shareXFiles([XFile(file.path)],
          text: 'My FemCare+ Data Backup');
    } catch (e) {
      throw Exception('Backup failed: ${e.toString()}');
    }
  }

  /// Restore user data from a JSON file
  Future<void> restoreUserData(String userId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backupData['userId'] != userId) {
        // Optional: Allow restore to different user? Usually safer to restrict or warn
        throw Exception('Backup belongs to a different user account');
      }

      final data = backupData['data'] as Map<String, dynamic>;

      // Batch write to avoid many individual writes
      final batch = _firestore.batch();

      for (final entry in data.entries) {
        final collection = entry.key;
        final docs = entry.value as List<dynamic>;

        for (final docData in docs) {
          final docMap = docData as Map<String, dynamic>;
          // Use the original ID if possible, otherwise auto-ID
          final docId = docMap['id'] ??
              docMap['userId'] +
                  '_' +
                  DateTime.now().millisecondsSinceEpoch.toString();
          final docRef = _firestore.collection(collection).doc(docId);
          batch.set(docRef, docMap, SetOptions(merge: true));
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Restore failed: ${e.toString()}');
    }
  }
}
