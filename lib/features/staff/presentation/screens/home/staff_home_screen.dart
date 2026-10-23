import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../providers/staff_providers.dart';
import '../../../../../core/onboarding/onboarding_models.dart';
import '../../../../../core/onboarding/onboarding_providers.dart';
import '../../../../../core/onboarding/profile_gate.dart';
import '../../../../../core/series/series_catalog.dart';
import '../../../../care/presentation/care_providers.dart';
import '../care/staff_care_screens.dart';
import '../care/staff_client_updates_screen.dart';
import '../care/staff_cook_screens.dart';
import '../care/staff_instruction_screens.dart';

String _pretty(String s) => s
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// Staff home dashboard tab. Everything shown comes from the API — the
/// staff record's own name (`GET /staff/dashboard`, not the login account's
/// name), today's houses and attendance, tasks, training and the RM.
class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(staffDashboardProvider);
    final user = ref.watch(authProvider).user;
    final fallbackName = displayNameOr(user?.name, user?.phone);

    return Scaffold(
      body: AsyncValueWidget(
        value: dashboard,
        onRetry: () => ref.invalidate(staffDashboardProvider),
        loadingMessage: context.l10n.loading,
        builder: (data) {
          final name = data.fullName.trim().isNotEmpty ? data.fullName.trim() : fallbackName;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: DsRefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(staffDashboardProvider);
                  ref.invalidate(staffPlacementsTodayProvider);
                  ref.invalidate(staffTodayAttendanceProvider);
                  ref.invalidate(staffAttendanceHistoryProvider);
                  ref.invalidate(staffTrainingHomeProvider);
                  ref.invalidate(staffNotificationsProvider);
                  ref.invalidate(staffCareTodayProvider);
                  ref.invalidate(cookTodayProvider);
                  ref.invalidate(staffInstructionsProvider);
                  ref.invalidate(clientUpdatesUnreadProvider);
                },
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _WelcomeHeader(name: name, data: data),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _OnboardingCard(),
                          const _TodayShiftCard(),
                          const SizedBox(height: 14),
                          _StatsRow(completionPct: data.completionPct),
                          const SizedBox(height: 16),
                          const StaffClientUpdatesHomeCard(),
                          const StaffCareHomeCard(),
                          const StaffCookHomeCard(),
                          const StaffInstructionsHomeCard(),
                          if (data.todayTasks.isNotEmpty) _TasksCard(tasks: data.todayTasks),
                          const _TrainingCard(),
                          if (data.assignedRmName.trim().isEmpty)
                            const _NoRmCard()
                          else
                            _RmCard(name: data.assignedRmName, phone: data.assignedRmPhone),
                          const DsSection('Quick actions'),
                          const _QuickActionsGrid(),
                          const SizedBox(height: 100),
                        ]
                            .animate(interval: 60.ms)
                            .fadeIn(duration: 360.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeHeader extends ConsumerWidget {
  const _WelcomeHeader({required this.name, required this.data});

  final String name;
  final StaffDashboardData data;

  void _showNewRequestSheet(BuildContext context) {
    final rmPhone = data.assignedRmPhone.trim();
    DsBottomSheet.show<void>(
      context: context,
      title: 'New request',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rmPhone.isNotEmpty)
            DsListCard(
              icon: Icons.event_busy_rounded,
              title: 'Leave or shift change',
              subtitle: 'Call your RM, ${data.assignedRmName}',
              onTap: () {
                Navigator.pop(context);
                CommunicationHelper.makePhoneCall(context, rmPhone, recipientName: data.assignedRmName);
              },
            ),
          DsListCard(
            icon: Icons.payments_rounded,
            title: 'Salary advance or query',
            subtitle: 'See your salary and payslips',
            onTap: () {
              Navigator.pop(context);
              context.push(StaffRoutes.salary);
            },
          ),
          DsListCard(
            icon: Icons.support_agent_rounded,
            title: 'Help & support',
            subtitle: 'Raise a question with HomeGenny',
            onTap: () {
              Navigator.pop(context);
              context.push(StaffRoutes.help);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = name.split(RegExp(r'\s+')).first;
    final unread = ref.watch(staffNotificationsProvider).valueOrNull?.where((n) => !n.isRead).length ?? 0;
    final subtitle = [
      if (data.series.isNotEmpty) SeriesDisplay.label(data.series),
      if (data.staffCode.isNotEmpty) data.staffCode,
    ].join(' · ');

    return DsHeroHeader(
      leading: DsRingAvatar(name: name, onTap: () => context.go(StaffRoutes.profile)),
      actions: [
        DsHeroIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badgeCount: unread,
          onPressed: () => context.push(StaffRoutes.notifications),
        ),
      ],
      eyebrow: dsGreeting(),
      eyebrowIcon: Icons.wb_sunny_rounded,
      // A new sign-up has no name until the profile wizard is done — the
      // fallback is their phone or "Welcome".
      title: name == 'Welcome' || RegExp(r'^[0-9+ ]+$').hasMatch(name)
          ? 'Welcome to\nHomeGenny'
          : 'Welcome back,\n$firstName',
      subtitle: subtitle.isEmpty ? null : subtitle,
      floatingIcons: const [
        Icons.cleaning_services_rounded,
        Icons.fingerprint_rounded,
        Icons.workspace_premium_rounded,
      ],
      bottom: DsHeroPillButton(
        label: 'New Request',
        icon: Icons.add_rounded,
        onPressed: () => _showNewRequestSheet(context),
      ),
    );
  }
}

/// Today's house and attendance, with the one action that matters now.
class _TodayShiftCard extends ConsumerWidget {
  const _TodayShiftCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementsAsync = ref.watch(staffPlacementsTodayProvider);
    final today = ref.watch(staffTodayAttendanceProvider).valueOrNull;
    final placements = placementsAsync.valueOrNull;
    final title = GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary);
    final small = GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary);

    if (placementsAsync.isLoading && placements == null) {
      return Container(
        height: 120,
        decoration: dsCardDecoration(radius: 20),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    // No house to work at yet — show where onboarding stands instead.
    if (placements == null || placements.placements.isEmpty) {
      return DsListCard(
        icon: Icons.home_work_rounded,
        iconColor: AppColors.warning,
        title: 'No active placement yet',
        subtitle: 'Your RM will place you once onboarding is complete',
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.go(StaffRoutes.pipeline),
      );
    }

    StaffPlacementOption house = placements.placements.first;
    for (final p in placements.placements) {
      if (p.placementId == placements.checkedInAt) house = p;
    }
    final onDuty = placements.isCheckedIn;
    final checkedOut = !onDuty && today?.checkOut != null;
    final (status, color) = onDuty
        ? ('On duty', AppColors.success)
        : checkedOut
            ? ('Shift done', AppColors.secondary)
            : ('Not checked in', AppColors.warning);
    final timeLine = onDuty && today?.checkIn != null
        ? 'Checked in at ${DateFormatter.time(today!.checkIn)}'
        : checkedOut
            ? 'Checked out at ${DateFormatter.time(today!.checkOut)}'
            : placements.placements.length > 1
                ? '${placements.placements.length} houses today'
                : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("TODAY'S SHIFT", style: small.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const Spacer(),
              DsPill(status, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsIconTile(Icons.home_rounded, color: color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(house.clientName, style: title),
                    if (house.address != null && house.address!.trim().isNotEmpty)
                      Text(house.address!.trim(), style: small, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (timeLine != null) ...[
                      const SizedBox(height: 4),
                      Text(timeLine, style: small.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (checkedOut)
            // Checking in again at the same house reopens the day.
            DsOutlineButton(
              label: 'Check in again',
              onPressed: () => context.push(StaffRoutes.checkIn),
            )
          else
            DsGradientButton(
              label: onDuty ? 'Check out' : 'Check in',
              icon: onDuty ? Icons.logout_rounded : Icons.fingerprint_rounded,
              onPressed: () => context.push(onDuty ? StaffRoutes.checkOut : StaffRoutes.checkIn),
            ),
        ],
      ),
    );
  }
}

/// Attendance (from history) and profile completion side by side.
class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.completionPct});
  final int completionPct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(staffAttendanceHistoryProvider).valueOrNull ?? const <AttendanceRecord>[];
    final worked = records.where((r) => r.status != 'absent').length;
    final attendancePct = records.isEmpty ? null : (worked * 100 / records.length).round();

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'ATTENDANCE',
            percent: attendancePct,
            caption: records.isEmpty ? 'No days yet' : '$worked/${records.length} days',
            onTap: () => context.go(StaffRoutes.attendance),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: 'PROFILE',
            percent: completionPct,
            caption: completionPct >= 100 ? 'Complete' : 'Finish setup',
            onTap: () => context.push(StaffRoutes.profileCompletion),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.percent, required this.caption, required this.onTap});

  final String label;
  final int? percent;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = (percent ?? 0).clamp(0, 100) / 100;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: dsCardDecoration(radius: 20),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value),
                  duration: 900.ms,
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          backgroundColor: AppColors.lightSurfaceVariant,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        percent == null ? '—' : '$percent%',
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
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

