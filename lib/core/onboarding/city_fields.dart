import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design_system/design_system.dart';
import 'onboarding_models.dart';


/// City is always a dropdown from `GET /meta/cities` — it decides the branch
/// and the RM, so it is never free text.
class CityDropdown extends StatelessWidget {
  const CityDropdown({super.key, required this.cities, required this.value, required this.onChanged});

  final List<CityOption> cities;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final known = cities.any((c) => c.city == value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingFieldLabel('City'),
        DropdownButtonFormField<String>(
          key: ValueKey('city-$value'),
          initialValue: known ? value : null,
          isExpanded: true,
          hint: const Text('Choose your city'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(16),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.iconAccent, size: 21),
          ),
          items: [
            for (final c in cities) DropdownMenuItem(value: c.city, child: Text(c.city)),
          ],
          validator: (v) => v == null ? 'Choose your city' : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class AreaDropdown extends StatelessWidget {
  const AreaDropdown({super.key, required this.areas, required this.value, required this.onChanged});

  final List<String> areas;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingFieldLabel('Area', optional: true),
        DropdownButtonFormField<String?>(
          key: ValueKey('area-$value-${areas.length}'),
          initialValue: areas.contains(value) ? value : null,
          isExpanded: true,
          hint: const Text('Choose your area'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(16),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.map_rounded, color: AppColors.iconAccent, size: 21),
          ),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Not sure / other')),
            for (final a in areas) DropdownMenuItem<String?>(value: a, child: Text(a)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Field label matching `DsLabeledField`'s, for pickers and chip groups.
class OnboardingFieldLabel extends StatelessWidget {
  const OnboardingFieldLabel(this.label, {super.key, this.optional = false});
  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
          if (optional) ...[
            const SizedBox(width: 6),
            Text('Optional', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary)),
          ],
        ],
      ),
    );
  }
}
