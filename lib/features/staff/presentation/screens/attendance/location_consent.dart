import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../design_system/design_system.dart';

const _consentKey = 'staff_location_sharing_consent';

/// Whether the staff member has agreed to share location while on duty.
bool hasLocationSharingConsent(WidgetRef ref) =>
    ref.read(hiveServiceProvider).getSetting<bool>(_consentKey) ?? false;

/// Shows the on-duty location sharing notice once, before the first
/// check-in that needs it (required by the stores). Returns true when the
/// staff member agreed. Also asks for the notification permission
/// (Android 13+) so the "sharing your location" notification is visible.
Future<bool> ensureLocationSharingConsent(BuildContext context, WidgetRef ref) async {
  if (hasLocationSharingConsent(ref)) return true;
  final agreed = await DsConfirmationDialog.show(
    context: context,
    icon: Icons.share_location_rounded,
    title: 'Location while on duty',
    message: 'While you are checked in, HomeGenny shares your location with the family and '
        'your RM about every 5 minutes. It stops when you check out. Your location is never '
        'shared when you are not on duty.',
    confirmLabel: 'I understand',
    cancelLabel: 'Not now',
  );
  if (agreed != true) return false;
  await ref.read(hiveServiceProvider).saveSetting(_consentKey, true);
  try {
    await Permission.notification.request();
  } catch (_) {
    // Not supported on this platform — nothing to ask.
  }
  return true;
}

/// "1.2 km" / "350 m".
String formatDistance(int meters) =>
    meters < 1000 ? '$meters m' : '${(meters / 1000).toStringAsFixed(1)} km';
