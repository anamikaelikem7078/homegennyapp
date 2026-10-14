
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfx/pdfx.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Reformats a plain `YYYY-MM-DD` date for display without ever going
/// through [DateTime] — parsing a date-only string as UTC (or accidentally
/// treating it as one) can shift the displayed day depending on the device's
/// timezone, so this only ever does string surgery.
String _prettyPlainDate(String? ymd) {
  if (ymd == null || ymd.isEmpty) return '';
  final parts = ymd.split('-');
  if (parts.length != 3) return ymd;
  const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return ymd;
  return '$day ${months[month]} ${parts[0]}';
}


void _back(BuildContext context) => context.canPop() ? context.pop() : context.go(StaffRoutes.training);

/// Training home — study material + quizzes for every batch the staff member
/// is (or was) enrolled in. Stays reachable regardless of pipeline stage,
/// since a rescheduled quiz can arrive after the staff has moved on.
class StaffTrainingScreen extends ConsumerWidget {
  const StaffTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(staffTrainingHomeProvider);

    return DsPage(
      title: 'Training',
      subtitle: 'Mandatory courses & quizzes',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffTrainingHomeProvider),
      body: dsAsyncBody(
        home,
        onRetry: () => ref.invalidate(staffTrainingHomeProvider),
        builder: (h) {
          final quizzes = [for (final b in h.batches) ...b.quizzes];
          final passed = quizzes.where((q) => q.state == TrainingQuizState.passed).length;
          final open = quizzes
              .where((q) => q.state == TrainingQuizState.available || q.state == TrainingQuizState.inProgress)
              .length;
          final materials = h.batches.fold<int>(0, (a, b) => a + b.materials.length);

          return [
            DsGradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const DsGlassPill('MANDATORY TRAINING', icon: Icons.school_rounded),
                            const SizedBox(height: 12),
                            Text(
                              open > 0 ? '$open ${open == 1 ? 'quiz is' : 'quizzes are'} ready' : 'Keep learning',
                              style: GoogleFonts.plusJakartaSans(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Study your batch material and complete each quiz.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const DsFloatingIconTile(icon: Icons.menu_book_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: DsGlassStat(value: '$materials', label: 'Materials', icon: Icons.library_books_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: DsGlassStat(value: '$passed/${quizzes.length}', label: 'Quizzes passed', icon: Icons.emoji_events_rounded)),
                    ],
                  ),
                ],
              ),
            ),
            if (h.videoCert.required_ > 0) ...[
              const SizedBox(height: 14),
              _VideoCertProgress(progress: h.videoCert),
            ],
            if (h.batches.isEmpty) ...[
              const SizedBox(height: 16),
              const DsEmptyBlock(
                icon: Icons.school_rounded,
                title: 'No training yet',
                message: 'Your trainer hasn\'t added you to a batch yet. Check back soon.',
              ),
            ] else
              for (final batch in h.batches) ..._batchSection(context, batch),
          ];
        },
      ),
    );
  }

  List<Widget> _batchSection(BuildContext context, TrainingBatch batch) {
    final who = [batch.trainerName, if (batch.classroom != null) batch.classroom!].where((s) => s.isNotEmpty).join(' · ');
    return [
      DsSection(batch.batchCode, trailing: DsPill('${_prettyPlainDate(batch.startDate)} – ${_prettyPlainDate(batch.endDate)}')),
      if (who.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.iconAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  who,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      if (batch.materials.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: dsCardDecoration(),
          child: Column(
            children: [
              for (var i = 0; i < batch.materials.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 66, endIndent: 16, color: AppColors.lightBorder),
                _MaterialTile(material: batch.materials[i]),
              ],
            ],
          ),
        ),
      for (final q in batch.quizzes) _QuizCard(quiz: q),
    ];
  }
}

class _VideoCertProgress extends StatelessWidget {
  const _VideoCertProgress({required this.progress});
  final TrainingVideoCertProgress progress;