/// Pipeline task the server sends a new sign-up — opens the profile wizard.
const _profileTaskId = 'profile';

class _TasksCard extends ConsumerWidget {
  const _TasksCard({required this.tasks});
  final List<StaffTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = tasks.where((t) => !t.done).length;
    final next = tasks.firstWhere((t) => !t.done, orElse: () => tasks.first);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsListCard(
        icon: Icons.checklist_rounded,
        title: open == 0 ? 'All tasks done' : '$open ${open == 1 ? 'task' : 'tasks'} to do',
        subtitle: next.title,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => !next.done && next.id == _profileTaskId
            ? openProfileWizard(context, ref)
            : context.push(StaffRoutes.tasksToday),
      ),
    );
  }
}

/// §4 — what `GET /me/onboarding` says comes next, above everything else.
class _OnboardingCard extends ConsumerWidget {
  const _OnboardingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(onboardingProvider).valueOrNull;
    final Widget card;
    switch (status?.nextStep) {
      case OnboardingNextStep.completeProfile:
        card = const ProfileIncompleteCard(compact: true);
      case OnboardingNextStep.waitForRm:
        card = const DsNote(
          tone: DsNoteTone.success,
          title: 'Profile submitted',
          text: 'Profile submitted. We\'ll assign your RM soon.',
        );
      case OnboardingNextStep.verification:
        final rm = status!.rm;
        card = DsNote(
          title: 'Next: document verification',
          text: rm == null
              ? 'Your RM will call you to verify your documents.'
              : 'Your RM ${rm.name}${rm.phone.isEmpty ? '' : ' (${rm.phone})'} will call you to verify your documents.',
        );
      case OnboardingNextStep.ready:
      case null:
        return const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: card);
  }
}

