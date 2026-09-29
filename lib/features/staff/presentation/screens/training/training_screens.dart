import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import '../../widgets/staff_scaffold.dart';

const _kBg = Color(0xFFFBF9F8);
const _kPrimary = Color(0xFF1A56FF);
const _kInk = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kHairline = Color(0xFFF1F5F9);

TextStyle _serif({required double size, FontWeight weight = FontWeight.w600, Color color = _kInk}) =>
    GoogleFonts.libreCaslonText(fontSize: size, fontWeight: weight, color: color);

TextStyle _sans({required double size, FontWeight weight = FontWeight.w400, Color color = _kMuted}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

/// Reformats a plain `YYYY-MM-DD` date for display without ever going
/// through [DateTime] — parsing a date-only string as UTC (or accidentally
/// treating it as one) can shift the displayed day depending on the device's
/// timezone, so this only ever does string surgery.
String _prettyPlainDate(String? ymd) {
  if (ymd == null || ymd.isEmpty) return '';
  final parts = ymd.split('-');
  if (parts.length != 3) return ymd;
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null || month < 1 || month > 12) return ymd;
  return '$day ${months[month]} ${parts[0]}';
}

AppBar _trainingAppBar(BuildContext context, String title) => AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kPrimary),
        onPressed: () {
          if (context.canPop()) context.pop();
        },
      ),
      centerTitle: true,
      title: Text(title, style: _serif(size: 20, color: _kPrimary)),
    );

