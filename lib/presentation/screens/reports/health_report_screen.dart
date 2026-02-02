import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/health_report_service.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Health report screen
class HealthReportScreen extends ConsumerStatefulWidget {
  const HealthReportScreen({super.key});

  @override
  ConsumerState<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends ConsumerState<HealthReportScreen> {
  final _reportService = HealthReportService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 90));
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _endDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _generateReport() async {
    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final pdfFile = await _reportService.generateHealthReport(
        userId: user.userId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        // Show options dialog
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Generated'),
            content: const Text('What would you like to do with the report?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('preview'),
                child: const Text('Preview'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('share'),
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('cancel'),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (action == 'preview') {
          await _reportService.previewHealthReport(pdfFile);
        } else if (action == 'share') {
          await _reportService.shareHealthReport(pdfFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Report'),
        ),
        body: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: AppTheme.lightPink,
                child: Padding(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: AppTheme.primaryPink,
                          ),
                          ResponsiveConfig.widthBox(8),
                          Text(
                            'Generate Health Report',
                            style: ResponsiveConfig.textStyle(
                              size: 18,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ResponsiveConfig.heightBox(12),
                      Text(
                        'Create a comprehensive PDF report of your health data including cycles, wellness entries, and pad usage. Perfect for sharing with healthcare providers.',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ResponsiveConfig.heightBox(24),

              // Date Range Selection
              Text(
                'Report Period',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.bold,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              Card(
                child: Padding(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _selectStartDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _startDate != null
                                ? DateFormat('MMM dd, yyyy').format(_startDate!)
                                : 'Select start date',
                          ),
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      InkWell(
                        onTap: _selectEndDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                : 'Select end date',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ResponsiveConfig.heightBox(24),

              // Quick Date Presets
              Text(
                'Quick Presets',
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.bold,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetButton('Last 30 Days', () {
                    setState(() {
                      _endDate = DateTime.now();
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 30));
                    });
                  }),
                  _buildPresetButton('Last 90 Days', () {
                    setState(() {
                      _endDate = DateTime.now();
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 90));
                    });
                  }),
                  _buildPresetButton('Last 6 Months', () {
                    setState(() {
                      _endDate = DateTime.now();
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 180));
                    });
                  }),
                  _buildPresetButton('Last Year', () {
                    setState(() {
                      _endDate = DateTime.now();
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 365));
                    });
                  }),
                ],
              ),
              ResponsiveConfig.heightBox(32),

              // Generate Button
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isGenerating
                      ? 'Generating Report...'
                      : 'Generate PDF Report',
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: ResponsiveConfig.padding(vertical: 16),
                ),
              ),
              ResponsiveConfig.heightBox(16),

              // Disclaimer
              Card(
                color: AppTheme.palePink,
                child: Padding(
                  padding: ResponsiveConfig.padding(all: 12),
                  child: Text(
                    'This report is for informational purposes only and should not replace professional medical advice.',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ).copyWith(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
