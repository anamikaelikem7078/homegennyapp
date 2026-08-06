import 'package:flutter/material.dart';

import 'widgets/feedback/ds_feedback.dart';

export '../../core/theme/app_colors.dart';
export '../../core/utils/result.dart';
export 'foundations/app_decorations.dart';
export 'tokens/app_breakpoints.dart';
export 'tokens/app_durations.dart';
export 'tokens/app_radius.dart';
export 'tokens/app_shadows.dart';
export 'tokens/app_spacing.dart';
export 'widgets/buttons/ds_buttons.dart';
export 'widgets/cards/ds_cards.dart';
export 'widgets/chips/ds_status_chip.dart';
export 'widgets/dialogs/ds_dialogs.dart';
export 'widgets/feedback/ds_feedback.dart';
export 'widgets/inputs/ds_dropdown.dart';
export 'widgets/inputs/ds_otp_field.dart';
export 'widgets/inputs/ds_text_field.dart';
export 'widgets/loaders/ds_loaders.dart';
export 'widgets/navigation/ds_navigation.dart';
export 'widgets/pickers/ds_date_time_picker.dart';
export 'widgets/pickers/ds_document_picker.dart';
export 'widgets/pickers/ds_image_picker.dart';
export 'widgets/search/ds_search_bar.dart';
export 'widgets/states/ds_states.dart';
export 'widgets/timeline/ds_timeline.dart';
export 'widgets/layout/ds_role_layout.dart';
export 'widgets/motion/ds_fade_in.dart';

/// Design system extensions for [BuildContext].
extension DsContextExtensions on BuildContext {
  void showDsSnackBar(
    String message, {
    DsSnackBarType type = DsSnackBarType.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    DsSnackBar.show(
      this,
      message: message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showDsToast(
    String message, {
    DsToastType type = DsToastType.info,
  }) {
    DsToast.show(this, message: message, type: type);
  }
}
