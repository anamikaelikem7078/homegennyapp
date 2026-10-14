import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../navigation/ds_navigation.dart';

/// Gradient hero header shared by every role's main screens — the same
/// navy → electric-blue hero, glowing blobs and floating orange icon tiles
/// used on the login / sign-up screens.
///
/// Place it as the first child of a scroll view. Pass [bottom] for content
/// that should sit inside the hero (stats, search, chips).
class DsHeroHeader extends StatelessWidget {
  const DsHeroHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.eyebrowIcon = Icons.bolt_rounded,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.floatingIcons = const [],
    this.bottom,
    this.showBack = false,
    this.onBack,
    this.bottomRadius = 32,
    this.extraBottomPadding = 28,
  });

  final String title;

  /// Small pill above the title (e.g. "Good morning").
  final String? eyebrow;
  final IconData eyebrowIcon;
  final String? subtitle;

  /// Widget shown at the top-left (e.g. avatar). Ignored when [showBack].
  final Widget? leading;

  /// Top-right actions — use [DsHeroIconButton].
  final List<Widget> actions;

  /// Up to three icons that float on the right side of the hero.
  final List<IconData> floatingIcons;
  final Widget? bottom;
  final bool showBack;
  final VoidCallback? onBack;
  final double bottomRadius;

  /// Space below the content — leave room when a card overlaps the hero.
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final hasTopRow = showBack || leading != null || actions.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRRect(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -50,
                child: _Blob(
                  size: 220,
                  color: AppColors.sunYellow.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -70,
                child: _Blob(
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              for (var i = 0; i < floatingIcons.length && i < 3; i++)
                Positioned(
                  top: topInset + const [70.0, 128.0, 92.0][i],
                  right: const [24.0, 78.0, 128.0][i],
                  child: _FloatingIcon(
                    icon: floatingIcons[i],
                    size: const [50.0, 40.0, 34.0][i],
                    delay: i * 350,
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  topInset + 12,
                  20,
                  extraBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTopRow)
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            if (showBack)
                              DsBackButton(onPressed: onBack, onDark: true)
                            else if (leading != null)
                              leading!,
                            const Spacer(),
                            for (final a in actions) ...[
                              const SizedBox(width: 8),
                              a,
                            ],
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),
                    SizedBox(height: hasTopRow ? 22 : 8),
                    if (eyebrow != null) ...[
                      _EyebrowPill(text: eyebrow!, icon: eyebrowIcon)
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 350.ms)
                          .scaleXY(
                            begin: 0.8,
                            end: 1,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 12),
                    ],
                    Padding(
                      padding: EdgeInsets.only(
                        right: floatingIcons.isEmpty ? 0 : 96,
                      ),
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate(delay: 180.ms)
                        .fadeIn(duration: 450.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: EdgeInsets.only(
                          right: floatingIcons.isEmpty ? 0 : 96,
                        ),
                        child: Text(
                          subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      )
                          .animate(delay: 300.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
                    if (bottom != null) ...[
                      const SizedBox(height: 20),
                      bottom!
                          .animate(delay: 380.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Time-of-day greeting for hero eyebrows.
String dsGreeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// White pill CTA that sits on the hero (blue text, press-to-shrink).
class DsHeroPillButton extends StatefulWidget {
  const DsHeroPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<DsHeroPillButton> createState() => _DsHeroPillButtonState();
}

class _DsHeroPillButtonState extends State<DsHeroPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onPressed?.call();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: 120.ms,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 17, color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent round icon button for use on [DsHeroHeader].
class DsHeroIconButton extends StatelessWidget {
  const DsHeroIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final int badgeCount;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );

    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.primaryDark, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.12, duration: 800.ms),
            ),
        ],
      ),
    );
  }
}

/// Avatar with a yellow ring, for the hero's leading slot.
class DsRingAvatar extends StatelessWidget {
  const DsRingAvatar({super.key, required this.name, this.onTap, this.size = 44});

  final String name;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.sunYellow,
          shape: BoxShape.circle,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Translucent stat tile for the hero's [DsHeroHeader.bottom] slot.
class DsHeroStat extends StatelessWidget {
  const DsHeroStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
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

class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.sunYellow, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
        .moveY(begin: -5, end: 5, duration: 2200.ms, curve: Curves.easeInOut);
  }
}
