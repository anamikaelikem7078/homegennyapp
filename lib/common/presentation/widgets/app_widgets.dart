import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';

/// Decorative gradient background for auth screens.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkBackground,
                  AppColors.darkSurface,
                  AppColors.primaryDark,
                ],
              )
            : AppColors.authGradient,
      ),
      child: child,
    );
  }
}

/// HomeGenny logo mark with brand styling.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.showTagline = false,
    this.tagline,
  });

  final double size;
  final bool showTagline;
  final String? tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: context.theme.cardColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              color: context.theme.cardColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.home_work_rounded,
            size: size * 0.5,
            color: context.theme.cardColor,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
        if (showTagline && tagline != null) ...[
          SizedBox(height: 16),
          Text(
            tagline!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.theme.cardColor.withValues(alpha: 0.85),
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        ],
      ],
    );
  }
}

/// White card container for auth form content.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

/// Centered status illustration for error/empty states.
class StatusIllustration extends StatelessWidget {
  const StatusIllustration({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 56, color: color),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
        SizedBox(height: 32),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
        SizedBox(height: 12),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}

/// Loading overlay for async operations.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  SizedBox(height: 16),
                  Text(message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
