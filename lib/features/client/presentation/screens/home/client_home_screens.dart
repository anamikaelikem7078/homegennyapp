import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/core/theme/app_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/models/client_models.dart';
import '../../../domain/models/staff_request_models.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';
import '../../../../../core/series/series_catalog.dart';

/// Client home / dashboard tab.
///
/// Top to bottom: a compact header with today's numbers, anything waiting
/// on the family, their staff (one card each, with that staff member's
/// actions), quick actions, this month's attendance, and the cover note.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(clientDashboardProvider);
    final assignedStaff = ref.watch(clientAssignedStaffProvider);

    Future<void> refresh() async {
      ref
        ..invalidate(clientDashboardProvider)
        ..invalidate(clientAssignedStaffProvider)
        ..invalidate(clientAttendanceHistoryProvider)
        ..invalidate(clientStaffRequestsProvider)
        ..invalidate(clientNotificationsProvider);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: AsyncValueWidget(
        value: dashboard,
        onRetry: () => ref.invalidate(clientDashboardProvider),
        loadingMessage: context.l10n.loading,
        builder: (data) {
          final staff = assignedStaff.valueOrNull ?? const <ClientAssignedStaff>[];
          return DsRefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _HomeHeader(data: data, staffCount: staff.length),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AttentionSection(data: data),
                      _SectionTitle(
                        'Your staff',
                        count: staff.isEmpty ? null : staff.length,
                        action: staff.isEmpty ? null : ('See all', () => context.go(ClientRoutes.staff)),
                      ),
                      assignedStaff.when(
                        loading: () => const Padding(padding: EdgeInsets.all(24), child: DsLoadingWidget()),
                        error: (_, _) => const _NoStaffCard(),
                        data: (list) => list.isEmpty
                            ? const _NoStaffCard()
                            : Column(children: [for (final s in list) _StaffRowCard(staff: s)]),
                      ),
                      _SectionTitle('Quick actions'),
                      _QuickActionsGrid(hasCook: staff.any((s) => s.hasMenu)),
                      _SectionTitle(
                        'This month',
                        action: ('Details', () => context.push(ClientRoutes.attendanceSummary)),
                      ),
                      const _MonthAttendanceCard(),
                      const SizedBox(height: 16),
                      const _CareShieldBanner(),
                      const SizedBox(height: 110), // room for the floating nav bar
                    ].animate(interval: 60.ms).fadeIn(duration: 360.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);

BoxDecoration _whiteCard({double radius = 20}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xFFE8EBF2)),
  boxShadow: [BoxShadow(color: const Color(0xFF0B1B4D).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.count, this.action});
  final String title;
  final int? count;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Text(title, style: AppFonts.display(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
        if (count != null) ...[const SizedBox(width: 8), DsPill('$count')],
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: action!.$2,
            child: Text(
              action!.$1,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.data, required this.staffCount});
  final ClientDashboardData data;
  final int staffCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final unread = (ref.watch(clientNotificationsProvider).valueOrNull ?? const []).where((n) => !n.isRead).length;
    final (todayValue, todayIcon) = switch (data.todayAttendanceStatus) {
      'CHECKED_IN' => ('On duty', Icons.how_to_reg_rounded),
      'CHECKED_OUT' => ('Shift done', Icons.task_alt_rounded),
      'NOT_CHECKED_IN' => ('Not in yet', Icons.schedule_rounded),
      _ => ('—', Icons.schedule_rounded),
    };

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, top + 14, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      DsRingAvatar(name: data.clientName, onTap: () => context.go(ClientRoutes.profile)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dsGreeting(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              data.clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.display(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      DsHeroIconButton(
                        icon: Icons.notifications_none_rounded,
                        tooltip: 'Notifications',
                        badgeCount: unread,
                        onPressed: () => context.push(ClientRoutes.notifications),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.groups_rounded,
                          value: '$staffCount',
                          label: staffCount == 1 ? 'Staff at home' : 'Staff at home',
                          onTap: () => context.go(ClientRoutes.staff),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeaderStat(
                          icon: todayIcon,
                          value: todayValue,
                          label: 'Today',
                          onTap: () => context.push(ClientRoutes.attendanceToday),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.account_balance_wallet_rounded,
                          value: CurrencyFormatter.inr(data.totalUnpaidAmount),
                          label: data.pendingInvoicesCount == 0 ? 'All paid' : 'Due',
                          onTap: () => context.go(ClientRoutes.payments),
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
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.icon, required this.value, required this.label, required this.onTap});
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.sunYellow),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Needs your attention
// ---------------------------------------------------------------------------

/// Only what is waiting on the family: bills to pay and staff requests.
/// With nothing waiting, a single "Request staff" prompt instead.
class _AttentionSection extends ConsumerWidget {
  const _AttentionSection({required this.data});
  final ClientDashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = (ref.watch(clientStaffRequestsProvider).valueOrNull ?? const <StaffRequest>[]).where((r) => r.isOpen).toList();
    final toChoose = open.where((r) => r.canChoose).fold<int>(0, (sum, r) => sum + r.shortlistedCount);

    final items = <Widget>[
      if (data.pendingInvoicesCount > 0)
        _AttentionTile(
          color: AppColors.error,
          icon: Icons.receipt_long_rounded,
          title: '${CurrencyFormatter.inr(data.totalUnpaidAmount)} to pay',
          subtitle: data.pendingInvoicesCount == 1 ? '1 invoice pending' : '${data.pendingInvoicesCount} invoices pending',
          cta: 'Pay now',
          onTap: () => context.push(ClientRoutes.pendingPayment),
        ),
      if (toChoose > 0)
        _AttentionTile(
          color: AppColors.warning,
          icon: Icons.how_to_reg_rounded,
          title: 'Choose your staff',
          subtitle: toChoose == 1 ? '1 staff member shortlisted for you' : '$toChoose staff shortlisted for you',
          cta: 'Choose',
          onTap: () => context.push(ClientRoutes.staffRequests),
        )
      else if (open.isNotEmpty)
        _AttentionTile(
          color: AppColors.primary,
          icon: Icons.person_search_rounded,
          title: open.length == 1 ? '1 open staff request' : '${open.length} open staff requests',
          subtitle: StaffRequestStatus.message(open.first.status),
          cta: 'View',
          onTap: () => context.push(ClientRoutes.staffRequests),
        ),
    ];

    if (items.isEmpty) {
      return _RequestStaffPrompt(onTap: () => context.push(ClientRoutes.staffRequestNew));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('Needs your attention', style: AppFonts.display(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        for (final w in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: w),
      ],
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      DsIconTile(icon, size: 40, color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                            Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          cta,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
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

class _RequestStaffPrompt extends StatelessWidget {
  const _RequestStaffPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _whiteCard(),
        child: Row(
          children: [
            const DsIconTile(Icons.person_add_alt_1_rounded, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need more help at home?', style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
                  Text('Request a caretaker, nurse or cook', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _muted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Your staff
// ---------------------------------------------------------------------------

/// One staff member: who they are on the left, their status, and a row of
/// what the family can do for them.
class _StaffRowCard extends StatelessWidget {
  const _StaffRowCard({required this.staff});
  final ClientAssignedStaff staff;

  @override
  Widget build(BuildContext context) {
    final s = staff;
    final name = s.fullName ?? 'Staff';
    final seriesLabel = SeriesDisplay.label(s.series);
    final accent = SeriesDisplay.color(s.series);
    final deployed = s.status == 'ACTIVE_DEPLOYED';
    final pid = s.placementId;
    final initials = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    final actions = <(IconData, String, VoidCallback)>[
      if (pid != null && s.hasCarePlan)
        (Icons.health_and_safety_rounded, 'Daily care', () => context.push(ClientRoutes.careHome(pid), extra: name)),
      if (pid != null && s.hasMenu) (Icons.restaurant_menu_rounded, 'Menu', () => context.push(ClientRoutes.menu(pid), extra: name)),
      if (pid != null && s.hasInstructions)
        (Icons.record_voice_over_rounded, 'Instruct', () => context.push(ClientRoutes.instructions(pid), extra: name)),
      (
        Icons.chat_bubble_outline_rounded,
        'Chat',
        () => context.push(
          '${AppRoutes.chat}?recipientName=${Uri.encodeComponent(name)}&recipientRole=${Uri.encodeComponent(seriesLabel)}',
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _whiteCard(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            onTap: () => context.push(ClientRoutes.staffProfile(s.staffId)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Row(
                children: [
                  // Series-coloured ring, status dot on the edge.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent, width: 2.5)),
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.12)),
                          alignment: Alignment.center,
                          child: Text(
                            initials.isEmpty ? '?' : initials,
                            style: AppFonts.display(color: accent, fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: deployed ? AppColors.success : AppColors.warning,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
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
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: _ink),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(SeriesDisplay.icon(s.series), size: 12, color: accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    seriesLabel,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                deployed ? 'Since ${_formatDate(s.deploymentDate)}' : 'On trial',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: deployed ? _muted : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEFF1F6)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                for (final (icon, label, onTap) in actions)
                  Expanded(child: _StaffAction(icon: icon, label: label, color: accent, onTap: onTap)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAction extends StatelessWidget {
  const _StaffAction({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink),
          ),
        ],
      ),
    ),
  );
}

class _NoStaffCard extends StatelessWidget {
  const _NoStaffCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: _whiteCard(),
    child: Column(
      children: [
        const DsIconTile(Icons.people_alt_rounded, size: 52),
        const SizedBox(height: 10),
        Text('No staff at home yet', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 4),
        Text(
          'Once your staff is placed, their daily care, instructions and chat appear here.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _muted),
        ),
        const SizedBox(height: 12),
        DsGradientButton(
          label: 'Request staff',
          icon: Icons.person_add_alt_1_rounded,
          isExpanded: false,
          onPressed: () => context.push(ClientRoutes.staffRequestNew),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.hasCook});
  final bool hasCook;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.person_add_alt_1_rounded, 'Request staff', AppColors.primary, () => context.push(ClientRoutes.staffRequestNew)),
      (Icons.event_note_rounded, 'Attendance', const Color(0xFF0D9488), () => context.push(ClientRoutes.attendanceHistory)),
      (Icons.receipt_long_rounded, 'Invoices', const Color(0xFF7C3AED), () => context.go(ClientRoutes.payments)),
      (Icons.history_rounded, 'Payments', const Color(0xFF2563EB), () => context.push(ClientRoutes.paymentHistory)),
      (Icons.swap_horiz_rounded, 'Replace', const Color(0xFFEA580C), () => context.push(ClientRoutes.replacementRequest)),
      (Icons.report_problem_rounded, 'Complaint', AppColors.error, () => context.push(ClientRoutes.complaintRaise)),
      if (hasCook) (Icons.tune_rounded, 'Food profile', const Color(0xFFD97706), () => context.push(ClientRoutes.foodProfile)),
      (Icons.assignment_ind_rounded, 'My requests', const Color(0xFF0891B2), () => context.push(ClientRoutes.staffRequests)),
      if (!hasCook)
        (Icons.notifications_rounded, 'Alerts', const Color(0xFF475569), () => context.push(ClientRoutes.notifications)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
      decoration: _whiteCard(radius: 22),
      child: Wrap(
        children: [
          for (final (icon, label, color, onTap) in items)
            FractionallySizedBox(
              widthFactor: 0.25,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 2),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                        child: Icon(icon, color: color, size: 23),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink),
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

// ---------------------------------------------------------------------------
// This month
// ---------------------------------------------------------------------------

class _MonthAttendanceCard extends ConsumerWidget {
  const _MonthAttendanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(clientAttendanceHistoryProvider).valueOrNull ?? const <ClientAttendanceRecord>[];
    final present = list.where((r) => r.status == 'PRESENT').length;
    final total = list.length;
    final pct = total == 0 ? 0.0 : present / total;
    final absent = total - present;

    return GestureDetector(
      onTap: () => context.push(ClientRoutes.attendanceSummary),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _whiteCard(radius: 22),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: 900.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: const Color(0xFFEEF2FF),
                      color: pct >= 0.9 ? AppColors.success : (pct >= 0.7 ? AppColors.warning : AppColors.primary),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(pct * 100).round()}%',
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: _ink)),
                  const SizedBox(height: 2),
                  Text(
                    total == 0 ? 'No days recorded yet' : '$present of $total days present',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: _muted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniStat(color: AppColors.success, label: 'Present', value: present),
                      const SizedBox(width: 14),
                      _MiniStat(color: AppColors.error, label: 'Absent', value: absent),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('$value $label', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
    ],
  );
}

// ---------------------------------------------------------------------------
// Cover
// ---------------------------------------------------------------------------

class _CareShieldBanner extends StatelessWidget {
  const _CareShieldBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(colors: [Color(0xFFEEF3FF), Color(0xFFF7F9FF)]),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.premiumInsuranceActive, style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 2),
              Text(
                context.l10n.insuranceCoverDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatDate(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

void _homeBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

/// Attendance summary from dashboard.
class ClientAttendanceSummaryScreen extends ConsumerWidget {
  const ClientAttendanceSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientAttendanceHistoryProvider);
    final today = ref.watch(clientTodayAttendanceProvider).valueOrNull;
    final l10n = context.l10n;

    return DsPage(
      title: l10n.attendanceSummary,
      subtitle: l10n.thisMonth,
      onBack: () => _homeBack(context),
      onRefresh: () async {
        ref.invalidate(clientAttendanceHistoryProvider);
        ref.invalidate(clientTodayAttendanceProvider);
      },
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(clientAttendanceHistoryProvider),
        builder: (records) {
          final present = records.where((r) => r.status == 'PRESENT').length;
          final total = records.length;
          final percent = total == 0 ? 0.0 : present / total * 100;
          final summary = ClientAttendanceSummary(presentDays: present, totalDays: total, attendancePercent: percent);
          return [
            DsGradientCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: summary.attendancePercent / 100),
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
                              backgroundColor: Colors.white.withValues(alpha: 0.18),
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
                        DsGlassPill(l10n.thisMonth.toUpperCase(), icon: Icons.calendar_month_rounded),
                        const SizedBox(height: 10),
                        Text(
                          l10n.daysPresentDesc(summary.presentDays.toString(), summary.totalDays.toString()),
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.35, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (today != null)
              DsListCard(
                icon: Icons.today_rounded,
                iconColor: today.checkInTime != null ? AppColors.success : AppColors.warning,
                title: l10n.today,
                subtitle: today.checkInTime != null ? l10n.checkInTime(today.checkInTime!) : l10n.noRecordsYet,
                trailing: DsPill(
                  today.todayStatus.replaceAll('_', ' '),
                  color: today.checkInTime != null ? AppColors.success : AppColors.warning,
                ),
              ),
            const DsSection('Explore'),
            DsAdaptiveGrid(
              children: [
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.today_rounded,
                  title: l10n.todaysAttendance,
                  subtitle: 'Check-in, check-out and GPS',
                  onTap: () => context.push(ClientRoutes.attendanceToday),
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.history_rounded,
                  title: l10n.attendanceHistory,
                  subtitle: 'Every day this month',
                  onTap: () => context.push(ClientRoutes.attendanceHistory),
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.error,
                  title: l10n.raiseIssue,
                  subtitle: 'Report a late or missed day',
                  onTap: () => context.push(ClientRoutes.attendanceRaiseIssue),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }
}

/// Pending payment from dashboard.
class ClientPendingPaymentScreen extends ConsumerWidget {
  const ClientPendingPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(clientInvoicesProvider);
    final inv = invoices.valueOrNull?.firstOrNull;
    final l10n = context.l10n;

    return DsPage(
      title: l10n.paymentRequired,
      onBack: () => _homeBack(context),
      onRefresh: () async => ref.invalidate(clientInvoicesProvider),
      bottom: inv == null
          ? null
          : DsGradientButton(
              label: l10n.payNow,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(ClientRoutes.paymentGateway),
            ),
      body: dsAsyncBody(
        invoices,
        onRetry: () => ref.invalidate(clientInvoicesProvider),
        builder: (list) {
          if (list.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.receipt_long_rounded,
                title: 'No invoices yet',
                message: 'Invoices appear after your Relationship Manager approves shifts and Finance runs payroll.',
              ),
            ];
          }
          final inv = list.first;
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsGlassPill(inv.billingMonth.toUpperCase(), icon: Icons.receipt_long_rounded),
                        const SizedBox(height: 12),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: inv.totalAmount),
                          duration: 900.ms,
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.inr(v),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          l10n.dueBy(inv.dueDate),
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
                  const DsFloatingIconTile(icon: Icons.account_balance_wallet_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DsNote(tone: DsNoteTone.warning, title: l10n.serviceSetup, text: l10n.pendingAuthorization),
            const DsSection('Details'),
            DsListCard(
              icon: Icons.description_rounded,
              title: l10n.viewInvoice,
              subtitle: l10n.invoicePdfDesc(inv.id),
              onTap: () => context.push(ClientRoutes.invoice),
            ),
            DsListCard(
              icon: Icons.insights_rounded,
              title: l10n.paymentStatus,
              subtitle: l10n.pendingAuthorization,
              onTap: () => context.push(ClientRoutes.paymentStatus),
            ),
            DsListCard(
              icon: Icons.history_rounded,
              title: l10n.paymentHistory,
              subtitle: 'Your previous payments',
              onTap: () => context.push(ClientRoutes.paymentHistory),
            ),
          ];
        },
      ),
    );
  }
}

/// Assigned staff overview from dashboard.
class ClientAssignedStaffScreen extends ConsumerWidget {
  const ClientAssignedStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedStaff = ref.watch(clientAssignedStaffProvider);
    final l10n = context.l10n;

    return DsPage(
      title: l10n.assignedStaff,
      onBack: () => _homeBack(context),
      onRefresh: () async => ref.invalidate(clientAssignedStaffProvider),
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
          return [
            ClientStaffHeroCard(
              name: staff.fullName ?? 'Staff',
              series: SeriesDisplay.label(staff.series),
              staffCode: staff.staffCode ?? '',
              isOnDuty: staff.status == 'ACTIVE_DEPLOYED',
              onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
            ),
            if (list.length > 1) ...[
              DsSection('Also placed', trailing: DsPill('${list.length - 1}')),
              for (final s in list.skip(1))
                DsListCard(
                  icon: Icons.person_rounded,
                  title: s.fullName ?? s.staffCode ?? 'Staff',
                  subtitle: [if (s.staffCode != null) s.staffCode!, if (s.series != null) SeriesDisplay.label(s.series)].join(' · '),
                  onTap: () => context.push(ClientRoutes.staffProfile(s.staffId)),
                ),
            ],
            const DsSection('About your staff'),
            DsAdaptiveGrid(
              children: [
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.badge_rounded,
                  title: l10n.staffProfile,
                  onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.work_history_rounded,
                  title: l10n.experience,
                  onTap: () => context.push(ClientRoutes.staffExperience(staff.staffId)),
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.psychology_rounded,
                  title: l10n.skills,
                  onTap: () => context.push(ClientRoutes.staffSkills(staff.staffId)),
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.schedule_rounded,
                  title: l10n.attendance,
                  onTap: () => context.push(ClientRoutes.staffAttendance(staff.staffId)),
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.trending_up_rounded,
                  title: l10n.performance,
                  onTap: () => context.push(ClientRoutes.staffPerformance(staff.staffId)),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }
}
