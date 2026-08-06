import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(staffProfileProvider);
    final authUser = ref.watch(authProvider).user;

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
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A56FF)),
            onPressed: () => context.push(StaffRoutes.settings),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Error loading profile',
          onRetry: () => ref.invalidate(staffProfileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Profile Header
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400',
                        ),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                profile.name,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile.role.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Completion Card
            GestureDetector(
              onTap: () => context.push(StaffRoutes.profileCompletion),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED), // Soft orange bg
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFFF97316),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Completion',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Unlock premium coordinator features',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${profile.completionPercent}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A56FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: profile.completionPercent / 100,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A56FF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Management Modules
            Text(
              'MANAGEMENT MODULES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            _ModuleTile(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF1A56FF),
              iconBgColor: const Color(0xFFEFF6FF),
              title: 'Documents',
              subtitle: 'Verified ID & Tax forms',
              onTap: () => context.push(StaffRoutes.documents),
            ),
            _ModuleTile(
              icon: Icons.school_outlined,
              iconColor: const Color(0xFFF97316),
              iconBgColor: const Color(0xFFFFF7ED),
              title: 'Training',
              subtitle: '4 Modules in progress',
              onTap: () => context.push(StaffRoutes.training),
            ),
            _ModuleTile(
              icon: Icons.videocam_outlined,
              iconColor: const Color(0xFF0EA5E9),
              iconBgColor: const Color(0xFFF0F9FF),
              title: 'Video Certification',
              subtitle: 'Awaiting submission',
              onTap: () => context.push(StaffRoutes.videoCertification),
            ),
            _ModuleTile(
              icon: Icons.edit_document,
              iconColor: const Color(0xFFEF4444),
              iconBgColor: const Color(0xFFFEF2F2),
              title: 'Agreement',
              subtitle: 'Signature required',
              subtitleColor: const Color(0xFFEF4444),
              onTap: () => context.push(StaffRoutes.agreement),
            ),
            _ModuleTile(
              icon: Icons.location_on_outlined,
              iconColor: const Color(0xFF10B981),
              iconBgColor: const Color(0xFFECFDF5),
              title: 'Deployment',
              subtitle: 'View current assignment',
              onTap: () => context.push(StaffRoutes.deployment),
            ),
            _ModuleTile(
              icon: Icons.payments_outlined,
              iconColor: const Color(0xFFEAB308),
              iconBgColor: const Color(0xFFFEFCE8),
              title: 'Salary',
              subtitle: 'Financial overview',
              onTap: () => context.push(StaffRoutes.salary),
            ),
            _ModuleTile(
              icon: Icons.support_agent_outlined,
              iconColor: const Color(0xFF8B5CF6),
              iconBgColor: const Color(0xFFF5F3FF),
              title: 'Help & Support',
              subtitle: 'Concierge assistance',
              onTap: () => context.push(StaffRoutes.help),
            ),

            const SizedBox(height: 24),

            // Bottom Actions
            GestureDetector(
              onTap: () => context.push(StaffRoutes.settings),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF64748B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'System Settings',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  // const SizedBox(width: 8),
                  Text(
                    'Logout from Device',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 18),
                ],
              ),
            ),
            const SizedBox(height: 68),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subtitleColor ?? const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
