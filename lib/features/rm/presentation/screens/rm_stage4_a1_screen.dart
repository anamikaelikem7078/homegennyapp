import 'package:flutter/material.dart';
import 'rm_agreement_instrument_screen.dart';

/// A1 — Employment agreement. Thin wrapper over the shared e-sign flow.
class RmStage4A1Screen extends StatelessWidget {
  const RmStage4A1Screen({super.key, required this.staffId, required this.clientId});
  final String staffId;
  final String clientId;

  @override
  Widget build(BuildContext context) {
    return RmAgreementInstrumentScreen(staffId: staffId, clientId: clientId, type: 'A1', title: 'A1 · Employment Agreement');
  }
}
