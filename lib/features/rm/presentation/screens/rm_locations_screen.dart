import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// `GET /rm/locations` — despite the task brief describing this as
/// "staff GPS/location data", the actual backend response is branch/city/
/// area configuration used to filter attendance (verified against
/// `rm.service.ts`: `getLocations` returns `{ cities, branches, areas }`
/// with no per-staff coordinates at all, and no separate staff-GPS
/// endpoint exists anywhere in the API). This screen shows exactly that —
/// a location/branch reference list — not a fabricated map of staff pins.
class RmLocationsScreen extends ConsumerWidget {
  const RmLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(rmLocationsProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: Text('Locations', style: RmTheme.headline(context).copyWith(fontSize: 20)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmLocationsProvider),
        child: AsyncValueWidget<LocationsData>(
          value: locationsAsync,
          onRetry: () => ref.invalidate(rmLocationsProvider),
          builder: (data) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildInfoBanner()
                  .animate()
                  .fadeIn(delay: 50.ms, duration: 350.ms)
                  .slideY(begin: 0.05, end: 0, delay: 50.ms, duration: 350.ms),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Branches', data.branches.length),
              const SizedBox(height: 10),
              for (var i = 0; i < data.branches.length; i++)
                _LocationCard(
                  icon: Icons.apartment_rounded,
                  title: data.branches[i].name,
                  subtitle: data.branches[i].city,
                ).animate().fadeIn(delay: (100 + i * 40).ms, duration: 300.ms).slideY(
                      begin: 0.04,
                      end: 0,
                      delay: (100 + i * 40).ms,
                      duration: 300.ms,
                    ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Areas', data.areas.length),
              const SizedBox(height: 10),
              for (var i = 0; i < data.areas.length; i++)
                _LocationCard(
                  icon: Icons.place_rounded,
                  title: data.areas[i].label,
                  subtitle: data.areas[i].city,
                ).animate().fadeIn(delay: (150 + i * 40).ms, duration: 300.ms).slideY(
                      begin: 0.04,
                      end: 0,
                      delay: (150 + i * 40).ms,
                      duration: 300.ms,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.amberWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RmTheme.amberWarning.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: RmTheme.amberWarning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is branch/city reference data used for attendance filtering — the backend has no staff '
              'GPS/live-location endpoint. No map or staff pins are shown here.',
              style: GoogleFonts.inter(
                color: const Color(0xFFB45309),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label, int count) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: RmTheme.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: RmTheme.electricBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: RmTheme.electricBlue),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x03000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: RmTheme.electricBlue.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, color: RmTheme.electricBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5, color: RmTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: RmTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
