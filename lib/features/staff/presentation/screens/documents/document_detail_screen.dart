import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import 'documents_screen.dart' show documentStatusStyle;
import 'upload_document_screen.dart';

/// Document preview with approval status.
class StaffDocumentDetailScreen extends ConsumerWidget {
  const StaffDocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final document = ref.watch(staffDocumentProvider(documentId));
    final rejected = document.valueOrNull?.status == DocumentApprovalStatus.rejected;

    return DsPage(
      title: 'Document',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.documents),
      onRefresh: () async => ref.invalidate(staffDocumentProvider(documentId)),
      bottom: rejected
          ? DsGradientButton(
              label: 'Re-upload document',
              icon: Icons.upload_file_rounded,
              onPressed: () => context.push(StaffRoutes.documentReupload(documentId)),
            )
          : null,
      body: dsAsyncBody(
        document,
        onRetry: () => ref.invalidate(staffDocumentProvider(documentId)),
        builder: (doc) {
          final (color, icon, label, gradient) = documentStatusStyle(doc.status);
          return [
            DsGradientCard(
              colors: gradient,
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.description_rounded, color: AppColors.iconAccent, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    doc.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DsGlassPill(label.toUpperCase(), icon: icon),
                ],
              ),
            ),
            const DsSection('Details'),
            DsInfoCard(
              lines: [
                DsInfoLine(Icons.category_rounded, 'Type', doc.type),
                DsInfoLine(Icons.event_rounded, 'Uploaded', doc.uploadedAt),
                DsInfoLine(Icons.verified_rounded, 'Status', label, valueColor: color),
              ],
            ),
            const SizedBox(height: 14),
            if (doc.status == DocumentApprovalStatus.rejected)
              DsNote(
                tone: DsNoteTone.danger,
                title: 'Why it was rejected',
                text: doc.rejectionReason ?? 'Please upload a clearer copy of this document.',
              )
            else if (doc.status == DocumentApprovalStatus.pending)
              const DsNote(
                tone: DsNoteTone.warning,
                title: 'Under review',
                text: 'Verification usually takes 24–48 hours.',
              )
            else
              const DsNote(tone: DsNoteTone.success, title: 'Verified', text: 'Nothing more to do for this document.'),
          ];
        },
      ),
    );
  }
}

/// Re-upload rejected document.
class StaffDocumentReuploadScreen extends ConsumerStatefulWidget {
  const StaffDocumentReuploadScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<StaffDocumentReuploadScreen> createState() => _StaffDocumentReuploadScreenState();
}

class _StaffDocumentReuploadScreenState extends ConsumerState<StaffDocumentReuploadScreen> {
  List<PlatformFile> _files = [];
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_files.isEmpty) {
      context.showDsSnackBar('Select a file', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await ref.read(staffRepositoryProvider).reuploadDocument(widget.documentId, _files.first.name);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffDocumentsProvider);
        ref.invalidate(staffDocumentProvider(widget.documentId));
        context.showDsSnackBar('Document re-uploaded', type: DsSnackBarType.success);
        context.go(StaffRoutes.documents);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(staffDocumentProvider(widget.documentId)).valueOrNull;

    return DsPage(
      title: 'Re-upload document',
      subtitle: doc?.name ?? 'Submit a clear copy',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.documents),
      bottom: DsGradientButton(
        label: 'Submit for review',
        icon: Icons.send_rounded,
        isLoading: _isSubmitting,
        onPressed: _isSubmitting || _files.isEmpty ? null : _submit,
      ),
      body: [
        if (doc?.rejectionReason != null) ...[
          DsNote(tone: DsNoteTone.danger, title: 'Previous upload rejected', text: doc!.rejectionReason!),
          const SizedBox(height: 4),
        ],
        const DsSection('New file'),
        StaffFileDropBox(
          file: _files.isEmpty ? null : _files.first,
          onTap: () async {
            final files = await pickStaffDocument(context);
            if (files != null && mounted) setState(() => _files = files);
          },
          onClear: () => setState(() => _files = []),
        ),
        const DsSection('Tips for approval'),
        const DsInfoCard(
          lines: [
            DsInfoLine(Icons.light_mode_rounded, 'Lighting', 'Bright, no glare'),
            DsInfoLine(Icons.crop_free_rounded, 'Framing', 'All 4 corners visible'),
            DsInfoLine(Icons.center_focus_strong_rounded, 'Focus', 'Text sharp & readable'),
          ],
        ),
      ],
    );
  }
}
