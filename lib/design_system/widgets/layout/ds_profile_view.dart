import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../dialogs/ds_dialogs.dart';
import '../navigation/ds_navigation.dart';

/// One number on the profile stats strip.
class DsProfileStat {
  const DsProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    this.decimals = 0,
  });

  final String label;
  final num value;
  final IconData icon;

  /// Digits after the decimal point (e.g. 1 for a 4.9 rating).
  final int decimals;
}

/// One row inside a profile menu section.
class DsProfileMenuItem {
  const DsProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.urgent = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Small pill on the right (e.g. "Action needed").
  final String? badge;

  /// Tints the row red to flag something that needs attention.
  final bool urgent;
}

class DsProfileSection {
  const DsProfileSection({required this.title, required this.items});

  final String title;
  final List<DsProfileMenuItem> items;
}

/// A front/back fact shown on the flip side of the member card.
class DsProfileFact {
  const DsProfileFact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// Shared profile page for Staff, Client and RM — a holographic member card
/// that tilts as you drag it and flips on tap, a count-up stats strip,
/// grouped menu cards and a confirm-to-logout button.
class DsProfileView extends StatelessWidget {
  const DsProfileView({
    super.key,
    required this.name,
    required this.role,
    required this.idLabel,
    required this.idValue,
    required this.sections,
    required this.onLogout,
    this.title = 'My profile',
    this.tagline = 'HomeGenny Member',
    this.facts = const [],
    this.stats = const [],
    this.highlight,
    this.onBack,
    this.onSettings,
    this.logoutLabel = 'Log out',
    this.bottomPadding = 120,
  });

  final String title;
  final String name;
  final String role;
  final String idLabel;
  final String idValue;
  final String tagline;

  /// Shown on the back of the card.
  final List<DsProfileFact> facts;
  final List<DsProfileStat> stats;

  /// Optional card between stats and menus (e.g. profile completion).
  final Widget? highlight;
  final List<DsProfileSection> sections;
  final Future<void> Function() onLogout;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final String logoutLabel;

  /// Space at the bottom for a floating nav bar.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          toolbarHeight: 68,
          leadingWidth: onBack == null ? 0 : 64,
          leading: onBack == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: DsBackButton(onPressed: onBack),
                ),
          titleSpacing: onBack == null ? 20 : 8,
          title: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.lightTextPrimary,
            ),
          ),
          actions: [
            if (onSettings != null)
              _CircleIconButton(
                icon: Icons.settings_rounded,
                onTap: onSettings!,
              ),
            const SizedBox(width: 20),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPadding),
          sliver: SliverList.list(
            children: [
              _MemberCard(
                name: name,
                role: role,
                idLabel: idLabel,
                idValue: idValue,
                tagline: tagline,
                facts: facts,
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.25, end: 0, curve: Curves.easeOutBack, duration: 700.ms)
                  .rotate(begin: -0.015, end: 0, duration: 700.ms),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap the card to flip · drag to tilt',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextHint,
                  ),
                ),
              ).animate(delay: 900.ms).fadeIn(duration: 500.ms),
              if (stats.isNotEmpty) ...[
                const SizedBox(height: 18),
                _StatsStrip(stats: stats),
              ],
              if (highlight != null) ...[
                const SizedBox(height: 14),
                highlight!,
              ],
              for (final s in sections) ...[
                const SizedBox(height: 22),
                _SectionCard(section: s),
              ],
              const SizedBox(height: 26),
              _LogoutButton(label: logoutLabel, onLogout: onLogout),
              const SizedBox(height: 18),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'HomeGenny · v1.0.0 · Made with ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextHint,
                      ),
                    ),
                    const Icon(Icons.favorite_rounded, size: 12, color: AppColors.secondary)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1, end: 1.25, duration: 700.ms),
                  ],
                ),
              ),
            ]
                .animate(interval: 60.ms, delay: 200.ms)
                .fadeIn(duration: 380.ms),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Member card
// ---------------------------------------------------------------------------

class _MemberCard extends StatefulWidget {
  const _MemberCard({
    required this.name,
    required this.role,
    required this.idLabel,
    required this.idValue,
    required this.tagline,
    required this.facts,
  });

  final String name;
  final String role;
  final String idLabel;
  final String idValue;
  final String tagline;
  final List<DsProfileFact> facts;

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard>
    with TickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final AnimationController _reset = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addListener(() {
      final t = Curves.easeOutBack.transform(_reset.value);
      setState(() {
        _tilt = Offset.lerp(_tiltAtRelease, Offset.zero, t)!;
      });
    });

  Offset _tilt = Offset.zero;
  Offset _tiltAtRelease = Offset.zero;