/// Training home — study material + quizzes for every batch the staff member
/// is (or was) enrolled in. Stays reachable regardless of pipeline stage,
/// since a rescheduled quiz can arrive after the staff has moved on.
class StaffTrainingScreen extends ConsumerWidget {
  const StaffTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(staffTrainingHomeProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _trainingAppBar(context, 'Training'),
      body: home.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Could not load training',
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(staffTrainingHomeProvider),
        ),
        data: (h) {
          if (h.batches.isEmpty) {
            return const DsEmptyState(
              icon: Icons.school_outlined,
              title: 'No training yet',
              message: 'Your trainer hasn\'t added you to a batch yet. Check back soon.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffTrainingHomeProvider),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                Text('Mandatory Training', style: _serif(size: 26)),
                const SizedBox(height: 8),
                Text(
                  'Study your batch material and complete each quiz to stay on track.',
                  style: _sans(size: 14, color: _kMuted).copyWith(height: 1.5),
                ),
                if (h.videoCert.required_ > 0) ...[
                  const SizedBox(height: 20),
                  _VideoCertProgressBar(progress: h.videoCert),
                ],
                const SizedBox(height: 24),
                for (final batch in h.batches) _BatchSection(batch: batch),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VideoCertProgressBar extends StatelessWidget {
  const _VideoCertProgressBar({required this.progress});
  final TrainingVideoCertProgress progress;

  @override
  Widget build(BuildContext context) {
    final ratio = progress.required_ == 0 ? 0.0 : progress.approved / progress.required_;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.videocam_outlined, size: 16, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                'Video certification ${progress.approved}/${progress.required_} approved',
                style: _sans(size: 12, weight: FontWeight.w600, color: _kInk),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchSection extends StatelessWidget {
  const _BatchSection({required this.batch});
  final TrainingBatch batch;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(batch.batchCode, style: _sans(size: 10, weight: FontWeight.w700, color: const Color(0xFF94A3B8)).copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(
            [batch.trainerName, if (batch.classroom != null) batch.classroom!].where((s) => s.isNotEmpty).join(' · '),
            style: _serif(size: 18),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: _kMuted),
              const SizedBox(width: 6),
              Text(
                '${_prettyPlainDate(batch.startDate)} – ${_prettyPlainDate(batch.endDate)}',
                style: _sans(size: 12),
              ),
            ],
          ),
          if (batch.materials.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('STUDY MATERIAL', style: _sans(size: 10, weight: FontWeight.w700, color: const Color(0xFF94A3B8)).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 8),
            for (final m in batch.materials) _MaterialTile(material: m),
          ],
          if (batch.quizzes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('QUIZZES', style: _sans(size: 10, weight: FontWeight.w700, color: const Color(0xFF94A3B8)).copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 8),
            for (final q in batch.quizzes) _QuizCard(quiz: q),
          ],
        ],
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});
  final TrainingMaterial material;

  ({IconData icon, Color color}) get _style => switch (material.type) {
        TrainingMaterialType.pdf => (icon: Icons.picture_as_pdf_outlined, color: const Color(0xFFDC2626)),
        TrainingMaterialType.video => (icon: Icons.play_circle_outline, color: _kPrimary),
        TrainingMaterialType.note => (icon: Icons.description_outlined, color: const Color(0xFF475569)),
      };

  String get _subtitle => switch (material.type) {
        TrainingMaterialType.pdf =>
          material.sizeBytes != null ? '${(material.sizeBytes! / 1024).round()} KB' : 'PDF',
        TrainingMaterialType.video => 'Video',
        TrainingMaterialType.note => 'Note',
      };

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return InkWell(
      onTap: () => context.push(StaffRoutes.trainingMaterial(material.id), extra: material),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: s.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(s.icon, size: 18, color: s.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.title, style: _sans(size: 13, weight: FontWeight.w600, color: _kInk)),
                  Text(_subtitle, style: _sans(size: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
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
    final (String subtitle, String? buttonLabel, VoidCallback? onPressed) = switch (quiz.state) {
      TrainingQuizState.locked => ('Quiz opens on ${_prettyPlainDate(quiz.opensAt)}', null, null),
      TrainingQuizState.scheduled => (
          'Retake on ${DateFormatter.timestamp(quiz.opensAt)}${quiz.rescheduleNote != null ? '\n${quiz.rescheduleNote}' : ''}',
          null,
          null,
        ),
      TrainingQuizState.available => (
          '${quiz.questionCount} questions · ${quiz.totalPoints} marks · Pass ${quiz.passMarks}'
              '${quiz.rescheduleNote != null ? '\n${quiz.rescheduleNote}' : ''}',
          'Start',
          () => context.push(StaffRoutes.trainingQuiz(quiz.id)),
        ),
      TrainingQuizState.inProgress => (
          'Continue your quiz',
          'Continue',
          () => context.push(StaffRoutes.trainingQuiz(quiz.id)),
        ),
      TrainingQuizState.underReview => ('Submitted — trainer is checking your answers', null, null),
      TrainingQuizState.passed => (
          'Passed · ${r?.score ?? 0}/${r?.maxScore ?? quiz.totalPoints}',
          'View result',
          () => context.push(StaffRoutes.trainingResult(r?.attemptId ?? quiz.attemptId ?? '')),
        ),
      TrainingQuizState.failed => (
          '${r?.score ?? 0}/${r?.maxScore ?? quiz.totalPoints} — trainer will reschedule',
          'View result',
          () => context.push(StaffRoutes.trainingResult(r?.attemptId ?? quiz.attemptId ?? '')),
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: _kHairline)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title, style: _sans(size: 13, weight: FontWeight.w600, color: _kInk)),
                const SizedBox(height: 4),
                Text(subtitle, style: _sans(size: 11).copyWith(height: 1.4)),
              ],
            ),
          ),
          if (buttonLabel != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                minimumSize: const Size(0, 34),
              ),
              child: Text(buttonLabel, style: _sans(size: 12, weight: FontWeight.w600, color: Colors.white)),
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
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _trainingAppBar(context, m?.title ?? 'Material'),
      body: m == null
          ? DsErrorState(
              title: 'Material not found',
              message: 'Open this from the Training screen.',
              onRetry: () => context.go(StaffRoutes.training),
              retryLabel: 'Back to Training',
            )
          : switch (m.type) {
              TrainingMaterialType.note => _NoteView(material: m),
              TrainingMaterialType.pdf => _PdfView(material: m),
              TrainingMaterialType.video => _VideoView(material: m),
            },
    );
  }
}

class _NoteView extends StatelessWidget {
  const _NoteView({required this.material});
  final TrainingMaterial material;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        material.body ?? '',
        style: _sans(size: 15, color: _kInk).copyWith(height: 1.7),
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
    final result = await ref.read(staffRepositoryProvider).downloadTrainingMaterial(url);
    if (!mounted) return;
    result.fold(
      onSuccess: (bytes) {
        setState(() {
          _controller = PdfControllerPinch(document: PdfDocument.openData(Uint8List.fromList(bytes)));
        });
      },
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
      return DsErrorState(title: 'Could not open PDF', message: _error, onRetry: _load);
    }
    final controller = _controller;
    if (controller == null) return const DsLoadingWidget();
    return PdfViewPinch(controller: controller);
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
    setState(() => _controller = controller..play());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return DsErrorState(title: 'Could not play video', message: _error, onRetry: () {
        setState(() => _error = null);
        _load();
      });
    }
    final controller = _controller;
    if (controller == null) return const DsLoadingWidget();
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(controller),
            GestureDetector(
              onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
              child: AnimatedOpacity(
                opacity: controller.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black26,
                  child: const Icon(Icons.play_arrow_rounded, size: 56, color: Colors.white),
                ),
              ),
            ),
            VideoProgressIndicator(controller, allowScrubbing: true, padding: const EdgeInsets.all(8)),
          ],
        ),
      ),
    );
  }
}

