import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

class AgreementStatusScreen extends ConsumerWidget {
  const AgreementStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreement = ref.watch(staffAgreementProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    const electricBlue = Color(0xFF1A56FF);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: electricBlue),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: electricBlue,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400',
              ),
            ),
          ),
        ],
      ),
      body: agreement.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Failed to load status',
          onRetry: () => ref.invalidate(staffAgreementProvider),
        ),
        data: (data) => _buildContent(context, data, isDark, textColor, subtitleColor, electricBlue),
      ),
    );
  }

  Widget _buildContent(BuildContext context, StaffAgreement data, bool isDark, Color textColor, Color subtitleColor, Color electricBlue) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100), // padding bottom for sticky button
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agreement Status',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your onboarding documentation and finalize the latest signature requirements.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 32),

              // Task Module
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: electricBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.description, color: electricBlue, size: 24),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED), // Soft orange bg
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'SIGNATURE REQUIRED',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: const Color(0xFFC2410C), // Orange text
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Employment Agreement',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A legal framework defining the relationship and responsibilities between you and the household.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? AppColors.darkBorder : const Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 28,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: const NetworkImage(
                                    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400',
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFE0E7FF), // Soft blue
                                  child: Text(
                                    'HG',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4338CA),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Shared with 2 people',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              Text(
                'PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 24),

              // Timeline
              _buildTimelineItem(
                context,
                title: 'Agreement Generated',
                subtitle: 'October 24, 2023',
                icon: Icons.check,
                isCompleted: true,
                isDark: isDark,
              ),
              _buildTimelineItem(
                context,
                title: 'Review Completed',
                subtitle: 'October 25, 2023',
                icon: Icons.check,
                isCompleted: true,
                isDark: isDark,
              ),
              _buildTimelineItem(
                context,
                title: 'Digital Signature',
                subtitle: 'Waiting for your electronic signature.',
                icon: Icons.edit,
                isActive: true,
                isDark: isDark,
              ),
              _buildTimelineItem(
                context,
                title: 'Activation',
                subtitle: 'Access to all platform features upon completion.',
                icon: Icons.lock_outline,
                isLocked: true,
                isLast: true,
                isDark: isDark,
              ),
            ],
          ),
        ),

        // Sticky Bottom Button
        if (data.status == AgreementStatus.pending)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.push(StaffRoutes.agreementSignature),
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                label: Text(
                  'SIGN NOW',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: electricBlue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: electricBlue.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          )
        else if (data.status == AgreementStatus.signed)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () => context.push(StaffRoutes.agreement),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: isDark ? AppColors.darkTextPrimary : const Color(0xFF4B5563),
                ),
                child: Text(
                  'View Agreement',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    bool isCompleted = false,
    bool isActive = false,
    bool isLocked = false,
    bool isLast = false,
    required bool isDark,
  }) {
    const electricBlue = Color(0xFF1A56FF);

    Widget circleContent;
    Color borderColor;
    Color bgColor;

    Color titleColor;
    Color descColor;

    if (isCompleted) {
      borderColor = const Color(0xFF86EFAC); // light green
      bgColor = const Color(0xFFDCFCE7).withValues(alpha: 0.5);
      circleContent = const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20);
      
      titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
      descColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    } else if (isActive) {
      borderColor = electricBlue;
      bgColor = electricBlue;
      circleContent = Icon(icon, color: Colors.white, size: 18);
      
      titleColor = electricBlue;
      descColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    } else { // Locked
      borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);
      bgColor = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F4F6);
      circleContent = Icon(icon, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 18);
      
      titleColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
      descColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    }

    return CustomPaint(
      painter: _TimelineLinePainter(
        isLast: isLast,
        color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Center(child: circleContent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: electricBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'CURRENT',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: electricBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: descColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineLinePainter extends CustomPainter {
  _TimelineLinePainter({required this.isLast, required this.color});
  
  final bool isLast;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (isLast) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
      
    // Circle is 32x32. Center X is 16. Starts at Y=32, goes to the bottom.
    canvas.drawLine(const Offset(16, 32), Offset(16, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _TimelineLinePainter oldDelegate) {
    return oldDelegate.isLast != isLast || oldDelegate.color != color;
  }
}