  @override
  void dispose() {
    _flip.dispose();
    _reset.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    _flip.isCompleted || _flip.velocity > 0 ? _flip.reverse() : _flip.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      onPanUpdate: (d) {
        _reset.stop();
        setState(() {
          _tilt = Offset(
            (_tilt.dx + d.delta.dx / 140).clamp(-0.35, 0.35),
            (_tilt.dy - d.delta.dy / 140).clamp(-0.35, 0.35),
          );
        });
      },
      onPanEnd: (_) {
        _tiltAtRelease = _tilt;
        _reset.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final angle = Curves.easeInOutCubic.transform(_flip.value) * math.pi;
          final showBack = angle > math.pi / 2;
          final matrix = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(_tilt.dy)
            ..rotateY(_tilt.dx + angle);

          return Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: AspectRatio(
              aspectRatio: 1.62,
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _CardBack(
                        idLabel: widget.idLabel,
                        idValue: widget.idValue,
                        facts: widget.facts,
                        seed: widget.idValue,
                      ),
                    )
                  : _CardFront(
                      name: widget.name,
                      role: widget.role,
                      idLabel: widget.idLabel,
                      idValue: widget.idValue,
                      tagline: widget.tagline,
                      glare: _tilt,
                    ),
            ),
          );
        },
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.primaryDark, AppColors.primary],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ],
    );

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.name,
    required this.role,
    required this.idLabel,
    required this.idValue,
    required this.tagline,
    required this.glare,
  });

  final String name;
  final String role;
  final String idLabel;
  final String idValue;
  final String tagline;
  final Offset glare;

  String get _initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative rings.
          Positioned(
            right: -60,
            top: -60,
            child: _Ring(size: 200, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: _Ring(size: 120, color: AppColors.sunYellow.withValues(alpha: 0.18)),
          ),
          Positioned(
            left: -50,
            bottom: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Glare that follows the tilt.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      (-glare.dx * 3).clamp(-1.0, 1.0),
                      (glare.dy * 3 - 0.6).clamp(-1.0, 1.0),
                    ),
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.sunYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.home_rounded, size: 16, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HomeGenny',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: AppColors.sunYellow),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppColors.sunYellow,
                            AppColors.secondary,
                            AppColors.sunYellow,
                          ],
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials.isEmpty ? '?' : _initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idLabel.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            idValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.robotoMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tagline,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sunYellow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        // Holographic sheen sweeping across now and then.
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          delay: 2500.ms,
          duration: 1600.ms,
          angle: 0.6,
          color: Colors.white.withValues(alpha: 0.22),
        );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.idLabel,
    required this.idValue,
    required this.facts,
    required this.seed,
  });

  final String idLabel;
  final String idValue;
  final List<DsProfileFact> facts;
  final String seed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in facts.take(3))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(f.icon, size: 15, color: AppColors.secondaryLight),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                f.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (facts.isEmpty)
                  Text(
                    'HomeGenny',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CustomPaint(painter: _CodePainter(seed)),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan to verify',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Decorative QR-style grid derived from [seed] (stable per user).
class _CodePainter extends CustomPainter {
  _CodePainter(this.seed);
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 11;
    final cell = size.width / n;
    final paint = Paint()..color = AppColors.navy;
    final rnd = math.Random(seed.hashCode);

    void finder(int cx, int cy) {
      final r = Rect.fromLTWH(cx * cell, cy * cell, cell * 3, cell * 3);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(cell * 0.6)), paint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.deflate(cell * 0.6), Radius.circular(cell * 0.3)),
        Paint()..color = Colors.white,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r.deflate(cell * 1.05), Radius.circular(cell * 0.2)),
        Paint()..color = AppColors.secondary,
      );
    }

    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final inFinder = (x < 4 && y < 4) || (x > n - 5 && y < 4) || (x < 4 && y > n - 5);
        if (inFinder || !rnd.nextBool()) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x * cell, y * cell, cell, cell).deflate(cell * 0.08),
            Radius.circular(cell * 0.25),
          ),
          paint,
        );
      }
    }
    finder(0, 0);
    finder(n - 3, 0);
    finder(0, n - 3);
  }

  @override
  bool shouldRepaint(_CodePainter old) => old.seed != seed;
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 18),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats, sections, logout
// ---------------------------------------------------------------------------

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.stats});
  final List<DsProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.iconAccentSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(stats[i].icon, size: 18, color: AppColors.iconAccent),
                  ),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: stats[i].value.toDouble()),
                    duration: 1000.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Text(
                      v.toStringAsFixed(stats[i].decimals),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  Text(
                    stats[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final DsProfileSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            section.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 66, endIndent: 16),
                _MenuRow(item: section.items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});
  final DsProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final accent = item.urgent ? AppColors.error : AppColors.iconAccent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          item.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.urgent ? AppColors.error : AppColors.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (item.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.urgent
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: item.urgent ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.lightSurfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
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

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.label, required this.onLogout});
  final String label;
  final Future<void> Function() onLogout;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _busy = false;

  Future<void> _confirm() async {
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Log out?',
      message: 'You\'ll need your mobile number and password to sign back in.',
      confirmLabel: 'Log out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await widget.onLogout();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _busy ? null : _confirm,
        child: SizedBox(
          height: 54,
          child: Center(
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.error,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.lightBorder)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: AppColors.lightTextPrimary),
        ),
      ),
    );
  }
}

/// Profile completion card for use in [DsProfileView.highlight].
class DsProfileProgressCard extends StatelessWidget {
  const DsProfileProgressCard({
    super.key,
    required this.percent,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final int percent;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: 1100.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: v,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        color: AppColors.secondary,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    Text(
                      '${(v * 100).round()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
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
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
