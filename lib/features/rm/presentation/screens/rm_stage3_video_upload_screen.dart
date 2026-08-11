import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmStage3VideoUploadScreen extends StatefulWidget {
  final String staffId;

  const RmStage3VideoUploadScreen({super.key, required this.staffId});

  @override
  State<RmStage3VideoUploadScreen> createState() => _RmStage3VideoUploadScreenState();
}

class _RmStage3VideoUploadScreenState extends State<RmStage3VideoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _videoFile;
  VideoPlayerController? _videoPlayerController;
  bool _isUploading = false;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() {
        _videoFile = video;
        _isUploading = false;
      });

      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(video.path));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(video.path));
      }

      await _videoPlayerController!.initialize();
      setState(() {});
      _videoPlayerController!.play();
    }
  }

  void _uploadVideo() {
    setState(() {
      _isUploading = true;
    });

    // Simulate upload delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
        // Navigate to the next screen for demonstration
        context.push(RmRoutes.stage3VideoReview(widget.staffId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (_videoFile != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: RmTheme.sophisticatedShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                ),
              ),
            _buildUploadStatusCard(context),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'VIDEO UPLOAD',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SHA-256 hash stored · AWS COMPLIANCE lock',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickVideo,
        backgroundColor: RmTheme.electricBlue,
        child: const Icon(Icons.videocam, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: RmTheme.offWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: RmTheme.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Video Upload',
        style: GoogleFonts.libreCaslonText(
          color: RmTheme.electricBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STAGE 3',
          style: GoogleFonts.inter(
            color: RmTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Training & Video Self-Certification',
          style: GoogleFonts.libreCaslonText(
            color: RmTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Series-specific curriculum delivered in-branch. Culminates in the Video Self-Certification — the most legally significant document in the pipeline. SHA-256 verified on every playback. 7-year permanent retention.',
          style: GoogleFonts.inter(
            color: RmTheme.textSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isUploading
                    ? 'Uploading...'
                    : _videoFile != null
                        ? 'Ready to upload'
                        : 'No video recorded',
                style: GoogleFonts.inter(
                  color: RmTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isUploading)
                Text(
                  'Uploading...',
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isUploading)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: RmTheme.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(RmTheme.electricBlue),
                minHeight: 8,
              ),
            ),
          if (!_isUploading && _videoFile != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RmTheme.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'UPLOAD VIDEO',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (_videoFile == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RmTheme.offWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RmTheme.borderSubtle, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.videocam_outlined, size: 48, color: RmTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the camera button to record video',
                    style: GoogleFonts.inter(color: RmTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          _buildInfoCard(
            title: 'SHA-256 HASH',
            child: Text(
              _videoFile != null ? 'Pending calculation...' : 'Not available',
              style: GoogleFonts.spaceMono(
                color: RmTheme.electricBlue,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'STORAGE',
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, color: RmTheme.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AWS S3 · COMPLIANCE Object\nLock · 7yr retention',
                    style: GoogleFonts.inter(
                      color: RmTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildComplianceBanner(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.offWhite,
        border: Border.all(color: RmTheme.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: RmTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildComplianceBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.emeraldGreen.withOpacity(0.1),
        border: Border.all(color: RmTheme.emeraldGreen.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: RmTheme.emeraldGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: RmTheme.emeraldGreen,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: const [
                  TextSpan(text: 'Video will be '),
                  TextSpan(
                    text: 'NEVER-DELETE',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ' once hash is committed to database.'),
                ],
              ),
            ),
          ),
        ],
      ),
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
