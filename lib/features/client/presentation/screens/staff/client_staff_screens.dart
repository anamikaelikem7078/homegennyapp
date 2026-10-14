import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../../../../core/series/series_catalog.dart';
import '../care/client_care_screens.dart';

void _staffBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.staff);
  }
}

bool _isLate(String status) => status.toUpperCase() == 'LATE';
bool _isAbsent(String status) => status.toUpperCase() == 'ABSENT';

/// Gradient staff header used across the staff screens.
class _StaffHero extends StatelessWidget {
  const _StaffHero({
    required this.name,
    required this.subtitle,
    this.badge,
    this.badgeIcon = Icons.verified_rounded,
    this.stats = const [],
  });

  final String name;
  final String subtitle;
  final String? badge;
  final IconData badgeIcon;
  final List<Widget> stats;

  @override
  Widget build(BuildContext context) {
    return DsGradientCard(
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [AppColors.sunYellow, AppColors.secondary, AppColors.sunYellow],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: DsInitialsAvatar(name: name, size: 64, radius: 32),
                    ),
                  ).animate().scaleXY(begin: 0.6, end: 1, duration: 600.ms, curve: Curves.elasticOut),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(badgeIcon, size: 16, color: AppColors.iconAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 8),
                      DsGlassPill(badge!.toUpperCase(), icon: badgeIcon),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: stats[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated ring with a centered value.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.label, required this.caption, this.size = 120, this.color});
  final double value;
  final String label;
  final String caption;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1).toDouble()),
        duration: 1100.ms,
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: size * 0.08,
                strokeCap: StrokeCap.round,
                backgroundColor: c.withValues(alpha: 0.12),
                color: c,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.24,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Staff tab.
class ClientStaffTabScreen extends ConsumerWidget {
  const ClientStaffTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedStaff = ref.watch(clientAssignedStaffProvider);
    final history = ref.watch(clientAttendanceHistoryProvider).valueOrNull ?? const <ClientAttendanceRecord>[];
    final l10n = context.l10n;

