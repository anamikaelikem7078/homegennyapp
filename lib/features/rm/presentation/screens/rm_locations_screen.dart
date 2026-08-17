import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// `GET /rm/locations` — despite the task brief describing this as
/// "staff GPS/location data", the actual backend response is branch/city/
/// area configuration used to filter attendance (verified against
/// `rm.service.ts`: `getLocations` returns `{ cities, branches, areas }`
/// with no per-staff coordinates at all, and no separate staff-GPS
/// endpoint exists anywhere in the API). This screen shows exactly that —
/// a location/branch reference list — not a fabricated map of staff pins.
class RmLocationsScreen extends ConsumerWidget {
  const RmLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(rmLocationsProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Locations')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmLocationsProvider),
        child: AsyncValueWidget<LocationsData>(
          value: locationsAsync,
          onRetry: () => ref.invalidate(rmLocationsProvider),
          builder: (data) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: RmTheme.amberWarning.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'This is branch/city reference data used for attendance filtering — the backend has no staff GPS/live-location '
                  'endpoint. No map or staff pins are shown here.',
                ),
              ),
              const SizedBox(height: 20),
              Text('Branches', style: RmTheme.title(context)),
              const SizedBox(height: 8),
              for (final b in data.branches)
                ListTile(leading: const Icon(Icons.apartment_outlined), title: Text(b.name), subtitle: Text(b.city)),
              const SizedBox(height: 20),
              Text('Areas', style: RmTheme.title(context)),
              const SizedBox(height: 8),
              for (final a in data.areas)
                ListTile(leading: const Icon(Icons.place_outlined), title: Text(a.label), subtitle: Text(a.city)),
            ],
          ),
        ),
      ),
    );
  }
}
