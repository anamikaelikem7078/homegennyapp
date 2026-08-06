import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/staff_scaffold.dart';

/// Document preview with approval status.
class StaffDocumentDetailScreen extends ConsumerWidget {
  const StaffDocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(staffDocumentProvider(documentId));

    return StaffPageScaffold(
      title: 'Document Preview',
      body: document.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Error',
          onRetry: () => ref.invalidate(staffDocumentProvider(documentId)),
        ),
        data: (doc) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: AppDecorations.softCard(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 64,
                    color: AppColors.secondary.withValues(alpha: 0.8),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(doc.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('${doc.type} · ${doc.uploadedAt}'),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text('Approval Status', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                DsStatusChip(
                  label: _statusLabel(doc.status),
                  type: _statusType(doc.status),
                ),
              ],
            ),
            if (doc.status == DocumentApprovalStatus.rejected &&
                doc.rejectionReason != null) ...[
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(doc.rejectionReason!)),
                  ],
                ),
              ),
            ],
            const Spacer(),
            if (doc.status == DocumentApprovalStatus.rejected)
              DsPrimaryButton(
                label: 'Re-upload Document',
                icon: Icons.upload_file_rounded,
                onPressed: () =>
                    context.push(StaffRoutes.documentReupload(documentId)),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(DocumentApprovalStatus s) => switch (s) {
        DocumentApprovalStatus.approved => 'Approved',
        DocumentApprovalStatus.pending => 'Pending',
        DocumentApprovalStatus.rejected => 'Rejected',
      };

  DsStatusType _statusType(DocumentApprovalStatus s) => switch (s) {
        DocumentApprovalStatus.approved => DsStatusType.success,
        DocumentApprovalStatus.pending => DsStatusType.warning,
        DocumentApprovalStatus.rejected => DsStatusType.error,
      };
}

/// Re-upload rejected document.
class StaffDocumentReuploadScreen extends ConsumerStatefulWidget {
  const StaffDocumentReuploadScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<StaffDocumentReuploadScreen> createState() =>
      _StaffDocumentReuploadScreenState();
}

class _StaffDocumentReuploadScreenState
    extends ConsumerState<StaffDocumentReuploadScreen> {
  List<PlatformFile> _files = [];
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_files.isEmpty) {
      context.showDsSnackBar('Select a file', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await ref.read(staffRepositoryProvider).reuploadDocument(
          widget.documentId,
          _files.first.name,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffDocumentsProvider);
        ref.invalidate(staffDocumentProvider(widget.documentId));
        context.showDsSnackBar('Document re-uploaded', type: DsSnackBarType.success);
        context.go(StaffRoutes.documents);
      },
      onError: (f) =>
          context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaffPageScaffold(
      title: 'Re-upload Document',
      subtitle: 'Submit a clear copy',
      body: Column(
        children: [
          DsDocumentPicker(
            label: 'Select new file',
            onDocumentPicked: (f) => setState(() => _files = f),
          ),
          const Spacer(),
          DsPrimaryButton(
            label: 'Submit for Review',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
