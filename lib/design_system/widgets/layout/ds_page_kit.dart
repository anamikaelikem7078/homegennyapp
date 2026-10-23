import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/exceptions/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../buttons/ds_buttons.dart';
import '../navigation/ds_navigation.dart';

/// Page kit shared by Client / Staff sub-pages: pinned app bar with a round
/// back button, staggered body, sticky footer, gradient hero cards, notes,
/// pills, empty states and an async helper. Everything adapts to the
/// available width (small phones → tablets).

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE8EBF2);
const _canvas = Color(0xFFF6F8FC);

/// Horizontal page gutter for the current width.
double dsGutter(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 360) return 14;
  if (w < 600) return 20;
  return 28;
}

const dsCardShadow = [
  BoxShadow(color: Color(0x0F0B1B4D), blurRadius: 18, offset: Offset(0, 8)),
];

BoxDecoration dsCardDecoration({Color color = Colors.white, double radius = 22, Color? border}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? _border.withValues(alpha: 0.8)),
      boxShadow: dsCardShadow,
    );

/// Sliver page with a pinned app bar.
class DsPage extends StatelessWidget {
  const DsPage({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.onRefresh,
    this.onBack,
    this.showBack = true,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.animate = true,
    this.extraBottomPadding = 0,
  });

  final String title;
  final String? subtitle;
  final List<Widget> body;
  final List<Widget> actions;

  /// Sticky footer (usually the primary CTA).
  final Widget? bottom;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onBack;
  final bool showBack;
  final Widget? floatingActionButton;

  /// Replaces [bottom] for tab screens with a nav bar.
  final Widget? bottomNavigationBar;
  final bool animate;

  /// Extra space under the list, e.g. for a floating bottom nav.
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    final gutter = dsGutter(context);
    final children = animate
        ? body
            .animate(interval: 55.ms)
            .fadeIn(duration: 380.ms)
            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic)
        : body;

    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _canvas,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          automaticallyImplyLeading: false,
          toolbarHeight: subtitle == null ? 68 : 74,
          leadingWidth: showBack ? gutter + 44 : 0,
          leading: showBack
              ? Padding(
                  padding: EdgeInsets.only(left: gutter),
                  child: Center(
                    child: DsBackButton(
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    ),
                  ),
                )
              : null,
          titleSpacing: showBack ? 12 : gutter,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: _ink,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
            ],
          ),
          actions: [...actions, SizedBox(width: gutter - 8)],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            4,
            gutter,
            ((bottom == null && bottomNavigationBar == null) ? 40 : 24) + extraBottomPadding,
          ),
          sliver: SliverList.list(children: children),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: _canvas,
      floatingActionButton: floatingActionButton,
      body: onRefresh == null
          ? scroll
          : RefreshIndicator(color: AppColors.primary, onRefresh: onRefresh!, child: scroll),
      bottomNavigationBar: bottomNavigationBar ??
          (bottom == null
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 12),
                  child: SafeArea(top: false, child: bottom!),
                ).animate().slideY(begin: 1, end: 0, duration: 450.ms, curve: Curves.easeOutCubic)),
    );
  }
}

/// Round white icon button for [DsPage.actions].
class DsPageAction extends StatelessWidget {
  const DsPageAction({super.key, required this.icon, required this.onPressed, this.tooltip, this.badge = 0});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(side: BorderSide(color: _border)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onPressed!();
                    },
              child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 21, color: _ink)),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Navy → blue gradient hero card. [colors] can override the gradient.
class DsGradientCard extends StatelessWidget {
  const DsGradientCard({
    super.key,
    required this.child,
    this.colors,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.decorate = true,
  });

  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Draws the soft yellow blob in the corner.
  final bool decorate;

  static const blue = [AppColors.navy, AppColors.primaryDark, AppColors.primary];
  static const green = [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)];
  static const orange = [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFFB923C)];
  static const red = [Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFFF87171)];

  @override
  Widget build(BuildContext context) {
    final c = colors ?? blue;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: c.last.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (decorate)
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sunYellow.withValues(alpha: 0.14),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// White rounded icon tile used on gradient cards, gently floating.
class DsFloatingIconTile extends StatelessWidget {
  const DsFloatingIconTile({super.key, required this.icon, this.size = 54, this.float = true});
  final IconData icon;
  final double size;
  final bool float;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.32)),
      child: Icon(icon, color: AppColors.iconAccent, size: size * 0.5),
    );
    if (!float) return tile;
    return tile
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -3, end: 3, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

