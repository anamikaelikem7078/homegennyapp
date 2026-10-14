import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maps/location_address_providers.dart';
import '../../maps/location_address_service.dart';

/// Displays the human-readable address for a coordinate pair, reverse
/// geocoding it via [locationAddressProvider].
///
/// Shows a small loading indicator while resolving, the formatted address
/// on success, and "Address unavailable" if the lookup fails — it never
/// throws or leaves the UI blank. Watching a `family` provider means the
/// lookup automatically re-runs only when [latitude]/[longitude] change,
/// and repeats for the same coordinates reuse the cached result.
class LocationAddressWidget extends ConsumerWidget {
  const LocationAddressWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.style,
    this.icon = Icons.location_on_outlined,
    this.maxLines = 2,
  });

  final double latitude;
  final double longitude;
  final TextStyle? style;
  final IconData? icon;
  final int maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ref.watch(
      locationAddressProvider(
        LatLngParams(latitude: latitude, longitude: longitude),
      ),
    );

    final textStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Theme.of(context).hintColor),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: address.when(
            loading: () => SizedBox(
              height: (textStyle?.fontSize ?? 14) + 4,
              width: (textStyle?.fontSize ?? 14) + 4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => Text(
              LocationAddressService.fallbackAddress,
              style: textStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
            data: (value) => Text(
              value,
              style: textStyle,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