    return DsPage(
      title: 'Your staff',
      subtitle: l10n.professionalProfile,
      showBack: false,
      extraBottomPadding: 90,
      onRefresh: () async {
        ref.invalidate(clientAssignedStaffProvider);
        ref.invalidate(clientAttendanceHistoryProvider);
      },
      actions: [
        DsPageAction(
          icon: Icons.notifications_rounded,
          tooltip: l10n.notifications,
          onPressed: () => context.push(ClientRoutes.notifications),
        ),
      ],
      body: dsAsyncBody(
        assignedStaff,
        onRetry: () => ref.invalidate(clientAssignedStaffProvider),
        builder: (list) {
          if (list.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.people_alt_rounded,
                title: 'No staff assigned yet',
                message: 'Your assigned staff will appear here once deployed.',
              ),
            ];
          }
          final staff = list.first;
          final profile = ref.watch(clientStaffProfileProvider(staff.staffId)).valueOrNull;
          final deployed = staff.status == 'ACTIVE_DEPLOYED';
          final skills = (profile?.skills.isNotEmpty ?? false)
              ? profile!.skills
              : [l10n.skill1, l10n.skill2, l10n.skill3, l10n.skill4, l10n.skill5, l10n.skill6];
          final recent = history.take(14).toList();

          return [
            _StaffHero(
              name: staff.fullName ?? 'Staff',
              subtitle: [if (staff.series != null) SeriesDisplay.label(staff.series), if (staff.staffCode != null) staff.staffCode!].join(' · '),
              badge: deployed ? 'Actively deployed' : 'On trial',
              badgeIcon: deployed ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              stats: [
                DsGlassStat(
                  value: profile?.attendancePercent != null ? '${profile!.attendancePercent!.round()}%' : '—',
                  label: 'Attendance',
                  icon: Icons.event_available_rounded,
                ),
                DsGlassStat(
                  value: profile?.performanceScore != null ? profile!.performanceScore!.toStringAsFixed(1) : '—',
                  label: 'Rating',
                  icon: Icons.star_rounded,
                ),
                DsGlassStat(
                  value: profile?.isVerified == true ? 'Yes' : '—',
                  label: 'Verified',
                  icon: Icons.verified_user_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClientDailyCareLinks(staff: list),
            Row(
              children: [
                Expanded(
                  child: DsGradientButton(
                    label: 'View profile',
                    icon: Icons.badge_rounded,
                    onPressed: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DsOutlineButton(
                    label: 'Attendance',
                    icon: Icons.calendar_month_rounded,
                    onPressed: () => context.push(ClientRoutes.staffAttendance(staff.staffId)),
                  ),
                ),
              ],
            ),
            DsSection(l10n.professionalProfile),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(),
              child: Text(
                l10n.professionalProfileDesc,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.55, color: const Color(0xFF374151)),
              ),
            ),
            DsSection(
              l10n.workExperience,
              trailing: TextButton(
                onPressed: () => context.push(ClientRoutes.staffExperience(staff.staffId)),
                child: Text('See all', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              ),
            ),
            _TimelineEntry(
              date: l10n.expDate1,
              title: l10n.expTitle1,
              company: l10n.expCompany1,
              description: l10n.expDesc1,
              active: true,
              isLast: false,
            ),
            _TimelineEntry(
              date: l10n.expDate2,
              title: l10n.expTitle2,
              company: l10n.expCompany2,
              description: l10n.expDesc2,
              isLast: true,
            ),
            DsSection(
              l10n.expertiseSkills,
              trailing: TextButton(
                onPressed: () => context.push(ClientRoutes.staffSkills(staff.staffId)),
                child: Text('See all', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < skills.length; i++)
                  _SkillChip(label: skills[i])
                      .animate(delay: (50 * i).ms)
                      .fadeIn(duration: 250.ms)
                      .scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
              ],
            ),
            DsSection(l10n.attendanceRecordLabel),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const DsIconTile(Icons.calendar_month_rounded, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.monthlyPunctuality,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      DsPill(
                        profile?.attendancePercent != null ? '${profile!.attendancePercent!.round()}%' : '—',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (recent.isEmpty)
                    Text(
                      'No attendance logged yet.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.lightTextSecondary),
                    )
                  else
                    _DayDots(records: recent),
                  const Divider(height: 28, color: AppColors.lightBorder),
                  Text(
                    l10n.recentActivity,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ActivityItem(title: l10n.activity1, time: l10n.activityTime1),
                  const SizedBox(height: 10),
                  _ActivityItem(title: l10n.activity2, time: l10n.activityTime2),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }
}

class _DayDots extends StatelessWidget {
  const _DayDots({required this.records});
  final List<ClientAttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < records.length; i++)
          Tooltip(
            message: '${records[i].date} · ${records[i].status}',
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _isAbsent(records[i].status)
                    ? AppColors.error.withValues(alpha: 0.15)
                    : _isLate(records[i].status)
                        ? AppColors.warning
                        : AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _isAbsent(records[i].status) ? Icons.close_rounded : Icons.check_rounded,
                size: 15,
                color: _isAbsent(records[i].status) ? AppColors.error : Colors.white,
              ),
            ).animate(delay: (30 * i).ms).scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack),
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.date,
    required this.title,
    required this.company,
    required this.description,
    required this.isLast,
    this.active = false,
  });

  final String date;
  final String title;
  final String company;
  final String description;
  final bool isLast;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: dsCardDecoration(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DsPill(date, color: active ? AppColors.primary : AppColors.lightTextSecondary),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 14, color: AppColors.iconAccent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          company,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF374151)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.iconAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.title, required this.time});
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.lightTextSecondary),
        ),
      ],
    );
  }
}

