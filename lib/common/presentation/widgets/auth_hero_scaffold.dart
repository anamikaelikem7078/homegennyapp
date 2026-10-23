import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../design_system/widgets/navigation/ds_navigation.dart';

/// Shared layout for the auth flow (OTP, forgot / reset / change password,
/// biometric): the login screen's gradient hero with floating orange icons
/// and a white sheet that slides up over it.
class AuthHeroScaffold extends StatelessWidget {
  const AuthHeroScaffold({
    super.key,
    required this.titleLine1,
    required this.titleHighlight,
    required this.children,
    this.subtitle,
    this.badge,
    this.badgeIcon = Icons.bolt_rounded,
    this.onBack,
    this.floatingIcons = const [
      Icons.lock_rounded,
      Icons.verified_user_rounded,
      Icons.key_rounded,
    ],
    this.sheetTitle,
    this.sheetSubtitle,
    this.formKey,
  });

  /// First headline line (white).
  final String titleLine1;

  /// Second headline line, drawn with the yellow highlighter swipe.
  final String titleHighlight;
  final String? subtitle;
  final String? badge;
  final IconData badgeIcon;

  /// Back action; hidden when null.
  final VoidCallback? onBack;
  final List<IconData> floatingIcons;
  final String? sheetTitle;
  final String? sheetSubtitle;

  /// When set, the sheet content is wrapped in a [Form] with this key.
  final GlobalKey<FormState>? formKey;

  /// Sheet content — animated in one after another.
  final List<Widget> children;

  static const double _heroHeight = 300;
  static const double _overlap = 36;

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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthHero(
                    titleLine1: titleLine1,
                    titleHighlight: titleHighlight,
                    subtitle: subtitle,
                    badge: badge,
                    badgeIcon: badgeIcon,
                    onBack: onBack,
                    floatingIcons: floatingIcons,
                  ),
                  Transform.translate(
                    offset: const Offset(0, -_overlap),
                    child: _buildSheet(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet() {
    final sheet = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
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
          if (sheetTitle != null)
            Text(
              sheetTitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.lightTextPrimary,
              ),
            ),
          if (sheetSubtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              sheetSubtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
          if (sheetTitle != null || sheetSubtitle != null)
            const SizedBox(height: 22),
          ...children,
        ]
            .animate(interval: 60.ms, delay: 250.ms)
            .fadeIn(duration: 420.ms)
            .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
      ),
    );
    return (formKey == null ? sheet : Form(key: formKey, child: sheet))
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 650.ms, curve: Curves.easeOutQuart)
        .fadeIn(duration: 400.ms);
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.titleLine1,
    required this.titleHighlight,
    required this.subtitle,
    required this.badge,
    required this.badgeIcon,
    required this.onBack,
    required this.floatingIcons,
  });

  final String titleLine1;
  final String titleHighlight;
  final String? subtitle;
  final String? badge;
  final IconData badgeIcon;
  final VoidCallback? onBack;
  final List<IconData> floatingIcons;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final headline = GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.1,
      letterSpacing: -1,
    );

    // Landscape phones and very short screens get a tighter hero.
    final compact = MediaQuery.sizeOf(context).height < 600;

    // A minimum height, not a fixed one: with large text or a narrow phone
    // the hero grows instead of hiding its subtitle under the sheet.
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 0 : AuthHeroScaffold._heroHeight + topInset,
      ),
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _Blob(
              size: 230,
              color: AppColors.sunYellow.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -80,
            child: _Blob(
              size: 210,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          for (var i = 0; i < floatingIcons.length && i < 3; i++)
            Positioned(
              top: topInset + const [64.0, 140.0, 178.0][i],
              right: const [26.0, 92.0, 22.0][i],
              child: _FloatingIcon(
                icon: floatingIcons[i],
                size: const [56.0, 44.0, 48.0][i],
                delay: i * 400,
              ),
            ),
          // Copy — not positioned, so it sizes the hero.
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              topInset + 12,
              24,
              AuthHeroScaffold._overlap + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 42,
                  child: onBack == null
                      ? null
                      : DsBackButton(onPressed: onBack, onDark: true)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.4, end: 0),
                ),
                SizedBox(height: compact ? 8 : 30),
                if (badge != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: AppColors.sunYellow, size: 14),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn(duration: 400.ms)
                      .scaleXY(begin: 0.8, end: 1, curve: Curves.easeOutBack),
                  const SizedBox(height: 14),
                ],
                Padding(
                  padding: const EdgeInsets.only(right: 90),
                  child: Text(titleLine1, style: headline),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -2,
                      right: -4,
                      bottom: 2,
                      height: 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.sunYellow.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ).animate(delay: 750.ms).scaleX(
                            begin: 0,
                            end: 1,
                            alignment: Alignment.centerLeft,
                            duration: 500.ms,
                            curve: Curves.easeOutCubic,
                          ),
                    ),
                    Text(titleHighlight, style: headline),
                  ],
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
                if (subtitle != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 70),
                    child: Text(
                      subtitle!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                      .animate(delay: 450.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.4, end: 0),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.9, end: 1.1, duration: 4.seconds, curve: Curves.easeInOut);
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.icon,
    required this.size,
    required this.delay,
  });

  final IconData icon;
  final double size;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: AppColors.secondary, size: size * 0.46),
    )
        .animate(delay: (300 + delay).ms)
        .fadeIn(duration: 500.ms)
        .scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack, duration: 600.ms)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: 2200.ms, curve: Curves.easeInOut);
  }
}
