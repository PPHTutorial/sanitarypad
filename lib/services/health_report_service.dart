import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../data/models/cycle_model.dart';
import '../data/models/wellness_model.dart';
import '../data/models/pad_model.dart';
import '../services/cycle_service.dart';
import '../services/wellness_service.dart';
import '../services/pad_service.dart';

/// Health report service for generating PDF reports
class HealthReportService {
  final CycleService _cycleService = CycleService();
  final WellnessService _wellnessService = WellnessService();
  final PadService _padService = PadService();

  /// Generate comprehensive health report PDF
  Future<File> generateHealthReport({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final reportStartDate = startDate ?? now.subtract(const Duration(days: 90));
    final reportEndDate = endDate ?? now;

    // Fetch data
    final allCycles = await _cycleService.getCycles();
    final cycles = allCycles
        .where((c) =>
            c.startDate
                .isAfter(reportStartDate.subtract(const Duration(days: 1))) &&
            c.startDate.isBefore(reportEndDate.add(const Duration(days: 1))))
        .toList();

    final wellnessEntries = await _wellnessService.getWellnessEntries(
      startDate: reportStartDate,
      endDate: reportEndDate,
    );

    // Get pad history
    final pads = await _padService.getPadChanges(
      startDate: reportStartDate,
      endDate: reportEndDate,
    );

    // Create PDF
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildReportInfo(reportStartDate, reportEndDate),
            pw.SizedBox(height: 20),
            _buildCycleSummary(cycles),
            pw.SizedBox(height: 20),
            _buildWellnessSummary(wellnessEntries),
            pw.SizedBox(height: 20),
            _buildPadUsageSummary(pads),
            pw.SizedBox(height: 20),
            _buildRecommendations(cycles, wellnessEntries),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/health_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Share health report
  Future<void> shareHealthReport(File pdfFile) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'FemCare+ Health Report',
      text: 'My health report from FemCare+',
    );
  }

  /// Preview health report
  Future<void> previewHealthReport(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdfFile.readAsBytes(),
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FemCare+ Health Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.pink,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Comprehensive Health & Wellness Analysis',
          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildReportInfo(DateTime startDate, DateTime endDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Period',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
            style: pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCycleSummary(List<CycleModel> cycles) {
    if (cycles.isEmpty) {
      return pw.Text('No cycle data available for this period.');
    }

    final avgCycleLength =
        cycles.map((c) => c.cycleLength).reduce((a, b) => a + b) /
            cycles.length;
    final avgPeriodLength =
        cycles.map((c) => c.periodLength).reduce((a, b) => a + b) /
            cycles.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Menstrual Cycle Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBox('Total Cycles', cycles.length.toString()),
            _buildStatBox('Avg Cycle Length',
                '${avgCycleLength.toStringAsFixed(1)} days'),
            _buildStatBox('Avg Period Length',
                '${avgPeriodLength.toStringAsFixed(1)} days'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildWellnessSummary(List<WellnessModel> entries) {
    if (entries.isEmpty) {
      return pw.Text('No wellness data available for this period.');
    }

    final avgHydration =
        entries.map((e) => e.hydration.waterGlasses).reduce((a, b) => a + b) /
            entries.length;
    final avgSleep = entries.map((e) => e.sleep.hours).reduce((a, b) => a + b) /
        entries.length;
    final avgEnergy =
        entries.map((e) => e.mood.energyLevel).reduce((a, b) => a + b) /
            entries.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Wellness Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildStatBox(
                'Avg Hydration', '${avgHydration.toStringAsFixed(1)} glasses'),
            _buildStatBox('Avg Sleep', '${avgSleep.toStringAsFixed(1)} hours'),
            _buildStatBox('Avg Energy', '${avgEnergy.toStringAsFixed(1)}/5'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPadUsageSummary(List<PadModel> pads) {
    if (pads.isEmpty) {
      return pw.Text('No pad usage data available for this period.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pad Usage Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Total pad changes: ${pads.length}'),
      ],
    );
  }

  pw.Widget _buildRecommendations(
    List<CycleModel> cycles,
    List<WellnessModel> wellnessEntries,
  ) {
    final recommendations = <String>[];

    if (cycles.isNotEmpty) {
      final avgCycleLength =
          cycles.map((c) => c.cycleLength).reduce((a, b) => a + b) /
              cycles.length;
      if (avgCycleLength < 21 || avgCycleLength > 35) {
        recommendations.add(
          'Your cycle length (${avgCycleLength.toStringAsFixed(1)} days) is outside the normal range. Consider consulting with a healthcare provider.',
        );
      }
    }

    if (wellnessEntries.isNotEmpty) {
      final lowEnergyDays =
          wellnessEntries.where((e) => e.mood.energyLevel <= 2).length;
      if (lowEnergyDays > wellnessEntries.length * 0.3) {
        recommendations.add(
          'You\'ve been experiencing low energy on ${(lowEnergyDays / wellnessEntries.length * 100).toStringAsFixed(0)}% of tracked days. Consider reviewing your sleep and nutrition.',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations
          .add('Keep up the great work! Your health tracking looks good.');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Recommendations',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        ...recommendations.map((rec) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '• $rec',
                style: pw.TextStyle(fontSize: 11),
              ),
            )),
      ],
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.pink50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'This report is for informational purposes only and should not replace professional medical advice. Please consult with a healthcare provider for medical concerns.',
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
