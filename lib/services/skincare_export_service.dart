import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/skincare_model.dart';

class SkincareExportService {
  static final SkincareExportService _instance = SkincareExportService._();
  factory SkincareExportService() => _instance;
  SkincareExportService._();

  Future<void> exportJournalAsPdf(List<SkinJournalEntry> entries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('SkinCare+ Journal Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: <List<String>>[
                <String>['Date', 'Condition', 'Hydration', 'Oiliness', 'Notes'],
                ...entries.map((e) => [
                      DateFormat('MMM d, y').format(e.date),
                      e.skinCondition ?? 'N/A',
                      e.hydrationLevel?.toString() ?? 'N/A',
                      e.oilinessLevel?.toString() ?? 'N/A',
                      e.notes ?? '',
                    ])
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/skincare_journal_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'My Skincare Journal Report');
  }

  Future<void> shareDashboardSummary(Map<String, dynamic> stats) async {
    final summary = "🌟 My Skincare Progress Summary 🌟\n\n"
        "✨ Active Products: ${stats['productsCount']}\n"
        "💧 Hydration Level: ${stats['avgHydration']}/10\n"
        "😊 Current Feel: ${stats['currentCondition']}\n"
        "🎯 Goals Met: ${stats['goalsMet']}\n\n"
        "Tracked with SaniPad Wellness Hub";

    await Share.share(summary);
  }
}
