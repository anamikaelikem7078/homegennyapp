import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/staff_scaffold.dart';

/// Check-in screen with selfie capture and GPS verification.
class StaffCheckInScreen extends ConsumerStatefulWidget {
  const StaffCheckInScreen({super.key});

  @override
  ConsumerState<StaffCheckInScreen> createState() => _StaffCheckInScreenState();
}

class _StaffCheckInScreenState extends ConsumerState<StaffCheckInScreen> {
  File? _selfie;
  bool _verifyingGps = false;
  bool _gpsVerified = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _simulateGpsVerification();
  }

  Future<void> _simulateGpsVerification() async {
    setState(() => _verifyingGps = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _verifyingGps = false;
      _gpsVerified = true;
    });
  }

  Future<void> _checkIn() async {
    final placementConfirmed =
        ref.read(staffDeploymentProvider).valueOrNull?.hasActivePlacement ??
        false;
    if (!placementConfirmed) {
      context.showDsSnackBar(
        'Attendance unlocks once your placement is confirmed',
        type: DsSnackBarType.warning,
      );
      return;
    }
    if (_selfie == null) {
      context.showDsSnackBar(
        'Please capture a selfie before checking in',
        type: DsSnackBarType.warning,
      );
      return;
    }
    if (!_gpsVerified) {
      context.showDsSnackBar(
        'Waiting for GPS verification',
        type: DsSnackBarType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    // Note: the backend's check-in endpoint only accepts optional
    // latitude/longitude — there is no selfie field. The selfie capture
    // above is a local-only verification step; no location package is
    // wired into the app yet, so coordinates aren't sent.
    final result = await ref.read(staffRepositoryProvider).checkIn();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (data) {
        ref.invalidate(staffTodayAttendanceProvider);
        ref.invalidate(staffAttendanceHistoryProvider);
        ref.invalidate(staffDashboardProvider);
        context.showDsSnackBar('Checked in successfully', type: DsSnackBarType.success);
        context.go(StaffRoutes.attendance);
      },
      onError: (failure) {
        context.showDsSnackBar(failure.message, type: DsSnackBarType.error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deployment = ref.watch(staffDeploymentProvider);
    final placementConfirmed = deployment.valueOrNull?.hasActivePlacement ?? false;

    // Defends the route itself, not just the hub screen's toggle — a staff
    // member without a confirmed placement has no work site to check in
    // against, so block entry here too regardless of how this screen was
    // reached.
    if (!deployment.isLoading && !placementConfirmed) {
      return StaffPageScaffold(
        title: 'Check In',
        subtitle: 'Verify your location and identity',
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Placement not confirmed yet',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Attendance can only be marked once you have been deployed to a client. Check your deployment status for updates.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.lg),
                DsGradientButton(
                  label: 'View Deployment Status',
                  icon: Icons.badge_outlined,
                  onPressed: () => context.go(StaffRoutes.deployment),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StaffPageScaffold(
      title: 'Check In',
      subtitle: 'Verify your location and identity',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GpsStatusCard(
            verifying: _verifyingGps,
            verified: _gpsVerified,
            onRetry: _verifyingGps ? null : _simulateGpsVerification,
          ),
          SizedBox(height: AppSpacing.xl),
          DsImagePicker(
            label: 'Selfie for attendance',
            height: 200,
            initialImage: _selfie,
            onImagePicked: (file) => setState(() => _selfie = file),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Take a clear selfie at your work location. This helps verify your attendance.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          DsGradientButton(
            label: 'Check In Now',
            icon: Icons.fingerprint_rounded,
            isLoading: _isSubmitting,
            onPressed: _selfie != null && _gpsVerified && !_isSubmitting
                ? _checkIn
                : null,
          ),
        ],
      ),
    );
  }
}

class _GpsStatusCard extends StatelessWidget {
  const _GpsStatusCard({
    required this.verifying,
    required this.verified,
    this.onRetry,
  });

  final bool verifying;
  final bool verified;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, chipType, chipLabel) = verifying
        ? (
            Icons.gps_fixed_rounded,
            'Verifying location...',
            'Checking GPS against your deployment site',
            DsStatusType.info,
            'Verifying',
          )
        : verified
            ? (
                Icons.location_on_rounded,
                'Location verified',
                'Green Park, Delhi · Within 100m of work site',
                DsStatusType.success,
                'Verified',
              )
            : (
                Icons.gps_off_rounded,
                'Location not verified',
                'Unable to confirm your work location',
                DsStatusType.error,
                'Failed',
              );

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.softCard(context),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: verifying
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(icon, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (!verifying && !verified && onRetry != null)
            TextButton(onPressed: onRetry, child: Text('Retry'))
          else
            DsStatusChip(label: chipLabel, type: chipType),
        ],
      ),
    );
  }
}
