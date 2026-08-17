import 'package:flutter/material.dart';
import 'rm_agreement_instrument_screen.dart';

/// A3 — Client Indemnity. Modeled as an `/agreements` record with
/// `type: 'A3'` (no separate indemnity endpoint exists — the backend's
/// `ClientIndemnity` Prisma model has no controller wired up). Thin wrapper
/// over the shared e-sign flow.
class RmStage4A3Screen extends StatelessWidget {
  const RmStage4A3Screen({super.key, required this.staffId, required this.clientId});
  final String staffId;
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return RmAgreementInstrumentScreen(staffId: staffId, clientId: clientId, type: 'A3', title: 'A3 · Client Indemnity');
  }
}
