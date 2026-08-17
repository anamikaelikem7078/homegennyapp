import 'package:flutter/material.dart';
import 'rm_agreement_instrument_screen.dart';

/// A2 — Scope of Work. Uses `/agreements` (type A2), not the placement-scoped
/// `/sow` endpoints — `ScopeOfWork.placementId` is required on that model,
/// but a placement doesn't exist until S5_DEPLOY, after this stage. The
/// SOW *document content* (`/sow` create/send/amend) is a separate,
/// placement-scoped action available from the Placement detail screen once
/// a placement exists — see the plan's "known gaps" for this discrepancy.
class RmStage4A2Screen extends StatelessWidget {
  const RmStage4A2Screen({super.key, required this.staffId, required this.clientId});
  final String staffId;
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return RmAgreementInstrumentScreen(staffId: staffId, clientId: clientId, type: 'A2', title: 'A2 · Scope of Work');
  }
}
