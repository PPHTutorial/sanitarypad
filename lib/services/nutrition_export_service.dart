import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/nutrition_models.dart';

class NutritionExportService {
  static final NutritionExportService _instance = NutritionExportService._();
  factory NutritionExportService() => _instance;
  NutritionExportService._();

  Future<void> exportMealLogsAsPdf(List<MealEntry> entries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Nutrition+ Meal Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: <List<String>>[
                <String>['Date', 'Meal', 'Type', 'Calories', 'Macros (P/C/F)'],
                ...entries.map((e) => [
                      DateFormat('MMM d, y').format(e.loggedAt),
                      e.name,
                      e.type.name.toUpperCase(),
                      '${e.calories} kcal',
                      '${e.protein}g / ${e.carbs}g / ${e.fat}g',
                    ])
              ],
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/nutrition_meal_report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'My Nutrition Meal Report');
  }

  Future<void> shareNutritionSummary(Map<String, dynamic> stats) async {
    final summary = "🥗 My Nutrition Progress Summary 🥗\n\n"
        "🔥 Avg Daily Calories: ${stats['avgCalories']} kcal\n"
        "⚖️ Weight Progress: ${stats['weightChange']} kg\n"
        "🍱 Meals Logged: ${stats['mealCount']}\n"
        "🎯 Goals Progress: ${stats['goalsCompletion']}%\n\n"
        "Tracked with SaniPad Wellness Hub";

    await Share.share(summary);
  }
}
