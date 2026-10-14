import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';
import '../../../../../core/series/series_catalog.dart';

void _backOrHome(BuildContext context) {
  // `canPop()` is false whenever this screen is the only stack entry — a
  // browser refresh/direct URL load leaves nothing to pop back to.
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

/// Replacement request form.
class ClientReplacementRequestScreen extends ConsumerStatefulWidget {
  const ClientReplacementRequestScreen({super.key});

  @override
  ConsumerState<ClientReplacementRequestScreen> createState() => _ClientReplacementRequestScreenState();
}

class _ClientReplacementRequestScreenState extends ConsumerState<ClientReplacementRequestScreen> {
  final _reason = TextEditingController();
  bool _loading = false;
  String _urgency = 'STANDARD';
  String? _pickedFileName;
  // Placement to replace — required once the client has more than one staff
  // member placed; the backend 400s with "send placement_id to say which
  // one" if it's ambiguous. `staffId` from GET /client/assigned-staff is the
  // only per-placement identifier that model exposes, so it's reused here.
  String? _selectedPlacementId;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFileName = result.files.first.name);
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      context.showDsSnackBar('Please provide a reason', type: DsSnackBarType.warning);
      return;
    }
    final assignedStaff = await ref.read(clientAssignedStaffProvider.future);
    if (!mounted) return;
    if (assignedStaff.length > 1 && _selectedPlacementId == null) {
      context.showDsSnackBar(
        'You have more than one staff member placed — please pick who this is for',
        type: DsSnackBarType.warning,
      );
      return;
    }
    final placementId = _selectedPlacementId ?? (assignedStaff.length == 1 ? assignedStaff.first.staffId : null);
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).requestReplacement(
          reason: _reason.text,
          placementId: placementId,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (r) {
        ref.invalidate(clientReplacementsProvider);
        context.showDsSnackBar(r.message, type: DsSnackBarType.success);
        context.go(ClientRoutes.replacementStatus);
      },
      // A 400 asking to disambiguate the placement (or any other server
      // error) is surfaced verbatim rather than guessed at client-side.
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedStaff = ref.watch(clientAssignedStaffProvider).valueOrNull ?? const <ClientAssignedStaff>[];
    const levels = [
      ('LOW', 'Low', Icons.south_rounded, AppColors.success),
      ('STANDARD', 'Standard', Icons.remove_rounded, AppColors.primary),
      ('CRITICAL', 'Critical', Icons.priority_high_rounded, AppColors.error),
    ];

    return DsPage(
      title: 'Request replacement',
      onBack: () => _backOrHome(context),
      actions: [
        DsPageAction(
          icon: Icons.track_changes_rounded,
          tooltip: 'Request status',
          onPressed: () => context.push(ClientRoutes.replacementStatus),
        ),
      ],
      bottom: DsGradientButton(
        label: 'Submit request',
        icon: Icons.send_rounded,
        isLoading: _loading,
        onPressed: _loading ? null : _submit,
      ),
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DsGlassPill('REPLACEMENT', icon: Icons.swap_horiz_rounded),
                    const SizedBox(height: 12),
                    Text(
                      'Need a different staff member?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us what\'s wrong and your Relationship Manager will find the right match.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const DsFloatingIconTile(icon: Icons.published_with_changes_rounded),
            ],
          ),
        ),
        if (assignedStaff.length > 1) ...[
          const DsSection('Which staff member?'),
          for (final s in assignedStaff)
            _StaffOption(
              staff: s,
              selected: _selectedPlacementId == s.staffId,
              onTap: () => setState(() => _selectedPlacementId = s.staffId),
            ),
        ],
        const DsSection('Describe the issue'),
        DsLabeledField(
          label: 'Reason',
          controller: _reason,
          icon: Icons.edit_note_rounded,
          hint: 'Detail the nature of the problem…',
          maxLines: 5,
          minLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        const DsSection('Urgency level'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label, icon, color) in levels)
              DsChoiceChip(
                label: label,
                icon: icon,
                color: color,
                selected: _urgency == value,
                onTap: () => setState(() => _urgency = value),
              ),
          ],
        ),
        const DsSection('Supporting document', trailing: DsPill('Optional', color: AppColors.lightTextSecondary)),
        _UploadBox(fileName: _pickedFileName, onTap: _pickDocument, onClear: () => setState(() => _pickedFileName = null)),
        const SizedBox(height: 18),
        const DsNote(
          title: 'Priority handling',
          text: 'Our team responds within 15 minutes for critical issues.',
        ),
      ],
    );
  }
}

