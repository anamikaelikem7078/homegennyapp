import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/communication_helper.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// New staff and client sign-ups that have no RM yet. Accepting one makes
/// the current RM theirs (first RM to accept wins — the backend returns 409
/// if someone else got there first).
class RmSignupRequestsScreen extends ConsumerStatefulWidget {
  const RmSignupRequestsScreen({super.key});

  @override
  ConsumerState<RmSignupRequestsScreen> createState() => _RmSignupRequestsScreenState();
}

class _RmSignupRequestsScreenState extends ConsumerState<RmSignupRequestsScreen> {
  SignupRequestType? _filter;
  final Set<String> _accepting = {};

  Future<void> _accept(SignupRequest r) async {
    final kind = r.type == SignupRequestType.staff ? 'staff member' : 'client';
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Accept ${r.name}?',
      message: 'You will become the Relationship Manager for this $kind. They will be notified.',
      confirmLabel: 'Accept',
      icon: Icons.how_to_reg_rounded,
    );
    if (ok != true || !mounted) return;

    setState(() => _accepting.add(r.id));
    final result = await ref.read(rmRepositoryProvider).acceptSignupRequest(r.type, r.id);
    if (!mounted) return;
    setState(() => _accepting.remove(r.id));
    result.fold(
      onSuccess: (_) => DsSnackBar.show(
        context,
        message: 'You are now the RM for ${r.name}',
        type: DsSnackBarType.success,
      ),
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
    // Refresh either way — on a 409 the request has gone to another RM.
    ref.invalidate(rmSignupRequestsProvider);
    ref.invalidate(rmDashboardProvider);
    ref.invalidate(rmKanbanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(rmSignupRequestsProvider);

    return RmStageScaffold(
      title: 'New sign-ups',
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(rmSignupRequestsProvider),
      body: rmAsyncBody<List<SignupRequest>>(
        requestsAsync,
        onRetry: () => ref.invalidate(rmSignupRequestsProvider),
        builder: (rows) {
          final staffCount = rows.where((r) => r.type == SignupRequestType.staff).length;
          final clientCount = rows.length - staffCount;
          final visible = _filter == null ? rows : rows.where((r) => r.type == _filter).toList();
          return [
            const RmNote(
              text: 'These staff and clients signed up without an RM. Accept one to become their RM.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'All (${rows.length})',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                _FilterChip(
                  label: 'Staff ($staffCount)',
                  selected: _filter == SignupRequestType.staff,
                  onTap: () => setState(() => _filter = SignupRequestType.staff),
                ),
                _FilterChip(
                  label: 'Clients ($clientCount)',
                  selected: _filter == SignupRequestType.client,
                  onTap: () => setState(() => _filter = SignupRequestType.client),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              const RmEmptyBlock(
                icon: Icons.how_to_reg_rounded,
                title: 'No pending sign-ups',
                message: 'New staff and clients who register in the app will show up here.',
              )
            else
              for (final r in visible)
                _RequestCard(
                  request: r,
                  accepting: _accepting.contains(r.id),
                  onAccept: () => _accept(r),
                ),
          ];
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: RmTheme.electricBlue,
      backgroundColor: Colors.white,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : RmTheme.textPrimary,
      ),
      side: BorderSide(color: selected ? RmTheme.electricBlue : RmTheme.borderSubtle),
      showCheckmark: false,
    );
  }
}

String _ago(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes}m ago';
  if (d.inDays < 1) return '${d.inHours}h ago';
  if (d.inDays < 30) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.accepting, required this.onAccept});
  final SignupRequest request;
  final bool accepting;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final isStaff = r.type == SignupRequestType.staff;
    final details = [
      r.phone,
      if (isStaff && r.staffCode != null) r.staffCode!,
      if (!isStaff && (r.city?.isNotEmpty ?? false)) r.city!,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isStaff ? Icons.badge_rounded : Icons.home_work_rounded,
                  color: RmTheme.iconAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name.isEmpty ? 'New sign-up' : r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RmStatusPill(
                    label: isStaff ? 'Staff' : 'Client',
                    color: isStaff ? RmTheme.electricBlue : RmTheme.emeraldGreen,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _ago(r.createdAt),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: RmTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (isStaff && (r.series != null || r.pipelineStage != null)) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (r.series != null) rmTitleCase(r.series!),
                if (r.pipelineStage != null) rmStageName(r.pipelineStage!),
              ].join(' · '),
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: RmTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (r.phone.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => CommunicationHelper.makePhoneCall(context, r.phone, recipientName: r.name),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call'),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: accepting ? null : onAccept,
                  style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
                  icon: accepting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(accepting ? 'Accepting…' : 'Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
