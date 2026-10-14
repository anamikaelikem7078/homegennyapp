import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/client_update_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../navigation/staff_routes.dart';

String _ago(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

(IconData, String) _typeLook(String type) => switch (type) {
      ClientUpdateType.carePlan => (Icons.assignment_rounded, 'Care plan'),
      ClientUpdateType.foodProfile => (Icons.tune_rounded, 'Food preferences'),
      ClientUpdateType.menu => (Icons.restaurant_menu_rounded, 'Menu'),
      ClientUpdateType.mealFeedback => (Icons.star_rounded, 'Meal rating'),
      ClientUpdateType.instruction => (Icons.record_voice_over_rounded, 'Instruction'),
      _ => (Icons.notifications_rounded, type),
    };

/// Where an update is acted on.
String? _routeFor(ClientUpdate u) => switch (u.type) {
      ClientUpdateType.carePlan => StaffRoutes.carePlan(u.placementId),
      ClientUpdateType.foodProfile || ClientUpdateType.menu => StaffRoutes.cookToday,
      ClientUpdateType.mealFeedback => StaffRoutes.cookRatings(u.placementId),
      ClientUpdateType.instruction => StaffRoutes.instructions,
      _ => null,
    };

// ---------------------------------------------------------------------------
// Home card
// ---------------------------------------------------------------------------

/// "New from the family" with the unread badge. Hidden when there is nothing
/// from the family at all.
class StaffClientUpdatesHomeCard extends ConsumerWidget {
  const StaffClientUpdatesHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(clientUpdatesUnreadProvider).valueOrNull;
    if (unread == null || unread == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DsListCard(
        icon: Icons.mark_email_unread_rounded,
        iconColor: AppColors.error,
        title: 'New from the family',
        subtitle: unread == 1 ? '1 update to read' : '$unread updates to read',
        margin: EdgeInsets.zero,
        onTap: () => context.push(StaffRoutes.clientUpdates),
        trailing: DsPill('$unread', color: AppColors.error),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Feed
// ---------------------------------------------------------------------------

class StaffClientUpdatesScreen extends ConsumerStatefulWidget {
  const StaffClientUpdatesScreen({super.key});

  @override
  ConsumerState<StaffClientUpdatesScreen> createState() => _StaffClientUpdatesScreenState();
}

class _StaffClientUpdatesScreenState extends ConsumerState<StaffClientUpdatesScreen> {
  bool _unreadOnly = true;

  /// Items marked read on this screen, shown read straight away.
  final _readNow = <String>{};
  String? _busy;

  String _key(ClientUpdate u) => '${u.type}:${u.id}:${u.version}';

  Future<void> _markRead(ClientUpdate u) async {
    setState(() => _busy = _key(u));
    final r = await ref.read(careApiProvider).acknowledgeUpdate(u.type, u.id);
    if (!mounted) return;
    setState(() => _busy = null);
    r.fold(
      onSuccess: (_) {
        HapticFeedback.lightImpact();
        setState(() => _readNow.add(_key(u)));
        invalidateAfterAck(ref);
      },
      // e.g. a newer version replaced it — the refreshed feed shows that one.
      onError: (f) {
        context.showDsSnackBar(f.message, type: DsSnackBarType.error);
        ref.invalidate(clientUpdatesProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clientUpdatesProvider);
    return DsPage(
      title: 'New from the family',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async {
        _readNow.clear();
        invalidateAfterAck(ref);
      },
      body: [
        Wrap(
          spacing: 8,
          children: [
            DsChoiceChip(label: 'To read', selected: _unreadOnly, onTap: () => setState(() => _unreadOnly = true)),
            DsChoiceChip(label: 'All', selected: !_unreadOnly, onTap: () => setState(() => _unreadOnly = false)),
          ],
        ),
        const SizedBox(height: 12),
        ...dsAsyncBody(
          async,
          onRetry: () => ref.invalidate(clientUpdatesProvider),
          builder: (feed) {
            final items = [
              for (final u in feed.items)
                if (_readNow.contains(_key(u)) && !u.isRead) u.markedRead() else u,
            ];
            // Something just marked read stays visible until refresh.
            final shown = _unreadOnly ? items.where((u) => !u.isRead || _readNow.contains(_key(u))).toList() : items;
            if (shown.isEmpty) {
              return [
                DsEmptyBlock(
                  icon: Icons.mark_email_read_rounded,
                  color: AppColors.success,
                  title: _unreadOnly ? 'All read' : 'Nothing yet',
                  message: _unreadOnly
                      ? 'You have read everything the family sent.'
                      : 'Care plans, menus, ratings and instructions from the family show here.',
                ),
              ];
            }
            return [for (final u in shown) _UpdateCard(update: u, busy: _busy == _key(u), onRead: () => _markRead(u))];
          },
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.update, required this.busy, required this.onRead});
  final ClientUpdate update;
  final bool busy;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final u = update;
    final (icon, kind) = _typeLook(u.type);
    final route = _routeFor(u);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(border: u.isRead ? null : AppColors.warning),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsIconTile(icon, size: 38, color: u.isRead ? AppColors.lightTextSecondary : null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [kind, if (u.clientName != null) u.clientName!].join(' · '),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
                    ),
                    Text(_ago(u.at), style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.lightTextSecondary)),
                  ],
                ),
              ),
              if (u.isRead) const DsPill('Read ✓', color: AppColors.success) else const DsPill('New', color: AppColors.error),
            ],
          ),
          const SizedBox(height: 10),
          Text(u.title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
          // What changed — written by the backend, shown highlighted as-is.
          for (final c in u.changes)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: u.isRead ? const Color(0xFFF3F5FA) : const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (route != null)
                Expanded(child: DsOutlineButton(label: 'Open', onPressed: () => context.push(route))),
              if (route != null && !u.isRead) const SizedBox(width: 10),
              if (!u.isRead)
                Expanded(
                  child: DsGradientButton(
                    label: 'Mark as read',
                    icon: Icons.done_all_rounded,
                    isLoading: busy,
                    onPressed: busy ? null : onRead,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
