import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Video certification — prompts view. `POST /video-cert/upload-url` and
/// `/finalize` are STAFF/ADMIN-only (verified against live Swagger role
/// guards), so RM cannot upload on a staff member's behalf. This screen is
/// monitoring-only: it shows what the staff member is required to submit,
/// via the real `GET /video-cert/prompts/:series`.
class RmStage3VideoUploadScreen extends ConsumerWidget {
  const RmStage3VideoUploadScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Video Certification Prompts')),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
        builder: (staff) {
          if (staff == null) return const Center(child: Text('Staff not found'));
          final promptsAsync = ref.watch(rmVideoCertPromptsProvider(staff.series));
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${staff.fullName} · ${staff.series}', style: RmTheme.headline(context).copyWith(fontSize: 20)),
                const SizedBox(height: 8),
                const Text('RM cannot upload on the staff member\'s behalf — this is a read-only view of what is required.'),
                const SizedBox(height: 20),
                Expanded(
                  child: AsyncValueWidget<VideoCertPrompts>(
                    value: promptsAsync,
                    onRetry: () => ref.invalidate(rmVideoCertPromptsProvider(staff.series)),
                    builder: (prompts) => ListView(
                      children: [
                        Text('${prompts.count} prompts · min ${prompts.minDuration}s each', style: RmTheme.body(context)),
                        const SizedBox(height: 12),
                        for (final p in prompts.prompts)
                          ListTile(
                            leading: const Icon(Icons.play_circle_outline),
                            title: Text(p),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
