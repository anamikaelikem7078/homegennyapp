import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Digital signature screen with draw or typed confirmation.
///
/// Not a scrolling page on purpose: the drawing pad needs every pan gesture.
class DigitalSignatureScreen extends ConsumerStatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  ConsumerState<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends ConsumerState<DigitalSignatureScreen> {
  final _nameController = TextEditingController();
  final _points = <Offset>[];
  bool _useDrawMode = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasSignature => _useDrawMode ? _points.length > 4 : _nameController.text.trim().isNotEmpty;

  void _clear() {
    HapticFeedback.lightImpact();
    setState(() {
      _points.clear();
      _nameController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_hasSignature) {
      context.showDsSnackBar('Please provide your signature', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _isSubmitting = true);
    final signature = _useDrawMode ? 'draw:${_points.length}' : _nameController.text.trim();
    final result = await ref.read(staffRepositoryProvider).signAgreement(signature);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffAgreementProvider);
        context.showDsSnackBar('Agreement signed successfully', type: DsSnackBarType.success);
        context.go(StaffRoutes.agreementStatus);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = dsGutter(context);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: DsAppBar(
        title: 'Digital signature',
        subtitle: 'Sign to accept the agreement',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.agreement),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModeToggle(
                drawMode: _useDrawMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _useDrawMode = v);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: 280.ms,
                  child: _useDrawMode ? _buildDrawPad() : _buildTypePad(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.iconAccent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Legally valid, secured with digital encryption',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DsOutlineButton(
                      label: 'Clear',
                      icon: Icons.refresh_rounded,
                      onPressed: _isSubmitting ? null : _clear,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DsGradientButton(
                      label: 'Submit',
                      icon: Icons.check_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _hasSignature && !_isSubmitting ? _submit : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawPad() {
    return Container(
      key: const ValueKey('draw'),
      decoration: dsCardDecoration(radius: 26),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: GestureDetector(
          onPanStart: (d) => setState(() => _points.add(d.localPosition)),
          onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
          onPanEnd: (_) => setState(() => _points.add(Offset.zero)),
          child: CustomPaint(
            painter: _SignaturePainter(List.of(_points), AppColors.primary),
            size: Size.infinite,
            child: Stack(
              children: [
                // Signature baseline.
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 48,
                  child: Row(
                    children: [
                      const Icon(Icons.close_rounded, size: 16, color: AppColors.lightTextHint),
                      const SizedBox(width: 6),
                      Expanded(child: Container(height: 1.5, color: AppColors.lightBorder)),
                    ],
                  ),
                ),
                if (_points.isEmpty)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DsIconTile(Icons.gesture_rounded, size: 60)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveX(begin: -4, end: 4, duration: 1200.ms, curve: Curves.easeInOut),
                        const SizedBox(height: 12),
                        Text(
                          'Draw your signature here',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypePad() {
    final name = _nameController.text.trim();
    return SingleChildScrollView(
      key: const ValueKey('type'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: dsCardDecoration(radius: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsLabeledField(
              label: 'Type your full legal name',
              controller: _nameController,
              icon: Icons.person_rounded,
              hint: 'Enter your legal name',
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            Text(
              'Preview',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 90,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AnimatedSwitcher(
                duration: 200.ms,
                child: Text(
                  name.isEmpty ? 'Your signature' : name,
                  key: ValueKey(name),
                  style: GoogleFonts.dancingScript(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: name.isEmpty ? AppColors.lightTextHint : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.drawMode, required this.onChanged});
  final bool drawMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(bool v, String label, IconData icon) {
      final on = drawMode == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: 220.ms,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: on ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: on
                  ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: on ? Colors.white : AppColors.iconAccent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: on ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        children: [
          seg(true, 'Draw', Icons.draw_rounded),
          seg(false, 'Type', Icons.keyboard_rounded),
        ],
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
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] == Offset.zero || points[i + 1] == Offset.zero) continue;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => oldDelegate.points.length != points.length;
}
