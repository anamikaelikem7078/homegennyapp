import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// A3 — Client Indemnity. Placement-scoped (`POST /indemnity`), tied to the
/// TRIAL placement created right after A1 is signed. Unlike SOW, sending
/// the clause is a single call — there's no separate create/send step —
/// the client then acknowledges or contests it from their own app.
class RmStage4A3Screen extends ConsumerStatefulWidget {
  const RmStage4A3Screen({super.key, required this.staffId, required this.placementId});
  final String staffId;
  final String placementId;

  @override
  ConsumerState<RmStage4A3Screen> createState() => _RmStage4A3ScreenState();
}

class _RmStage4A3ScreenState extends ConsumerState<RmStage4A3Screen> {
  final _versionController = TextEditingController(text: 'v1');
  final _textController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _versionController.dispose();
    _textController.dispose();
    super.dispose();
  }

  ClientIndemnity? _latest(List<ClientIndemnity> items) {
    if (items.isEmpty) return null;
    final sorted = [...items]..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    return sorted.first;
  }

  Future<void> _send() async {
    if (_versionController.text.trim().isEmpty || _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a clause version and text first')));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(rmRepositoryProvider).createIndemnity(
          placementId: widget.placementId,
          clauseVersion: _versionController.text.trim(),
          clauseText: _textController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmIndemnityListProvider(widget.placementId));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indemnity clause sent to client')));
      },
      onError: (f) {
        setState(() => _error = f.message);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final indemnityAsync = ref.watch(rmIndemnityListProvider(widget.placementId));
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'A3 · Client Indemnity',
          style: RmTheme.headline(context).copyWith(fontSize: 18),
        ),
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (staff) {
          final staffName = staff?.fullName ?? widget.staffId;
          final staffCode = staff?.staffCode;
          final staffSeries = staff != null ? StaffSeries.label(staff.series).toUpperCase() : null;

          return indemnityAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (items) {
              final indemnity = _latest(items);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Staff Header Card
                    _buildStaffHeader(staffName, staffCode, staffSeries),
                    const SizedBox(height: 20),

                    // Document detail or creation form
                    if (indemnity == null)
                      _buildCreateCard()
                    else
                      _buildDocumentDetailCard(indemnity),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RmTheme.crimsonDanger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RmTheme.crimsonDanger.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: RmTheme.crimsonDanger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: RmTheme.crimsonDanger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 400.ms),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStaffHeader(String name, String? code, String? series) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: RmTheme.electricBlue.withOpacity(0.1),
            child: Text(
              firstLetter,
              style: GoogleFonts.inter(
                color: RmTheme.electricBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${code ?? "ID: " + widget.staffId}${series != null ? " • $series" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.02, end: 0, duration: 400.ms);
  }

  Widget _buildCreateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Indemnity Clause',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Placement ID: ${widget.placementId}',
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12.5,
              color: RmTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Send the client indemnity clause to set contract terms and safeguard liability requirements.',
            style: GoogleFonts.inter(
              color: RmTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _versionController,
            style: GoogleFonts.inter(fontSize: 14.5, color: RmTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Clause version',
              labelStyle: GoogleFonts.inter(color: RmTheme.textSecondary, fontSize: 13.5),
              filled: true,
              fillColor: RmTheme.offWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: RmTheme.borderSubtle.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: RmTheme.borderSubtle.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textController,
            maxLines: 5,
            style: GoogleFonts.inter(fontSize: 14.5, color: RmTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter clause text detailing liabilities, indemnification terms, and exclusions...',
              hintStyle: GoogleFonts.inter(color: RmTheme.textSecondary.withOpacity(0.5), fontSize: 13.5),
              filled: true,
              fillColor: RmTheme.offWhite,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: RmTheme.borderSubtle.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: RmTheme.borderSubtle.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _busy ? null : _send,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Send Indemnity Clause',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _buildDocumentDetailCard(ClientIndemnity indemnity) {
    final statusColor = indemnity.contested
        ? RmTheme.crimsonDanger
        : (indemnity.isAcknowledged ? RmTheme.emeraldGreen : RmTheme.amberWarning);
    
    final statusText = indemnity.contested
        ? 'CONTESTED'
        : (indemnity.isAcknowledged ? 'ACKNOWLEDGED' : 'SENT');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indemnity Clause',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: RmTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Version: ${indemnity.clauseVersion}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: RmTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '• Placement ID: ${widget.placementId}',
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: RmTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RmTheme.offWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5)),
            ),
            child: Text(
              indemnity.clauseText,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: RmTheme.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.03, end: 0);
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
}
