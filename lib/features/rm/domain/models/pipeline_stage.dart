/// Canonical RM pipeline stage values — must match the `PIPELINE_STAGES`
/// constant in the backend's `rm.controller.ts` exactly. `POST
/// /rm/pipeline/:staffId/advance` only accepts these 8 strings for
/// `to_stage`; anything else 400s.
abstract final class PipelineStages {
  static const s1Intake = 'S1_INTAKE';
  static const s2Verify = 'S2_VERIFY';
  static const s25Assess = 'S2_5_ASSESS';
  static const s3Train = 'S3_TRAIN';
  static const s4Agreements = 'S4_AGREEMENTS';
  static const s5Deploy = 'S5_DEPLOY';
  static const deferred = 'DEFERRED';
  static const terminal = 'TERMINAL';

  /// Forward-flow order — excludes the two exception states. S2_5_ASSESS is
  /// not in it: Stage 2.5 is switched off (`stage_2_5_enabled: false` on
  /// `GET /meta/series`), so S2 goes straight to S3.
  static const List<String> order = [
    s1Intake,
    s2Verify,
    s3Train,
    s4Agreements,
    s5Deploy,
  ];

  /// The flow with S2_5_ASSESS — only for a staff member still sitting in
  /// S2.5, or if the backend switches it back on.
  static const List<String> orderWithS25 = [
    s1Intake,
    s2Verify,
    s25Assess,
    s3Train,
    s4Agreements,
    s5Deploy,
  ];

  static const List<String> all = [...orderWithS25, deferred, terminal];

  /// The flow to draw for a staff member at [stage]: includes S2.5 only when
  /// it is switched on or the staff member is in it.
  static List<String> flowFor(String stage, {bool stage25Enabled = false}) =>
      stage25Enabled || stage == s25Assess ? orderWithS25 : order;

  /// The forward stages to show as columns/chips for `GET /rm/kanban`
  /// [columns]: S2.5 only when it is switched on or someone is in it.
  static List<String> visibleStages(
    Map<String, List<Object?>> columns, {
    bool stage25Enabled = false,
  }) =>
      stage25Enabled || (columns[s25Assess]?.isNotEmpty ?? false)
          ? orderWithS25
          : order;

  /// The next stage in the forward flow, or null if [current] is the last
  /// forward stage or an exception state with no automatic "next".
  static String? nextStage(String current, {bool stage25Enabled = false}) {
    final flow = flowFor(current, stage25Enabled: stage25Enabled);
    final i = flow.indexOf(current);
    if (i == -1 || i == flow.length - 1) return null;
    return flow[i + 1];
  }

  /// Whether advancing from [from] to [to] is a legal client-side
  /// transition: exactly one step forward, or into DEFERRED/TERMINAL from
  /// any active forward stage. This mirrors (and pre-checks ahead of) the
  /// backend's own FSM validation so the RM app can reject an illegal
  /// transition with a clear message instead of a raw 400.
  ///
  /// `S2_VERIFY → S3_TRAIN` is always legal. Entering S2_5_ASSESS is legal
  /// only while Stage 2.5 is switched on; a staff member already in it can
  /// still move out (→ S3_TRAIN / DEFERRED / TERMINAL).
  static bool canAdvance(String from, String to, {bool stage25Enabled = false}) {
    if (to == deferred || to == terminal) return orderWithS25.contains(from);
    if (to == s25Assess && !stage25Enabled) return false;
    if (from == s2Verify && to == s3Train) return true;
    return nextStage(from, stage25Enabled: stage25Enabled) == to;
  }

  static String label(String stage) => switch (stage) {
        s1Intake => 'S1 · Intake',
        s2Verify => 'S2 · Verification',
        s25Assess => 'S2.5 · Assessment',
        s3Train => 'S3 · Training',
        s4Agreements => 'S4 · Agreements',
        s5Deploy => 'S5 · Deploy',
        deferred => 'Deferred',
        terminal => 'Terminal',
        _ => stage,
      };

  static String shortLabel(String stage) => switch (stage) {
        s1Intake => 'S1',
        s2Verify => 'S2',
        s25Assess => 'S2.5',
        s3Train => 'S3',
        s4Agreements => 'S4',
        s5Deploy => 'S5',
        deferred => 'Deferred',
        terminal => 'Terminal',
        _ => stage,
      };
}

/// Valid `terminal_outcome` values — required only when advancing to
/// TERMINAL.
abstract final class TerminalOutcomes {
  static const enrolled = 'ENROLLED';
  static const conditional = 'CONDITIONAL';
  static const deferredOutcome = 'DEFERRED';
  static const denied = 'DENIED';
  static const abandoned = 'ABANDONED';
  static const lateExit = 'LATE_EXIT';

  static const List<String> all = [
    enrolled,
    conditional,
    deferredOutcome,
    denied,
    abandoned,
    lateExit,
  ];
}

/// Staff series short codes — what `POST /rm/intake`,
/// `POST /video-cert/upload-url`, and the kanban `series` filter take.
///
/// Only UC / SC / CK are taken on for new staff; MAID and DR are paused but
/// their staff still exist. Pickers read the active list from
/// `seriesCatalogProvider` (`GET /meta/series`), never from [all].
abstract final class StaffSeries {
  static const driver = 'DR';
  static const skilledCare = 'SC';
  static const unskilledCare = 'UC';
  static const cook = 'CK';
  static const maid = 'MAID';

  /// Every series a staff member can have — for filters and lookups only.
  static const List<String> all = [unskilledCare, skilledCare, cook, maid, driver];

  static String label(String series) => switch (series) {
        driver => 'Driver (DR)',
        skilledCare => 'Skilled Care (SC)',
        unskilledCare => 'Unskilled Care (UC)',
        cook => 'Cook (CK)',
        maid => 'Maid (MAID)',
        _ => series,
      };

  /// Refundable deposit per series, per the task spec — not auto-derived
  /// server-side, the client must send the right amount.
  static num depositFor(String series) => switch (series) {
        driver => 2000,
        skilledCare => 1500,
        unskilledCare => 1000,
        cook => 1000,
        maid => 500,
        _ => 0,
      };
}