/// `assignedRm` is null until an RM is assigned — say so, never invent one.
class _NoRmCard extends StatelessWidget {
  const _NoRmCard();

  @override
  Widget build(BuildContext context) {
    return const DsListCard(
      icon: Icons.support_agent_rounded,
      title: 'Relationship manager',
      subtitle: 'RM not assigned yet',
    );
  }
}

/// Current training batch and video certification progress (`/training/mine`).
class _TrainingCard extends ConsumerWidget {
  const _TrainingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final training = ref.watch(staffTrainingHomeProvider).valueOrNull;
    if (training == null) return const SizedBox.shrink();
    final batch = training.batches.isEmpty ? null : training.batches.first;
    final cert = training.videoCert;
    if (batch == null && cert.required_ == 0) return const SizedBox.shrink();

    final parts = [
      if (batch != null) '${batch.batchCode} · ${_pretty(batch.status)}',
      if (cert.required_ > 0) 'Video certification ${cert.approved}/${cert.required_}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DsListCard(
        icon: Icons.school_rounded,
        title: 'Training',
        subtitle: parts.join('\n'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(StaffRoutes.training),
      ),
    );
  }
}

/// The staff member's Relationship Manager, with call and chat.
class _RmCard extends StatelessWidget {
  const _RmCard({required this.name, required this.phone});

  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Row(
        children: [
          DsInitialsAvatar(name: name, size: 44, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR RM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          _RoundAction(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => context.push(
              Uri(
                path: AppRoutes.chat,
                queryParameters: {'recipientName': name, 'recipientRole': 'Relationship Manager'},
              ).toString(),
            ),
          ),
          if (phone.trim().isNotEmpty) ...[
            const SizedBox(width: 8),
            _RoundAction(
              icon: Icons.call_rounded,
              onTap: () => CommunicationHelper.makePhoneCall(context, phone, recipientName: name),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = [
    (Icons.fingerprint_rounded, 'Attendance', StaffRoutes.attendance),
    (Icons.payments_rounded, 'Salary', StaffRoutes.salary),
    (Icons.folder_rounded, 'Documents', StaffRoutes.documents),
    (Icons.location_on_rounded, 'Deployment', StaffRoutes.deployment),
    (Icons.school_rounded, 'Training', StaffRoutes.training),
    (Icons.support_agent_rounded, 'Help', StaffRoutes.help),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, label, route) in _actions)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => route == StaffRoutes.attendance ? context.go(route) : context.push(route),
              child: Ink(
                decoration: dsCardDecoration(radius: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DsIconTile(icon, size: 42),
                    const SizedBox(height: 8),
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
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final StaffTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = _tile();
    if (task.done || task.id != _profileTaskId) return tile;
    return GestureDetector(onTap: () => openProfileWizard(context, ref), child: tile);
  }

  Widget _tile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20, color: task.done ? const Color(0xFFF0FDF4) : Colors.white),
      child: Row(
        children: [
          AnimatedContainer(
            duration: 250.ms,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: task.done ? AppColors.success : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: task.done ? AppColors.success : AppColors.lightBorder, width: 2),
            ),
            child: task.done ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: task.done ? AppColors.lightTextSecondary : AppColors.lightTextPrimary,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (task.done) const DsPill('Done', color: AppColors.success),
        ],
      ),
    );
  }
}

/// Today's tasks screen.
class StaffTodaysTasksScreen extends ConsumerWidget {
  const StaffTodaysTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(staffTasksProvider);

