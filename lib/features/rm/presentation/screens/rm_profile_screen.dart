import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmProfileScreen extends ConsumerWidget {
  const RmProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final stats = ref.watch(rmDashboardStatsProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: RmTheme.textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsCard(stats),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Account Settings'),
            _buildListTile(Icons.person_outline, 'Personal Information', 'Update your details', () {
              _showComingSoon(context, 'Personal Information');
            }),
            _buildListTile(Icons.security, 'Security & Privacy', 'Password and authentication', () {
              _showComingSoon(context, 'Security & Privacy');
            }),
            _buildListTile(Icons.notifications_none, 'Notifications', 'Manage alert preferences', () {
              _showComingSoon(context, 'Notifications');
            }),
            const SizedBox(height: 24),
            _buildSectionTitle('Support'),
            _buildListTile(Icons.help_outline, 'Help Center', 'FAQs and contact support', () {
              _showComingSoon(context, 'Help Center');
            }),
            _buildListTile(Icons.info_outline, 'About HomeGenny', 'Version 1.0.0', () {
              _showAboutDialog(context);
            }),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RmTheme.crimsonDanger.withOpacity(0.1),
                  foregroundColor: RmTheme.crimsonDanger,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout),
                label: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 4),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background gradient
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                RmTheme.electricBlue.withOpacity(0.15),
                RmTheme.offWhite,
              ],
            ),
          ),
        ),
        // Profile Info
        Positioned(
          bottom: 0,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    )
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: user?.avatarUrl != null 
                    ? NetworkImage(user!.avatarUrl!) 
                    : const NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150'),
                  backgroundColor: RmTheme.surfaceSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Priya Sharma',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: RmTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: RmTheme.electricBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Relationship Manager',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.electricBlue,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'priya.s@homegenny.com',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: RmTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Map<String, int> stats) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A56FF).withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Staff', stats['totalStaff'] ?? 45, Icons.people_outline),
              _buildDivider(),
              _buildStatItem('Active Trials', stats['trialsActive'] ?? 12, Icons.play_circle_outline),
              _buildDivider(),
              _buildStatItem('Pending', stats['pipeline'] ?? 8, Icons.pending_actions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RmTheme.electricBlue, size: 28),
        const SizedBox(height: 12),
        Text(
          value.toString(),
          style: GoogleFonts.libreCaslonText(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: RmTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: RmTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 48,
      width: 1,
      color: RmTheme.borderSubtle,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: RmTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: RmTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: RmTheme.textPrimary),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: RmTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 13, color: RmTheme.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: RmTheme.borderSubtle),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature settings are coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: RmTheme.electricBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About HomeGenny', style: GoogleFonts.libreCaslonText(fontWeight: FontWeight.bold)),
        content: Text('Version 1.0.0\n\nThe premium domestic staff management platform.', style: GoogleFonts.inter()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: RmTheme.electricBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
