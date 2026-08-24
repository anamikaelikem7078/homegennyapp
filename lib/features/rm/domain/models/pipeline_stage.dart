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

  /// Forward-flow order — excludes the two exception states.
  static const List<String> order = [
    s1Intake,
    s2Verify,
    s25Assess,
    s3Train,
    s4Agreements,
    s5Deploy,
  ];

  static const List<String> all = [...order, deferred, terminal];

  /// The next stage in the forward flow, or null if [current] is the last
  /// forward stage or an exception state with no automatic "next".
  static String? nextStage(String current) {
    final i = order.indexOf(current);
    if (i == -1 || i == order.length - 1) return null;
    return order[i + 1];
  }

  /// Whether advancing from [from] to [to] is a legal client-side
  /// transition: exactly one step forward, or into DEFERRED/TERMINAL from
  /// any active forward stage. This mirrors (and pre-checks ahead of) the
  /// backend's own FSM validation so the RM app can reject an illegal
  /// transition with a clear message instead of a raw 400.
  ///
  /// One deliberate exception: `S2_VERIFY → S3_TRAIN` is also legal — the
  /// backend FSM allows skipping S2_5_ASSESS entirely for non-DR series
  /// (the driver practical road test only applies to DR), so this is not a
  /// "skip a step" violation for those staff.
  static bool canAdvance(String from, String to) {
    if (to == deferred || to == terminal) return order.contains(from);
    if (from == s2Verify && to == s3Train) return true;
    return nextStage(from) == to;
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

/// Staff series short codes — the only 4 values `POST /rm/intake`,
/// `POST /video-cert/upload-url`, and the kanban `series` filter accept.
abstract final class StaffSeries {
  static const driver = 'DR';
  static const skilledCare = 'SC';
  static const unskilledCare = 'UC';
  static const maid = 'MAID';

  static const List<String> all = [driver, skilledCare, unskilledCare, maid];

  static String label(String series) => switch (series) {
        driver => 'Driver (DR)',
        skilledCare => 'Skilled Care (SC)',
        unskilledCare => 'Unskilled Care (UC)',
        maid => 'Maid (MAID)',
        _ => series,
      };

  /// Refundable deposit per series, per the task spec — not auto-derived
  /// server-side, the client must send the right amount.
  static num depositFor(String series) => switch (series) {
        driver => 2000,
        skilledCare => 1500,
        unskilledCare => 1000,
        maid => 500,
        _ => 0,
      };
}
