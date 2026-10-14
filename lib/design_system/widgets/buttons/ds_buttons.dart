import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';

enum DsButtonSize { small, medium, large }

/// Shared pill-button internals: press-to-shrink, soft shadow, loading swap.
class DsButtonBase extends StatefulWidget {
  const DsButtonBase({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
    this.padding,
    this.decoration,
    this.foregroundColor = Colors.white,
    this.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isExpanded;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final Color foregroundColor;
  final BoxBorder? border;

  @override
  State<DsButtonBase> createState() => _DsButtonBaseState();
}

class _DsButtonBaseState extends State<DsButtonBase> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? 54.0;
    final radius = BorderRadius.circular(buttonHeight);
    final base = widget.decoration ?? const BoxDecoration();

    final content = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _setPressed(true) : null,
        onTapUp: _enabled ? (_) => _setPressed(false) : null,
        onTapCancel: _enabled ? () => _setPressed(false) : null,
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: 120.ms,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: 220.ms,
            height: buttonHeight,
            padding: widget.padding ??
                EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: base.copyWith(
              borderRadius: radius,
              border: widget.border ?? base.border,
              boxShadow: _pressed
                  ? base.boxShadow
                      ?.map((s) => s.copyWith(
                            blurRadius: s.blurRadius / 2,
                            offset: s.offset / 2,
                          ))
                      .toList()
                  : base.boxShadow,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: 220.ms,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: a, child: c),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: widget.foregroundColor,
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('content'),
                        child: widget.child,
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.isExpanded) return content;
    return SizedBox(width: double.infinity, child: content);
  }
}

TextStyle _labelStyle(Color color, {double size = 16}) =>
    GoogleFonts.plusJakartaSans(
      color: color,
      fontWeight: FontWeight.w800,
      fontSize: size,
    );

Widget _labelRow({
  required String label,
  required Color color,
  IconData? icon,
  double size = 16,
  bool trailingArrow = false,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 20, color: color),
        SizedBox(width: AppSpacing.xs),
      ],
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _labelStyle(color, size: size),
        ),
      ),
      if (trailingArrow) ...[
        const SizedBox(width: 10),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_forward_rounded, size: 16, color: color),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: 0, end: 3, duration: 700.ms, curve: Curves.easeInOut),
      ],
    ],
  );
}

List<BoxShadow> _brandShadow() => [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.35),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];

/// Primary action button — blue gradient pill (login CTA style).
class DsPrimaryButton extends StatelessWidget {
  const DsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
    this.size = DsButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;
  final DsButtonSize size;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      height: _height,
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        gradient: disabled ? null : AppColors.primaryGradient,
        color: disabled ? AppColors.primary.withValues(alpha: 0.4) : null,
        boxShadow: disabled ? null : _brandShadow(),
      ),
      child: _labelRow(
        label: label,
        color: Colors.white,
        icon: icon,
        size: size == DsButtonSize.small ? 14 : 16,
        trailingArrow: icon == null && isExpanded && size != DsButtonSize.small,
      ),
    );
  }

  double get _height => switch (size) {
        DsButtonSize.small => 44,
        DsButtonSize.medium => 54,
        DsButtonSize.large => 58,
      };
}

/// Secondary action button — soft blue-tinted pill.
class DsSecondaryButton extends StatelessWidget {
  const DsSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : AppColors.primary;
    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      foregroundColor: fg,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.primaryContainer
                .withValues(alpha: onPressed == null ? 0.5 : 1),
      ),
      child: _labelRow(label: label, color: fg, icon: icon),
    );
  }
}

/// Outline pill button (biometric-button style on the login screen).
class DsOutlineButton extends StatelessWidget {
  const DsOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      foregroundColor: textColor,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF7F8FB),
        border: Border.all(
          color: color?.withValues(alpha: 0.5) ??
              (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: (color ?? AppColors.iconAccent).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: color ?? AppColors.iconAccent),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _labelStyle(textColor, size: 15)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient pill button with an idle shimmer sweep.
class DsGradientButton extends StatelessWidget {
  const DsGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final button = DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      foregroundColor: Colors.white,
      height: 56,
      decoration: BoxDecoration(
        gradient: disabled ? null : (gradient ?? AppColors.primaryGradient),
        color: disabled ? AppColors.primary.withValues(alpha: 0.4) : null,
        boxShadow: disabled ? null : _brandShadow(),
      ),
      child: _labelRow(
        label: label,
        color: Colors.white,
        icon: icon,
        trailingArrow: icon == null && isExpanded,
      ),
    );

    if (disabled || isLoading) return button;
    return button.animate(onPlay: (c) => c.repeat()).shimmer(
          delay: 1800.ms,
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.28),
        );
  }
}
