import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Video certification prompt list.
class StaffVideoCertificationScreen extends ConsumerWidget {
  const StaffVideoCertificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompts = ref.watch(staffVideoCertProvider);
    final promptList = prompts.valueOrNull;
    final allApproved =
        promptList != null &&
        promptList.isNotEmpty &&
        promptList.every((p) => p.status == VideoCertStatus.approved);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A56FF),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(StaffRoutes.profile);
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400',
              ),
            ),
          ),
        ],
      ),
      body: prompts.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF1A56FF),
                onRefresh: () => ref.refresh(staffVideoCertProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  children: [
                    Text(
                      'Video Certification',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile by certifying your identity\nand service quality through our verification\nprocess.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...list.map((prompt) => _PromptTile(prompt: prompt)),
                    const SizedBox(height: 16),

                    // Assistance Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF475569),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need assistance?',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Review our video quality guidelines to ensure faster\napproval from our curation team.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: allApproved
          ? null
          : Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F8).withOpacity(0.9),
                border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final list = prompts.valueOrNull;
                      if (list == null || list.isEmpty) return;
                      // Only a prompt that hasn't been uploaded/approved yet
                      // is eligible to (re-)record — if everything left is
                      // already uploaded/approved there is nothing to do, so
                      // don't fall back to re-recording an already-submitted
                      // prompt.
                      final nextPrompt = list
                          .where(
                            (p) =>
                                p.status != VideoCertStatus.approved &&
                                p.status != VideoCertStatus.uploaded,
                          )
                          .firstOrNull;
                      if (nextPrompt == null) {
                        context.showDsSnackBar(
                          'All videos are already recorded and under review',
                          type: DsSnackBarType.warning,
                        );
                        return;
                      }
                      final localFile = ref.read(
                        staffVideoCertLocalRecordingsProvider,
                      )[nextPrompt.id];
                      if (localFile != null) {
                        context.push(
                          '${StaffRoutes.videoCertPreview}?promptId=${nextPrompt.id}',
                          extra: localFile,
                        );
                      } else {
                        context.push(
                          '${StaffRoutes.videoCertRecord}?promptId=${nextPrompt.id}&title=${Uri.encodeComponent(nextPrompt.title)}',
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                    ),
                    label: Text(
                      'START RECORDING',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PromptTile extends ConsumerWidget {
  const _PromptTile({required this.prompt});
  final VideoCertPrompt prompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    if (prompt.title.contains('Introduction')) {
      icon = Icons.filter_center_focus_outlined;
      iconColor = const Color(0xFF1A56FF);
      iconBgColor = const Color(0xFFEEF2FF);
    } else if (prompt.title.contains('Demonstration')) {
      icon = Icons.dry_cleaning_outlined;
      iconColor = const Color(0xFF1A56FF);
      iconBgColor = const Color(0xFFF1F5F9);
    } else {
      icon = Icons.handshake_outlined;
      iconColor = const Color(0xFF1A56FF);
      iconBgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              _buildStatusPill(prompt.status),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            prompt.title,
            style: GoogleFonts.libreCaslonText(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prompt.instructions,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          if (prompt.status != VideoCertStatus.approved) ...[
            const SizedBox(height: 24),
            _buildAction(context, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, WidgetRef ref) {
    // `uploaded` means a video was already submitted and is awaiting
    // review — surface that instead of a re-upload action so staff can't
    // fire off another submission while one is already pending.
    if (prompt.status == VideoCertStatus.uploaded) {
      return GestureDetector(
        onTap: () => context.push(StaffRoutes.videoCertStatus(prompt.id)),
        child: Row(
          children: [
            Text(
              'UNDER REVIEW',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 16),
          ],
        ),
      );
    }

    // A recording already sits on-device for this prompt (recorded but not
    // yet uploaded) — hide the record action and surface the pending upload
    // instead, so staff can tell at a glance which prompts still need a
    // recording versus which just need the upload finished.
    final localFile = ref.watch(staffVideoCertLocalRecordingsProvider)[prompt.id];
    if (localFile != null) {
      return GestureDetector(
        onTap: () => context.push(
          '${StaffRoutes.videoCertPreview}?promptId=${prompt.id}',
          extra: localFile,
        ),
        child: Row(
          children: [
            Text(
              'RECORDED · COMPLETE UPLOAD',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF16A34A),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF16A34A),
              size: 16,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push(
        '${StaffRoutes.videoCertRecord}?promptId=${prompt.id}&title=${Uri.encodeComponent(prompt.title)}',
      ),
      child: Row(
        children: [
          Text(
            prompt.status == VideoCertStatus.rejected
                ? 'RE-RECORD'
                : 'RECORD NOW',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A56FF),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.videocam_outlined,
            color: Color(0xFF1A56FF),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(VideoCertStatus status) {
    switch (status) {
      case VideoCertStatus.approved:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'APPROVED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF16A34A),
              letterSpacing: 0.5,
            ),
          ),
        );
      case VideoCertStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PENDING',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC2410C),
              letterSpacing: 0.5,
            ),
          ),
        );
      case VideoCertStatus.rejected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'REJECTED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
              letterSpacing: 0.5,
            ),
          ),
        );
      case VideoCertStatus.uploaded:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'UPLOADED',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3730A3),
              letterSpacing: 0.5,
            ),
          ),
        );
    }
  }
}

