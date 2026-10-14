import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/utils/file_hash.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

(Color, IconData, String) _statusStyle(VideoCertStatus s) => switch (s) {
      VideoCertStatus.approved => (AppColors.success, Icons.verified_rounded, 'Approved'),
      VideoCertStatus.uploaded => (AppColors.primary, Icons.hourglass_top_rounded, 'Under review'),
      VideoCertStatus.rejected => (AppColors.error, Icons.replay_rounded, 'Rejected'),
      VideoCertStatus.pending => (AppColors.warning, Icons.videocam_rounded, 'To record'),
    };

String _fmt(Duration d) =>
    '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

void _back(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(StaffRoutes.videoCertification);

/// Small step indicator ("Record → Preview → Upload") for the flow screens.
class _FlowSteps extends StatelessWidget {
  const _FlowSteps({required this.current});
  final int current; // 0..2

  @override
  Widget build(BuildContext context) {
    const labels = ['Record', 'Preview', 'Upload'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.primary : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: i <= current ? AppColors.primary : AppColors.lightBorder, width: 2),
                ),
                child: i < current
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: i <= current ? Colors.white : AppColors.lightTextSecondary,
                        ),
                      ),
              ),
              const SizedBox(width: 5),
              Text(
                labels[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: i == current ? FontWeight.w800 : FontWeight.w600,
                  color: i <= current ? AppColors.primary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Video certification prompt list.
class StaffVideoCertificationScreen extends ConsumerWidget {
  const StaffVideoCertificationScreen({super.key});

  void _startNext(BuildContext context, WidgetRef ref, List<VideoCertPrompt> list) {
    // Only a prompt that hasn't been uploaded/approved yet is eligible to
    // (re-)record — if everything left is already uploaded/approved there is
    // nothing to do, so don't fall back to re-recording a submitted prompt.
    final next = list
        .where((p) => p.status != VideoCertStatus.approved && p.status != VideoCertStatus.uploaded)
        .firstOrNull;
    if (next == null) {
      context.showDsSnackBar('All videos are already recorded and under review', type: DsSnackBarType.warning);
      return;
    }
    final localFile = ref.read(staffVideoCertLocalRecordingsProvider)[next.id];
    if (localFile != null) {
      context.push('${StaffRoutes.videoCertPreview}?promptId=${next.id}', extra: localFile);
    } else {
      context.push('${StaffRoutes.videoCertRecord}?promptId=${next.id}&title=${Uri.encodeComponent(next.title)}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(staffVideoCertProvider);
    final list = prompts.valueOrNull;
    final allApproved = list != null && list.isNotEmpty && list.every((p) => p.status == VideoCertStatus.approved);

    return DsPage(
      title: 'Video certification',
      subtitle: 'Show your skills on camera',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.profile),
      onRefresh: () => ref.refresh(staffVideoCertProvider.future),
      bottom: list == null || list.isEmpty || allApproved
          ? null
          : DsGradientButton(
              label: 'Start recording',
              icon: Icons.videocam_rounded,
              onPressed: () => _startNext(context, ref, list),
            ),
      body: dsAsyncBody(
        prompts,
        onRetry: () => ref.invalidate(staffVideoCertProvider),
        builder: (list) {
          final approved = list.where((p) => p.status == VideoCertStatus.approved).length;
          final review = list.where((p) => p.status == VideoCertStatus.uploaded).length;
          return [
            DsGradientCard(
              colors: allApproved ? DsGradientCard.green : DsGradientCard.blue,
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: list.isEmpty ? 0 : approved / list.length),
                      duration: 1000.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: AppColors.sunYellow,
                            ),
                          ),
                          Text(
                            '$approved/${list.length}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsGlassPill(allApproved ? 'CERTIFIED' : 'IN PROGRESS', icon: Icons.verified_rounded),
                        const SizedBox(height: 10),
                        Text(
                          allApproved ? 'You\'re fully certified!' : 'Record ${list.length} short videos',
                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        if (review > 0)
                          Text(
                            '$review under review',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DsSection('Videos', trailing: DsPill('${list.length}')),
            if (list.isEmpty)
              const DsEmptyBlock(
                icon: Icons.videocam_off_rounded,
                title: 'No videos required',
                message: 'Your Relationship Manager hasn\'t assigned any video prompts yet.',
              )
            else
              for (var i = 0; i < list.length; i++) _PromptCard(prompt: list[i], index: i),
            const SizedBox(height: 4),
            const DsNote(
              title: 'Tips for faster approval',
              text: 'Record in good light, keep the phone steady and speak clearly. Each video should follow its prompt.',
            ),
          ];
        },
      ),
    );
  }
}

class _PromptCard extends ConsumerWidget {
  const _PromptCard({required this.prompt, required this.index});
  final VideoCertPrompt prompt;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon, label) = _statusStyle(prompt.status);
    // A recording already on-device (recorded but not uploaded) shows the
    // pending upload instead of a record action.
    final localFile = ref.watch(staffVideoCertLocalRecordingsProvider)[prompt.id];
    final pendingUpload = localFile != null &&
        prompt.status != VideoCertStatus.uploaded &&
        prompt.status != VideoCertStatus.approved;

    final (String? actionLabel, IconData actionIcon, VoidCallback? onTap, Color actionColor) = switch (prompt.status) {
      VideoCertStatus.approved => (null, Icons.check_rounded, null, AppColors.success),
      // `uploaded` = submitted and awaiting review — surface that instead of
      // a re-upload action so staff can't fire off a second submission.
      VideoCertStatus.uploaded => (
          'View status',
          Icons.chevron_right_rounded,
          () => context.push(StaffRoutes.videoCertStatus(prompt.id)),
          AppColors.primary,
        ),
      _ when localFile != null => (
          'Finish upload',
          Icons.cloud_upload_rounded,
          () => context.push('${StaffRoutes.videoCertPreview}?promptId=${prompt.id}', extra: localFile),
          AppColors.success,
        ),
      _ => (
          prompt.status == VideoCertStatus.rejected ? 'Re-record' : 'Record now',
          Icons.videocam_rounded,
          () => context.push(
                '${StaffRoutes.videoCertRecord}?promptId=${prompt.id}&title=${Uri.encodeComponent(prompt.title)}',
              ),
          AppColors.primary,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(border: color.withValues(alpha: 0.25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.iconAccentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.iconAccent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prompt.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(width: 8),
              if (pendingUpload)
                const DsPill('Recorded', color: AppColors.success, icon: Icons.cloud_upload_rounded)
              else
                DsPill(label, color: color, icon: icon),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prompt.instructions,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: const Color(0xFF374151)),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: actionColor.withValues(alpha: 0.1),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionIcon, size: 17, color: actionColor),
                        const SizedBox(width: 6),
                        Text(
                          actionLabel,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: actionColor),
                        ),
                      ],
                    ),
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

/// Record video screen.
class StaffRecordVideoScreen extends ConsumerStatefulWidget {
  const StaffRecordVideoScreen({super.key, this.promptId, this.title});

  final String? promptId;
  final String? title;

  @override
  ConsumerState<StaffRecordVideoScreen> createState() => _StaffRecordVideoScreenState();
}

class _StaffRecordVideoScreenState extends ConsumerState<StaffRecordVideoScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _initializing = true;
  String? _error;
  bool _isRecording = false;
  bool _isTogglingRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_isPromptAlreadyHandled()) {
      // Reached this route for a prompt that's already been recorded
      // (locally, pending upload) or already submitted/approved — bounce
      // back instead of letting the camera open and allow a duplicate
      // recording/upload for the same prompt.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.showDsSnackBar(
          'This video is already recorded. Complete the upload or check its status instead.',
          type: DsSnackBarType.warning,
        );
        _back(context);
      });
      return;
    }
    _initCamera();
  }

  bool _isPromptAlreadyHandled() {
    final promptId = widget.promptId;
    if (promptId == null) return false;
    final prompts = ref.read(staffVideoCertProvider).valueOrNull;
    final prompt = prompts?.where((p) => p.id == promptId).firstOrNull;
    final alreadySubmitted =
        prompt != null && (prompt.status == VideoCertStatus.uploaded || prompt.status == VideoCertStatus.approved);
    final alreadyRecordedLocally = ref.read(staffVideoCertLocalRecordingsProvider).containsKey(promptId);
    return alreadySubmitted || alreadyRecordedLocally;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device.';
        });
        return;
      }
      // Prefer the front camera for a self-recorded certification video.
      final frontIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = frontIndex != -1 ? frontIndex : 0;
      await _startController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      setState(() {
        _initializing = false;
        _error = e.description ?? 'Unable to access the camera.';
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _error = 'Unable to access the camera.';
      });
    }
  }

  Future<void> _startController(CameraDescription description) async {
    final controller = CameraController(description, ResolutionPreset.high, enableAudio: true);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _initializing = false;
      _error = null;
    });
  }

  Future<void> _flipCamera() async {
    if (_isRecording || _cameras.length < 2) return;
    HapticFeedback.selectionClick();
    final oldController = _controller;
    setState(() {
      _controller = null;
      _initializing = true;
    });
    await oldController?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _startController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      setState(() {
        _initializing = false;
        _error = e.description ?? 'Unable to access the camera.';
      });
    }
  }

  Future<void> _toggleRecording() async {
    // Guards against a rapid double-tap firing two overlapping start/stop
    // calls on the same controller — which could otherwise stop the
    // recording twice and push two preview/upload screens for one video.
    if (_isTogglingRecording) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    HapticFeedback.mediumImpact();

    _isTogglingRecording = true;
    try {
      if (_isRecording) {
        try {
          final file = await controller.stopVideoRecording();
          _timer?.cancel();
          setState(() {
            _isRecording = false;
            _elapsed = Duration.zero;
          });
          if (!mounted) return;
          final promptId = widget.promptId;
          if (promptId != null) {
            ref.read(staffVideoCertLocalRecordingsProvider.notifier).update((state) => {...state, promptId: file});
          }
          context.push('${StaffRoutes.videoCertPreview}?promptId=${widget.promptId}', extra: file);
        } on CameraException catch (e) {
          context.showDsSnackBar(e.description ?? 'Failed to stop recording', type: DsSnackBarType.error);
        }
        return;
      }

      try {
        await controller.startVideoRecording();
        setState(() {
          _isRecording = true;
          _elapsed = Duration.zero;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() => _elapsed += const Duration(seconds: 1));
        });
      } on CameraException catch (e) {
        if (!mounted) return;
        context.showDsSnackBar(e.description ?? 'Failed to start recording', type: DsSnackBarType.error);
      }
    } finally {
      _isTogglingRecording = false;
    }
  }

  Widget _buildCameraBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: Colors.white),
              ),
              const SizedBox(height: 16),
              DsHeroPillButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: _initCamera),
            ],
          ),
        ),
      );
    }
    final controller = _controller;
    if (_initializing || controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.previewSize?.height ?? 1,
        height: controller.value.previewSize?.width ?? 1,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = dsGutter(context);
    final ready = !_initializing && _error == null;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: DsAppBar(
        title: 'Record video',
        subtitle: widget.title ?? 'Service demonstration',
        showBack: true,
        onBack: _isRecording ? null : () => _back(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FlowSteps(current: 0),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF0B1120),
                    border: Border.all(
                      color: _isRecording ? AppColors.error : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(color: AppColors.navy.withValues(alpha: 0.25), blurRadius: 28, offset: const Offset(0, 14)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildCameraBody()),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isRecording ? AppColors.error : Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ).animate(target: _isRecording ? 1 : 0, onPlay: (c) => c.repeat(reverse: true)).fade(begin: 1, end: 0.3),
                              const SizedBox(width: 6),
                              Text(
                                _isRecording ? _fmt(_elapsed) : 'PREVIEW',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_cameras.length > 1)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Flip camera',
                              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                              onPressed: _isRecording ? null : _flipCamera,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DsPill('Audio on', icon: Icons.mic_rounded),
                  const SizedBox(width: 8),
                  const DsPill('HD quality', icon: Icons.hd_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: GestureDetector(
                  onTap: ready ? _toggleRecording : null,
                  child: AnimatedContainer(
                    duration: 250.ms,
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _isRecording ? AppColors.error : AppColors.primary, width: 4),
                    ),
                    child: AnimatedContainer(
                      duration: 250.ms,
                      decoration: BoxDecoration(
                        color: !ready
                            ? AppColors.lightBorder
                            : (_isRecording ? AppColors.error : AppColors.primary),
                        borderRadius: BorderRadius.circular(_isRecording ? 12 : 40),
                      ),
                      margin: EdgeInsets.all(_isRecording ? 14 : 0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isRecording ? 'Tap to stop' : 'Tap to record',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Video preview before upload.
class StaffVideoPreviewScreen extends StatefulWidget {
  const StaffVideoPreviewScreen({super.key, this.promptId, this.videoFile});

  final String? promptId;
  final XFile? videoFile;

  @override
  State<StaffVideoPreviewScreen> createState() => _StaffVideoPreviewScreenState();
}

class _StaffVideoPreviewScreenState extends State<StaffVideoPreviewScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final file = widget.videoFile;
    if (file != null) {
      // On web, camera/video_player never expose a filesystem path — the
      // recorded file comes back as a blob: URL, so dart:io's File (and its
      // Platform check) must be avoided there.
      final controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(file.path))
          : VideoPlayerController.file(File(file.path));
      _controller = controller;
      controller.addListener(() {
        if (mounted) setState(() {});
      });
      controller.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = dsGutter(context);
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: DsAppBar(
        title: 'Preview',
        subtitle: 'Check your video before uploading',
        showBack: true,
        onBack: () => _back(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _FlowSteps(current: 1),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: const Color(0xFF0B1120),
                    boxShadow: [
                      BoxShadow(color: AppColors.navy.withValues(alpha: 0.25), blurRadius: 28, offset: const Offset(0, 14)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (isReady)
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.size.width,
                              height: controller.value.size.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        )
                      else if (widget.videoFile == null)
                        Center(
                          child: Text(
                            'No recording found',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white),
                          ),
                        )
                      else
                        const Center(child: CircularProgressIndicator(color: Colors.white)),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'RECORDED',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isReady)
                        Center(
                          child: GestureDetector(
                            onTap: _togglePlayback,
                            child: AnimatedOpacity(
                              duration: 200.ms,
                              opacity: controller.value.isPlaying ? 0.0 : 1.0,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 42),
                              ),
                            ),
                          ),
                        ),
                      if (isReady)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Row(
                            children: [
                              Text(
                                _fmt(controller.value.position),
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: VideoProgressIndicator(
                                  controller,
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
                                _fmt(controller.value.duration),
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DsOutlineButton(
                      label: 'Re-record',
                      icon: Icons.videocam_rounded,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DsGradientButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: widget.videoFile == null
                          ? null
                          : () => context.push(
                                '${StaffRoutes.videoCertUpload}?promptId=${widget.promptId}',
                                extra: widget.videoFile,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Upload video screen.
class StaffVideoUploadScreen extends ConsumerStatefulWidget {
  const StaffVideoUploadScreen({super.key, this.promptId, this.recordedFile});

  final String? promptId;
  final XFile? recordedFile;

  @override
  ConsumerState<StaffVideoUploadScreen> createState() => _StaffVideoUploadScreenState();
}

class _StaffVideoUploadScreenState extends ConsumerState<StaffVideoUploadScreen> {
  bool _uploading = false;
  double? _progress;
  PlatformFile? _pickedFile;
  bool _preparingRecordedFile = false;

  @override
  void initState() {
    super.initState();
    final recordedFile = widget.recordedFile;
    if (recordedFile != null) {
      _preparingRecordedFile = true;
      _loadRecordedFile(recordedFile);
    }
  }

  Future<void> _loadRecordedFile(XFile recordedFile) async {
    PlatformFile platformFile;
    // On web, PlatformFile needs in-memory bytes — a filesystem path isn't
    // usable there (same constraint file_picker has, see `_pickVideo` below).
    if (kIsWeb) {
      final bytes = await recordedFile.readAsBytes();
      platformFile = PlatformFile(name: recordedFile.name, size: bytes.length, bytes: bytes);
    } else {
      final file = File(recordedFile.path);
      platformFile = PlatformFile(
        path: recordedFile.path,
        name: recordedFile.name,
        size: file.existsSync() ? file.lengthSync() : 0,
      );
    }
    if (!mounted) return;
    setState(() {
      _pickedFile = platformFile;
      _preparingRecordedFile = false;
    });
  }

  Future<void> _pickVideo() async {
    // On web, file_picker never exposes a filesystem path — only in-memory
    // bytes — so `withData` must be forced there or the file is unusable.
    final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: kIsWeb);
    if (result != null) setState(() => _pickedFile = result.files.first);
  }

  Future<void> _upload() async {
    if (widget.promptId == null) return;
    final file = _pickedFile;
    if (file == null) {
      context.showDsSnackBar('Please select a video', type: DsSnackBarType.warning);
      return;
    }
    if (file.size > kMaxVideoCertBytes) {
      context.showDsSnackBar('Video is too large. Maximum size is 500 MB.', type: DsSnackBarType.warning);
      return;
    }
    setState(() {
      _uploading = true;
      _progress = null;
    });
    final result = await ref.read(staffRepositoryProvider).uploadVideoCert(
          widget.promptId!,
          file,
          onProgress: (sent, total) {
            if (!mounted || total <= 0) return;
            setState(() => _progress = sent / total);
          },
        );
    if (!mounted) return;
    setState(() => _uploading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffVideoCertProvider);
        ref.read(staffVideoCertLocalRecordingsProvider.notifier).update((state) => {...state}..remove(widget.promptId));
        ref.read(staffVideoCertSubmittedAtProvider.notifier).update(
              (state) => {...state, widget.promptId!: DateTime.now()},
            );
        context.showDsSnackBar('Video uploaded', type: DsSnackBarType.success);
        context.push(StaffRoutes.videoCertStatus(widget.promptId!));
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = _pickedFile;
    final pct = _progress == null ? null : (_progress! * 100).round();

    return PopScope(
      canPop: !_uploading,
      child: DsPage(
        title: 'Upload video',
        subtitle: 'Send it for review',
        onBack: _uploading ? () {} : () => _back(context),
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsGradientButton(
              label: _uploading ? 'Uploading…' : 'Upload for review',
              icon: Icons.cloud_upload_rounded,
              isLoading: _uploading,
              onPressed: (_uploading || _preparingRecordedFile || file == null) ? null : _upload,
            ),
            TextButton(
              onPressed: _uploading ? null : () => _back(context),
              child: Text(
                'Cancel and discard',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
        body: [
          const _FlowSteps(current: 2),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: _uploading ? (_progress ?? 0.0) : (file == null ? 0.0 : 1.0)),
                      duration: 300.ms,
                      builder: (_, v, _) => CircularProgressIndicator(
                        value: _uploading && _progress == null ? null : v,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.lightBorder,
                        color: _uploading ? AppColors.primary : AppColors.success,
                      ),
                    ),
                  ),
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: dsCardShadow),
                    alignment: Alignment.center,
                    child: _uploading && pct != null
                        ? Text(
                            '$pct%',
                            style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary),
                          )
                        : const Icon(Icons.movie_creation_rounded, color: AppColors.iconAccent, size: 44),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _uploading
                ? 'Uploading your video…'
                : _preparingRecordedFile
                    ? 'Preparing recorded video…'
                    : file == null
                        ? 'Choose a video to upload'
                        : 'Ready to upload',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
          ),
          if (_uploading)
            Text(
              'Keep this screen open until it finishes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
            ),
          const SizedBox(height: 22),
          if (_preparingRecordedFile)
            const Center(child: CircularProgressIndicator())
          else
            DsListCard(
              icon: file == null ? Icons.video_library_rounded : Icons.videocam_rounded,
              title: file?.name ?? 'Select a video',
              subtitle: file == null ? 'From your gallery · max 500 MB' : '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB',
              onTap: _uploading ? null : _pickVideo,
              trailing: file == null ? null : const DsPill('Change', icon: Icons.swap_horiz_rounded),
            ),
        ],
      ),
    );
  }
}

/// Video approval status screen.
class StaffVideoApprovalScreen extends ConsumerWidget {
  const StaffVideoApprovalScreen({super.key, required this.promptId});

  final String promptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(staffVideoCertProvider);
    final submittedAt = ref.watch(staffVideoCertSubmittedAtProvider)[promptId];

    return DsPage(
      title: 'Approval status',
      onBack: () => _back(context),
      onRefresh: () => ref.refresh(staffVideoCertProvider.future),
      bottom: DsGradientButton(
        label: 'Back to videos',
        icon: Icons.video_library_rounded,
        onPressed: () => context.go(StaffRoutes.videoCertification),
      ),
      body: dsAsyncBody(
        prompts,
        onRetry: () => ref.invalidate(staffVideoCertProvider),
        builder: (list) {
          final prompt = list.where((p) => p.id == promptId).firstOrNull;
          if (prompt == null) {
            return const [
              DsEmptyBlock(
                icon: Icons.search_off_rounded,
                title: 'Video not found',
                message: 'Pull to refresh or go back to the video list.',
              ),
            ];
          }
          final (color, icon, label) = _statusStyle(prompt.status);
          final approved = prompt.status == VideoCertStatus.approved;
          final rejected = prompt.status == VideoCertStatus.rejected;
          return [
            DsGradientCard(
              colors: approved ? DsGradientCard.green : (rejected ? DsGradientCard.red : DsGradientCard.blue),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 40),
                  ).animate().scaleXY(begin: 0.4, end: 1, duration: 650.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  DsGlassPill(label.toUpperCase()),
                  const SizedBox(height: 10),
                  Text(
                    prompt.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            const DsSection('Details'),
            DsInfoCard(
              lines: [
                DsInfoLine(
                  Icons.event_rounded,
                  'Submitted',
                  submittedAt != null ? DateFormat('MMM d, yyyy · h:mm a').format(submittedAt) : '—',
                ),
                DsInfoLine(
                  approved ? Icons.verified_user_rounded : Icons.schedule_rounded,
                  approved ? 'Reviewed by' : 'Estimated review',
                  approved ? 'HomeGenny team' : (rejected ? 'Reviewed' : '24–48 hours'),
                ),
                DsInfoLine(icon, 'Status', label, valueColor: color),
              ],
            ),
            const DsSection('Prompt'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(),
              child: Text(
                prompt.instructions,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.55, color: const Color(0xFF374151)),
              ),
            ),
            const SizedBox(height: 14),
            if (rejected)
              DsNote(
                tone: DsNoteTone.danger,
                title: 'Please record again',
                text: 'This video didn\'t meet the guidelines. Go back to the list and tap Re-record.',
              )
            else if (!approved)
              const DsNote(
                tone: DsNoteTone.warning,
                title: 'Under review',
                text: 'You\'ll get a notification once the team has reviewed your video.',
              )
            else
              const DsNote(tone: DsNoteTone.success, title: 'Approved', text: 'Great job — nothing more to do here.'),
          ];
        },
      ),
    );
  }
}
