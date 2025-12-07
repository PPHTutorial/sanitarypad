import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/themes/app_colors.dart';
import '../../app/themes/app_text_styles.dart';
import '../../app/themes/app_dimensions.dart';

/// Progress dialog for download operations
class DownloadProgressDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final double progress;
  final String? currentItem;
  final int totalItems;
  final int completedItems;
  final bool isIndeterminate;
  final VoidCallback? onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.progress = 0.0,
    this.currentItem,
    this.totalItems = 0,
    this.completedItems = 0,
    this.isIndeterminate = false,
    this.onCancel,
  });

  @override
  State<DownloadProgressDialog> createState() => _DownloadProgressDialogState();

  /// Show progress dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Stream<double> progressStream,
    Stream<String>? currentItemStream,
    required int totalItems,
    Stream<int>? completedItemsStream,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProgressDialogBuilder(
        title: title,
        subtitle: subtitle,
        progressStream: progressStream,
        currentItemStream: currentItemStream,
        totalItems: totalItems,
        completedItemsStream: completedItemsStream,
        onCancel: onCancel,
      ),
    );
  }
}

class _DownloadProgressDialogState extends State<DownloadProgressDialog> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing during download
      child: Dialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                widget.title,
                style: AppTextStyles.headline6,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.space8),
              
              // Subtitle
              if (widget.subtitle != null) ...[
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.space16),
              ],
              
              // Progress indicator
              if (widget.isIndeterminate)
                const CircularProgressIndicator()
              else ...[
                LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: AppColors.darkSurface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                  minHeight: 8.h,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                SizedBox(height: AppDimensions.space12),
                
                // Progress text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.totalItems > 0)
                      Text(
                        '${widget.completedItems}/${widget.totalItems}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Current item
              if (widget.currentItem != null && widget.currentItem!.isNotEmpty) ...[
                SizedBox(height: AppDimensions.space16),
                Container(
                  padding: EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 16.w,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: Text(
                          widget.currentItem!,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: AppDimensions.space16),
              
              // Cancel button (if allowed)
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDialogBuilder extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Stream<double> progressStream;
  final Stream<String>? currentItemStream;
  final int totalItems;
  final Stream<int>? completedItemsStream;
  final VoidCallback? onCancel;

  const _ProgressDialogBuilder({
    required this.title,
    this.subtitle,
    required this.progressStream,
    this.currentItemStream,
    required this.totalItems,
    this.completedItemsStream,
    this.onCancel,
  });

  @override
  State<_ProgressDialogBuilder> createState() => _ProgressDialogBuilderState();
}

class _ProgressDialogBuilderState extends State<_ProgressDialogBuilder> {
  double _progress = 0.0;
  String? _currentItem;
  int _completedItems = 0;

  @override
  void initState() {
    super.initState();
    widget.progressStream.listen((progress) {
      if (mounted) setState(() => _progress = progress.clamp(0.0, 1.0));
    });
    
    widget.currentItemStream?.listen((item) {
      if (mounted) setState(() => _currentItem = item);
    });
    
    widget.completedItemsStream?.listen((completed) {
      if (mounted) setState(() => _completedItems = completed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DownloadProgressDialog(
      title: widget.title,
      subtitle: widget.subtitle,
      progress: _progress,
      currentItem: _currentItem,
      totalItems: widget.totalItems,
      completedItems: _completedItems,
      onCancel: widget.onCancel != null
          ? () {
              widget.onCancel?.call();
              if (mounted) Navigator.of(context).pop();
            }
          : null,
    );
  }
}