/// Staff profile detail.
class ClientStaffProfileScreen extends ConsumerWidget {
  const ClientStaffProfileScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientStaffProfileProvider(staffId));
    final l10n = context.l10n;

    return DsPage(
      title: l10n.staffProfile,
      onBack: () => _staffBack(context),
      onRefresh: () async => ref.invalidate(clientStaffProfileProvider(staffId)),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientStaffProfileProvider(staffId)),
        builder: (s) => [
          _StaffHero(
            name: s.fullName,
            subtitle: '${SeriesDisplay.label(s.series)} · ${s.staffCode}',
            badge: s.isVerified ? 'Verified' : 'Verification pending',
            badgeIcon: s.isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            stats: [
              DsGlassStat(
                value: s.isVerified ? 'Verified' : 'Pending',
                label: 'Verification',
                icon: Icons.verified_user_rounded,
              ),
              DsGlassStat(value: s.pvStatus, label: 'Police check', icon: Icons.security_rounded),
            ],
          ),
          if (s.videoCertAvailable) ...[
            const SizedBox(height: 14),
            const DsNote(
              tone: DsNoteTone.success,
              title: 'Video certified',
              text: 'This staff member has completed HomeGenny\'s video training.',
            ),
          ],
          const DsSection('Explore'),
          DsAdaptiveGrid(
            children: [
              DsListCard(
                margin: EdgeInsets.zero,
                icon: Icons.work_history_rounded,
                title: l10n.experience,
                subtitle: l10n.yearsInCare,
                onTap: () => context.push(ClientRoutes.staffExperience(staffId)),
              ),
              DsListCard(
                margin: EdgeInsets.zero,
                icon: Icons.psychology_rounded,
                title: l10n.skills,
                subtitle: l10n.specialized,
                onTap: () => context.push(ClientRoutes.staffSkills(staffId)),
              ),
              DsListCard(
                margin: EdgeInsets.zero,
                icon: Icons.calendar_month_rounded,
                title: l10n.attendance,
                subtitle: l10n.attendanceRecordSub,
                onTap: () => context.push(ClientRoutes.staffAttendance(staffId)),
              ),
              DsListCard(
                margin: EdgeInsets.zero,
                icon: Icons.insights_rounded,
                title: l10n.performance,
                subtitle: l10n.topTier,
                onTap: () => context.push(ClientRoutes.staffPerformance(staffId)),
              ),
            ],
          ),
          const DsSection('Need a change?'),
          DsListCard(
            icon: Icons.swap_horiz_rounded,
            iconColor: AppColors.error,
            title: l10n.replacement,
            subtitle: l10n.manage,
            onTap: () => context.push(ClientRoutes.replacementRequest),
          ),
        ],
      ),
    );
  }
}

/// Staff experience.
class ClientStaffExperienceScreen extends ConsumerWidget {
  const ClientStaffExperienceScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientStaffProfileProvider(staffId));
    final l10n = context.l10n;

    return DsPage(
      title: l10n.experience,
      subtitle: l10n.curatedCareer,
      onBack: () => _staffBack(context),
      onRefresh: () async => ref.invalidate(clientStaffProfileProvider(staffId)),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientStaffProfileProvider(staffId)),
        builder: (s) => [
          DsGradientCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DsGlassPill('${s.experience.length} ROLES', icon: Icons.work_history_rounded),
                      const SizedBox(height: 12),
                      Text(
                        l10n.profJourneyExp,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.fullName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const DsFloatingIconTile(icon: Icons.workspace_premium_rounded),
              ],
            ),
          ),
          const DsSection('Focus areas'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DsChoiceChip(label: l10n.clinicalCare, selected: true, onTap: () {}),
              for (final t in [l10n.patientAdvocacy, l10n.gerontology, l10n.caseManagement, l10n.medicationAdmin])
                _SkillChip(label: t),
            ],
          ),
          const DsSection('Journey'),
          if (s.experience.isEmpty)
            const DsEmptyBlock(
              icon: Icons.work_off_rounded,
              title: 'No experience listed',
              message: 'Work history will appear here once it is added.',
            )
          else
            for (var i = 0; i < s.experience.length; i++)
              _TimelineEntry(
                date: s.experience[i].duration,
                title: s.experience[i].title,
                company: s.experience[i].organization,
                description: s.experience[i].description,
                active: i == 0,
                isLast: i == s.experience.length - 1,
              ),
          const SizedBox(height: 8),
          DsNote(text: l10n.referencesAvailable),
        ],
      ),
    );
  }
}

/// Staff skills.
class ClientStaffSkillsScreen extends ConsumerWidget {
  const ClientStaffSkillsScreen({super.key, required this.staffId});
  final String staffId;

