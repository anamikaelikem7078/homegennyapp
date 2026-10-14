import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

const _maxFileBytes = 5 * 1024 * 1024;

/// Opens the picker for PDF / JPG / PNG up to 5 MB.
Future<List<PlatformFile>?> pickStaffDocument(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    withData: kIsWeb,
  );
  if (result == null || !context.mounted) return null;
  if (result.files.any((f) => f.size > _maxFileBytes)) {
    context.showDsSnackBar('File is larger than 5 MB. Please choose a smaller file.', type: DsSnackBarType.warning);
    return null;
  }
  return result.files;
}

/// Dashed drop box showing the picked file.
class StaffFileDropBox extends StatelessWidget {
  const StaffFileDropBox({super.key, required this.file, required this.onTap, this.onClear});
  final PlatformFile? file;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    final isPdf = file?.extension?.toLowerCase() == 'pdf';
    final sizeKb = file == null ? 0 : (file!.size / 1024).round();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: CustomPaint(
        painter: _DashedRRectPainter(color: picked ? AppColors.primary : const Color(0xFFCBD5E1)),
        child: AnimatedContainer(
          duration: 250.ms,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: picked ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: AnimatedSwitcher(
            duration: 250.ms,
            child: picked
                ? Row(
                    key: const ValueKey('file'),
                    children: [
                      DsIconTile(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file!.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              '$sizeKb KB · tap to change',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (onClear != null)
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded, color: AppColors.lightTextSecondary),
                        ),
                    ],
                  )
                : Column(
                    key: const ValueKey('empty'),
                    children: [
                      const DsIconTile(Icons.cloud_upload_rounded, size: 60)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: -3, end: 3, duration: 1200.ms, curve: Curves.easeInOut),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to choose a file',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PDF, JPG or PNG · max 5 MB',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Upload a new staff document.
class StaffUploadDocumentScreen extends ConsumerStatefulWidget {
  const StaffUploadDocumentScreen({super.key});

  @override
  ConsumerState<StaffUploadDocumentScreen> createState() => _StaffUploadDocumentScreenState();
}

class _StaffUploadDocumentScreenState extends ConsumerState<StaffUploadDocumentScreen> {
  final _nameController = TextEditingController();
  String? _documentType;
  List<PlatformFile> _pickedFiles = [];
  bool _isSubmitting = false;

  // Must match the backend's canonical document type strings exactly (see
  // DocumentsService.getMandatoryDocumentTypes / homegenny's DOC_TYPE_TO_API)
  // — otherwise the upload is stored under a type the HR portal and the
  // mandatory-document/onboarding checks don't recognize, and it silently
  // fails to satisfy that document slot anywhere despite uploading fine.
  static const _documentTypes = [
    ('Aadhaar Card', Icons.badge_rounded),
    ('PAN Card', Icons.credit_card_rounded),
    ('Passport Size Photo', Icons.portrait_rounded),
    ('Police Verification Certificate', Icons.local_police_rounded),
    ('Address Proof', Icons.home_rounded),
    ('Other', Icons.description_rounded),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    if (_documentType == null) {
      context.showDsSnackBar('Please select a document type', type: DsSnackBarType.warning);
      return;
    }
    if (_pickedFiles.isEmpty) {
      context.showDsSnackBar('Please select a document to upload', type: DsSnackBarType.warning);
      return;
    }
    final file = _pickedFiles.first;
    final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : _documentType!;

    setState(() => _isSubmitting = true);
    final result = await ref.read(staffRepositoryProvider).uploadDocument(name, _documentType!, file);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffDocumentsProvider);
        context.showDsSnackBar('Document uploaded successfully', type: DsSnackBarType.success);
        context.go(StaffRoutes.documents);
      },
      onError: (failure) => context.showDsSnackBar(failure.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _pickFile() async {
    final files = await pickStaffDocument(context);
    if (files != null && mounted) setState(() => _pickedFiles = files);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _documentType != null && _pickedFiles.isNotEmpty;

    return DsPage(
      title: 'Upload document',
      subtitle: 'Submit a new file for review',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.documents),
      bottom: DsGradientButton(
        label: 'Upload document',
        icon: Icons.cloud_upload_rounded,
        isLoading: _isSubmitting,
        onPressed: _isSubmitting || !ready ? null : _upload,
      ),
      body: [
        const DsSection('1. Document type', top: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (type, icon) in _documentTypes)
              DsChoiceChip(
                label: type,
                icon: icon,
                selected: _documentType == type,
                onTap: () => setState(() => _documentType = type),
              ),
          ],
        ),
        const DsSection('2. Name'),
        DsLabeledField(
          label: 'Document name',
          optional: true,
          controller: _nameController,
          icon: Icons.edit_rounded,
          hint: 'e.g. Aadhaar Card front',
        ),
        const DsSection('3. File'),
        StaffFileDropBox(
          file: _pickedFiles.isEmpty ? null : _pickedFiles.first,
          onTap: _pickFile,
          onClear: () => setState(() => _pickedFiles = []),
        ),
        const SizedBox(height: 16),
        const DsNote(
          tone: DsNoteTone.success,
          title: 'Secure upload',
          text: 'Files are encrypted and only seen by the HomeGenny verification team.',
        ),
      ],
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) => old.color != color;
}
