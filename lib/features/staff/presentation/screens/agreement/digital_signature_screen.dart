import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Digital signature screen with draw or typed confirmation.
class DigitalSignatureScreen extends ConsumerStatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  ConsumerState<DigitalSignatureScreen> createState() =>
      _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends ConsumerState<DigitalSignatureScreen> {
  final _nameController = TextEditingController();
  final _points = <Offset>[];
  bool _useDrawMode = true;
  bool _isSubmitting = false;

  static const Color _electricBlue = Color(0xFF1A56FF);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasSignature =>
      _useDrawMode ? _points.length > 4 : _nameController.text.trim().isNotEmpty;

  void _clear() {
    setState(() {
      _points.clear();
      _nameController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_hasSignature) {
      context.showDsSnackBar(
        'Please provide your signature',
        type: DsSnackBarType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final signature = _useDrawMode
        ? 'draw:${_points.length}'
        : _nameController.text.trim();

    final result =
        await ref.read(staffRepositoryProvider).signAgreement(signature);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffAgreementProvider);
        context.showDsSnackBar(
          'Agreement signed successfully',
          type: DsSnackBarType.success,
        );
        context.go(StaffRoutes.agreementStatus);
      },
      onError: (f) {
        context.showDsSnackBar(f.message, type: DsSnackBarType.error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Signature',
              style: GoogleFonts.libreCaslonText(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'SIGN TO ACCEPT THE AGREEMENT',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose how you would like to sign',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildCustomSegmentedControl(isDark),
              const SizedBox(height: 24),
              Expanded(
                child: _useDrawMode ? _buildDrawPad(isDark) : _buildTypePad(isDark),
              ),
              const SizedBox(height: 24),
              Text(
                'LEGAL VALIDITY ENSURED BY DIGITAL ENCRYPTION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildOutlineButton('CLEAR', onPressed: _isSubmitting ? null : _clear),
              const SizedBox(height: 12),
              _buildPrimaryButton(
                'SUBMIT SIGNATURE',
                isLoading: _isSubmitting,
                onPressed: _hasSignature && !_isSubmitting ? _submit : null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSegmentedControl(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildSegmentButton(true, 'Draw', Icons.edit_rounded, isDark)),
          Expanded(child: _buildSegmentButton(false, 'Type', Icons.text_fields_rounded, isDark)),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(bool isDraw, String label, IconData icon, bool isDark) {
    final isSelected = _useDrawMode == isDraw;

    return GestureDetector(
      onTap: () => setState(() => _useDrawMode = isDraw),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _electricBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _electricBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawPad(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() => _points.add(details.localPosition));
          },
          onPanEnd: (_) => setState(() => _points.add(Offset.zero)),
          child: CustomPaint(
            painter: _SignaturePainter(_points, _electricBlue),
            size: Size.infinite,
            child: _points.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF9FAFB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 32,
                            color: isDark ? AppColors.darkTextHint : const Color(0xFFD1D5DB),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Draw your signature here',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextHint : const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTypePad(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type your full name to confirm',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: AppSpacing.md),
          DsTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your legal name',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(String label, {VoidCallback? onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: isDark ? AppColors.darkTextSecondary : const Color(0xFF4B5563),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, {VoidCallback? onPressed, bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _electricBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: _electricBlue.withValues(alpha: 0.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points, this.color);

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] == Offset.zero || points[i + 1] == Offset.zero) continue;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.points != points;
}

