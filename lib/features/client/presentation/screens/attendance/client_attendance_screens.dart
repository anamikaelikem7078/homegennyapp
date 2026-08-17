import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

String _currentMonthYear() {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final now = DateTime.now();
  return '${months[now.month - 1]} ${now.year}';
}

/// Today's attendance.
class ClientTodayAttendanceScreen extends ConsumerWidget {
  const ClientTodayAttendanceScreen({super.key});

  Widget _buildBottomNavigationBar(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final inactiveColor = const Color(0xFF94A3B8);
    
    Widget buildItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? primaryColor : inactiveColor, size: 20),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildItem(
              icon: Icons.home_outlined,
              label: 'HOME',
              isActive: false,
              onTap: () => context.go(ClientRoutes.dashboard),
            ),
            buildItem(
              icon: Icons.people_outline,
              label: 'STAFF',
              isActive: true,
              onTap: () => context.go(ClientRoutes.staff),
            ),
            buildItem(
              icon: Icons.payments_outlined,
              label: 'PAYMENTS',
              isActive: false,
              onTap: () => context.go(ClientRoutes.payments),
            ),
            buildItem(
              icon: Icons.person_outline_rounded,
              label: 'PROFILE',
              isActive: false,
              onTap: () => context.go(ClientRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clientTodayAttendanceProvider);
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    final offWhite = const Color(0xFFFBF9F8);

    final tactileCardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.02),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: today.when(
        loading: () => const Center(child: DsLoadingWidget()),
        error: (_, __) => const Center(child: DsErrorState(title: 'Error')),
        data: (t) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Headline
            Center(
              child: Text(
                "Today's Attendance",
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Profile Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE0E7FF), width: 1.5),
                boxShadow: tactileCardShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t.staffName ?? 'Staff',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.todayStatus.replaceAll('_', ' '),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF3730A3),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        t.gpsVerified ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                        color: textGrey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.gpsVerified ? 'Location verified' : 'Location not verified',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Daily Log Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: tactileCardShadows,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TODAY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.checkInTime != null ? 'In: ${t.checkInTime}' : 'No records yet',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.todayStatus.replaceAll('_', ' '),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Raise Issue Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: tactileCardShadows,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push(ClientRoutes.attendanceRaiseIssue),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flag_outlined, color: Color(0xFFDC2626), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Raise Issue',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textDark,
                            ),
                          ),
                        ),
                        Icon(Icons.info_outline, color: textGrey.withValues(alpha: 0.7), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Attendance history.
class ClientAttendanceHistoryScreen extends ConsumerWidget {
  const ClientAttendanceHistoryScreen({super.key});

  Widget _buildBottomNavigationBar(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final inactiveColor = const Color(0xFF94A3B8);
    
    Widget buildItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? primaryColor : inactiveColor, size: 20),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildItem(
              icon: Icons.home_outlined,
              label: 'HOME',
              isActive: false,
              onTap: () => context.go(ClientRoutes.dashboard),
            ),
            buildItem(
              icon: Icons.people_outline,
              label: 'STAFF',
              isActive: true,
              onTap: () => context.go(ClientRoutes.staff),
            ),
            buildItem(
              icon: Icons.payments_outlined,
              label: 'PAYMENTS',
              isActive: false,
              onTap: () => context.go(ClientRoutes.payments),
            ),
            buildItem(
              icon: Icons.person_outline_rounded,
              label: 'PROFILE',
              isActive: false,
              onTap: () => context.go(ClientRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientAttendanceHistoryProvider);
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    final offWhite = const Color(0xFFFBF9F8);

    final tactileCardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.02),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    Widget buildRecordCard({
      required String date,
      required String checkIn,
      required String? checkOut,
      required String status,
    }) {
      Color bgBadgeColor;
      Color textBadgeColor;
      if (status.toUpperCase() == 'PRESENT') {
        bgBadgeColor = const Color(0xFFDCFCE7);
        textBadgeColor = const Color(0xFF16A34A);
      } else if (status.toUpperCase() == 'LATE') {
        bgBadgeColor = const Color(0xFFFEF3C7);
        textBadgeColor = const Color(0xFFD97706);
      } else { // ABSENT
        bgBadgeColor = const Color(0xFFFEE2E2);
        textBadgeColor = const Color(0xFFDC2626);
      }

      String timeText = checkIn;
      if (checkOut != null && checkOut.isNotEmpty && checkOut != '—') {
        timeText = '$checkIn · Out: $checkOut';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: tactileCardShadows,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: status.toUpperCase() == 'ABSENT' ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status.toUpperCase() == 'ABSENT'
                    ? Icons.cancel_outlined
                    : (status.toUpperCase() == 'LATE' ? Icons.access_time : Icons.check_circle_outline),
                color: status.toUpperCase() == 'ABSENT'
                    ? const Color(0xFFDC2626)
                    : (status.toUpperCase() == 'LATE' ? const Color(0xFFD97706) : primaryColor),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.toUpperCase() == 'ABSENT' ? 'No records found' : 'In: $timeText',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: textGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bgBadgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(
                  color: textBadgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {}, // Filter action
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_rounded, color: primaryColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: GoogleFonts.inter(
                              color: textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: history.when(
        loading: () => const Center(child: DsLoadingWidget()),
        error: (_, __) => const Center(child: DsErrorState(title: 'Error')),
        data: (list) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Headline & Period
            Text(
              'Attendance\nHistory',
              style: GoogleFonts.libreCaslonText(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currentMonthYear(),
              style: GoogleFonts.libreCaslonText(
                fontSize: 18,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // Records stack
            ...list.map((r) {
              return buildRecordCard(
                date: r.date,
                checkIn: r.checkIn ?? '--',
                checkOut: r.checkOut,
                status: r.status,
              );
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Raise attendance issue.
class ClientRaiseAttendanceIssueScreen extends ConsumerStatefulWidget {
  const ClientRaiseAttendanceIssueScreen({super.key});

  @override
  ConsumerState<ClientRaiseAttendanceIssueScreen> createState() =>
      _ClientRaiseAttendanceIssueScreenState();
}

class _ClientRaiseAttendanceIssueScreenState
    extends ConsumerState<ClientRaiseAttendanceIssueScreen> {
  final _message = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_message.text.trim().isEmpty) {
      context.showDsSnackBar('Please describe the issue', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref
        .read(clientRepositoryProvider)
        .raiseAttendanceIssue(message: _message.text);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Issue submitted', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    final offWhite = const Color(0xFFFBF9F8);

    final tactileCardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.02),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  // Headline & Subtext
                  Text(
                    'Raise Issue',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Report attendance concerns.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: textGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Input Module
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      boxShadow: tactileCardShadows,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag_outlined, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Describe the issue',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFF1F5F9)),
                        TextField(
                          controller: _message,
                          maxLines: 8,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Late arrival, early leave...',
                            hintStyle: GoogleFonts.inter(
                              color: textGrey.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Primary CTA Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Issue',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