/// A quiz — MCQ questions render as radio options, TEXT questions as a free
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

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(staffQuizStartProvider(widget.quizId));

    return StaffPageScaffold(
      title: 'Quiz',
      body: attempt.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Quiz unavailable',
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(staffQuizStartProvider(widget.quizId)),
        ),
        data: (a) => Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(AppSpacing.lg),
                itemCount: a.questions.length,
                itemBuilder: (_, i) {
                  final q = a.questions[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${q.questionText}  (${q.points} pt${q.points == 1 ? '' : 's'})',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        if (q.type == TrainingQuestionType.mcq)
                          ...List.generate((q.options ?? []).length, (oi) {
                            return RadioListTile<int>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(q.options![oi]),
                              value: oi,
                              groupValue: _selected[q.id],
                              onChanged: (v) => setState(() => _selected[q.id] = v!),
                            );
                          })
                        else
                          TextField(
                            minLines: 3,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: 'Type your answer…',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => _text[q.id] = v,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: DsPrimaryButton(
                label: 'Submit Quiz',
                isLoading: _submitting,
                onPressed: _submitting ? null : () => _submit(a),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(QuizAttemptStart attempt) async {
    final unanswered = attempt.questions.where((q) => q.type == TrainingQuestionType.mcq
        ? !_selected.containsKey(q.id)
        : (_text[q.id]?.trim().isEmpty ?? true));

    if (unanswered.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unanswered questions'),
          content: Text(
            '${unanswered.length} question${unanswered.length == 1 ? '' : 's'} left blank will be marked wrong. Submit anyway?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Go back')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Submit anyway')),
          ],
        ),
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

/// Quiz result — keyed by attempt id. While still under review this shows a
/// waiting state instead of scores (the endpoint returns no questions yet).
class StaffTrainingResultScreen extends ConsumerWidget {
  const StaffTrainingResultScreen({super.key, required this.attemptId});
  final String attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(staffQuizResultProvider(attemptId));

    return StaffPageScaffold(
      title: 'Quiz Result',
      showBack: false,
      body: result.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Could not load result',
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(staffQuizResultProvider(attemptId)),
        ),
        data: (r) {
          if (r.state == TrainingQuizState.underReview) {
            return DsEmptyState(
              icon: Icons.hourglass_top_rounded,
              title: 'Submitted',
              message: 'Trainer is checking your answers. You\'ll be notified once it\'s graded.',
              actionLabel: 'Back to Training',
              onAction: () => context.go(StaffRoutes.training),
            );
          }
          final passed = r.passed ?? false;
          return ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(
                      passed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                      size: 72,
                      color: passed ? AppColors.success : AppColors.error,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(r.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      passed ? 'Passed' : 'Not this time — trainer will reschedule',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('${r.score ?? 0}/${r.maxScore} · Pass mark ${r.passMarks}'),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              for (final q in r.questions) _ResultQuestionTile(question: q),
              SizedBox(height: AppSpacing.md),
              DsOutlineButton(label: 'Back to Training', onPressed: () => context.go(StaffRoutes.training)),
            ],
          );
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
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                question.correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18,
                color: question.correct ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(question.questionText, style: _sans(size: 13, weight: FontWeight.w600, color: _kInk))),
              Text('${question.pointsAwarded}/${question.points}', style: _sans(size: 12, weight: FontWeight.w600)),
            ],
          ),
          if (question.type == TrainingQuestionType.mcq && question.options != null) ...[
            const SizedBox(height: 8),
            for (var i = 0; i < question.options!.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      i == question.yourSelectedOption ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 16,
                      color: i == question.yourSelectedOption ? _kPrimary : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(question.options![i], style: _sans(size: 12))),
                  ],
                ),
              ),
          ] else if (question.yourAnswerText != null) ...[
            const SizedBox(height: 8),
            Text('Your answer: ${question.yourAnswerText}', style: _sans(size: 12).copyWith(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
