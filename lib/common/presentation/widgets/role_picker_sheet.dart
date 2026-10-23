import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../domain/models/user_role.dart';

const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);

/// How each sign-up role is presented: title, pitch, perks, art.
class RoleOptionInfo {
  const RoleOptionInfo({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.perks,
    required this.gradient,
  });

  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> perks;
  final List<Color> gradient;

  static const client = RoleOptionInfo(
    role: UserRole.client,
    icon: Icons.home_rounded,
    title: 'I need help at home',
    subtitle: 'Sign up as a Client',
    perks: ['Verified caretakers, nurses and cooks', 'Track attendance and daily care', 'An RM looks after your home'],
    gradient: [AppColors.primaryLight, AppColors.primaryDark],
  );

  static const staff = RoleOptionInfo(
    role: UserRole.staff,
    icon: Icons.badge_rounded,
    title: 'I want to work',
    subtitle: 'Sign up as Staff',
    perks: ['Steady work with verified families', 'Free training and certification', 'Salary on time, every month'],
    gradient: [AppColors.secondaryLight, AppColors.secondaryDark],
  );

  static const all = [client, staff];
}

/// A large selectable role card: gradient icon tile, title, perks and a
/// check when selected.
class RoleOptionCard extends StatelessWidget {
  const RoleOptionCard({super.key, required this.info, required this.selected, required this.onTap});

  final RoleOptionInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = info.gradient.last;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedScale(
        scale: selected ? 1 : 0.985,
        duration: 220.ms,
        child: AnimatedContainer(
          duration: 250.ms,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.06) : const Color(0xFFF7F8FB),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? accent : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
            boxShadow: selected
                ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: info.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
                ),
                child: Icon(info.icon, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.subtitle.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: accent),
                    ),
                    const SizedBox(height: 2),
                    Text(info.title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                    const SizedBox(height: 8),
                    for (final perk in info.perks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 15, color: accent.withValues(alpha: 0.8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                perk,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: 220.ms,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : Colors.white,
                  border: Border.all(color: selected ? accent : const Color(0xFFD1D5DB), width: 2),
                ),
                child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "I am a… Client | Staff" as a bottom sheet — used when the OTP step finds
/// the number is new after all. Returns null if dismissed.
Future<UserRole?> showRolePickerSheet(BuildContext context) {
  return showModalBottomSheet<UserRole>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome to HomeGenny', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 4),
            Text(
              'This number is new here. How will you use the app?',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: _muted),
            ),
            const SizedBox(height: 18),
            for (final info in RoleOptionInfo.all) ...[
              RoleOptionCard(info: info, selected: false, onTap: () => Navigator.of(context).pop(info.role)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    ),
  );
}

/// "This number is for an office account" — RM/BM/Admin/HR numbers can't use
/// OTP login.
Future<void> showOfficeAccountDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 28),
      ),
      title: Text('Office account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
      content: Text(
        'This number is for an office account. Please use the HomeGenny web portal.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.45, color: _muted),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
      ],
    ),
  );
}
