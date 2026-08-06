import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// Pending video reviews.
class RmPendingVideosScreen extends ConsumerWidget {
  const RmPendingVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(rmPendingVideosProvider);

    return RmPageScaffold(
      title: 'Pending Videos',
      subtitle: 'Review staff video submissions',
      body: videos.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _VideoTile(
            video: list[i],
            onTap: () => context.push(RmRoutes.videoWatch(list[i].id)),
          ),
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, required this.onTap});
  final RmPendingVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(Icons.play_circle_outline, color: AppColors.primary, size: 32),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.promptTitle, style: Theme.of(context).textTheme.titleSmall),
                  Text('${video.staffName} · ${video.uploadedAt}'),
                ],
              ),
            ),
            const DsStatusChip(label: 'Pending', type: DsStatusType.warning),
          ],
        ),
      ),
    );
  }
}

/// Watch video and review.
class RmWatchVideoScreen extends ConsumerStatefulWidget {
  const RmWatchVideoScreen({super.key, required this.videoId});
  final String videoId;

  @override
  ConsumerState<RmWatchVideoScreen> createState() => _RmWatchVideoScreenState();
}

class _RmWatchVideoScreenState extends ConsumerState<RmWatchVideoScreen> {
  final _remarks = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).approveVideo(
          widget.videoId,
          remarks: _remarks.text.isEmpty ? null : _remarks.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    _handleResult(result, 'Video approved');
  }

  Future<void> _reject() async {
    if (_remarks.text.isEmpty) {
      context.showDsSnackBar('Remarks required', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).rejectVideo(widget.videoId, _remarks.text);
    if (!mounted) return;
    setState(() => _loading = false);
    _handleResult(result, 'Video rejected');
  }

  void _handleResult(dynamic result, String msg) {
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmPendingVideosProvider);
        context.showDsSnackBar(msg, type: DsSnackBarType.success);
        context.go(RmRoutes.videosPending);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(rmPendingVideosProvider);

    return RmPageScaffold(
      title: 'Watch Video',
      body: videos.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final video = list.cast<RmPendingVideo?>().firstWhere(
                (v) => v?.id == widget.videoId,
                orElse: () => null,
              );
          if (video == null) return const DsEmptyState(title: 'Not found');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.onSurface,
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: Icon(Icons.play_circle_fill, color: context.theme.cardColor, size: 64),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(video.promptTitle, style: Theme.of(context).textTheme.titleMedium),
              Text('${video.staffName} · ${video.uploadedAt}'),
              SizedBox(height: AppSpacing.lg),
              DsTextField(controller: _remarks, label: 'Remarks', hint: 'Review comments', maxLines: 3),
              const Spacer(),
              Row(
                children: [
                  Expanded(child: DsOutlineButton(label: 'Reject', onPressed: _loading ? null : _reject, color: AppColors.error)),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: DsPrimaryButton(label: 'Approve', isLoading: _loading, onPressed: _approve)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