  static const _expertise = [
    (
      'Culinary & fine dining',
      'Gourmet international cuisines, dietary specialisations including keto and vegan, and formal table service for entertaining.',
      'Elite',
      Icons.restaurant_rounded,
      ['Cordon Bleu certified', 'Sommelier basics', 'Event management'],
    ),
    (
      'Emergency response',
      'Trauma response, paediatric CPR and chronic illness management, with complete discretion in health coordination.',
      'Expert',
      Icons.medical_services_rounded,
      ['First aid', 'CPR certified'],
    ),
    (
      'Estate stewardship',
      'Specialist care for textiles, marble surfaces and art, plus wardrobe management and inventory of high-value perishables.',
      'Elite',
      Icons.cleaning_services_rounded,
      ['Antique care', 'Organisation'],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientStaffProfileProvider(staffId));

    return DsPage(
      title: context.l10n.skills,
      subtitle: 'Expertise & specialised skills',
      onBack: () => _staffBack(context),
      onRefresh: () async => ref.invalidate(clientStaffProfileProvider(staffId)),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientStaffProfileProvider(staffId)),
        builder: (s) => [
          DsGradientCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DsGlassPill('CURATION OF EXCELLENCE', icon: Icons.auto_awesome_rounded),
                      const SizedBox(height: 12),
                      Text(
                        '${s.skills.length} verified ${s.skills.length == 1 ? 'skill' : 'skills'}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        s.fullName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const DsFloatingIconTile(icon: Icons.psychology_rounded),
              ],
            ),
          ),
          if (s.skills.isNotEmpty) ...[
            const DsSection('Verified skills'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < s.skills.length; i++)
                  _SkillChip(label: s.skills[i])
                      .animate(delay: (40 * i).ms)
                      .fadeIn(duration: 250.ms)
                      .scaleXY(begin: 0.85, end: 1, curve: Curves.easeOutBack),
              ],
            ),
          ],
          const DsSection('Areas of expertise'),
          DsAdaptiveGrid(
            minItemWidth: 300,
            children: [
              for (var i = 0; i < _expertise.length; i++)
                _ExpertiseCard(
                  title: _expertise[i].$1,
                  description: _expertise[i].$2,
                  level: _expertise[i].$3,
                  icon: _expertise[i].$4,
                  tags: _expertise[i].$5,
                  highlight: i == 1,
                ),
            ],
          ),
          const SizedBox(height: 16),
          DsNote(
            title: 'Looking for a specific certification?',
            text: 'Ask your Relationship Manager — we can match a specialist to your home\'s needs.',
          ),
        ],
      ),
    );
  }
}

class _ExpertiseCard extends StatelessWidget {
  const _ExpertiseCard({
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
    required this.tags,
    this.highlight = false,
  });

  final String title;
  final String description;
  final String level;
  final IconData icon;
  final List<String> tags;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? Colors.white : AppColors.lightTextPrimary;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: highlight ? Colors.white : AppColors.iconAccentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.iconAccent),
            ),
            const Spacer(),
            highlight ? DsGlassPill(level.toUpperCase()) : DsPill(level, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 14),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: fg)),
        const SizedBox(height: 6),
        Text(
          description,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: highlight ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in tags)
              highlight ? DsGlassPill(t.toUpperCase()) : DsPill(t, color: AppColors.iconAccent),
          ],
        ),
      ],
    );

    if (highlight) return DsGradientCard(padding: const EdgeInsets.all(16), radius: 22, child: body);
    return Container(padding: const EdgeInsets.all(16), decoration: dsCardDecoration(), child: body);
  }
}