    return DsPage(
      title: 'Today\'s tasks',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffTasksProvider),
      body: dsAsyncBody(
        tasks,
        onRetry: () => ref.invalidate(staffTasksProvider),
        builder: (list) {
          final done = list.where((t) => t.done).length;
          return [
            DsGradientCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: list.isEmpty ? 1 : done / list.length),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: AppColors.sunYellow,
                            ),
                          ),
                          Text(
                            '$done/${list.length}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      list.isEmpty || done == list.length ? 'All caught up for today!' : '${list.length - done} tasks left today',
                      style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const DsEmptyBlock(
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
                title: 'No tasks',
                message: 'You are all caught up!',
              )
            else
              for (final t in list) _TaskTile(task: t),
          ];
        },
      ),
    );
  }
}

/// Profile completion screen.
class StaffProfileCompletionScreen extends ConsumerWidget {
  const StaffProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(staffProfileProvider);
    final completionPct = ref.watch(staffDashboardProvider).valueOrNull?.completionPct ?? 0;
    final documents = ref.watch(staffDocumentsProvider).valueOrNull ?? const <StaffDocument>[];
    final pendingDocuments = documents.where((d) => d.status == DocumentApprovalStatus.pending).length;
    final rejectedDocuments = documents.where((d) => d.status == DocumentApprovalStatus.rejected).length;
    final agreement = ref.watch(staffAgreementProvider).valueOrNull;
    final videoCert = ref.watch(staffTrainingHomeProvider).valueOrNull?.videoCert;

