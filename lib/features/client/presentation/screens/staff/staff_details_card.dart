import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';

final _accessTokenProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(secureStorageProvider).read(StorageKeys.accessToken),
);

/// Photo, personal details, verification badges and call buttons from
/// `GET /client/staff/:id/profile`. Any field can be null — its row is hidden.
class StaffDetailsCard extends ConsumerWidget {
  const StaffDetailsCard({super.key, required this.profile});

  final ClientStaffProfile profile;

  static String _title(String s) => s.isEmpty ? s : '${s[0]}${s.substring(1).toLowerCase()}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final facts = [
      if (p.age != null) '${p.age} yrs',
      if (p.gender != null) _title(p.gender!),
      if (p.hometown != null) 'From ${p.hometown}',
      if (p.experienceYears != null) '${p.experienceYears} years experience',
    ];
    final badges = [
      if (p.pvStatus == 'CLEAR') ('Police verified', Icons.local_police_rounded),
      if (p.idVerified) ('ID verified', Icons.badge_rounded),
      if (p.healthScreening == true) ('Health checked', Icons.health_and_safety_rounded),
      if (p.videoCertAvailable) ('Video certified', Icons.videocam_rounded),
      if (p.trained) ('Trained', Icons.school_rounded),
    ];
    final start = DateTime.tryParse(p.placementStartDate ?? '');
    final placementLine = p.placementStatusLabel == null
        ? null
        : start == null
            ? p.placementStatusLabel!
            : '${p.placementStatusLabel} since ${DateFormatter.date(start)}';
    final small = GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.lightTextSecondary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StaffPhoto(photoUrl: p.photoUrl, name: p.fullName, token: ref.watch(_accessTokenProvider).valueOrNull),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (p.seriesLabel != null) Text(p.seriesLabel!, style: small),
                    if (placementLine != null) Text(placementLine, style: small),
                  ],
                ),
              ),
            ],
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(facts.join(' · '), style: small.copyWith(fontWeight: FontWeight.w600)),
          ],
          if (p.emergencyContactName != null) ...[
            const SizedBox(height: 4),
            Text('Emergency contact: ${p.emergencyContactName}', style: small),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (label, icon) in badges) DsPill(label, color: AppColors.success, icon: icon),
              ],
            ),
          ],
          if (p.phone != null || p.rmPhone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (p.phone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          CommunicationHelper.makePhoneCall(context, p.phone!, recipientName: p.displayFirstName),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text('Call ${p.displayFirstName}'),
                    ),
                  ),
                if (p.phone != null && p.rmPhone != null) const SizedBox(width: 8),
                if (p.rmPhone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          CommunicationHelper.makePhoneCall(context, p.rmPhone!, recipientName: p.rmName ?? 'Your RM'),
                      icon: const Icon(Icons.support_agent_rounded, size: 18),
                      label: const Text('Call RM'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The staff photo needs the Bearer token; initials when there is none or
/// it fails to load (e.g. 404).
class _StaffPhoto extends StatelessWidget {
  const _StaffPhoto({required this.photoUrl, required this.name, required this.token});

  final String? photoUrl;
  final String name;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final initials = DsInitialsAvatar(name: name, size: 56, radius: 28);
    final url = photoUrl;
    if (url == null || token == null) return initials;
    return ClipOval(
      child: Image.network(
        '${ApiConstants.baseUrl}$url',
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        headers: {ApiConstants.headerAuthorization: '${ApiConstants.bearerPrefix}$token'},
        errorBuilder: (_, _, _) => initials,
      ),
    );
  }
}
