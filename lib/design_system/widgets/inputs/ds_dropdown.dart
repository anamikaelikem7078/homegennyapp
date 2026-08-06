import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_spacing.dart';

/// Design system dropdown field.
class DsDropdown<T> extends StatelessWidget {
  const DsDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
  });

  final T? value;
  final List<DsDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
          ),
          SizedBox(height: AppSpacing.xs),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(item.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: AppDecorations.inputDecoration(
            context,
            hint: hint,
            prefix: prefixIcon != null ? Icon(prefixIcon) : null,
          ),
          borderRadius: BorderRadius.circular(16),
          icon: Icon(Icons.keyboard_arrow_down_rounded),
        ).animate().fadeIn(duration: 250.ms),
      ],
    );
  }
}

class DsDropdownItem<T> {
  const DsDropdownItem({required this.value, required this.label});

  final T value;
  final String label;
}
