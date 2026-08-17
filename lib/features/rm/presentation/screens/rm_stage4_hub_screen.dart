import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';

/// S4 Agreements hub — contracts/e-sign, *not* an assessment stage (that
/// already happened at S2.5). Covers A1 (Employment), A2 (Scope of Work),
/// A3 (Client Indemnity), each an `/agreements` record. RM must not be able
/// to skip this stage: advancing to S5_DEPLOY is only offered once all
/// three show `SIGNED`, checked live via `GET /agreements`.
class RmStage4HubScreen extends ConsumerWidget {
  const RmStage4HubScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final client = ref.watch(agreementClientProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Agreements (S4)')),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
        builder: (staff) {
          if (staff == null) return const Center(child: Text('Staff not found'));
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName, style: RmTheme.headline(context).copyWith(fontSize: 22)),
                Text(staff.staffCode, style: RmTheme.body(context)),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(client?.customerName ?? 'No client selected'),
                    subtitle: const Text('All 3 agreement instruments are tied to this client'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final selected = await context.push<FinanceCustomer>(RmRoutes.stage4A2Client(staffId));
                      if (selected != null) {
                        ref.read(agreementClientProvider(staffId).notifier).state = selected;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (client == null)
                  const Expanded(child: Center(child: Text('Select a client to see agreement status.')))
                else
                  Expanded(child: _InstrumentList(staffId: staffId, staff: staff, clientId: client.id)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InstrumentList extends ConsumerWidget {
  const _InstrumentList({required this.staffId, required this.staff, required this.clientId});
  final String staffId;
  final StaffRow staff;
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreementsAsync = ref.watch(rmAgreementsProvider(AgreementListParams(staffId: staffId, clientId: clientId)));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(rmAgreementsProvider(AgreementListParams(staffId: staffId, clientId: clientId))),
      child: AsyncValueWidget<List<Agreement>>(
        value: agreementsAsync,
        onRetry: () => ref.invalidate(rmAgreementsProvider(AgreementListParams(staffId: staffId, clientId: clientId))),
        builder: (agreements) {
          Agreement? find(String type) {
            final matches = agreements.where((a) => a.type == type).toList()
              ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
            return matches.isEmpty ? null : matches.first;
          }

          final a1 = find(AgreementTypes.a1Employment);
          final a2 = find(AgreementTypes.a2Sow);
          final a3 = find(AgreementTypes.a3Indemnity);
          final allSigned = a1?.isSigned == true && a2?.isSigned == true && a3?.isSigned == true;

          return ListView(
            children: [
              _instrumentTile(context, AgreementTypes.a1Employment, a1, () => context.push(RmRoutes.stage4A1(staffId), extra: clientId)),
              _instrumentTile(context, AgreementTypes.a2Sow, a2, () => context.push(RmRoutes.stage4A2(staffId), extra: clientId)),
              _instrumentTile(context, AgreementTypes.a3Indemnity, a3, () => context.push(RmRoutes.stage4A3(staffId), extra: clientId)),
              const SizedBox(height: 24),
              AdvanceStageButton(
                staffId: staffId,
                fromStage: staff.pipelineStage,
                toStage: PipelineStages.s5Deploy,
                label: 'Advance to Deploy (S5)',
                reasonCode: 'AGREEMENTS_SIGNED',
                enabled: allSigned,
              ),
              if (!allSigned)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('All three instruments must be SIGNED before advancing.', style: TextStyle(color: RmTheme.textSecondary, fontSize: 12)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _instrumentTile(BuildContext context, String type, Agreement? agreement, VoidCallback onTap) {
    final status = agreement?.status ?? 'NOT CREATED';
    final color = agreement?.isSigned == true ? RmTheme.emeraldGreen : RmTheme.amberWarning;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(agreement?.isSigned == true ? Icons.check_circle : Icons.radio_button_unchecked, color: color),
        title: Text(AgreementTypes.label(type)),
        subtitle: Text(status),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
