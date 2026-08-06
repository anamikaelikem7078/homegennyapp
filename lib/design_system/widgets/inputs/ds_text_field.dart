import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_spacing.dart';

/// Design system text field with label and validation support.
class DsTextField extends StatelessWidget {
  const DsTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.readOnly = false,
    this.obscureText = false,
    this.textInputAction,
    this.autofocus = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final int? maxLength;
  final bool readOnly;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autofocus: autofocus,
          inputFormatters: inputFormatters,
          decoration: AppDecorations.inputDecoration(
            context,
            hint: hint,
            prefix: prefixIcon != null ? Icon(prefixIcon) : null,
            suffix: suffixIcon,
          ),
        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),
      ],
    );
  }
}

/// Password field with visibility toggle.
class DsPasswordField extends StatefulWidget {
  const DsPasswordField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<DsPasswordField> createState() => _DsPasswordFieldState();
}

class _DsPasswordFieldState extends State<DsPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return DsTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      validator: widget.validator,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
