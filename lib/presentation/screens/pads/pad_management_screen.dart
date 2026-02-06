import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/pad_provider.dart';
import '../../../services/credit_manager.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import 'package:sanitarypad/presentation/widgets/ads/eco_ad_wrapper.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Pad management screen
class PadManagementScreen extends ConsumerStatefulWidget {
  const PadManagementScreen({super.key});

  @override
  ConsumerState<PadManagementScreen> createState() =>
      _PadManagementScreenState();
}

class _PadManagementScreenState extends ConsumerState<PadManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _changeTime = DateTime.now();
  String _padType = AppConstants.padTypeRegular;
  String _flowIntensity = AppConstants.flowMedium;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_changeTime),
    );
    if (picked != null) {
      setState(() {
        _changeTime = DateTime(
          _changeTime.year,
          _changeTime.month,
          _changeTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _changeTime,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _changeTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _changeTime.hour,
          _changeTime.minute,
        );
      });
    }
  }

  Future<void> _logPadChange() async {
    if (!_formKey.currentState!.validate()) return;

    // Credit Check
    final hasCredit = await ref
        .read(creditManagerProvider)
        .requestCredit(context, ActionType.padChange);
    if (!hasCredit) return;

    setState(() => _isLoading = true);

    try {
      final padService = ref.read(padServiceProvider);
      await padService.logPadChange(
        changeTime: _changeTime,
        padType: _padType,
        flowIntensity: _flowIntensity,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await ref
          .read(creditManagerProvider)
          .consumeCredits(ActionType.padChange);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pad change logged successfully')),
        );
        setState(() {
          _changeTime = DateTime.now();
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(padInventoryStreamProvider);
    final recentPadsAsync = ref.watch(padChangesStreamProvider);
    final lowStockItems = ref.watch(lowStockItemsProvider);

    return BackButtonHandler(
        fallbackRoute: '/home',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pad Management'),
          ),
          bottomNavigationBar: const EcoAdWrapper(adType: AdType.banner),
          body: SingleChildScrollView(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Current Stock
                _buildInventorySection(
                    context, inventoryAsync.value ?? [], lowStockItems),
                ResponsiveConfig.heightBox(24),

                // Log Pad Change
                _buildLogPadSection(context),
                ResponsiveConfig.heightBox(24),

                // Recent Changes
                _buildRecentChangesSection(
                    context, recentPadsAsync.value ?? []),
              ],
            ),
          ),
        ));
  }

  Widget _buildInventorySection(
    BuildContext context,
    List inventory,
    List lowStockItems,
  ) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Stock',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to inventory management
                    _showAddStockDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stock'),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            if (inventory.isEmpty)
              Text(
                'No inventory tracked yet',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...inventory.map<Widget>((item) {
                final isLow = lowStockItems.contains(item);
                return Padding(
                  padding: ResponsiveConfig.padding(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.padType.toUpperCase(),
                              style: ResponsiveConfig.textStyle(
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (item.brand != null)
                              Text(
                                item.brand!,
                                style: ResponsiveConfig.textStyle(
                                  size: 12,
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${item.quantity} pads',
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                              weight:
                                  isLow ? FontWeight.w600 : FontWeight.normal,
                              color: isLow ? AppTheme.errorRed : null,
                            ),
                          ),
                          if (isLow) ...[
                            ResponsiveConfig.widthBox(8),
                            Container(
                              padding: ResponsiveConfig.padding(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: ResponsiveConfig.borderRadius(4),
                              ),
                              child: Text(
                                'LOW!',
                                style: ResponsiveConfig.textStyle(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLogPadSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log Pad Change',
                style: ResponsiveConfig.textStyle(
                  size: 18,
                  weight: FontWeight.w600,
                ),
              ),
              ResponsiveConfig.heightBox(16),
              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          app_date_utils.DateUtils.formatDate(_changeTime),
                        ),
                      ),
                    ),
                  ),
                  ResponsiveConfig.widthBox(12),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          app_date_utils.DateUtils.formatTime(_changeTime),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(16),
              // Pad Type
              Text(
                'Pad Type',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w500,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              _buildPadTypeSelector(),
              ResponsiveConfig.heightBox(16),
              // Flow Intensity
              Text(
                'Flow Intensity',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w500,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              _buildFlowIntensitySelector(),
              ResponsiveConfig.heightBox(16),
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any notes...',
                ),
                maxLines: 2,
              ),
              ResponsiveConfig.heightBox(16),
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _logPadChange,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log Pad Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPadTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPadTypeOption('Light', AppConstants.padTypeLight),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child: _buildPadTypeOption('Regular', AppConstants.padTypeRegular),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child: _buildPadTypeOption('Super', AppConstants.padTypeSuper),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child:
              _buildPadTypeOption('Overnight', AppConstants.padTypeOvernight),
        ),
      ],
    );
  }

  Widget _buildPadTypeOption(String label, String value) {
    final isSelected = _padType == value;
    return InkWell(
      onTap: () => setState(() => _padType = value),
      child: Container(
        padding: ResponsiveConfig.padding(all: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightPink : AppTheme.palePink,
          borderRadius: ResponsiveConfig.borderRadius(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: ResponsiveConfig.textStyle(
            size: 12,
            weight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryPink : AppTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFlowIntensitySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildFlowOption('Light', AppConstants.flowLight),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child: _buildFlowOption('Medium', AppConstants.flowMedium),
        ),
        ResponsiveConfig.widthBox(8),
        Expanded(
          child: _buildFlowOption('Heavy', AppConstants.flowHeavy),
        ),
      ],
    );
  }

  Widget _buildFlowOption(String label, String value) {
    final isSelected = _flowIntensity == value;
    return InkWell(
      onTap: () => setState(() => _flowIntensity = value),
      child: Container(
        padding: ResponsiveConfig.padding(all: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightPink : AppTheme.palePink,
          borderRadius: ResponsiveConfig.borderRadius(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryPink : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: ResponsiveConfig.textStyle(
            size: 12,
            weight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.primaryPink : AppTheme.mediumGray,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRecentChangesSection(BuildContext context, List recentPads) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Changes',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (recentPads.isEmpty)
              Text(
                'No pad changes logged yet',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...recentPads.take(5).map<Widget>((pad) {
                return Padding(
                  padding: ResponsiveConfig.padding(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sanitizer,
                        color: AppTheme.primaryPink,
                        size: ResponsiveConfig.iconSize(20),
                      ),
                      ResponsiveConfig.widthBox(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app_date_utils.DateUtils.formatTime(
                                  pad.changeTime),
                              style: ResponsiveConfig.textStyle(
                                size: 14,
                                weight: FontWeight.w600,
                              ),
                            ),
                            ResponsiveConfig.heightBox(2),
                            Text(
                              '${pad.padType.toUpperCase()} - ${pad.flowIntensity}',
                              style: ResponsiveConfig.textStyle(
                                size: 12,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pad.duration > 0)
                        Text(
                          '${pad.duration}h',
                          style: ResponsiveConfig.textStyle(
                            size: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context) {
    final quantityController = TextEditingController();
    final brandController = TextEditingController();
    String selectedType = AppConstants.padTypeRegular;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Pad Type'),
                items: [
                  AppConstants.padTypeLight,
                  AppConstants.padTypeRegular,
                  AppConstants.padTypeSuper,
                  AppConstants.padTypeOvernight,
                ].map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedType = value);
                  }
                },
              ),
              ResponsiveConfig.heightBox(16),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              ResponsiveConfig.heightBox(16),
              TextFormField(
                controller: brandController,
                decoration:
                    const InputDecoration(labelText: 'Brand (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity = int.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid quantity')),
                  );
                  return;
                }

                try {
                  final padService = ref.read(padServiceProvider);
                  await padService.updateInventory(
                    padType: selectedType,
                    quantity: quantity,
                    brand: brandController.text.isEmpty
                        ? null
                        : brandController.text,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Stock updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
