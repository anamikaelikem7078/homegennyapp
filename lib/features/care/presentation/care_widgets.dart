import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../design_system/design_system.dart';
import '../domain/care_models.dart';
import 'care_providers.dart';

/// "POSITION_CHANGE" → "Position change".
String carePretty(String raw) {
  final s = raw.replaceAll('_', ' ').toLowerCase();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

List<String> careSplit(String text) =>
    [for (final p in text.split(',')) if (p.trim().isNotEmpty) p.trim()];

(String, Color, IconData) careTaskStatusLook(CareTask t) => switch (t.status) {
      CareTaskStatus.done when t.outOfRange => ('Out of range', AppColors.error, Icons.warning_rounded),
      CareTaskStatus.done when t.isLate => ('Done late', AppColors.warning, Icons.check_circle_rounded),
      CareTaskStatus.done => ('Done', AppColors.success, Icons.check_circle_rounded),
      CareTaskStatus.skipped => ('Skipped', AppColors.lightTextSecondary, Icons.remove_circle_rounded),
      CareTaskStatus.missed => ('Missed', AppColors.error, Icons.error_rounded),
      _ => ('Pending', AppColors.primary, Icons.schedule_rounded),
    };

IconData careTaskTypeIcon(String type) => switch (type) {
      'MEDICATION' => Icons.medication_rounded,
      'VITAL' => Icons.monitor_heart_rounded,
      _ => Icons.directions_walk_rounded,
    };

/// One checklist row: time, title, reading/skip reason and a status pill.
/// [actions] (staff Done/Skip buttons) go under it.
class CareTaskTile extends StatelessWidget {
  const CareTaskTile({super.key, required this.task, this.actions});
  final CareTask task;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final t = task;
    final (label, color, icon) = careTaskStatusLook(t);
    final reading = t.reading;
    final instructions = t.target['instructions'];
    final food = t.target['food_relation'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(border: t.status == CareTaskStatus.missed ? AppColors.error.withValues(alpha: 0.5) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  t.time,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
              ),
              DsIconTile(careTaskTypeIcon(t.type), size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                    ),
                    if (reading != null)
                      Text(
                        reading,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: t.outOfRange ? AppColors.error : AppColors.success,
                        ),
                      ),
                    if (t.type == 'MEDICATION' && (food is String && food != 'ANY' || instructions is String))
                      Text(
                        [
                          if (food is String && food != 'ANY') '${carePretty(food)} food',
                          if (instructions is String) instructions,
                        ].join(' · '),
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    if (t.skipReason != null)
                      Text(
                        'Skipped: ${t.skipReason}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    if (t.notes != null)
                      Text(
                        t.notes!,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.lightTextSecondary),
                      ),
                  ],
                ),
              ),
              DsPill(label, color: color, icon: icon),
            ],
          ),
          if (t.photoFileIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            CarePhotoStrip(fileIds: t.photoFileIds),
          ],
          if (actions != null) ...[const SizedBox(height: 12), actions!],
        ],
      ),
    );
  }
}

/// Small "done / total" summary chips.
class CareSummaryRow extends StatelessWidget {
  const CareSummaryRow({super.key, required this.summary});
  final CareSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        DsPill('${s.done}/${s.total} done', color: AppColors.success, icon: Icons.check_rounded),
        if (s.pending > 0) DsPill('${s.pending} pending', icon: Icons.schedule_rounded),
        if (s.missed > 0) DsPill('${s.missed} missed', color: AppColors.error, icon: Icons.error_rounded),
        if (s.skipped > 0) DsPill('${s.skipped} skipped', color: AppColors.lightTextSecondary),
        if (s.outOfRange > 0) DsPill('${s.outOfRange} out of range', color: AppColors.error, icon: Icons.warning_rounded),
      ],
    );
  }
}

/// A care file image, fetched with the Bearer token.
class CareFileImage extends ConsumerWidget {
  const CareFileImage({super.key, required this.fileId, this.size = 72});
  final String fileId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(careFileBytesProvider(fileId));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: bytes.when(
          loading: () => const ColoredBox(color: Color(0xFFF3F5FA)),
          error: (_, _) => const ColoredBox(
            color: Color(0xFFF3F5FA),
            child: Icon(Icons.broken_image_rounded, color: AppColors.lightTextSecondary),
          ),
          data: (b) => GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(child: InteractiveViewer(child: Image.memory(b))),
            ),
            child: Image.memory(b, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class CarePhotoStrip extends StatelessWidget {
  const CarePhotoStrip({super.key, required this.fileIds, this.onRemove});
  final List<String> fileIds;
  final void Function(String id)? onRemove;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in fileIds)
            Stack(
              children: [
                CareFileImage(fileId: id),
                if (onRemove != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove!(id),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      );
}

/// Picks a photo (camera or gallery) and uploads it as [kind]; returns the
/// file id, or null if cancelled/failed (failures are shown).
Future<String?> carePickAndUpload(
  BuildContext context,
  WidgetRef ref, {
  required String placementId,
  String kind = 'PHOTO',
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  // Keep photos well under the 5 MB limit.
  final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
  if (picked == null || !context.mounted) return null;
  final result = await ref.read(careApiProvider).uploadFile(
        placementId: placementId,
        kind: kind,
        path: picked.path,
        filename: picked.name,
      );
  if (!context.mounted) return null;
  return result.fold(
    onSuccess: (f) => f.id,
    onError: (f) {
      context.showDsSnackBar(f.message, type: DsSnackBarType.error);
      return null;
    },
  );
}

/// Asks for a required reason; returns null if cancelled.
Future<String?> careAskText(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  required String confirmLabel,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 14),
                DsLabeledField(
                  label: label,
                  controller: controller,
                  icon: Icons.edit_note_rounded,
                  hint: hint,
                  maxLines: 4,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 16),
                DsGradientButton(
                  label: confirmLabel,
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(sheetContext).pop(controller.text.trim()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The changes[] lines of a new plan version, highlighted.
class CareChangesList extends StatelessWidget {
  const CareChangesList({super.key, required this.changes});
  final List<CareChange> changes;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in changes)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                c.text,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
              ),
            ),
        ],
      );
}
