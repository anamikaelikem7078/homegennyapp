import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

class ClientStaffTabScreen extends ConsumerWidget {
  const ClientStaffTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedStaff = ref.watch(clientAssignedStaffProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => context.push(ClientRoutes.notifications),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade100, width: 1.5),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1A56FF),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: assignedStaff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          if (list.isEmpty) {
            return const DsEmptyState(
              title: 'No staff assigned yet',
              message: 'Your assigned staff will appear here once deployed.',
              icon: Icons.people_outline,
            );
          }
          final staff = list.first;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: context.theme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A56FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.star, color: context.theme.cardColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Name and Title
              Center(
                child: Text(
                  staff.fullName ?? 'Staff',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 32,
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  staff.series ?? '',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A56FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    staff.status == 'ACTIVE_DEPLOYED' ? Icons.check_circle_outline : Icons.hourglass_empty_rounded,
                    color: Color(0xFF1A56FF),
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    staff.status == 'ACTIVE_DEPLOYED' ? 'Actively Deployed' : 'On Trial',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A56FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (staff.staffCode != null && staff.staffCode!.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('|', style: TextStyle(color: Colors.black26)),
                    ),
                    Text(
                      staff.staffCode!,
                      style: GoogleFonts.inter(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 40),
              // Professional Profile
              Text(
                context.l10n.professionalProfile,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 16,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: context.l10n.dDropcap,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 48,
                        color: context.colors.onSurface,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.professionalProfileDesc,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              // Work Experience
              Text(
                context.l10n.workExperience,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 16,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 24),
              _TimelineItem(
                date: context.l10n.expDate1,
                title: context.l10n.expTitle1,
                company: context.l10n.expCompany1,
                description: context.l10n.expDesc1,
                isLast: false,
                isActive: true,
              ),
              _TimelineItem(
                date: context.l10n.expDate2,
                title: context.l10n.expTitle2,
                company: context.l10n.expCompany2,
                description: context.l10n.expDesc2,
                isLast: true,
                isActive: false,
              ),
              SizedBox(height: 32),
              // Expertise & Skills
              Text(
                context.l10n.expertiseSkills,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 16,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  _SkillChip(label: context.l10n.skill1),
                  _SkillChip(label: context.l10n.skill2),
                  _SkillChip(label: context.l10n.skill3),
                  _SkillChip(label: context.l10n.skill4),
                  _SkillChip(label: context.l10n.skill5),
                  _SkillChip(label: context.l10n.skill6),
                ],
              ),
              SizedBox(height: 40),
              // Attendance Record
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.attendanceRecordLabel,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 16,
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A56FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: Color(0xFF1A56FF),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          context.l10n.monthlyPunctuality,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '98%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        context.l10n.mon,
                        context.l10n.tue,
                        context.l10n.wed,
                        context.l10n.thu,
                        context.l10n.fri,
                        context.l10n.sat,
                        context.l10n.sun
                      ].map((day) {
                        return Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [true, true, true, true, true, false, false]
                          .map((active) {
                            return Container(
                              width: 32,
                              height: 32,
                              color: active
                                  ? const Color(0xFF1A56FF)
                                  : Colors.grey.shade200,
                            );
                          })
                          .toList(),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [true, true, true, true, true, false, false]
                          .map((active) {
                            return Container(
                              width: 32,
                              height: 32,
                              color: active
                                  ? const Color(0xFF1A56FF)
                                  : Colors.grey.shade200,
                            );
                          })
                          .toList(),
                    ),
                    SizedBox(height: 32),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    SizedBox(height: 24),
                    Text(
                      context.l10n.recentActivity,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 16),
                    _ActivityItem(
                      title: context.l10n.activity1,
                      time: context.l10n.activityTime1,
                    ),
                    SizedBox(height: 16),
                    _ActivityItem(
                      title: context.l10n.activity2,
                      time: context.l10n.activityTime2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100), // padding for floating bottom nav
            ],
          );
        },
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.date,
    required this.title,
    required this.company,
    required this.description,
    required this.isLast,
    required this.isActive,
  });
  final String date;
  final String title;
  final String company;
  final String description;
  final bool isLast;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF1A56FF)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 100,
                color: Colors.grey.shade200,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A56FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.libreCaslonText(
                  color: context.colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                company,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              if (!isLast) SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // very light grey for chips
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: context.colors.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
        Icon(Icons.circle_outlined, color: const Color(0xFF1A56FF), size: 14),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: context.colors.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.inter(color: context.colors.onSurfaceVariant, fontSize: 11),
            ),
          ],
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

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Avatar
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: context.theme.dividerColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            // Name and Title
            Center(
              child: Text(
                s.fullName,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 4),
            Center(
              child: Text(
                s.series,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9E7C5D),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              s.isVerified ? Icons.verified_outlined : Icons.hourglass_empty_rounded,
                              color: Color(0xFF1A56FF),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              s.isVerified ? 'Verified' : 'Pending',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF1A56FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'VERIFICATION',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security_outlined,
                              color: Color(0xFF1A56FF),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              s.pvStatus,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF1A56FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'PV STATUS',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            // Navigation Blocks
            _NavCard(
              icon: Icons.work_outline,
              title: context.l10n.experience,
              subtitle: context.l10n.yearsInCare,
              onTap: () => context.push(ClientRoutes.staffExperience(staffId)),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NavCardSquare(
                    icon: Icons.verified_outlined,
                    title: context.l10n.skills,
                    subtitle: context.l10n.specialized,
                    onTap: () =>
                        context.push(ClientRoutes.staffSkills(staffId)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _NavCardSquare(
                    icon: Icons.calendar_today_outlined,
                    title: context.l10n.attendance,
                    subtitle: context.l10n.attendanceRecordSub,
                    onTap: () =>
                        context.push(ClientRoutes.staffAttendance(staffId)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NavCardSquare(
                    icon: Icons.insights,
                    title: context.l10n.performance,
                    subtitle: context.l10n.topTier,
                    onTap: () =>
                        context.push(ClientRoutes.staffPerformance(staffId)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _NavCardSquare(
                    icon: Icons.person_remove_alt_1_outlined,
                    title: context.l10n.replacement,
                    subtitle: context.l10n.manage,
                    onTap: () => context.push(ClientRoutes.replacementRequest),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(height: 100), // padding for bottom nav if any
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1A56FF), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF1A56FF),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _NavCardSquare extends StatelessWidget {
  const _NavCardSquare({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1A56FF), size: 22),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF1A56FF),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Center(
              child: Text(
                context.l10n.curatedCareer,
                style: GoogleFonts.inter(
                  color: const Color(0xFF9E7C5D), // A sophisticated brown/gold
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                context.l10n.profJourneyExp,
                textAlign: TextAlign.center,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                width: 40,
                height: 1,
                color: context.theme.dividerColor,
              ),
            ),
            SizedBox(height: 32),
            // Journey Tags
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _JourneyTag(label: context.l10n.clinicalCare, isActive: true),
                _JourneyTag(label: context.l10n.patientAdvocacy),
                _JourneyTag(label: context.l10n.gerontology),
                _JourneyTag(label: context.l10n.caseManagement),
                _JourneyTag(label: context.l10n.medicationAdmin),
              ],
            ),
            SizedBox(height: 40),
            // Timeline
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: s.experience.length,
              itemBuilder: (context, index) {
                final exp = s.experience[index];
                return _TimelineCard(
                  dateRange: exp.duration, // usually "2018 - PRESENT" etc
                  title: exp.title,
                  company: exp.organization,
                  description: exp.description,
                  isLast: index == s.experience.length - 1,
                );
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.black, // From the image, the button is black
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                context.l10n.downloadDossier,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                context.l10n.referencesAvailable,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _JourneyTag extends StatelessWidget {
  const _JourneyTag({required this.label, this.isActive = false});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF3E8DA) : Colors.white,
        border: Border.all(
          color: isActive ? const Color(0xFFDEBFA3) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: context.colors.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.dateRange,
    required this.title,
    required this.company,
    required this.description,
    this.isLast = false,
  });
  final String dateRange;
  final String title;
  final String company;
  final String description;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: context.colors.onSurface,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1, color: context.theme.dividerColor),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateRange.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF9E7C5D),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      title,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 20,
                        color: context.colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      company,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9E7C5D),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.colors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Staff skills.
class ClientStaffSkillsScreen extends ConsumerWidget {
  const ClientStaffSkillsScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientStaffProfileProvider(staffId));

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text(
              'CURATION OF EXCELLENCE',
              style: GoogleFonts.inter(
                color: const Color(0xFF1A56FF),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Expertise &\nSpecialized Skills',
              style: GoogleFonts.libreCaslonText(
                fontSize: 32,
                color: const Color(0xFF1A56FF),
                height: 1.1,
              ),
            ),
            SizedBox(height: 16),
            Container(width: 40, height: 1, color: context.theme.dividerColor),
            SizedBox(height: 32),
            // Category Scroll
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _CategoryCard(icon: Icons.restaurant, label: 'COOKING'),
                  SizedBox(width: 12),
                  _CategoryCard(
                    icon: Icons.elderly,
                    label: 'ELDERLY CARE',
                    isActive: true,
                  ),
                  SizedBox(width: 12),
                  _CategoryCard(
                    icon: Icons.cleaning_services,
                    label: 'ESTATE CARE',
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Detailed Cards
            const _ExpertiseCard(
              title: 'Culinary & Fine Dining',
              description:
                  'Mastery of gourmet international cuisines, dietary specialization including keto and vegan transitions, and formal table service for high-profile entertaining.',
              level: 'ELITE LEVEL',
              icon: Icons.restaurant,
              tags: ['CORDON BLEU CERTIFIED', 'SOMMELIER BASICS', 'EVENT MGMT'],
            ),
            SizedBox(height: 16),
            const _ExpertiseCard(
              title: 'Emergency Response',
              description:
                  'Advanced trauma response, pediatric CPR, and chronic illness management. Absolute discretion in medical advocacy and health record coordination.',
              level: 'EXPERT',
              icon: Icons.medical_services,
              tags: ['VIEW CERTIFICATIONS'],
              isDark: true,
            ),
            SizedBox(height: 16),
            // Third card layout
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estate Stewardship',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 22,
                      color: const Color(0xFF1A56FF),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Beyond cleaning—this is the preservation of luxury assets. Specialist care for rare textiles, marble surfaces, and museum-grade art collections.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Color(0xFF1A56FF),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Wardrobe management',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1A56FF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: Color(0xFF1A56FF),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Inventory of high-value perishables',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1A56FF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ANTIQUE CARE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF1A56FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'ELITE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF1A56FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        const Divider(color: Color(0xFFE5E7EB)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ORGANIZATION',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF1A56FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'EXPERT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF1A56FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    'Refine Your\nSearch',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 24,
                      color: const Color(0xFF1A56FF),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Looking for a specific certification? Filter our pool of specialists to find the perfect match for your home\'s unique requirements.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF1A56FF).withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'REQUEST SPECIALIST',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1A56FF),
                        side: const BorderSide(
                          color: Color(0xFF1A56FF),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'DOWNLOAD CATALOG',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.label,
    this.isActive = false,
  });
  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? const Color(0xFF1A56FF) : const Color(0xFFE5E7EB),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF1A56FF), size: 24),
          SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF1A56FF),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
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
    this.isDark = false,
  });
  final String title;
  final String description;
  final String level;
  final IconData icon;
  final List<String> tags;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A56FF) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: isDark ? null : Border.all(color: context.theme.dividerColor),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 150,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF0F4FF),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  level,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isDark ? Colors.white : const Color(0xFF1A56FF),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 22,
                  color: isDark ? Colors.white : const Color(0xFF1A56FF),
                ),
              ),
              SizedBox(height: 12),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black54,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.transparent
                          : const Color(0xFFF9FAFB),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: isDark ? Colors.white : const Color(0xFF1A56FF),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Staff attendance view.
