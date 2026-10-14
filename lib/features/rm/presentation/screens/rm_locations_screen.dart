import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// `GET /rm/locations` — despite the task brief describing this as
/// "staff GPS/location data", the actual backend response is branch/city/
/// area configuration used to filter attendance (verified against
/// `rm.service.ts`: `getLocations` returns `{ cities, branches, areas }`
/// with no per-staff coordinates at all, and no separate staff-GPS
/// endpoint exists anywhere in the API). This screen shows exactly that —
/// a location/branch reference list — not a fabricated map of staff pins.
class RmLocationsScreen extends ConsumerStatefulWidget {
  const RmLocationsScreen({super.key});

  @override
  ConsumerState<RmLocationsScreen> createState() => _RmLocationsScreenState();
}

class _RmLocationsScreenState extends ConsumerState<RmLocationsScreen> {
  String? _city;

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(rmLocationsProvider);

    return RmStageScaffold(
      title: 'Locations',
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(rmLocationsProvider),
      body: rmAsyncBody<LocationsData>(
        locationsAsync,
        onRetry: () => ref.invalidate(rmLocationsProvider),
        builder: (data) {
          final cities = {
            ...data.cities,
            ...data.branches.map((b) => b.city),
          }.where((c) => c.isNotEmpty).toList()
            ..sort();
          final branches = data.branches
              .where((b) => _city == null || b.city == _city)
              .toList();
          final branchIds = data.branches.map((b) => b.id).toSet();
          final orphanAreas = data.areas
              .where((a) => !branchIds.contains(a.branchId))
              .where((a) => _city == null || a.city == _city)
              .toList();

          return [
            _LocationsHero(
              cities: cities.length,
              branches: data.branches.length,
              areas: data.areas.length,
            ),
            const SizedBox(height: 14),
            const RmNote(
              text: 'Branch and area reference used for attendance. '
                  'Live staff location is not tracked, so no map is shown.',
            ),
            if (cities.length > 1) ...[
              const RmSectionTitle(title: 'City'),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    _CityChip(
                      label: 'All',
                      selected: _city == null,
                      onTap: () => setState(() => _city = null),
                    ),
                    for (final c in cities)
                      _CityChip(
                        label: c,
                        selected: _city == c,
                        onTap: () => setState(() => _city = c),
                      ),
                  ],
                ),
              ),
            ],
            RmSectionTitle(
              title: 'Branches',
              trailing: RmStatusPill(label: '${branches.length}', color: RmTheme.electricBlue),
            ),
            if (branches.isEmpty)
              const RmEmptyBlock(
                icon: Icons.location_off_rounded,
                title: 'No branches',
                message: 'No branches are configured for this city yet.',
              )
            else
              for (final b in branches)
                _BranchCard(
                  branch: b,
                  areas: data.areas.where((a) => a.branchId == b.id).toList(),
                ),
            if (orphanAreas.isNotEmpty)
              _BranchCard(
                branch: BranchInfo(id: '', name: 'Other areas', city: _city ?? 'All cities'),
                areas: orphanAreas,
              ),
          ];
        },
      ),
    );
  }
}

class _LocationsHero extends StatelessWidget {
  const _LocationsHero({required this.cities, required this.branches, required this.areas});
  final int cities;
  final int branches;
  final int areas;

  @override
  Widget build(BuildContext context) {
    Widget stat(IconData icon, int value, String label) => Expanded(
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: RmTheme.iconAccent, size: 21),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: 800.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  '${v.round()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          stat(Icons.location_city_rounded, cities, 'Cities'),
          stat(Icons.apartment_rounded, branches, 'Branches'),
          stat(Icons.place_rounded, areas, 'Areas'),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: 220.ms,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? RmTheme.electricBlue : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: selected ? RmTheme.electricBlue : RmTheme.borderSubtle),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : RmTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchCard extends StatefulWidget {
  const _BranchCard({required this.branch, required this.areas});
  final BranchInfo branch;
  final List<AreaInfo> areas;

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final hasAreas = widget.areas.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _open ? RmTheme.electricBlue.withValues(alpha: 0.35) : RmTheme.borderSubtle.withValues(alpha: 0.7),
        ),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: hasAreas ? () => setState(() => _open = !_open) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: RmTheme.iconAccentSoft,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: RmTheme.iconAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.branch.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: RmTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: RmTheme.textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  '${widget.branch.city} · ${widget.areas.length} '
                                  '${widget.areas.length == 1 ? 'area' : 'areas'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: RmTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasAreas)
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: 250.ms,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: RmTheme.offWhite,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: RmTheme.electricBlue),
                        ),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: 280.ms,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_open
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final a in widget.areas)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: RmTheme.offWhite,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.place_rounded, size: 14, color: RmTheme.iconAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        a.label.isNotEmpty ? a.label : a.area,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: RmTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(duration: 250.ms).scaleXY(begin: 0.9, end: 1),
                            ],
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