  @override
  Widget build(BuildContext context) {
    final ratio = progress.required_ == 0 ? 0.0 : progress.approved / progress.required_;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push(StaffRoutes.videoCertification),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: dsCardDecoration(),
          child: Row(
            children: [
              const DsIconTile(Icons.videocam_rounded, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video certification',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio.clamp(0, 1).toDouble()),
                        duration: 900.ms,
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: AppColors.lightSurfaceVariant,
                          color: ratio >= 1 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DsPill('${progress.approved}/${progress.required_}', color: ratio >= 1 ? AppColors.success : AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});
  final TrainingMaterial material;

  @override
  Widget build(BuildContext context) {
    final (icon, color, sub) = switch (material.type) {
      TrainingMaterialType.pdf => (
          Icons.picture_as_pdf_rounded,
          AppColors.error,
          material.sizeBytes != null ? 'PDF · ${(material.sizeBytes! / 1024).round()} KB' : 'PDF',
        ),
      TrainingMaterialType.video => (Icons.play_circle_rounded, AppColors.primary, 'Video'),
      TrainingMaterialType.note => (Icons.sticky_note_2_rounded, AppColors.iconAccent, 'Note'),
    };
    return InkWell(
      onTap: () => context.push(StaffRoutes.trainingMaterial(material.id), extra: material),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            DsIconTile(icon, color: color, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                  ),
                  Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz});
  final TrainingQuiz quiz;

  @override
  Widget build(BuildContext context) {
    final r = quiz.lastResult;
    final note = quiz.rescheduleNote != null ? '\n${quiz.rescheduleNote}' : '';
    final (String subtitle, String? buttonLabel, VoidCallback? onPressed, Color color, IconData icon) = switch (quiz.state) {
      TrainingQuizState.locked => (
          'Opens on ${_prettyPlainDate(quiz.opensAt)}',
          null,
          null,
          AppColors.lightTextSecondary,
          Icons.lock_rounded,
        ),
      TrainingQuizState.scheduled => (
          'Retake on ${DateFormatter.timestamp(quiz.opensAt)}$note',
          null,
          null,
          AppColors.warning,
          Icons.event_repeat_rounded,
        ),
      TrainingQuizState.available => (
          '${quiz.questionCount} questions · ${quiz.totalPoints} marks · Pass ${quiz.passMarks}$note',
          'Start',
          () => context.push(StaffRoutes.trainingQuiz(quiz.id)),
          AppColors.primary,
          Icons.quiz_rounded,
        ),
      TrainingQuizState.inProgress => (
          'Continue where you left off',
          'Continue',
          () => context.push(StaffRoutes.trainingQuiz(quiz.id)),
          AppColors.primary,
          Icons.edit_note_rounded,
        ),
      TrainingQuizState.underReview => (
          'Submitted — trainer is checking your answers',
          null,
          null,
          AppColors.warning,
          Icons.hourglass_top_rounded,
        ),
      TrainingQuizState.passed => (
          'Passed · ${r?.score ?? 0}/${r?.maxScore ?? quiz.totalPoints}',
          'Result',
          () => context.push(StaffRoutes.trainingResult(r?.attemptId ?? quiz.attemptId ?? '')),
          AppColors.success,
          Icons.emoji_events_rounded,
        ),
      TrainingQuizState.failed => (
          '${r?.score ?? 0}/${r?.maxScore ?? quiz.totalPoints} — trainer will reschedule',
          'Result',
          () => context.push(StaffRoutes.trainingResult(r?.attemptId ?? quiz.attemptId ?? '')),
          AppColors.error,
          Icons.replay_rounded,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(border: color.withValues(alpha: 0.25)),
      child: Row(
        children: [
          DsIconTile(icon, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4, color: AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(width: 10),
            Material(
              color: color,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    buttonLabel,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Opens one piece of study material. There is no single-material fetch
/// endpoint, so [material] is expected to arrive via `extra` from the
/// training home list — if it's missing (e.g. a raw deep link), the screen
/// just points the user back to Training rather than guessing at content.
class StaffTrainingMaterialScreen extends StatelessWidget {
  const StaffTrainingMaterialScreen({super.key, required this.materialId, this.material});
  final String materialId;
  final TrainingMaterial? material;

  @override
  Widget build(BuildContext context) {
    final m = material;
    if (m == null) {
      return DsPage(
        title: 'Material',
        onBack: () => _back(context),
        body: [
          DsEmptyBlock(
            icon: Icons.search_off_rounded,
            title: 'Material not found',
            message: 'Open this from the Training screen.',
            action: DsGradientButton(
              label: 'Back to training',
              isExpanded: false,
              onPressed: () => context.go(StaffRoutes.training),
            ),
          ),
        ],
      );
    }
    if (m.type == TrainingMaterialType.note) {
      return DsPage(
        title: m.title,
        subtitle: 'Study note',
        onBack: () => _back(context),
        body: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: dsCardDecoration(),
            child: SelectableText(
              m.body ?? '',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.7, color: AppColors.lightTextPrimary),
            ),
          ),
        ],
      );
    }
    // PDF / video viewers need the full viewport (pinch + gestures).
    return Scaffold(
      backgroundColor: m.type == TrainingMaterialType.video ? const Color(0xFF0B1120) : AppColors.lightBackground,
      appBar: DsAppBar(
        title: m.title,
        subtitle: m.type == TrainingMaterialType.pdf ? 'PDF document' : 'Video lesson',
        showBack: true,
        onBack: () => _back(context),
        useGradient: m.type == TrainingMaterialType.video,
      ),
      body: SafeArea(
        top: false,
        child: m.type == TrainingMaterialType.pdf ? _PdfView(material: m) : _VideoView(material: m),
      ),
    );
  }
}

class _PdfView extends ConsumerStatefulWidget {
  const _PdfView({required this.material});
  final TrainingMaterial material;

  @override
  ConsumerState<_PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends ConsumerState<_PdfView> {
  PdfControllerPinch? _controller;
  String? _error;
  int _page = 1;
  int _pages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final url = widget.material.viewUrl;
    if (url == null) {
      setState(() => _error = 'No file attached to this material.');
      return;
    }
    final result = await ref.read(staffRepositoryProvider).downloadTrainingMaterial(url);
    if (!mounted) return;
    result.fold(
      onSuccess: (bytes) => setState(() {
        _controller = PdfControllerPinch(document: PdfDocument.openData(Uint8List.fromList(bytes)));
      }),
      onError: (f) => setState(() => _error = f.message),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.all(dsGutter(context)),
        child: Center(
          child: DsEmptyBlock(
            icon: Icons.picture_as_pdf_rounded,
            color: AppColors.error,
            title: 'Could not open PDF',
            message: _error!,
            action: DsGradientButton(label: 'Retry', icon: Icons.refresh_rounded, isExpanded: false, onPressed: _load),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        PdfViewPinch(
          controller: controller,
          onDocumentLoaded: (doc) => setState(() => _pages = doc.pagesCount),
          onPageChanged: (p) => setState(() => _page = p),
        ),
        if (_pages > 0)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page $_page of $_pages',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VideoView extends ConsumerStatefulWidget {
  const _VideoView({required this.material});
  final TrainingMaterial material;

  @override
  ConsumerState<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<_VideoView> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = widget.material.viewUrl;
    if (url == null) {
      setState(() => _error = 'No file attached to this material.');
      return;
    }
    final isAbsolute = url.startsWith('http://') || url.startsWith('https://');
    Uri uri;
    Map<String, String> headers = {};
    if (isAbsolute) {
      uri = Uri.parse(url);
    } else {
      uri = Uri.parse('${ApiConstants.apiOrigin}$url');
      final token = await ref.read(jwtTokenHandlerProvider).getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers = {ApiConstants.headerAuthorization: '${ApiConstants.bearerPrefix}$token'};
      }
    }
    final controller = VideoPlayerController.networkUrl(uri, httpHeaders: headers);
    try {
      await controller.initialize();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not play this video.');
      return;
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    controller.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _controller = controller..play());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.all(dsGutter(context)),
        child: Center(
          child: DsEmptyBlock(
            icon: Icons.videocam_off_rounded,
            color: AppColors.error,
            title: 'Could not play video',
            message: _error!,
            action: DsGradientButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              isExpanded: false,
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
            ),
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null) return const Center(child: CircularProgressIndicator(color: Colors.white));
    final playing = c.value.isPlaying;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dsGutter(context)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(c),
                GestureDetector(
                  onTap: () => playing ? c.pause() : c.play(),
                  child: AnimatedOpacity(
                    opacity: playing ? 0 : 1,
                    duration: 200.ms,
                    child: Container(
                      color: Colors.black38,
                      alignment: Alignment.center,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, size: 42, color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      Text(
                        _fmt(c.value.position),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VideoProgressIndicator(
                          c,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: AppColors.sunYellow,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmt(c.value.duration),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiz — MCQ questions render as option cards, TEXT questions as a free
/// text field. Submitting sends a list of answers keyed by the *attempt* id
/// (from `start`), never the quiz id.
class StaffQuizScreen extends ConsumerStatefulWidget {
  const StaffQuizScreen({super.key, required this.quizId});
  final String quizId;

  @override
  ConsumerState<StaffQuizScreen> createState() => _StaffQuizScreenState();
}

class _StaffQuizScreenState extends ConsumerState<StaffQuizScreen> {
  final Map<String, int> _selected = {};
  final Map<String, String> _text = {};
  bool _submitting = false;

  bool _answered(TrainingQuizQuestion q) =>
      q.type == TrainingQuestionType.mcq ? _selected.containsKey(q.id) : (_text[q.id]?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(staffQuizStartProvider(widget.quizId));
    final a = attempt.valueOrNull;
    final answered = a == null ? 0 : a.questions.where(_answered).length;
    final total = a?.questions.length ?? 0;

    return DsPage(
      title: 'Quiz',
      subtitle: a == null ? null : '$answered of $total answered',
      onBack: () => _back(context),
      bottom: a == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: total == 0 ? 0 : answered / total),
                    duration: 300.ms,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppColors.lightSurfaceVariant,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DsGradientButton(
                  label: 'Submit quiz',
                  icon: Icons.send_rounded,
                  isLoading: _submitting,
                  onPressed: _submitting ? null : () => _submit(a),
                ),
              ],
            ),
      body: dsAsyncBody(
        attempt,
        onRetry: () => ref.invalidate(staffQuizStartProvider(widget.quizId)),
        builder: (a) => [
          for (var i = 0; i < a.questions.length; i++) _questionCard(i, a.questions[i]),
        ],
      ),
    );
  }

  Widget _questionCard(int i, TrainingQuizQuestion q) {
    final done = _answered(q);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(border: done ? AppColors.primary.withValues(alpha: 0.3) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: 200.ms,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : AppColors.iconAccentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: done ? Colors.white : AppColors.iconAccent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  q.questionText,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.4, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(width: 8),
              DsPill('${q.points} pt${q.points == 1 ? '' : 's'}'),
            ],
          ),
          const SizedBox(height: 12),
          if (q.type == TrainingQuestionType.mcq)
            for (var oi = 0; oi < (q.options ?? []).length; oi++)
              _OptionTile(
                letter: String.fromCharCode(65 + oi),
                label: q.options![oi],
                selected: _selected[q.id] == oi,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected[q.id] = oi);
                },
              )
          else
            TextField(
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(hintText: 'Type your answer…'),
              onChanged: (v) => setState(() => _text[q.id] = v),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(QuizAttemptStart attempt) async {
    final unanswered = attempt.questions.where((q) => !_answered(q)).length;
    if (unanswered > 0) {
      final proceed = await DsConfirmationDialog.show(
        context: context,
        title: 'Unanswered questions',
        message: '$unanswered question${unanswered == 1 ? '' : 's'} left blank will be marked wrong. Submit anyway?',
        confirmLabel: 'Submit anyway',
        cancelLabel: 'Go back',
        icon: Icons.help_rounded,
      );
      if (proceed != true) return;
    }

    setState(() => _submitting = true);
    final answers = [
      for (final q in attempt.questions)
        TrainingQuizAnswer(
          questionId: q.id,
          selectedOption: q.type == TrainingQuestionType.mcq ? _selected[q.id] : null,
          answerText: q.type == TrainingQuestionType.text ? _text[q.id] : null,
        ),
    ];
    final result = await ref.read(staffRepositoryProvider).submitQuizAttempt(attempt.attemptId, answers);
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (r) {
        ref.invalidate(staffTrainingHomeProvider);
        context.pushReplacement(StaffRoutes.trainingResult(r.attemptId));
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.letter, required this.label, required this.selected, required this.onTap});
  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.07) : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.6),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 200.ms,
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.lightBorder),
              ),
              child: Text(
                letter,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiz result — keyed by attempt id. While still under review this shows a
/// waiting state instead of scores (the endpoint returns no questions yet).
class StaffTrainingResultScreen extends ConsumerWidget {
  const StaffTrainingResultScreen({super.key, required this.attemptId});
  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(staffQuizResultProvider(attemptId));

    return DsPage(
      title: 'Quiz result',
      onBack: () => context.go(StaffRoutes.training),
      onRefresh: () async => ref.invalidate(staffQuizResultProvider(attemptId)),
      bottom: DsOutlineButton(
        label: 'Back to training',
        icon: Icons.school_rounded,
        onPressed: () => context.go(StaffRoutes.training),
      ),
      body: dsAsyncBody(
        result,
        onRetry: () => ref.invalidate(staffQuizResultProvider(attemptId)),
        builder: (r) {
          if (r.state == TrainingQuizState.underReview) {
            return const [
              DsEmptyBlock(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                title: 'Submitted',
                message: 'Your trainer is checking your answers. You\'ll be notified once it\'s graded.',
              ),
            ];
          }
          final passed = r.passed ?? false;
          final score = r.score ?? 0;
          final correct = r.questions.where((q) => q.correct).length;
          return [
            DsGradientCard(
              colors: passed ? DsGradientCard.green : DsGradientCard.red,
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.emoji_events_rounded : Icons.replay_circle_filled_rounded,
                    size: 64,
                    color: passed ? AppColors.sunYellow : Colors.white,
                  ).animate().scaleXY(begin: 0.3, end: 1, duration: 700.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 10),
                  Text(
                    r.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    passed ? 'Congratulations, you passed!' : 'Not this time — your trainer will reschedule',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: DsGlassStat(value: '$score/${r.maxScore}', label: 'Score', icon: Icons.star_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: DsGlassStat(value: '${r.passMarks}', label: 'Pass mark', icon: Icons.flag_rounded)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DsGlassStat(value: '$correct/${r.questions.length}', label: 'Correct', icon: Icons.check_circle_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (r.questions.isNotEmpty) const DsSection('Your answers'),
            for (final q in r.questions) _ResultQuestionTile(question: q),
          ];
        },
      ),
    );
  }
}

class _ResultQuestionTile extends StatelessWidget {
  const _ResultQuestionTile({required this.question});
  final QuizResultQuestion question;

  @override
  Widget build(BuildContext context) {
    final color = question.correct ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20, border: color.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(question.correct ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question.questionText,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(width: 8),
              DsPill('${question.pointsAwarded}/${question.points}', color: color),
            ],
          ),
          if (question.type == TrainingQuestionType.mcq && question.options != null) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < question.options!.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: i == question.yourSelectedOption ? color.withValues(alpha: 0.08) : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      i == question.yourSelectedOption ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: i == question.yourSelectedOption ? color : AppColors.lightTextHint,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.options![i],
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.lightTextPrimary),
                      ),
                    ),
                    if (i == question.yourSelectedOption)
                      Text('Your answer', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
              ),
          ] else if (question.yourAnswerText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lightBackground, borderRadius: BorderRadius.circular(12)),
              child: Text(
                question.yourAnswerText!,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.lightTextPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