/// Small translucent pill for gradient cards.
class DsGlassPill extends StatelessWidget {
  const DsGlassPill(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        // One Text.rich, not a Row: ellipsizes when the pill is squeezed and
        // still works inside unbounded Rows, where a Flexible would throw.
        child: Text.rich(
          TextSpan(
            children: [
              if (icon != null)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Icon(icon, size: 13, color: Colors.white),
                  ),
                ),
              TextSpan(text: text),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Colors.white,
          ),
        ),
      );
}

/// Translucent stat tile for gradient cards.
class DsGlassStat extends StatelessWidget {
  const DsGlassStat({super.key, required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(height: 6),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      );
}

/// Section title with a blue bar and an optional trailing widget.
class DsSection extends StatelessWidget {
  const DsSection(this.title, {super.key, this.trailing, this.top = 22});
  final String title;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(2, top, 2, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: _ink,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

enum DsNoteTone { info, success, warning, danger }

/// Tinted note with an icon.
class DsNote extends StatelessWidget {
  const DsNote({super.key, required this.text, this.title, this.tone = DsNoteTone.info});
  final String text;
  final String? title;
  final DsNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      DsNoteTone.info => (AppColors.primary, Icons.info_rounded),
      DsNoteTone.success => (AppColors.success, Icons.check_circle_rounded),
      DsNoteTone.warning => (AppColors.warning, Icons.warning_amber_rounded),
      DsNoteTone.danger => (AppColors.error, Icons.error_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone == DsNoteTone.info ? AppColors.iconAccent : color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      title!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ),
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
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

/// Small colored status pill.
class DsPill extends StatelessWidget {
  const DsPill(this.label, {super.key, this.color = AppColors.primary, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      );
}

/// Orange-on-peach rounded icon tile.
class DsIconTile extends StatelessWidget {
  const DsIconTile(this.icon, {super.key, this.size = 44, this.color, this.background});
  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? (color?.withValues(alpha: 0.12) ?? AppColors.iconAccentSoft),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(icon, color: color ?? AppColors.iconAccent, size: size * 0.5),
      );
}

/// White card with an icon tile, title, subtitle and trailing slot.
class DsListCard extends StatelessWidget {
  const DsListCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(),
            child: Row(
              children: [
                DsIconTile(icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!]
                else if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(color: _canvas, shape: BoxShape.circle),
                    child: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label / value row inside a [DsInfoCard].
class DsInfoLine {
  const DsInfoLine(this.icon, this.label, this.value, {this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

/// White card listing [DsInfoLine]s with hairline dividers.
class DsInfoCard extends StatelessWidget {
  const DsInfoCard({super.key, required this.lines});
  final List<DsInfoLine> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: dsCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 66, endIndent: 16, color: _border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  DsIconTile(lines[i].icon, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lines[i].label,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: _muted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      lines[i].value.isEmpty ? '—' : lines[i].value,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: lines[i].valueColor ?? _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated empty / error block with a pulsing halo.
class DsEmptyBlock extends StatelessWidget {
  const DsEmptyBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.iconAccent,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: dsCardDecoration(),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.9, end: 1.08, duration: 1400.ms, curve: Curves.easeInOut),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45, color: _muted),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

/// Lays children out in 1 column on phones and 2 on wide screens.
class DsAdaptiveGrid extends StatelessWidget {
  const DsAdaptiveGrid({super.key, required this.children, this.spacing = 12, this.minItemWidth = 260});
  final List<Widget> children;
  final double spacing;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / minItemWidth).floor().clamp(1, 3);
        if (cols == 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++)
                Padding(padding: EdgeInsets.only(top: i == 0 ? 0 : spacing), child: children[i]),
            ],
          );
        }
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final child in children) SizedBox(width: w, child: child)],
        );
      },
    );
  }
}

/// Spinner / friendly error block with retry / [builder] output.
List<Widget> dsAsyncBody<T>(
  AsyncValue<T> value, {
  required VoidCallback onRetry,
  required List<Widget> Function(T data) builder,
}) {
  return value.when(
    skipLoadingOnRefresh: true,
    loading: () => const [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      ),
    ],
    error: (e, _) => [
      DsEmptyBlock(
        icon: Icons.cloud_off_rounded,
        color: AppColors.error,
        title: 'Something went wrong',
        message: e is Failure
            ? e.message
            : e is Exception
                ? e.toString().replaceFirst('Exception: ', '')
                : 'Please check your connection and try again.',
        action: DsGradientButton(label: 'Retry', icon: Icons.refresh_rounded, isExpanded: false, onPressed: onRetry),
      ),
    ],
    data: builder,
  );
}