/// Record video screen.
class StaffRecordVideoScreen extends ConsumerStatefulWidget {
  const StaffRecordVideoScreen({super.key, this.promptId, this.title});

  final String? promptId;
  final String? title;

  @override
  ConsumerState<StaffRecordVideoScreen> createState() =>
      _StaffRecordVideoScreenState();
}

class _StaffRecordVideoScreenState
    extends ConsumerState<StaffRecordVideoScreen> {
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
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(StaffRoutes.videoCertification);
        }
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
        prompt != null &&
        (prompt.status == VideoCertStatus.uploaded ||
            prompt.status == VideoCertStatus.approved);
    final alreadyRecordedLocally = ref
        .read(staffVideoCertLocalRecordingsProvider)
        .containsKey(promptId);
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
      final frontIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
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
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );
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
            ref.read(staffVideoCertLocalRecordingsProvider.notifier).update(
              (state) => {...state, promptId: file},
            );
          }
          context.push(
            '${StaffRoutes.videoCertPreview}?promptId=${widget.promptId}',
            extra: file,
          );
        } on CameraException catch (e) {
          context.showDsSnackBar(
            e.description ?? 'Failed to stop recording',
            type: DsSnackBarType.error,
          );
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
        context.showDsSnackBar(
          e.description ?? 'Failed to start recording',
          type: DsSnackBarType.error,
        );
      }
    } finally {
      _isTogglingRecording = false;
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildCameraBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _initCamera,
                child: Text(
                  'RETRY',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF8820),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
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
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A56FF),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A56FF),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Record Video',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Demonstrate your service setup clearly.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF737373),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF1A1C23),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildCameraBody()),
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? const Color(0xFFEF4444)
                                    : Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isRecording
                                  ? _formatDuration(_elapsed)
                                  : 'PREVIEW',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(
                            Icons.flip_camera_ios_outlined,
                            color: Colors.white,
                          ),
                          onPressed: _isRecording ? null : _flipCamera,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.title ?? 'Service Demonstration',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_initializing || _error != null)
                      ? null
                      : _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFFF8820),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.white : null,
                          shape: _isRecording
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isRecording ? 'STOP RECORDING' : 'START RECORDING',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.mic_none_outlined,
                        color: Color(0xFF737373),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Audio On',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                  Column(
                    children: [
                      const Icon(Icons.hd_outlined, color: Color(0xFF737373)),
                      const SizedBox(height: 4),
                      Text(
                        'HD Quality',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ],
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

/// Video preview before upload.
class StaffVideoPreviewScreen extends StatefulWidget {
  const StaffVideoPreviewScreen({super.key, this.promptId, this.videoFile});

  final String? promptId;
  final XFile? videoFile;

  @override
  State<StaffVideoPreviewScreen> createState() =>
      _StaffVideoPreviewScreenState();
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
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'STEP 2 OF 3',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: const Color(0xFF525252),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A56FF),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preview',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF0F1219),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      final controller = _controller;
                      final isReady =
                          controller != null && controller.value.isInitialized;
                      return Stack(
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
                          else
                            const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                isReady
                                    ? _formatDuration(controller.value.duration)
                                    : '00:00',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8820),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RECORDED',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isReady)
                            Center(
                              child: GestureDetector(
                                onTap: _togglePlayback,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    controller.value.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: const Color(0xFF1A1A1A),
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A1A1A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.videocam_outlined,
                              color: Color(0xFF1A1A1A),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RE-RECORD',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '${StaffRoutes.videoCertUpload}?promptId=${widget.promptId}',
                          extra: widget.videoFile,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8820),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CONTINUE',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
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
  ConsumerState<StaffVideoUploadScreen> createState() =>
      _StaffVideoUploadScreenState();
}

class _StaffVideoUploadScreenState
    extends ConsumerState<StaffVideoUploadScreen> {
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
      platformFile = PlatformFile(
        name: recordedFile.name,
        size: bytes.length,
        bytes: bytes,
      );
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _upload() async {
    if (widget.promptId == null) return;
    final file = _pickedFile;
    if (file == null) {
      context.showDsSnackBar(
        'Please select a video',
        type: DsSnackBarType.warning,
      );
      return;
    }
    setState(() {
      _uploading = true;
      _progress = null;
    });
    final result = await ref
        .read(staffRepositoryProvider)
        .uploadVideoCert(
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
        ref.read(staffVideoCertLocalRecordingsProvider.notifier).update(
          (state) => {...state}..remove(widget.promptId),
        );
        context.showDsSnackBar('Video uploaded', type: DsSnackBarType.success);
        context.push(StaffRoutes.videoCertStatus(widget.promptId!));
      },
      onError: (f) =>
          context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'STEP 3 OF 3',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: const Color(0xFF525252),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A56FF),
          ),
          onPressed: () {
            if (context.canPop() && !_uploading) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload Video',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CircularProgressIndicator(
                                value: _uploading ? _progress : 0.05,
                                strokeWidth: 4,
                                backgroundColor: const Color(0xFFE5E5E5),
                                color: const Color(0xFF1A56FF),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  color: Color(0xFF1A56FF),
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'STATUS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: const Color(0xFF737373),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _uploading
                            ? (_progress != null
                                  ? 'Uploading... ${(_progress! * 100).toStringAsFixed(0)}%'
                                  : 'Uploading...')
                            : 'Ready to upload',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF404040),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_preparingRecordedFile)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Preparing recorded video...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF404040),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_pickedFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFF1A56FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile!.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_pickedFile!.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF737373),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _uploading ? null : _pickVideo,
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFFA3A3A3),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tap to select video',
                        style: GoogleFonts.inter(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_uploading || _preparingRecordedFile)
                      ? null
                      : _upload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Upload for Review',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _uploading
                    ? null
                    : () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                child: Text(
                  'Cancel and discard',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF737373),
                  ),
                ),
              ),
            ],
          ),
        ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A56FF),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A56FF),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(StaffRoutes.videoCertification);
            }
          },
        ),
      ),
      body: prompts.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final prompt = list.where((p) => p.id == promptId).firstOrNull;
          if (prompt == null) {
            return const DsEmptyState(title: 'Not found');
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Approval Status',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (prompt.status == VideoCertStatus.pending) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Review the current state of your staff validation\nrequest.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF737373),
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  colors: [Color(0xFFF1F5F9), Colors.white],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                _buildStatusPill(prompt.status),
                                const SizedBox(height: 20),
                                Text(
                                  prompt.title,
                                  style: GoogleFonts.libreCaslonText(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF1A1A1A),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  prompt.instructions,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF525252),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                const Divider(color: Color(0xFFE5E5E5)),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SUBMITTED',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: const Color(0xFFA3A3A3),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Oct 24, 2023',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          prompt.status ==
                                                  VideoCertStatus.approved
                                              ? 'REVIEWER'
                                              : 'ESTIMATED REVIEW',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: const Color(0xFFA3A3A3),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          prompt.status ==
                                                  VideoCertStatus.approved
                                              ? 'Admin Panel'
                                              : '24-48 Hours',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go(StaffRoutes.videoCertification),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            prompt.status == VideoCertStatus.approved
                            ? const Color(0xFF1A56FF)
                            : const Color(0xFFFF8820),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BACK TO LIST',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            prompt.status == VideoCertStatus.approved
                                ? Icons.arrow_forward
                                : Icons.list,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (prompt.status == VideoCertStatus.approved) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1A1A1A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'VIEW FEEDBACK',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusPill(VideoCertStatus status) {
    if (status == VideoCertStatus.approved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF10B981),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'APPROVED',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          border: Border.all(color: const Color(0xFFFDE68A)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'PENDING',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
