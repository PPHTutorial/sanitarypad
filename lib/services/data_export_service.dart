import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/export_constants.dart';

/// Data export service
class DataExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export data to selected format
  Future<void> exportToFormat(String userId, ExportFormat format) async {
    try {
      final exportData = await _fetchAllUserData(userId);
      final fileName = generateExportFileName(userId);

      switch (format) {
        case ExportFormat.pdf:
          final pdfBytes = await _generatePdf(exportData);
          await _saveAndShareFile(pdfBytes, "$fileName.pdf");
          break;
        case ExportFormat.txt:
        case ExportFormat.docx:
          final textData = _formatAsText(exportData);
          final extension = format == ExportFormat.txt ? "txt" : "docx";
          await _saveAndShareFile(
            utf8.encode(textData),
            "$fileName.$extension",
          );
          break;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchAllUserData(String userId) async {
    return {
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
      'cycles': await _exportCycles(userId),
      'pads': await _exportPads(userId),
      'wellnessEntries': await _exportWellnessEntries(userId),
      'emergencyContacts': await _exportEmergencyContacts(userId),
      'subscription': await _exportSubscription(userId),
    };
  }

  String _formatAsText(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln("FemCare+ Data Export Summary");
    buffer.writeln("============================");
    buffer.writeln(
        "Date: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}");
    buffer.writeln("User ID: ${data['userId']}");
    buffer.writeln("\n");

    _appendSection(buffer, "Menstrual Cycles", data['cycles']);
    _appendSection(buffer, "Pad Usage Logs", data['pads']);
    _appendSection(buffer, "Wellness Journal Entries", data['wellnessEntries']);
    _appendSection(buffer, "Emergency Contacts", data['emergencyContacts']);
    _appendSection(buffer, "Subscription Status", [data['subscription']]);

    return buffer.toString();
  }

  /// Export subscription
  Future<Map<String, dynamic>> _exportSubscription(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionSubscriptions)
        .doc(userId)
        .get();

    if (!doc.exists) {
      return {'status': 'none', 'tier': 'free'};
    }

    final data = doc.data()!;
    return {
      'tier': data['tier'],
      'status': data['status'],
      'startDate': data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate().toIso8601String()
          : null,
      'endDate': data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate().toIso8601String()
          : null,
      'plan': data['plan'],
    };
  }

  void _appendSection(StringBuffer buffer, String title, List<dynamic> items) {
    buffer.writeln("## $title");
    buffer.writeln("-" * (title.length + 3));
    if (items.isEmpty) {
      buffer.writeln("No data recorded.\n");
      return;
    }
    for (var item in items) {
      buffer.writeln(JsonEncoder.withIndent('  ').convert(item));
      buffer.writeln("-" * 20);
    }
    buffer.writeln("\n");
  }

  Future<Uint8List> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text("FemCare+ Health Report",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text("Exported on: ${data['exportDate']}"),
            pw.Text("User ID: ${data['userId']}"),
            pw.SizedBox(height: 20),
            _buildPdfSection("Cycles", data['cycles']),
            _buildPdfSection("Pad Usage", data['pads']),
            _buildPdfSection("Wellness", data['wellnessEntries']),
            _buildPdfSection("Emergency Contacts", data['emergencyContacts']),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSection(String title, List<dynamic> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(),
        if (items.isEmpty)
          pw.Text("No data available.")
        else
          ...items.take(10).map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(item.toString(),
                    style: const pw.TextStyle(fontSize: 10)),
              )),
        if (items.length > 10) pw.Text("... (truncated for preview)"),
      ],
    );
  }

  Future<void> _saveAndShareFile(List<int> bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (Platform.isWindows) {
        // On Windows, sharing might not be as seamless as mobile.
        // We'll try to open the directory so the user can see their file.
        try {
          final xFile = XFile(file.path);
          await Share.shareXFiles([xFile], text: 'FemCare+ Data Export');
        } catch (e) {
          // Fallback: Open the folder containing the file
          final Uri uri = Uri.file(directory.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      } else {
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'FemCare+ Data Export');
      }
    } catch (e) {
      throw Exception('Failed to save or share file: ${e.toString()}');
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
        .orderBy('changeTime', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'changeTime':
            (data['changeTime'] as Timestamp).toDate().toIso8601String(),
        'padType': data['padType'],
        'flowIntensity': data['flowIntensity'],
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

  /// Original export logic (RESTORED/KEPT for compatibility if needed)
  Future<String> exportUserData(String userId) async {
    final data = await _fetchAllUserData(userId);
    return JsonEncoder.withIndent('  ').convert(data);
  }

  /// Generate export file name
  String generateExportFileName(String userId) {
    final date = DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'femcare_export_${userId.substring(0, 8)}_$dateStr';
  }
}
