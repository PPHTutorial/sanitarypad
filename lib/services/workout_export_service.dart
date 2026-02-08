import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/workout_models.dart';

class WorkoutExportService {
  static final WorkoutExportService _instance = WorkoutExportService._();
  factory WorkoutExportService() => _instance;
  WorkoutExportService._();

  Future<void> exportWorkoutHistoryAsPdf(List<WorkoutSession> sessions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Workout+ Performance Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: <List<String>>[
                <String>[
                  'Date',
                  'Workout',
                  'Duration',
                  'Cals Burned',
                  'Exercises'
                ],
                ...sessions.map((s) => [
                      DateFormat('MMM d, y').format(s.startedAt),
                      s.name,
                      '${s.totalDuration.inMinutes} min',
                      '${s.totalCaloriesBurned} kcal',
                      s.exercises.length.toString(),
                    ])
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/workout_performance_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'My Workout Performance Report');
  }

  Future<void> shareWorkoutSummary(Map<String, dynamic> stats) async {
    final summary = "💪 My Workout Progress Summary 💪\n\n"
        "⏱️ Total Training: ${stats['totalHours']} hours\n"
        "🔥 Calories Burned: ${stats['totalCalories']} kcal\n"
        "🏋️ Sessions: ${stats['sessionCount']}\n"
        "🏆 Most Frequent: ${stats['topCategory']}\n\n"
        "Tracked with SaniPad Wellness Hub";

    await Share.share(summary);
  }
}