/// Staff attendance view.
class ClientStaffAttendanceScreen extends ConsumerWidget {
  const ClientStaffAttendanceScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientAttendanceHistoryProvider);
    final profile = ref.watch(clientStaffProfileProvider(staffId)).valueOrNull;

    return DsPage(
      title: context.l10n.attendance,
      subtitle: profile?.fullName,
      onBack: () => _staffBack(context),
      onRefresh: () async {
        ref.invalidate(clientAttendanceHistoryProvider);
        ref.invalidate(clientStaffProfileProvider(staffId));
      },
      bottom: DsGradientButton(
        label: 'Raise an issue',
        icon: Icons.flag_rounded,
        onPressed: () => context.push(ClientRoutes.attendanceRaiseIssue),
      ),
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(clientAttendanceHistoryProvider),
        builder: (list) {
          final late = list.where((r) => _isLate(r.status)).length;
          final absent = list.where((r) => _isAbsent(r.status)).length;
          final onTime = list.length - late - absent;
          final percent = profile?.attendancePercent ??
              (list.isEmpty ? null : (onTime + late) / list.length * 100);

          return [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: dsCardDecoration(),
              child: Row(
                children: [
                  _Ring(
                    value: (percent ?? 0) / 100,
                    label: percent != null ? '${percent.round()}%' : '—',
                    caption: 'PRESENT',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _StatLine(color: AppColors.success, label: 'On time', value: '$onTime days'),
                        const SizedBox(height: 10),
                        _StatLine(color: AppColors.warning, label: 'Delayed', value: '$late days'),
                        const SizedBox(height: 10),
                        _StatLine(color: AppColors.error, label: 'Absent', value: '$absent days'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DsSection('Recent logs', trailing: DsPill('${list.length}')),
            if (list.isEmpty)
              const DsEmptyBlock(
                icon: Icons.event_busy_rounded,
                title: 'No logs yet',
                message: 'Attendance logs will appear here after the first shift.',
              )
            else
              for (var i = 0; i < list.length; i++)
                _LogCard(record: list[i])
                    .animate(delay: (40 * i.clamp(0, 10)).ms)
                    .fadeIn(duration: 280.ms)
                    .slideX(begin: 0.05, end: 0),
            const SizedBox(height: 6),
            const DsNote(
              title: 'Notice a discrepancy?',
              text: 'If attendance records don\'t match what you saw, raise an issue and we\'ll audit it.',
            ),
          ];
        },
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
        ),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.record});
  final ClientAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final (color, label, icon) = _isAbsent(r.status)
        ? (AppColors.error, 'Absent', Icons.cancel_rounded)
        : _isLate(r.status)
            ? (AppColors.warning, 'Delayed', Icons.schedule_rounded)
            : (AppColors.success, 'On time', Icons.check_circle_rounded);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Row(
        children: [
          DsIconTile(icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.date,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                Text(
                  'In ${r.checkIn ?? '—'}  ·  Out ${r.checkOut ?? '—'}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
          DsPill(label, color: color),
        ],
      ),
    );
  }
}

/// Staff performance.
class ClientStaffPerformanceScreen extends ConsumerWidget {
  const ClientStaffPerformanceScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientStaffProfileProvider(staffId));

    return DsPage(
      title: context.l10n.performance,
      subtitle: 'Service excellence report',
      onBack: () => _staffBack(context),
      onRefresh: () async => ref.invalidate(clientStaffProfileProvider(staffId)),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientStaffProfileProvider(staffId)),
        builder: (s) {
          final score = s.performanceScore;
          return [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              decoration: dsCardDecoration(),
              child: Column(
                children: [
                  _Ring(
                    value: score != null ? score / 5 : 0,
                    label: score != null ? score.toStringAsFixed(1) : '—',
                    caption: 'SCORE / 5',
                    size: 150,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Icon(
                          score != null && i < score.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: AppColors.sunYellow,
                          size: 26,
                        ).animate(delay: (100 * i).ms).scaleXY(begin: 0, end: 1, curve: Curves.elasticOut, duration: 600.ms),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (score != null && score >= 4.5)
                    const DsPill('Elite partner', color: AppColors.secondary, icon: Icons.workspace_premium_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.schedule_rounded,
                    value: s.attendancePercent != null ? '${s.attendancePercent!.round()}%' : '—',
                    label: 'Punctuality',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.reviews_rounded,
                    value: '${s.reviews.length}',
                    label: 'Reviews',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _MetricTile(icon: Icons.speed_rounded, value: '2h', label: 'Response'),
                ),
              ],
            ),
            DsSection('Recent reviews', trailing: DsPill('${s.reviews.length}')),
            if (s.reviews.isEmpty)
              const DsEmptyBlock(
                icon: Icons.rate_review_rounded,
                title: 'No reviews yet',
                message: 'Reviews from your household will show up here.',
              )
            else
              for (final r in s.reviews) _ReviewCard(review: r),
          ];
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        children: [
          DsIconTile(icon, size: 38),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ClientReview review;

  @override
  Widget build(BuildContext context) {
    final r = review;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsInitialsAvatar(name: r.reviewerName, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.reviewerName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                    ),
                    Text(r.date, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.lightTextSecondary)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < r.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.sunYellow,
                      size: 16,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“${r.comment}”',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