class ClientStaffAttendanceScreen extends ConsumerWidget {
  const ClientStaffAttendanceScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientAttendanceHistoryProvider);
    final profile = ref.watch(clientStaffProfileProvider(staffId));

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Color(0xFF000101)),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          'HOMEGENNY',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF000101),
            fontSize: 24,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC5C6CA).withOpacity(0.3)),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCxtVzxlyV3icOcviLju7HptJMxuDFi8wgrt2z913KhU_vhM3UbG2et7RXuJI3IVwIpoQkgAauyGqecm97ffSLLIXxxJHcmrHk9oEpM9hUtwx1GX3fJFYLj4qspXtLFvVSRXnnmf7STG2lsb4ViwAQ8Z87ct8pldMuXeGP3apmGtEX0wfEfhf8_JLKNfox7_nA8dCAn-nAemGtAcgntbwP_t7dPvCpQTUCWyy73GMyTUqsMa8tgeiNi',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          padding: const EdgeInsets.only(top: 24, bottom: 100),
          children: [
            // Efficiency Visualization
            Center(
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE2E2E5).withOpacity(0.4),
                      const Color(0xFFFBF9F8).withOpacity(0),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: (s.attendancePercent ?? 0) / 100,
                          strokeWidth: 2,
                          backgroundColor: const Color(0xFFE9E8E7),
                          color: const Color(0xFF000101),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'EFFICIENCY',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF735A3A).withOpacity(0.7),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.96,
                            ),
                          ),
                          Text(
                            s.attendancePercent != null ? '${s.attendancePercent!.round()}%' : '—',
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 40,
                              color: const Color(0xFF000101),
                              letterSpacing: -0.8,
                            ),
                          ),
                          Text(
                            'PRESENT',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: const Color(0xFF735A3A),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.96,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Summary Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor.withOpacity(0.4),
                        border: Border.all(color: const Color(0xFFC5C6CA).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -24,
                            top: -24,
                            bottom: -24,
                            child: Container(
                              width: 4,
                              color: const Color(0xFF000101),
                            ),
                          ),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'ON TIME',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF735A3A),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.96,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '21 DAYS',
                                  style: GoogleFonts.libreCaslonText(
                                    fontSize: 22,
                                    color: const Color(0xFF000101),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor.withOpacity(0.4),
                        border: Border.all(color: const Color(0xFFC5C6CA).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -24,
                            top: -24,
                            bottom: -24,
                            child: Container(
                              width: 4,
                              color: const Color(0xFF735A3A),
                            ),
                          ),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'DELAYED',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: const Color(0xFF735A3A),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.96,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '02 DAYS',
                                  style: GoogleFonts.libreCaslonText(
                                    fontSize: 22,
                                    color: const Color(0xFF735A3A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Record Listing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Recent Logs',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 22,
                          color: const Color(0xFF000101),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: const Color(0xFF735A3A).withOpacity(0.3))),
                        ),
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'VIEW ALL',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: const Color(0xFF735A3A),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.96,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // History List
                  history.when(
                    loading: () => const DsLoadingWidget(),
                    error: (_, __) => const DsErrorState(title: 'Error'),
                    data: (list) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = list[index];
                          final isLate = r.status == 'Late';

                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.theme.cardColor.withOpacity(0.4),
                              border: Border.all(color: const Color(0xFFC5C6CA).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.date,
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        color: const Color(0xFF000101),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'LOGGED',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        color: const Color(0xFF735A3A),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.96,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          r.checkIn ?? '--',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            color: isLate ? const Color(0xFF735A3A) : const Color(0xFF000101),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '/',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(0xFFC5C6CA),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          r.checkOut ?? '--',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            color: isLate ? const Color(0xFF735A3A) : const Color(0xFF000101),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.7,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'IN / OUT',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        color: const Color(0xFF735A3A),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLate ? Colors.transparent : const Color(0xFF000101),
                                    border: isLate ? Border.all(color: const Color(0xFF735A3A)) : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    isLate ? 'DELAYED' : 'ON TIME',
                                    style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      color: isLate ? const Color(0xFF735A3A) : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 48),

            // CTA Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1C1B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.report_problem_outlined,
                    color: Color(0xFFFFDDB6),
                    size: 36,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Notice a discrepancy?',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 22,
                      color: const Color(0xFFE3E2E0),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'If your attendance records don\'t align with your logs, please raise an issue for audit.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: const Color(0xFF838486),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.push(ClientRoutes.attendanceRaiseIssue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDDB6),
                      foregroundColor: const Color(0xFF291801),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'RAISE ISSUE',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        centerTitle: true,
        title: Text(
          'HOMEGENNY',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150',
              ),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            Center(
              child: Text(
                'INTERNAL REPORT',
                style: GoogleFonts.inter(
                  color: const Color(0xFF9E7C5D),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Service\nExcellence',
                textAlign: TextAlign.center,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 36,
                  color: context.colors.onSurface,
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Quantifying performance across all luxury\ntouchpoints.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 48),
            // Circular Gauge
            Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: s.performanceScore != null ? s.performanceScore! / 5 : 0,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade200,
                            color: context.colors.onSurface,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.performanceScore != null ? s.performanceScore!.toStringAsFixed(1) : '—',
                                style: GoogleFonts.libreCaslonText(
                                  fontSize: 64,
                                  color: context.colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'SCORE / 5',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: const Color(0xFF9E7C5D),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: context.theme.cardColor,
                            size: 14,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ELITE PARTNER',
                            style: GoogleFonts.inter(
                              color: context.theme.cardColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 56),
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Color(0xFF9E7C5D),
                          size: 20,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '98%',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 24,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PUNCTUALITY',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: context.theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.speed,
                          color: Color(0xFF9E7C5D),
                          size: 20,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '2h',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 24,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'RESPONSE\nTIME',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: context.colors.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            // Recent Reviews
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Reviews',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 22,
                    color: context.colors.onSurface,
                  ),
                ),
                Text(
                  'VIEW ALL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF9E7C5D),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            if (s.reviews.isEmpty)
              Text(
                'No reviews yet.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ...s.reviews.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFF9E7C5D),
                              size: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            r.date.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: context.colors.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        '"${r.comment}"',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: context.colors.onSurface,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '— ${r.reviewerName.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF9E7C5D),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
