import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Employment agreement details screen.
class AgreementScreen extends ConsumerWidget {
  const AgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreement = ref.watch(staffAgreementProvider);

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
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agreement',
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF1A56FF),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Review employment terms',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400'),
            ),
          )
        ],
      ),
      body: agreement.when(
        loading: () => const DsLoadingWidget(message: 'Loading agreement...'),
        error: (e, _) => DsErrorState(
          title: 'Failed to load agreement',
          message: e.toString(),
          onRetry: () => ref.invalidate(staffAgreementProvider),
        ),
        data: (data) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Employment\nAgreement',
                              style: GoogleFonts.libreCaslonText(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                                height: 1.1,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(data.status).toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            child: _buildRichText(data.content),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (data.status == AgreementStatus.pending)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(StaffRoutes.agreementSignature),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    label: Text(
                      'Sign Agreement',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => context.push(StaffRoutes.agreementStatus),
                child: Text(
                  'View Status',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(String text) {
    final companyName = 'HomeGenny Pvt. Ltd.';
    final parts = text.split(companyName);
    
    if (parts.length == 1) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF475569),
          height: 1.8,
        ),
      );
    }
    
    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i != parts.length - 1) {
        spans.add(
          TextSpan(
            text: companyName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A56FF),
            ),
          ),
        );
      }
    }
    
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF475569),
          height: 1.8,
        ),
        children: spans,
      ),
    );
  }

  String _statusLabel(AgreementStatus status) => switch (status) {
        AgreementStatus.pending => 'Pending',
        AgreementStatus.signed => 'Signed',
        AgreementStatus.expired => 'Expired',
      };
}
