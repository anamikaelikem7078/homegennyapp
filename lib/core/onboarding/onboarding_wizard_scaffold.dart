import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design_system/design_system.dart';

const _ink = AppColors.lightTextPrimary;
const _muted = AppColors.lightTextSecondary;

/// Layout for the "Complete your profile" wizards — the auth flow's look
/// (brand-gradient hero, yellow highlight, white sheet sliding over it) with
/// a step tracker in the hero and the Back / Next buttons pinned at the
/// bottom.
class OnboardingWizardScaffold extends StatelessWidget {
  const OnboardingWizardScaffold({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.titleLine1,
    required this.titleHighlight,
    required this.children,
    required this.onBack,
    this.subtitle,
    this.icon = Icons.person_rounded,
    this.bottom,
  });

  /// Short label per step ("About you", "Home"…).
  final List<String> steps;
  final int currentStep;
  final String titleLine1;

  /// Second headline line, drawn on the yellow highlighter swipe.
  final String titleHighlight;
  final String? subtitle;

  /// Large faded icon in the hero for this step.
  final IconData icon;
  final VoidCallback onBack;
  final List<Widget> children;

  /// Sticky footer — usually Back / Next.
  final Widget? bottom;

  static const double _overlap = 32;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WizardHero(
                    steps: steps,
                    currentStep: currentStep,
                    titleLine1: titleLine1,
                    titleHighlight: titleHighlight,
                    subtitle: subtitle,
                    icon: icon,
                    onBack: onBack,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_overlap),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Keyed by step so each step's fields animate in.
                          KeyedSubtree(
                            key: ValueKey(currentStep),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children
                                  .animate(interval: 50.ms)
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.25, end: 0, duration: 550.ms, curve: Curves.easeOutQuart).fadeIn(duration: 350.ms),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: bottom == null
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: AppColors.navy.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, -6)),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
                // heightFactor: 1 — a bottomNavigationBar may be as tall as
                // the screen, and a plain Center would fill all of it,
                // leaving the page body no room at all.
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: bottom),
                ),
              ),
      ),
    );
  }
}

class _WizardHero extends StatelessWidget {
  const _WizardHero({
    required this.steps,
    required this.currentStep,
    required this.titleLine1,
    required this.titleHighlight,
    required this.subtitle,
    required this.icon,
    required this.onBack,
  });

  final List<String> steps;
  final int currentStep;
  final String titleLine1;
  final String titleHighlight;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final headline = GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.1,
      letterSpacing: -0.8,
    );

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sunYellow.withValues(alpha: 0.16)),
            ),
          ),
          Positioned(
            right: 18,
            top: top + 62,
            child: Icon(icon, size: 92, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DsBackButton(onPressed: onBack, onDark: true),
                    const Spacer(),
                    _GlassPill('Step ${currentStep + 1} of ${steps.length}'),
                  ],
                ),
                const SizedBox(height: 22),
                Text(titleLine1, style: headline),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -2,
                      right: -4,
                      bottom: 2,
                      height: 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.sunYellow.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ).animate(key: ValueKey(titleHighlight), delay: 200.ms).scaleX(
                            begin: 0,
                            end: 1,
                            alignment: Alignment.centerLeft,
                            duration: 450.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                    Text(titleHighlight, style: headline),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: Text(
                      subtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                _StepTracker(steps: steps, current: currentStep),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      );
}

/// Numbered dots joined by lines: done = yellow check, current = white,
/// upcoming = outlined.
class _StepTracker extends StatelessWidget {
  const _StepTracker({required this.steps, required this.current});
  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final done = i < current;
      final active = i == current;
      items.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 30 : 26,
              height: active ? 30 : 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.sunYellow
                    : active
                        ? Colors.white
                        : Colors.transparent,
                border: Border.all(
                  color: done || active ? Colors.transparent : Colors.white.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: active
                    ? [BoxShadow(color: Colors.white.withValues(alpha: 0.35), blurRadius: 12)]
                    : null,
              ),
              alignment: Alignment.center,
              child: done
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.navy)
                  : Text(
                      '${i + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[i],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: Colors.white.withValues(alpha: active || done ? 1 : 0.65),
              ),
            ),
          ],
        ),
      );
      if (i < steps.length - 1) {
        items.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: i < current ? AppColors.sunYellow : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        );
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: items);
  }
}

/// Small heading inside a wizard sheet: orange icon tile, title, hint.
class OnboardingSectionHeader extends StatelessWidget {
  const OnboardingSectionHeader({super.key, required this.icon, required this.title, this.hint});

  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
                if (hint != null)
                  Text(hint!, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen brand-gradient "you're in" page that ends the sign-up flow.
class OnboardingSuccessView extends StatelessWidget {
  const OnboardingSuccessView({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.icon = Icons.check_rounded,
    this.nextSteps = const [],
    this.secondaryLabel,
    this.onSecondary,
    this.warning = false,
  });

  final String title;
  final String message;
  final IconData icon;

  /// "What happens next" — (icon, text) lines on a glass card.
  final List<(IconData, String)> nextSteps;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Restricted / stop states use an amber badge instead of the yellow one.
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final badgeColor = warning ? AppColors.warning : AppColors.sunYellow;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -70,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sunYellow.withValues(alpha: 0.14)),
                ),
              ),
              Positioned(
                bottom: -90,
                left: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          Center(
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: badgeColor,
                                  boxShadow: [BoxShadow(color: badgeColor.withValues(alpha: 0.5), blurRadius: 28)],
                                ),
                                child: Icon(icon, size: 40, color: AppColors.navy),
                              ),
                            ),
                          ).animate().scaleXY(begin: 0.3, end: 1, duration: 700.ms, curve: Curves.elasticOut).fadeIn(),
                          const SizedBox(height: 28),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.8,
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
                          if (nextSteps.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'WHAT HAPPENS NEXT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.sunYellow,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  for (final (icon, text) in nextSteps)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(icon, size: 18, color: Colors.white),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13.5,
                                                height: 1.4,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ).animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                          ],
                          const Spacer(),
                          if (onPrimary != null)
                            _WhiteButton(label: primaryLabel, onPressed: onPrimary!)
                                .animate(delay: 600.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.4, end: 0),
                          if (secondaryLabel != null && onSecondary != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: onSecondary,
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              child: Text(
                                secondaryLabel!,
                                style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      );
}
