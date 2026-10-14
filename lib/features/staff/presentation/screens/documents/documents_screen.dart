import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Colour, icon, label and hero gradient for a document status.
(Color, IconData, String, List<Color>) documentStatusStyle(DocumentApprovalStatus s) => switch (s) {
      DocumentApprovalStatus.approved => (AppColors.success, Icons.verified_rounded, 'Approved', DsGradientCard.green),
      DocumentApprovalStatus.pending => (AppColors.warning, Icons.schedule_rounded, 'Pending review', DsGradientCard.orange),
      DocumentApprovalStatus.rejected => (AppColors.error, Icons.error_rounded, 'Rejected', DsGradientCard.red),
    };

class StaffDocumentsScreen extends ConsumerWidget {
  const StaffDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(staffDocumentsProvider);

    return DsPage(
      title: 'Documents',
      subtitle: 'Keep your profile verified',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffDocumentsProvider),
      bottom: DsGradientButton(
        label: 'Upload document',
        icon: Icons.add_rounded,
        onPressed: () => context.push(StaffRoutes.documentsUpload),
      ),
      body: dsAsyncBody(
        documents,
        onRetry: () => ref.invalidate(staffDocumentsProvider),
        builder: (list) {
          int count(DocumentApprovalStatus s) => list.where((d) => d.status == s).length;
          final approved = count(DocumentApprovalStatus.approved);
          final pending = count(DocumentApprovalStatus.pending);
          final rejected = count(DocumentApprovalStatus.rejected);
          return [
            DsGradientCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: list.isEmpty ? 0 : approved / list.length),
                      duration: 1000.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: AppColors.sunYellow,
                            ),
                          ),
                          Text(
                            '$approved/${list.length}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified documents',
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            DsGlassPill('$pending PENDING'),
                            DsGlassPill('$rejected TO FIX'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (rejected > 0) ...[
              const SizedBox(height: 14),
              DsNote(
                tone: DsNoteTone.danger,
                title: '$rejected ${rejected == 1 ? 'document needs' : 'documents need'} attention',
                text: 'Re-upload a clear copy so your verification can continue.',
              ),
            ],
            DsSection('Your documents', trailing: DsPill('${list.length}')),
            if (list.isEmpty)
              DsEmptyBlock(
                icon: Icons.folder_open_rounded,
                title: 'No documents yet',
                message: 'Upload your ID and verification documents to get started.',
                action: DsGradientButton(
                  label: 'Upload document',
                  icon: Icons.upload_file_rounded,
                  isExpanded: false,
                  onPressed: () => context.push(StaffRoutes.documentsUpload),
                ),
              )
            else
              for (var i = 0; i < list.length; i++)
                _DocumentTile(document: list[i])
                    .animate(delay: (45 * i.clamp(0, 10)).ms)
                    .fadeIn(duration: 280.ms)
                    .slideX(begin: 0.05, end: 0),
            const SizedBox(height: 6),
            const DsNote(
              title: 'Why verification matters',
              text: 'Verified staff receive more service requests and higher platform priority.',
            ),
          ];
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});
  final StaffDocument document;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label, _) = documentStatusStyle(document.status);
    final rejected = document.status == DocumentApprovalStatus.rejected;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push(StaffRoutes.documentDetail(document.id)),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(border: rejected ? AppColors.error.withValues(alpha: 0.3) : null),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const DsIconTile(Icons.description_rounded, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            '${document.type} · ${document.uploadedAt}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DsPill(label, color: color, icon: icon),
                  ],
                ),
                if (rejected) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.rejectionReason ?? 'Please upload a clearer copy.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.error),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.primary,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: () => context.push(StaffRoutes.documentReupload(document.id)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Text(
                              'Fix now',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
