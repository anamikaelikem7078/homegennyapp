import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Document picker widget for PDF and office files.
class DsDocumentPicker extends StatefulWidget {
  const DsDocumentPicker({
    super.key,
    required this.onDocumentPicked,
    this.label,
    this.allowedExtensions,
    this.allowMultiple = false,
  });

  final ValueChanged<List<PlatformFile>> onDocumentPicked;
  final String? label;
  final List<String>? allowedExtensions;
  final bool allowMultiple;

  @override
  State<DsDocumentPicker> createState() => _DsDocumentPickerState();
}

class _DsDocumentPickerState extends State<DsDocumentPicker> {
  List<PlatformFile> _files = [];

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: widget.allowedExtensions != null
          ? FileType.custom
          : FileType.any,
      allowedExtensions: widget.allowedExtensions,
      allowMultiple: widget.allowMultiple,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _files = result.files);
      widget.onDocumentPicked(result.files);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.labelLarge),
          SizedBox(height: AppSpacing.xs),
        ],
        GestureDetector(
          onTap: _pickDocuments,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.softCard(context).copyWith(
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
              ),
            ),
            child: _files.isEmpty
                ? Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload document',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              'PDF, DOC, XLS supported',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  )
                : Column(
                    children: _files
                        .map(
                          (f) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.insert_drive_file_outlined),
                            title: Text(
                              f.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              f.size > 0
                                  ? '${(f.size / 1024).toStringAsFixed(1)} KB'
                                  : 'Unknown size',
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}
