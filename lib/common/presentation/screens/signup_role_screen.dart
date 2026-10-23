import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../domain/models/user_role.dart';
import '../widgets/auth_hero_scaffold.dart';
import '../widgets/role_picker_sheet.dart';

/// Sign-up step 1 for a number with no account: "Client or Staff?". Shown
/// between the login screen and the OTP screen, in the same hero style.
class SignupRoleScreen extends StatefulWidget {
  const SignupRoleScreen({super.key, required this.phone, this.initialRole});

  final String phone;
  final UserRole? initialRole;

  @override
  State<SignupRoleScreen> createState() => _SignupRoleScreenState();
}

class _SignupRoleScreenState extends State<SignupRoleScreen> {
  late UserRole? _role = widget.initialRole;

  void _continue() {
    final role = _role;
    if (role == null) return;
    context.push(
      Uri(path: AppRoutes.otp, queryParameters: {'phone': widget.phone, 'role': role.value}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _role == UserRole.staff
        ? const ['Verify your number', 'Fill your profile (2 min)', 'Your RM calls to verify documents']
        : const ['Verify your number', 'Add your name and home', 'Request staff for your home'];

    return AuthHeroScaffold(
      onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
      badge: 'New to HomeGenny',
      badgeIcon: Icons.waving_hand_rounded,
      titleLine1: 'Let\'s get you',
      titleHighlight: 'started.',
      subtitle: '+91 ${widget.phone} is new here. Tell us how you\'ll use HomeGenny.',
      floatingIcons: const [Icons.home_rounded, Icons.badge_rounded, Icons.favorite_rounded],
      sheetTitle: 'I am…',
      sheetSubtitle: 'Pick one — you can\'t switch later in the app',
      children: [
        for (final info in RoleOptionInfo.all) ...[
          RoleOptionCard(info: info, selected: _role == info.role, onTap: () => setState(() => _role = info.role)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _HowItWorks(key: ValueKey(_role), steps: steps),
        ),
        const SizedBox(height: 22),
        DsGradientButton(
          label: _role == null ? 'Choose one to continue' : 'Continue as ${_role == UserRole.staff ? 'Staff' : 'Client'}',
          icon: Icons.arrow_forward_rounded,
          onPressed: _role == null ? null : _continue,
        ),
        const SizedBox(height: 12),
        Text(
          'Picked the wrong one later? Your RM can fix it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightTextHint),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Three numbered steps on a soft blue card.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({super.key, required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOW IT WORKS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
