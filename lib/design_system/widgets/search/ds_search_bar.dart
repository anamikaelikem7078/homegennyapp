import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_spacing.dart';

/// Search bar with debounce-friendly onChanged callback.
class DsSearchBar extends StatefulWidget {
  const DsSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  State<DsSearchBar> createState() => _DsSearchBarState();
}

class _DsSearchBarState extends State<DsSearchBar> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: AppDecorations.softCard(context).copyWith(
        borderRadius: BorderRadius.circular(999),
      ),
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark
                ? AppColors.darkTextHint
                : AppColors.lightTextHint,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear?.call();
                    widget.onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }
}
