import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_radius.dart';

/// OTP input field with individual digit boxes.
class DsOtpField extends StatefulWidget {
  const DsOtpField({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.autoFocus = true,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool autoFocus;

  @override
  State<DsOtpField> createState() => _DsOtpFieldState();
}

class _DsOtpFieldState extends State<DsOtpField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes.first.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _fillFromPaste(value);
      return;
    }

    // Jumping focus synchronously inside `onChanged` races the text field's
    // own commit of the just-typed character — on some platforms the field
    // being left ends up with its input connection torn down before the
    // character is flushed, so it renders blank even though a digit was
    // typed. Deferring to the next frame lets the current field finish
    // committing first.
    if (value.isNotEmpty && index < widget.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[index + 1].requestFocus();
      });
    } else if (value.isEmpty && index > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[index - 1].requestFocus();
      });
    }

    widget.onChanged?.call(_otp);
    if (_otp.length == widget.length && !_otp.contains('')) {
      widget.onCompleted(_otp);
    }
  }

  void _fillFromPaste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    widget.onChanged?.call(_otp);
    if (_otp.length == widget.length) {
      widget.onCompleted(_otp);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              border: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (v) => _onDigitChanged(index, v),
          ),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.2, end: 0);
      }),
    );
  }
}
