import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../../../core/presentation/widgets/location_address_widget.dart';
import '../../../../../core/series/series_catalog.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/care_models.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../../domain/models/staff_request_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/dish_picker.dart';
import '../../widgets/map_pin_picker.dart';
import '../care/client_care_screens.dart'
    show CareActivitySheet, CareAddButton, CareItemCard, CareMedicineSheet, CareVitalSheet;

part 'client_staff_request_form.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

/// "BEDRIDDEN" → "Bedridden", "NON_VEG" → "Non veg".
String _pretty(String raw) {
  final s = raw.replaceAll('_', ' ').toLowerCase();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

List<String> _splitList(String text) =>
    [for (final p in text.split(',')) if (p.trim().isNotEmpty) p.trim()];

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _hhmm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Diet type in full: "NON_VEG" → "Non-vegetarian". Older requests may
/// still carry VEGAN, which falls back to a plain label.
String _dietLabel(String code) => switch (code) {
      'VEG' => 'Vegetarian',
      'EGG' => 'Eggetarian',
      'NON_VEG' => 'Non-vegetarian',
      'JAIN' => 'Jain',
      _ => _pretty(code),
    };

/// "2026-10-16" → "16 Oct".
String _dayMonth(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]}';
}

/// "19:30" → "7:30 PM".
String _time12(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first);
  if (h == null || parts.length < 2) return hhmm;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${parts[1]} ${h < 12 ? 'AM' : 'PM'}';
}

/// "16 Oct, 7:30 PM" (or just the date when there is no time).
String _when(StaffRequest r) => [
      if (r.startDate != null) _dayMonth(r.startDate!),
      if (r.startTime != null) _time12(r.startTime!),
    ].join(', ');

/// The list card's booking line:
/// "One-time visit · 2 h · 16 Oct, 7:30 PM" or
/// "Regular · Permanent · 12 h · from 16 Oct, 8:00 AM".
String _bookingLine(StaffRequest r) {
  final when = _when(r);
  if (r.isOneTime) {
    final h = BookingRules.hours((r.durationMin ?? (r.shiftHours * 60)) / 60);
    return ['One-time visit', '$h h', if (when.isNotEmpty) when].join(' · ');
  }
  return [
    'Regular',
    r.placementType == 'TEMPORARY' ? 'Hourly' : 'Permanent',
    '${BookingRules.hours(r.shiftHours)} h',
    if (when.isNotEmpty) 'from $when',
  ].join(' · ');
}

Color _statusColor(String status) => switch (status) {
      StaffRequestStatus.shortlisted => AppColors.warning,
      StaffRequestStatus.clientSelected => AppColors.primary,
      StaffRequestStatus.fulfilled => AppColors.success,
      StaffRequestStatus.cancelled => AppColors.error,
      _ => AppColors.lightTextSecondary,
    };

/// Asks for the (required) reason for "None of these" / "Cancel request".
Future<String?> _askReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                DsLabeledField(
                  label: 'Reason',
                  controller: controller,
                  icon: Icons.edit_note_rounded,
                  hint: hint,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 16),
                DsGradientButton(
                  label: confirmLabel,
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(sheetContext).pop(controller.text.trim()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SeriesOptionCard extends StatelessWidget {
  const _SeriesOptionCard({required this.option, required this.selected, required this.onTap});
  final SeriesOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (option.short) {
      'UC' => 'Daily help: bathing, walking, meals, company',
      'SC' => 'Trained nurse: medicines, vitals, wound care',
      'CK' => 'Home cook for your family\'s meals',
      _ => option.short,
    };
    return DsListCard(
      icon: SeriesDisplay.icon(option.value),
      iconColor: SeriesDisplay.color(option.value),
      title: option.label,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.primary : AppColors.lightBorder,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.optional = false});
  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          optional ? '$text (optional)' : text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary,
          ),
        ),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon = Icons.nightlight_round,
  });
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: dsCardDecoration(),
        child: Row(
          children: [
            DsIconTile(icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged});
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: dsCardDecoration(),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Fewer',
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'More',
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// My Requests list
// ---------------------------------------------------------------------------

class ClientStaffRequestsScreen extends ConsumerWidget {
  const ClientStaffRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(clientStaffRequestsProvider);

    return DsPage(
      title: 'My staff requests',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(clientStaffRequestsProvider),
      bottom: DsGradientButton(
        label: 'Request staff',
        icon: Icons.person_add_alt_1_rounded,
        onPressed: () => context.push(ClientRoutes.staffRequestNew),
      ),
      body: dsAsyncBody(
        requests,
        onRetry: () => ref.invalidate(clientStaffRequestsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.person_search_rounded,
                title: 'No requests yet',
                message: 'Ask for a caretaker or a cook, and your relationship manager will find the right person.',
              ),
            ];
          }
          return [for (final r in items) _RequestListCard(request: r)];
        },
      ),
    );
  }
}

