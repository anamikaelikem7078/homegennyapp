import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/domain/models/staff_entity.dart';
import '../providers/rm_providers.dart';

class RmStage3VideoReviewScreen extends ConsumerWidget {
  final String staffId;

  const RmStage3VideoReviewScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffDetailProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(context, staff),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVideoPlayer(staff),
            const SizedBox(height: 24),
            Text(
              'Stage 3 — Video Self-Certification playback.\nVerify identity and statement accuracy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: RmTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildVerificationCard(staff),
            const SizedBox(height: 32),
            _buildDecisionHub(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  AppBar _buildAppBar(BuildContext context, StaffEntity? staff) {
    return AppBar(
      backgroundColor: RmTheme.offWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: RmTheme.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Training — ${staff?.name ?? 'Staff'}',
        style: GoogleFonts.libreCaslonText(
          color: RmTheme.electricBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildVideoPlayer(StaffEntity? staff) {
    if (staff?.videoCertification == null || staff!.videoCertification!.isEmpty) {
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: RmTheme.textPrimary, // Mock video background
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1544717305-2782549b5136?q=80&w=600&auto=format&fit=crop'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.play_arrow, color: RmTheme.electricBlue, size: 40),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _VideoPlayerWidget(videoPath: staff.videoCertification!),
      ),
    );
  }

  Widget _buildVerificationCard(StaffEntity? staff) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RmTheme.sophisticatedShadow,
        border: const Border(
          top: BorderSide(color: RmTheme.electricBlue, width: 4),
        ),
      ),
      child: Column(
        children: [
          _buildStaffProfileSection(staff),
          Divider(color: RmTheme.borderSubtle, height: 1),
          _buildIntegrityReportSection(),
        ],
      ),
    );
  }

  Widget _buildStaffProfileSection(StaffEntity? staff) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STAFF PROFILE',
                style: GoogleFonts.inter(
                  color: RmTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                staff?.name ?? 'Ramesh K.',
                style: GoogleFonts.libreCaslonText(
                  color: RmTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${staff?.staffCode ?? 'DR-2024-147'}',
                style: GoogleFonts.inter(
                  color: RmTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RmTheme.offWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, color: RmTheme.electricBlue, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityReportSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildReportRow(
            icon: Icons.fingerprint,
            label: 'SHA-256 Hash Match',
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: RmTheme.electricBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RmTheme.electricBlue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, color: RmTheme.electricBlue, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'VERIFIED',
                    style: GoogleFonts.inter(
                      color: RmTheme.electricBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildReportRow(
            icon: Icons.timer_outlined,
            label: 'Total Duration',
            value: '4m 22s',
          ),
          const SizedBox(height: 20),
          _buildReportRow(
            icon: Icons.playlist_add_check,
            label: 'Prompts Answered',
            value: '6 of 6',
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow({required IconData icon, required String label, String? value, Widget? valueWidget}) {
    return Row(
      children: [
        Icon(icon, color: RmTheme.textSecondary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            color: RmTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (valueWidget != null) valueWidget,
        if (value != null)
          Text(
            value,
            style: GoogleFonts.inter(
              color: RmTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildDecisionHub(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Action logic here, maybe show a success modal or navigate back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video Approved! Moving to Agreements Stage.')),
              );
              context.go(RmRoutes.stage4Hub(staffId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RmTheme.electricBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: RmTheme.electricBlue.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'APPROVE VIDEO',
                  style: GoogleFonts.inter(
                    fontSize: 14,
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
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: RmTheme.textSecondary.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, color: RmTheme.textPrimary.withOpacity(0.8), size: 20),
                const SizedBox(width: 8),
                Text(
                  'REJECT — ADD REASON',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: RmTheme.textPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        border: Border(top: BorderSide(color: RmTheme.borderSubtle)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.grid_view, 'Dashboard', false, context, () => context.go(RmRoutes.dashboard)),
            _buildNavItem(Icons.view_kanban, 'Tracks', true, context, () {}),
            _buildNavItem(Icons.chat_bubble_outline, 'Messages', false, context, () {}),
            _buildNavItem(Icons.admin_panel_settings_outlined, 'Admin', false, context, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? RmTheme.electricBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : RmTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? RmTheme.textPrimary : RmTheme.textSecondary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  const _VideoPlayerWidget({required this.videoPath});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    } else {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    }
    _controller!.initialize().then((_) {
      setState(() {});
      _controller!.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: !_controller!.value.isPlaying
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.play_arrow, color: RmTheme.electricBlue, size: 40),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
