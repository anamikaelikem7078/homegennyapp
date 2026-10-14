import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../../../design_system/widgets/layout/ds_hero_header.dart';

/// Shared building blocks for the RM account-settings sub-screens:
/// gradient hero header, white 22px cards, orange icon tiles, Plus Jakarta.
abstract final class RmAccountStyle {
  static const Color chipBlue = Color(0xFFEBF2FF);
  static const Color bannerBlue = Color(0xFFEFF6FF);
  static const Color bannerBorder = Color(0xFFDBEAFE);
  static const Color ink = RmTheme.textPrimary;
  static const Color body = Color(0xFF4B5563);
  static const Color coral = RmTheme.crimsonDanger;
  static const Color coralChip = Color(0xFFFEE2E2);
  static const Color switchOff = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xB3E8EBF2);

  static const List<BoxShadow> cardShadow = RmTheme.subtleShadow;

  static BoxDecoration card({Color color = Colors.white}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: cardShadow,
      );
}

/// Scaffold for account sub-pages: a gradient [DsHeroHeader] (back button,
/// title, subtitle, optional [hero] content) followed by a staggered list.
class RmAccountScaffold extends StatelessWidget {
  const RmAccountScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.eyebrow,
    this.eyebrowIcon = Icons.bolt_rounded,
    this.hero,
    this.floatingIcons = const [],
    this.actions,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData eyebrowIcon;

  /// Extra content rendered at the bottom of the hero (stats, avatar…).
  final Widget? hero;
  final List<IconData> floatingIcons;
  final List<Widget> children;

  /// Hero actions — use [DsHeroIconButton] / [RmHeroTextButton].
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DsHeroHeader(
              title: title,
              subtitle: subtitle,
              eyebrow: eyebrow,
              eyebrowIcon: eyebrowIcon,
              showBack: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: actions ?? const [],
              floatingIcons: floatingIcons,
              bottom: hero,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + MediaQuery.paddingOf(context).bottom),
            sliver: SliverList.list(
              children: children
                  .animate(interval: 50.ms, delay: 150.ms)
                  .fadeIn(duration: 380.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent text pill for hero actions (e.g. "Reset").
class RmHeroTextButton extends StatelessWidget {
  const RmHeroTextButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: StadiumBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header with an optional right-hand slot.
class RmSectionLabel extends StatelessWidget {
  const RmSectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: RmTheme.electricBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Muted caption used in a [RmSectionLabel]'s trailing slot.
class RmSectionMeta extends StatelessWidget {
  const RmSectionMeta(this.text, {super.key, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tappable ? RmTheme.electricBlue.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: tappable ? FontWeight.w800 : FontWeight.w600,
          color: tappable ? RmTheme.electricBlue : RmTheme.textSecondary,
        ),
      ),
    );
    return tappable ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: label) : label;
  }
}

/// White rounded card that stacks rows with hairline dividers.
class RmGroupCard extends StatelessWidget {
  const RmGroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(const Divider(height: 1, indent: 72, endIndent: 16, color: RmTheme.borderSubtle));
      }
    }
    return Container(
      decoration: RmAccountStyle.card(),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent, child: Column(children: rows)),
    );
  }
}

/// Rounded icon tile — orange icon on soft orange by default.
class RmIconBadge extends StatelessWidget {
  const RmIconBadge(
    this.icon, {
    super.key,
    this.color = RmTheme.iconAccent,
    this.background = RmTheme.iconAccentSoft,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

/// Small rounded pill, e.g. "PRIMARY", "Staff", "VERIFICATION REQUIRED".
class RmPill extends StatelessWidget {
  const RmPill(
    this.text, {
    super.key,
    this.icon,
    this.color = RmTheme.electricBlue,
    this.background = RmAccountStyle.chipBlue,
    this.uppercase = false,
    this.border,
  });

  final String text;
  final IconData? icon;
  final Color color;
  final Color background;
  final bool uppercase;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border != null ? Border.all(color: border!) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 6)],
            Text(
              uppercase ? text.toUpperCase() : text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: uppercase ? 10.5 : 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: uppercase ? 0.8 : 0,
              ),
            ),
          ],
        ),
      );
}

class RmInfoRow extends StatelessWidget {
  const RmInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.badge,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final Widget? badge;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final valueStyle = monospace
        ? GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w600, color: RmAccountStyle.ink)
        : GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: RmAccountStyle.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          RmIconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value.isEmpty ? '—' : value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: valueStyle,
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 8), badge!],
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class RmSwitchRow extends StatelessWidget {
  const RmSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return AnimatedOpacity(
      duration: 200.ms,
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onChanged!(!value);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: 250.ms,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: value ? RmTheme.iconAccentSoft : RmTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: value ? RmTheme.iconAccent : RmTheme.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: RmAccountStyle.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: RmTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (v) {
                        HapticFeedback.selectionClick();
                        onChanged!(v);
                      },
                activeThumbColor: Colors.white,
                activeTrackColor: RmTheme.electricBlue,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: RmAccountStyle.switchOff,
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RmActionRow extends StatelessWidget {
  const RmActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = RmTheme.iconAccent,
    this.chipColor = RmTheme.iconAccentSoft,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Color chipColor;

  @override
  Widget build(BuildContext context) {
    final danger = color == RmAccountStyle.coral;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            RmIconBadge(icon, color: color, background: chipColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: danger ? RmAccountStyle.coral : RmAccountStyle.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: RmTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: danger ? RmAccountStyle.coralChip : RmTheme.offWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: danger ? RmAccountStyle.coral : RmTheme.electricBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width gradient pill CTA.
class RmPrimaryButton extends StatelessWidget {
  const RmPrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.trailingIcon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return DsGradientButton(
      label: label,
      icon: trailingIcon,
      isLoading: busy,
      onPressed: busy ? null : onPressed,
    );
  }
}

/// Small white card used inside a hero (e.g. stats).
class RmHeroGlassTile extends StatelessWidget {
  const RmHeroGlassTile({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: RmTheme.iconAccent),
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
                    fontSize: 14,
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

void rmToast(BuildContext context, String message, {bool error = false}) {
  DsSnackBar.show(
    context,
    message: message,
    type: error ? DsSnackBarType.error : DsSnackBarType.success,
  );
}

// Re-exported so account screens can use hero buttons without extra imports.
typedef RmHeroIconButton = DsHeroIconButton;