/// Labelled, filled text field with an orange leading icon.
class DsLabeledField extends StatelessWidget {
  const DsLabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.optional = false,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool optional;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink),
              ),
              if (optional) ...[
                const SizedBox(width: 6),
                Text(
                  'Optional',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: _muted),
                ),
              ],
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          maxLength: maxLength,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: _ink),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(bottom: maxLines > 1 ? (maxLines - 1) * 20.0 : 0),
                    child: Icon(icon, color: AppColors.iconAccent, size: 21),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Selectable chip / card used for choices (urgency, reasons…).
class DsChoiceChip extends StatelessWidget {
  const DsChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color = AppColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? color : _border),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.iconAccent),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar with initials on a blue gradient.
class DsInitialsAvatar extends StatelessWidget {
  const DsInitialsAvatar({super.key, required this.name, this.size = 44, this.imageUrl, this.radius});
  final String name;
  final double size;
  final String? imageUrl;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final r = BorderRadius.circular(radius ?? size * 0.32);
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fallback(initials))
            : _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.navy],
          ),
        ),
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
}

/// Expandable card (FAQ, details) with an icon and a rotating "+".
class DsExpandCard extends StatefulWidget {
  const DsExpandCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.initiallyOpen = false,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final bool initiallyOpen;

  @override
  State<DsExpandCard> createState() => _DsExpandCardState();
}

class _DsExpandCardState extends State<DsExpandCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 250.ms,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: dsCardDecoration(
        radius: 20,
        border: _open ? AppColors.primary.withValues(alpha: 0.35) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _open = !_open);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.icon != null) ...[DsIconTile(widget.icon!, size: 40), const SizedBox(width: 12)],
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _open ? 0.125 : 0,
                      duration: 250.ms,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _open ? AppColors.primary : _canvas,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_rounded, size: 18, color: _open ? Colors.white : AppColors.primary),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: 250.ms,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_open
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: EdgeInsets.fromLTRB(widget.icon != null ? 52 : 0, 10, 4, 2),
                          child: DefaultTextStyle.merge(
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.55, color: const Color(0xFF374151)),
                            child: widget.child,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum DsStepState { done, active, locked, failed }

class DsStep {
  const DsStep({required this.title, this.subtitle, this.state = DsStepState.locked, this.icon, this.onTap});
  final String title;
  final String? subtitle;
  final DsStepState state;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// Vertical timeline of steps (done / active / locked / failed).
class DsStepList extends StatelessWidget {
  const DsStepList({super.key, required this.steps});
  final List<DsStep> steps;

  static Color colorFor(DsStepState s) => switch (s) {
        DsStepState.done => AppColors.success,
        DsStepState.active => AppColors.primary,
        DsStepState.failed => AppColors.error,
        DsStepState.locked => const Color(0xFFCBD5E1),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 4),
      decoration: dsCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) _row(steps[i], i, i == steps.length - 1),
        ],
      ),
    );
  }

  Widget _row(DsStep s, int i, bool last) {
    final color = colorFor(s.state);
    final icon = switch (s.state) {
      DsStepState.done => Icons.check_rounded,
      DsStepState.failed => Icons.close_rounded,
      DsStepState.locked => Icons.lock_rounded,
      DsStepState.active => s.icon ?? Icons.circle,
    };
    final active = s.state == DsStepState.active;

    Widget dot = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: s.state == DsStepState.locked ? const Color(0xFFF1F5F9) : color,
        shape: BoxShape.circle,
        boxShadow: active ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)] : null,
      ),
      child: Icon(
        icon,
        size: s.state == DsStepState.active && s.icon == null ? 10 : 17,
        color: s.state == DsStepState.locked ? const Color(0xFF94A3B8) : Colors.white,
      ),
    );
    if (active) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.08, duration: 900.ms, curve: Curves.easeInOut);
    }

    return InkWell(
      onTap: s.onTap,
      borderRadius: BorderRadius.circular(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                dot.animate(delay: (90 * i).ms).scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: s.state == DsStepState.done ? AppColors.success.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 6, bottom: last ? 12 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: s.state == DsStepState.locked ? _muted : (active ? AppColors.primary : _ink),
                            ),
                          ),
                        ),
                        if (active) ...[const SizedBox(width: 8), const DsPill('Current')],
                      ],
                    ),
                    if (s.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        s.subtitle!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.4, color: _muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (s.onTap != null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