    final steps = <_CompletionStep>[
      _CompletionStep(
        icon: Icons.person_rounded,
        title: 'Personal details',
        subtitle: 'Your basic profile',
        status: ('Done', AppColors.success),
        onTap: () => context.canPop() ? context.pop() : context.go(StaffRoutes.profile),
      ),
      _CompletionStep(
        icon: Icons.folder_rounded,
        title: 'Documents',
        subtitle: 'ID verification',
        status: rejectedDocuments > 0
            ? ('$rejectedDocuments to fix', AppColors.error)
            : pendingDocuments > 0
                ? ('$pendingDocuments pending', AppColors.warning)
                : documents.isEmpty
                    ? ('Not started', AppColors.lightTextSecondary)
                    : ('All clear', AppColors.success),
        onTap: () => context.push(StaffRoutes.documents),
      ),
      _CompletionStep(
        icon: Icons.school_rounded,
        title: 'Training',
        subtitle: 'Safety & procedures',
        status: ('Open', AppColors.primary),
        onTap: () => context.push(StaffRoutes.training),
      ),
      _CompletionStep(
        icon: Icons.videocam_rounded,
        title: 'Video certification',
        subtitle: 'Record your introduction',
        status: videoCert == null
            ? ('Open', AppColors.primary)
            : videoCert.approved >= videoCert.required_
                ? ('Done', AppColors.success)
                : ('${videoCert.approved}/${videoCert.required_}', AppColors.warning),
        progress: videoCert == null || videoCert.required_ == 0 ? null : videoCert.approved / videoCert.required_,
        onTap: () => context.push(StaffRoutes.videoCertification),
      ),
      _CompletionStep(
        icon: Icons.draw_rounded,
        title: 'Agreement',
        subtitle: 'Terms and conditions',
        status: switch (agreement?.status) {
          AgreementStatus.signed => ('Signed', AppColors.success),
          AgreementStatus.expired => ('Expired', AppColors.error),
          AgreementStatus.pending => ('Sign now', AppColors.warning),
          null => ('Pending', AppColors.lightTextSecondary),
        },
        onTap: () => context.push(StaffRoutes.agreement),
      ),
    ];

    return DsPage(
      title: 'Profile completion',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async {
        ref.invalidate(staffProfileProvider);
        ref.invalidate(staffDashboardProvider);
        ref.invalidate(staffDocumentsProvider);
        ref.invalidate(staffAgreementProvider);
      },
      actions: [
        DsPageAction(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          onPressed: () => context.push(StaffRoutes.settings),
        ),
      ],
      bottom: DsGradientButton(
        label: 'Continue setup',
        icon: Icons.arrow_forward_rounded,
        onPressed: () => context.push(StaffRoutes.documents),
      ),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(staffProfileProvider),
        builder: (p) => [
          DsGradientCard(
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: completionPct / 100),
                    duration: 1100.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            color: AppColors.sunYellow,
                          ),
                        ),
                        Text(
                          '${(v * 100).round()}%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DsGlassPill('OVERALL PROGRESS', icon: Icons.trending_up_rounded),
                      const SizedBox(height: 10),
                      Text(
                        completionPct >= 100 ? 'Profile complete!' : 'You\'re almost there',
                        style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Finish the steps below to unlock full access.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const DsSection('Required steps'),
          for (var i = 0; i < steps.length; i++)
            _CompletionTile(step: steps[i])
                .animate(delay: (60 * i).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),
        ],
      ),
    );
  }
}

class _CompletionStep {
  const _CompletionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final (String, Color) status;
  final VoidCallback onTap;
  final double? progress;
}

class _CompletionTile extends StatelessWidget {
  const _CompletionTile({required this.step});
  final _CompletionStep step;

  @override
  Widget build(BuildContext context) {
    final (label, color) = step.status;
    final done = color == AppColors.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: step.onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DsIconTile(step.icon, size: 46),
                        if (done)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            step.subtitle,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DsPill(label, color: color),
                  ],
                ),
                if (step.progress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: step.progress!.clamp(0, 1).toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.lightSurfaceVariant,
                      color: color,
                    ),
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
