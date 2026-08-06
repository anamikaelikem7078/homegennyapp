import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

class StaffDocumentsScreen extends ConsumerWidget {
  const StaffDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(staffDocumentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(StaffRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF1A56FF)),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(StaffRoutes.documentsUpload),
        backgroundColor: const Color(0xFF1A56FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: documents.when(
        loading: () => const DsLoadingWidget(message: 'Loading documents...'),
        error: (e, _) => DsErrorState(
          title: 'Failed to load documents',
          message: e.toString(),
          onRetry: () => ref.invalidate(staffDocumentsProvider),
        ),
        data: (list) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffDocumentsProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                Text(
                  'Verified Documents',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ensure your profile remains compliant and\nsecure by keeping your credentials updated.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                if (list.isEmpty)
                  DsEmptyState(
                    title: 'No documents yet',
                    message: 'Upload your ID and verification documents.',
                    icon: Icons.folder_open_outlined,
                    actionLabel: 'Upload document',
                    onAction: () => context.push(StaffRoutes.documentsUpload),
                  )
                else
                  ...list.map((doc) => _DocumentListTile(document: doc)),
                const SizedBox(height: 24),
                // Educational Section
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Light grey
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Why verification\nmatters?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verified staff receive 40% more\nservice requests and enjoy higher\nplatform priority.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMiniIcon(Icons.shield_outlined),
                          _buildMiniIcon(Icons.verified_user_outlined),
                          _buildMiniIcon(Icons.trending_up_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(icon, color: const Color(0xFF1A56FF), size: 14),
    );
  }
}

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile({required this.document});

  final StaffDocument document;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(StaffRoutes.documentDetail(document.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.name,
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(context, document.status),
              ],
            ),
            const SizedBox(height: 20),
            if (document.status == DocumentApprovalStatus.rejected)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The uploaded document is blurred. Please\nprovide a high-resolution scan.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Icon(
                    document.status == DocumentApprovalStatus.pending
                        ? Icons.schedule
                        : Icons.verified_outlined,
                    size: 16,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    document.status == DocumentApprovalStatus.pending
                        ? 'Estimated resolution: 24-48 hours'
                        : 'Verified on ${document.uploadedAt}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, DocumentApprovalStatus status) {
    switch (status) {
      case DocumentApprovalStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'APPROVED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
              letterSpacing: 0.5,
            ),
          ),
        );
      case DocumentApprovalStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PENDING REVIEW',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC2410C),
              letterSpacing: 0.5,
            ),
          ),
        );
      case DocumentApprovalStatus.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'REJECTED',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => context.push(StaffRoutes.documentReupload(document.id)),
              child: Text(
                'Fix Now',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A56FF),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF1A56FF),
                ),
              ),
            ),
          ],
        );
    }
  }
}