class _StaffOption extends StatelessWidget {
  const _StaffOption({required this.staff, required this.selected, required this.onTap});
  final ClientAssignedStaff staff;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = staff.fullName ?? staff.staffCode ?? staff.staffId;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 220.ms,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.lightBorder, width: selected ? 1.6 : 1),
          boxShadow: dsCardShadow,
        ),
        child: Row(
          children: [
            DsInitialsAvatar(name: name, size: 42),
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    [if (staff.staffCode != null) staff.staffCode!, if (staff.series != null) SeriesDisplay.label(staff.series)].join(' · '),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: 200.ms,
              child: Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(selected),
                color: selected ? AppColors.primary : AppColors.lightBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.fileName, required this.onTap, required this.onClear});
  final String? fileName;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final picked = fileName != null;
    return Material(
      color: picked ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: picked ? AppColors.primary.withValues(alpha: 0.4) : AppColors.lightBorder,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              DsIconTile(picked ? Icons.insert_drive_file_rounded : Icons.cloud_upload_rounded, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName ?? 'Upload a document',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: picked ? AppColors.primary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      picked ? 'Tap to change' : 'JPEG, PNG or PDF · max 10 MB',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              if (picked)
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, color: AppColors.lightTextSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Replacement status.
class ClientReplacementStatusScreen extends ConsumerWidget {
  const ClientReplacementStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replacements = ref.watch(clientReplacementsProvider);

    return DsPage(
      title: 'Replacement status',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(clientReplacementsProvider),
      bottom: DsGradientButton(
        label: 'Request replacement',
        icon: Icons.swap_horiz_rounded,
        onPressed: () => context.push(ClientRoutes.replacementRequest),
      ),
      body: dsAsyncBody(
        replacements,
        onRetry: () => ref.invalidate(clientReplacementsProvider),
        builder: (requests) {
          if (requests.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.find_replace_rounded,
                title: 'No active request',
                message: 'You currently have no replacement requests for your staff.',
              ),
            ];
          }
          return [for (final r in requests) _RequestCard(request: r)];
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final ClientReplacementRequest request;

  static const _steps = [
    ClientReplacementStatus.pending,
    ClientReplacementStatus.inReview,
    ClientReplacementStatus.approved,
    ClientReplacementStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final r = request;
    final rejected = r.status == ClientReplacementStatus.rejected;
    final current = rejected ? 1 : _steps.indexOf(r.status);
    final color = rejected
        ? AppColors.error
        : r.status == ClientReplacementStatus.completed
            ? AppColors.success
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsIconTile(Icons.swap_horiz_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.currentStaffName.isEmpty ? 'Replacement request' : r.currentStaffName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (r.requestedAt.isNotEmpty)
                      Text(
                        'Requested ${r.requestedAt}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              DsPill(clientReplacementStatusLabel(r.status), color: color),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < _steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: i <= current ? color : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: i <= current ? color : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: i <= current ? color : AppColors.lightBorder, width: 2),
                      ),
                      child: i < current || (i == current && !rejected)
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : (rejected && i == current)
                              ? const Icon(Icons.close_rounded, size: 14, color: Colors.white)
                              : null,
                    ).animate(delay: (120 * i).ms).scaleXY(begin: 0.5, end: 1, curve: Curves.easeOutBack),
                    const SizedBox(height: 4),
                    Text(
                      switch (_steps[i]) {
                        ClientReplacementStatus.pending => 'Sent',
                        ClientReplacementStatus.inReview => rejected ? 'Rejected' : 'Review',
                        ClientReplacementStatus.approved => 'Approved',
                        _ => 'Done',
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: i <= current ? color : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (r.newStaffName != null || r.estimatedDate != null || r.reason.isNotEmpty) ...[
          const SizedBox(height: 14),
          DsInfoCard(
            lines: [
              if (r.newStaffName != null) DsInfoLine(Icons.person_add_alt_1_rounded, 'New staff', r.newStaffName!),
              if (r.estimatedDate != null) DsInfoLine(Icons.event_rounded, 'Estimated date', r.estimatedDate!),
              if (r.reason.isNotEmpty) DsInfoLine(Icons.chat_bubble_rounded, 'Reason', r.reason),
            ],
          ),
          ],
          if (r.remarks != null && r.remarks!.isNotEmpty) ...[
            const SizedBox(height: 12),
            DsNote(
              tone: rejected ? DsNoteTone.danger : DsNoteTone.info,
              title: 'Remarks',
              text: r.remarks!,
            ),
          ],
        ],
      ),
    );
  }
}
