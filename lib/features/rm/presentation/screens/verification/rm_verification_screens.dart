import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// Pending documents for verification.
class RmVerificationPendingScreen extends ConsumerWidget {
  const RmVerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(rmPendingDocumentsProvider);

    return RmPageScaffold(
      title: 'Pending Verification',
      subtitle: 'Review staff documents',
      body: docs.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => _DocTile(
            doc: list[i],
            onTap: () => context.push(RmRoutes.verificationDetail(list[i].id)),
          ),
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.doc, required this.onTap});
  final RmPendingDocument doc;
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.documentName, style: Theme.of(context).textTheme.titleSmall),
                  Text('${doc.staffName} · ${doc.uploadedAt}'),
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

/// Document verification detail with approve/reject.
class RmVerificationDetailScreen extends ConsumerStatefulWidget {
  const RmVerificationDetailScreen({super.key, required this.docId});
  final String docId;

  @override
  ConsumerState<RmVerificationDetailScreen> createState() =>
      _RmVerificationDetailScreenState();
}

class _RmVerificationDetailScreenState
    extends ConsumerState<RmVerificationDetailScreen> {
  final _remarks = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).approveDocument(
          widget.docId,
          remarks: _remarks.text.isEmpty ? null : _remarks.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    _handleResult(result, 'Document approved');
  }

  Future<void> _reject() async {
    if (_remarks.text.isEmpty) {
      context.showDsSnackBar('Remarks required for rejection', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).rejectDocument(
          widget.docId,
          _remarks.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    _handleResult(result, 'Document rejected');
  }

  void _handleResult(dynamic result, String msg) {
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmPendingDocumentsProvider);
        context.showDsSnackBar(msg, type: DsSnackBarType.success);
        context.go(RmRoutes.verificationPending);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(rmPendingDocumentsProvider);

    return RmPageScaffold(
      title: 'Document Review',
      body: docs.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final doc = list.where((d) => d.id == widget.docId).firstOrNull;
          if (doc == null) return const DsEmptyState(title: 'Not found');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsDocumentCard(title: doc.documentName, subtitle: doc.staffName, fileType: doc.documentType),
              SizedBox(height: AppSpacing.lg),
              DsTextField(controller: _remarks, label: 'Remarks', hint: 'Add review comments', maxLines: 3),
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
