import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../documents/upload_document_screen.dart' show pickStaffDocument;

/// Tax declaration — annual summary and investment proofs.
///
/// There is no tax endpoint yet: the figures are an illustrative estimate and
/// proofs are only attached locally until submission is wired to the backend.
class StaffTaxDeclarationScreen extends ConsumerStatefulWidget {
  const StaffTaxDeclarationScreen({super.key});

  @override
  ConsumerState<StaffTaxDeclarationScreen> createState() => _StaffTaxDeclarationScreenState();
}

class _StaffTaxDeclarationScreenState extends ConsumerState<StaffTaxDeclarationScreen> {
  static const _sections = [
    ('Section 80C', 'PF, LIC, ELSS mutual funds', Icons.savings_rounded),
    ('Section 80D', 'Medical insurance premiums', Icons.health_and_safety_rounded),
    ('Section 24', 'Home loan interest', Icons.home_rounded),
  ];

  final _proofs = <String, String>{};
  bool _submitting = false;

  (int, int) get _fy {
    final n = DateTime.now();
    final start = n.month >= 4 ? n.year : n.year - 1;
    return (start, start + 1);
  }

  Future<void> _attach(String section) async {
    final files = await pickStaffDocument(context);
    if (files == null || files.isEmpty || !mounted) return;
    setState(() => _proofs[section] = files.first.name);
    context.showDsSnackBar('Proof attached for $section', type: DsSnackBarType.success);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _submitting = false);
    await DsSuccessDialog.show(
      context: context,
      title: 'Declaration submitted',
      message: '${_proofs.length} ${_proofs.length == 1 ? 'proof' : 'proofs'} sent for review.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (start, end) = _fy;
    const liability = 142500.0;
    const paid = 85000.0;

    return DsPage(
      title: 'Tax declaration',
      subtitle: 'FY $start-${end % 100}',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.salary),
      bottom: DsGradientButton(
        label: _proofs.isEmpty ? 'Attach a proof to submit' : 'Submit declaration',
        icon: Icons.send_rounded,
        isLoading: _submitting,
        onPressed: _proofs.isEmpty || _submitting ? null : _submit,
      ),
      body: [
        DsGradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsGlassPill('FINANCIAL YEAR $start-${end % 100}', icon: Icons.receipt_long_rounded),
                        const SizedBox(height: 12),
                        Text(
                          'Estimated tax liability',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        Text(
                          '₹ 1,42,500',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const DsFloatingIconTile(icon: Icons.account_balance_rounded),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: paid / liability),
                  duration: 1000.ms,
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    color: AppColors.sunYellow,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: DsGlassStat(value: '₹ 85,000', label: 'Tax paid', icon: Icons.check_circle_rounded)),
                  SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: '₹ 57,500', label: 'Pending', icon: Icons.pending_rounded)),
                ],
              ),
            ],
          ),
        ),
        DsSection('Investment proofs', trailing: DsPill('${_proofs.length}/${_sections.length} attached')),
        for (final (section, desc, icon) in _sections)
          _ProofTile(
            section: section,
            description: desc,
            icon: icon,
            fileName: _proofs[section],
            onTap: () => _attach(section),
            onClear: () => setState(() => _proofs.remove(section)),
          ),
        const SizedBox(height: 4),
        DsNote(
          tone: DsNoteTone.warning,
          title: 'Deadline',
          text: 'Submit your proofs before March 31, $end.',
        ),
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  const _ProofTile({
    required this.section,
    required this.description,
    required this.icon,
    required this.fileName,
    required this.onTap,
    required this.onClear,
  });

  final String section;
  final String description;
  final IconData icon;
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final attached = fileName != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: 250.ms,
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(
              color: attached ? const Color(0xFFF0FDF4) : Colors.white,
              border: attached ? AppColors.success.withValues(alpha: 0.35) : null,
            ),
            child: Row(
              children: [
                DsIconTile(attached ? Icons.check_rounded : icon, size: 46, color: attached ? AppColors.success : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        attached ? fileName! : description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: attached ? AppColors.success : AppColors.lightTextSecondary,
                          fontWeight: attached ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (attached)
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded, color: AppColors.lightTextSecondary),
                  )
                else
                  const DsPill('Upload', icon: Icons.upload_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
