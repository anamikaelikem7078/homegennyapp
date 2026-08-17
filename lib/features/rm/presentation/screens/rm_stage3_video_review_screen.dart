import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Video certification review status. `PUT
/// /trainer/video-certifications/:id/review` (the actual approve/reject
/// action) is TRAINER/ADMIN-only, not RM — confirmed via live role guards,
/// despite living under the "Mobile App RM APIs" Swagger tag. This screen
/// therefore shows review status read-only via `GET /video-cert/list/:staffId`
/// and lets RM play back a submission (`POST /video-cert/view-url`), but
/// offers no approve/reject action.
class RmStage3VideoReviewScreen extends ConsumerWidget {
  const RmStage3VideoReviewScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(rmVideoCertsProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Video Certifications')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmVideoCertsProvider(staffId)),
        child: AsyncValueWidget<List<VideoCertItem>>(
          value: itemsAsync,
          onRetry: () => ref.invalidate(rmVideoCertsProvider(staffId)),
          builder: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No video certifications submitted yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildItem(context, ref, items[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, WidgetRef ref, VideoCertItem item) {
    Color color = RmTheme.amberWarning;
    if (item.reviewStatus == 'APPROVED') color = RmTheme.emeraldGreen;
    if (item.reviewStatus == 'REJECTED') color = RmTheme.crimsonDanger;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.videocam_outlined, color: color),
        title: Text(item.promptKey),
        subtitle: Text('Attempt #${item.attemptNumber}${item.reviewNotes != null ? ' · ${item.reviewNotes}' : ''}'),
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(item.reviewStatus, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Play back',
              onPressed: () => _play(context, ref, item),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref, VideoCertItem item) async {
    final result = await ref.read(rmRepositoryProvider).getVideoCertViewUrl(item.videoUrl);
    if (!context.mounted) return;
    result.fold(
      onSuccess: (url) {
        if (url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No playback URL returned')));
          return;
        }
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Playback URL'),
            content: SelectableText(url),
            actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close'))],
          ),
        );
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }
}