class _RequestListCard extends StatelessWidget {
  const _RequestListCard({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final color = _statusColor(r.status);
    return GestureDetector(
      onTap: () => context.push(ClientRoutes.staffRequestDetail(r.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: dsCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DsIconTile(SeriesDisplay.icon(r.series), color: SeriesDisplay.color(r.series)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.headcount > 1
                            ? '${SeriesDisplay.label(r.series)} × ${r.headcount}'
                            : SeriesDisplay.label(r.series),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        r.requestNo,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                DsPill(StaffRequestStatus.label(r.status), color: color),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _bookingLine(r),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              StaffRequestStatus.message(r.status),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextSecondary,
              ),
            ),
            if (r.shortlistedCount > 0 && r.canChoose) ...[
              const SizedBox(height: 10),
              DsPill(
                r.shortlistedCount == 1 ? '1 staff to choose from' : '${r.shortlistedCount} staff to choose from',
                color: AppColors.warning,
                icon: Icons.how_to_reg_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request detail
// ---------------------------------------------------------------------------

class ClientStaffRequestDetailScreen extends ConsumerStatefulWidget {
  const ClientStaffRequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ClientStaffRequestDetailScreen> createState() => _ClientStaffRequestDetailScreenState();
}

class _ClientStaffRequestDetailScreenState extends ConsumerState<ClientStaffRequestDetailScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(clientStaffRequestProvider(widget.requestId));
    ref.invalidate(clientStaffRequestsProvider);
  }

  Future<void> _run(Future<Result<void>> Function() action, String success) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar(success, type: DsSnackBarType.success);
        _refresh();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _choose(CandidateStaff staff) async {
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Choose ${staff.firstName}?',
      message: 'Your relationship manager will set up a trial with ${staff.firstName}.',
      confirmLabel: 'Choose',
      icon: Icons.how_to_reg_rounded,
    );
    if (ok != true || !mounted) return;
    await _run(
      // Send the staff id, not the candidate id.
      () => ref.read(clientRepositoryProvider).selectStaffForRequest(widget.requestId, staffId: staff.id),
      'You chose ${staff.firstName}',
    );
  }

  Future<void> _noneOfThese() async {
    final reason = await _askReason(
      context,
      title: 'None of these?',
      hint: 'Tell your RM what you are looking for instead',
      confirmLabel: 'Send to my RM',
    );
    if (reason == null || !mounted) return;
    await _run(
      () => ref.read(clientRepositoryProvider).rejectStaffRequestShortlist(widget.requestId, reason),
      'Your RM will look for other staff',
    );
  }

  Future<void> _cancel() async {
    final reason = await _askReason(
      context,
      title: 'Cancel this request?',
      hint: 'Why are you cancelling?',
      confirmLabel: 'Cancel request',
    );
    if (reason == null || !mounted) return;
    await _run(
      () => ref.read(clientRepositoryProvider).cancelStaffRequest(widget.requestId, reason),
      'Request cancelled',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clientStaffRequestProvider(widget.requestId));
    final request = async.valueOrNull;

    return DsPage(
      title: request?.requestNo ?? 'Staff request',
      onBack: () => _backOrHome(context),
      onRefresh: () async => _refresh(),
      bottom: request != null && request.canChoose
          ? DsOutlineButton(
              label: 'None of these',
              icon: Icons.thumb_down_alt_outlined,
              onPressed: _busy ? null : _noneOfThese,
            )
          : null,
      body: dsAsyncBody(
        async,
        onRetry: _refresh,
        builder: (r) => [
          _StatusCard(request: r),
          if (r.rm != null && (r.rm!.name != null || r.rm!.phone != null)) ...[
            const DsSection('Your relationship manager'),
            DsListCard(
              icon: Icons.support_agent_rounded,
              title: r.rm!.name ?? 'Relationship manager',
              subtitle: r.rm!.phone,
              trailing: r.rm!.phone == null
                  ? null
                  : IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                      onPressed: () => CommunicationHelper.makePhoneCall(
                        context,
                        r.rm!.phone!,
                        recipientName: r.rm!.name,
                      ),
                    ),
            ),
          ],
          if (r.candidates.isNotEmpty) ...[
            DsSection(
              r.canChoose ? 'Choose your staff' : 'Staff put forward',
              trailing: DsPill('${r.candidates.length}'),
            ),
            for (final c in r.candidates)
              _CandidateCard(
                candidate: c,
                canChoose: r.canChoose && !_busy,
                onChoose: () => _choose(c.staff),
              ),
          ],
          const DsSection('Your booking'),
          _YourBooking(request: r),
          if (r.menu != null) ...[
            DsSection(r.menu!.weekly.isNotEmpty
                ? 'Weekly menu'
                : '${r.menu!.meal == null ? 'Visit' : _pretty(r.menu!.meal!)} menu'),
            _BookingMenu(menu: r.menu!),
          ],
          if (r.careNeeds != null) ...[
            const DsSection('Care needs'),
            _BookingCareNeeds(needs: r.careNeeds!),
          ],
          const DsSection('What you asked for'),
          _AskedFor(request: r),
          if (r.isOpen) ...[
            const SizedBox(height: 18),
            Center(
              child: TextButton.icon(
                onPressed: _busy ? null : _cancel,
                icon: const Icon(Icons.close_rounded, color: AppColors.error),
                label: Text(
                  'Cancel request',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final color = _statusColor(r.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsIconTile(SeriesDisplay.icon(r.series), color: SeriesDisplay.color(r.series)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  SeriesDisplay.label(r.series),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              DsPill(StaffRequestStatus.label(r.status), color: color),
            ],
          ),
          const SizedBox(height: 12),
          DsNote(
            tone: switch (r.status) {
              StaffRequestStatus.fulfilled => DsNoteTone.success,
              StaffRequestStatus.cancelled => DsNoteTone.danger,
              StaffRequestStatus.shortlisted => DsNoteTone.warning,
              _ => DsNoteTone.info,
            },
            text: r.status == StaffRequestStatus.cancelled && (r.cancelReason ?? '').isNotEmpty
                ? 'Cancelled — ${r.cancelReason}'
                : StaffRequestStatus.message(r.status),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.canChoose, required this.onChoose});
  final StaffRequestCandidate candidate;
  final bool canChoose;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final s = candidate.staff;
    final facts = [
      SeriesDisplay.label(s.series),
      if (s.experienceYears != null) '${s.experienceYears} yrs experience',
      if (s.gender != null) _pretty(s.gender!),
      if (s.languageTier != null) 'Language ${s.languageTier}',
    ];
    final (statusLabel, statusColor) = switch (candidate.status) {
      StaffRequestCandidateStatus.clientSelected => ('You chose', AppColors.primary),
      StaffRequestCandidateStatus.placed => ('Placed', AppColors.success),
      StaffRequestCandidateStatus.clientRejected => ('Not chosen', AppColors.lightTextSecondary),
      _ => (null, AppColors.lightTextSecondary),
    };
    final showChoose = canChoose && candidate.status == StaffRequestCandidateStatus.proposed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsInitialsAvatar(name: s.firstName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.firstName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      facts.join(' · '),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              if (statusLabel != null) DsPill(statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              DsPill(
                s.aadhaarVerified ? 'Aadhaar verified' : 'Aadhaar pending',
                color: s.aadhaarVerified ? AppColors.success : AppColors.lightTextSecondary,
                icon: s.aadhaarVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              ),
              DsPill(
                s.policeVerified ? 'Police verified' : 'Police check pending',
                color: s.policeVerified ? AppColors.success : AppColors.lightTextSecondary,
                icon: s.policeVerified ? Icons.verified_user_rounded : Icons.hourglass_top_rounded,
              ),
            ],
          ),
          if ((candidate.rmNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${candidate.rmNote}” — your RM',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ],
          if (showChoose) ...[
            const SizedBox(height: 12),
            DsGradientButton(label: 'Choose', icon: Icons.how_to_reg_rounded, onPressed: onChoose),
          ],
        ],
      ),
    );
  }
}

/// Visit type, when, how long and where.
class _YourBooking extends StatelessWidget {
  const _YourBooking({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final when = _when(r);
    final howLong = r.isOneTime
        ? BookingRules.durationLabel(r.durationMin ?? (r.shiftHours * 60).round())
        : '${r.placementType == 'TEMPORARY' ? 'Hourly' : 'Permanent'} · ${BookingRules.hours(r.shiftHours)} h a day';
    return DsInfoCard(
      lines: [
        DsInfoLine(Icons.badge_rounded, 'Staff', '${SeriesDisplay.label(r.series)} × ${r.headcount}'),
        DsInfoLine(Icons.event_available_rounded, 'Visit', r.isOneTime ? 'One-time visit' : 'Regular staff'),
        if (when.isNotEmpty) DsInfoLine(Icons.event_rounded, r.isOneTime ? 'When' : 'Starts', when),
        DsInfoLine(Icons.timelapse_rounded, 'How long', howLong),
        if ((r.address ?? '').isNotEmpty) DsInfoLine(Icons.home_rounded, 'Address', r.address!),
      ],
    );
  }
}

/// A cook request's dishes (one-time) or weekly menu (regular).
class _BookingMenu extends StatelessWidget {
  const _BookingMenu({required this.menu});
  final StaffRequestMenu menu;

  @override
  Widget build(BuildContext context) {
    final m = menu;
    if (m.weekly.isNotEmpty) {
      return DsInfoCard(
        lines: [
          for (final e in m.weekly)
            DsInfoLine(
              Icons.restaurant_rounded,
              '${_pretty(e.dow)} ${_pretty(e.meal)}${e.mealTime != null ? ' ${_time12(e.mealTime!)}' : ''}',
              e.dishes.join(', '),
            ),
        ],
      );
    }
    return DsInfoCard(
      lines: [
        if (m.mealTime != null) DsInfoLine(Icons.schedule_rounded, 'Meal time', _time12(m.mealTime!)),
        DsInfoLine(Icons.restaurant_rounded, 'Dishes', m.dishes.join(', ')),
        if ((m.specialInstruction ?? '').isNotEmpty)
          DsInfoLine(Icons.edit_note_rounded, 'Note', m.specialInstruction!),
      ],
    );
  }
}

/// A care request's needs — the care-plan shape.
class _BookingCareNeeds extends StatelessWidget {
  const _BookingCareNeeds({required this.needs});
  final CarePlan needs;

  @override
  Widget build(BuildContext context) {
    final n = needs;
    String times(List<String> t) => t.isEmpty ? '' : ' (${t.join(', ')})';
    final patient = [
      ?n.patient.name,
      if (n.patient.age != null) '${n.patient.age} yrs',
    ].join(' · ');
    return DsInfoCard(
      lines: [
        if (patient.isNotEmpty) DsInfoLine(Icons.person_rounded, 'Patient', patient),
        if (n.medications.isNotEmpty)
          DsInfoLine(
            Icons.medication_rounded,
            'Medicines',
            n.medications.map((m) => '${m.summary}${times(m.times)}').join(', '),
          ),
        if (n.vitals.isNotEmpty)
          DsInfoLine(
            Icons.monitor_heart_rounded,
            'Checks',
            n.vitals
                .map((v) =>
                    '${VitalType.fallback.where((t) => t.type == v.type).firstOrNull?.label ?? carePretty(v.type)}${times(v.times)}')
                .join(', '),
          ),
        if (n.activities.isNotEmpty)
          DsInfoLine(
            Icons.directions_walk_rounded,
            'Activities',
            n.activities.map((a) => '${a.title.isEmpty ? carePretty(a.type) : a.title}${times(a.times)}').join(', '),
          ),
        if (n.dietNotes != null) DsInfoLine(Icons.restaurant_rounded, 'Diet', n.dietNotes!),
        if (n.dos != null) DsInfoLine(Icons.thumb_up_alt_rounded, 'Do', n.dos!),
        if (n.donts != null) DsInfoLine(Icons.block_rounded, 'Don\'t', n.donts!),
      ],
    );
  }
}

/// The requirements: patient or kitchen details, preferences, notes.
class _AskedFor extends StatelessWidget {
  const _AskedFor({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final q = r.requirements;
    String list(Object? v) => v is List ? v.map((e) => _pretty('$e')).join(', ') : '';

    return DsInfoCard(
      lines: [
        if (r.genderPref != 'ANY') DsInfoLine(Icons.wc_rounded, 'Staff gender', _pretty(r.genderPref)),
        if ((r.language ?? '').isNotEmpty) DsInfoLine(Icons.translate_rounded, 'Language', r.language!),
        if (q['patient_age'] != null) DsInfoLine(Icons.cake_rounded, 'Patient age', '${q['patient_age']}'),
        if (q['mobility'] != null) DsInfoLine(Icons.accessible_rounded, 'Mobility', _pretty('${q['mobility']}')),
        if (list(q['conditions']).isNotEmpty) DsInfoLine(Icons.healing_rounded, 'Conditions', list(q['conditions'])),
        if (list(q['medical_needs']).isNotEmpty)
          DsInfoLine(Icons.medical_services_rounded, 'Medical duties', list(q['medical_needs'])),
        if (q['night_care'] == true) const DsInfoLine(Icons.nightlight_round, 'Night care', 'Yes'),
        if (q['diet_type'] != null) DsInfoLine(Icons.restaurant_rounded, 'Diet', _dietLabel('${q['diet_type']}')),
        if (q['family_size'] != null) DsInfoLine(Icons.groups_rounded, 'People', '${q['family_size']}'),
        if (list(q['meals_per_day']).isNotEmpty)
          DsInfoLine(Icons.lunch_dining_rounded, 'Meals', list(q['meals_per_day'])),
        if (list(q['cuisines']).isNotEmpty) DsInfoLine(Icons.restaurant_menu_rounded, 'Cuisines', list(q['cuisines'])),
        if (list(q['health_conditions']).isNotEmpty)
          DsInfoLine(Icons.favorite_rounded, 'Health needs', list(q['health_conditions'])),
        if ((r.notes ?? '').isNotEmpty) DsInfoLine(Icons.edit_note_rounded, 'Notes', r.notes!),
      ],
    );
  }
}
