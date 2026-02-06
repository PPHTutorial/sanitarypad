import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../core/constants/export_constants.dart';

class HealthReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate a health report in the specified format
  Future<String> generateReport({
    required String userId,
    required ExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userData = await _getUserData(userId);
      final periodLogs = await _getPeriodLogs(userId, startDate, endDate);
      final wellnessJournal =
          await _getWellnessJournal(userId, startDate, endDate);

      switch (format) {
        case ExportFormat.pdf:
          return await _generatePdfReport(
              userData, periodLogs, wellnessJournal);
        case ExportFormat.txt:
          return await _generateTextReport(
              userData, periodLogs, wellnessJournal);
        case ExportFormat.docx:
          return await _generateTextReport(
              userData, periodLogs, wellnessJournal,
              isWord: true);
      }
    } catch (e) {
      throw Exception('Failed to generate report: ${e.toString()}');
    }
  }

  /// Maintain compatibility with existing screens
  Future<String> generateHealthReport({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    ExportFormat format = ExportFormat.pdf,
  }) async {
    return generateReport(
      userId: userId,
      format: format,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> shareHealthReport(String filePath) async {
    await Share.shareXFiles([XFile(filePath)],
        text: 'My FemCare+ Health Report');
  }

  Future<void> previewHealthReport(String filePath) async {
    if (filePath.endsWith('.pdf')) {
      final file = File(filePath);
      await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
    } else {
      await shareHealthReport(filePath);
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  Future<List<Map<String, dynamic>>> _getPeriodLogs(
      String userId, DateTime? start, DateTime? end) async {
    var query =
        _firestore.collection('pad_logs').where('userId', isEqualTo: userId);

    if (start != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: start);
    }
    if (end != null) query = query.where('timestamp', isLessThanOrEqualTo: end);

    final snapshot =
        await query.orderBy('timestamp', descending: true).limit(100).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _getWellnessJournal(
      String userId, DateTime? start, DateTime? end) async {
    var query = _firestore
        .collection('wellness_journal')
        .where('userId', isEqualTo: userId);

    if (start != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: start);
    }
    if (end != null) query = query.where('createdAt', isLessThanOrEqualTo: end);

    final snapshot =
        await query.orderBy('createdAt', descending: true).limit(50).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> _generatePdfReport(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> journal,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('FemCare+ Health Report',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 24)),
                  pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
                'Patient: ${user['fullName'] ?? user['displayName'] ?? 'N/A'}',
                style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
                'DOB: ${user['dateOfBirth'] != null ? DateFormat('MMM dd, yyyy').format((user['dateOfBirth'] as Timestamp).toDate()) : 'N/A'}'),
            pw.SizedBox(height: 20),
            pw.Text('Recent Period History',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            ...logs.map((log) {
              final date = (log['timestamp'] as Timestamp).toDate();
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                        width: 100,
                        child: pw.Text(DateFormat('MMM dd').format(date))),
                    pw.Text(
                        'Flow: ${log['flow'] ?? 'N/A'} | Pad: ${log['padBrand'] ?? 'N/A'}'),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 20),
            pw.Text('Recent Wellness Journal',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Divider(),
            ...journal.map((j) {
              final date = (j['createdAt'] as Timestamp).toDate();
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(DateFormat('MMM dd, yyyy').format(date),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(j['content'] ?? 'No content'),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/health_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<String> _generateTextReport(
    Map<String, dynamic> user,
    List<Map<String, dynamic>> logs,
    List<Map<String, dynamic>> journal, {
    bool isWord = false,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('FEMCARE+ HEALTH REPORT');
    buffer.writeln(
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('-----------------------------------');
    buffer.writeln(
        'Patient: ${user['fullName'] ?? user['displayName'] ?? 'N/A'}');
    buffer.writeln('-----------------------------------');
    buffer.writeln('\nPERIOD HISTORY');
    for (var log in logs) {
      final date = (log['timestamp'] as Timestamp).toDate();
      buffer.writeln(
          '${DateFormat('yyyy-MM-dd').format(date)}: Flow=${log['flow']}, Pad=${log['padBrand']}');
    }
    buffer.writeln('\nWELLNESS JOURNAL');
    for (var j in journal) {
      final date = (j['createdAt'] as Timestamp).toDate();
      buffer
          .writeln('${DateFormat('yyyy-MM-dd').format(date)}: ${j['content']}');
    }

    final tempDir = await getTemporaryDirectory();
    final ext = isWord ? 'docx' : 'txt';
    final file = File('${tempDir.path}/health_report.$ext');
    await file.writeAsString(buffer.toString());

    return file.path;
  }
}
