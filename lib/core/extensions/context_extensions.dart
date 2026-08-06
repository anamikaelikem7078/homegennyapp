import 'package:flutter/material.dart';

import '../localization/generated/app_localizations.dart';
import '../../design_system/design_system.dart' show DsSnackBar, DsSnackBarType;

extension ContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;

  void showAppSnackBar(String message, {bool isError = false}) {
    DsSnackBar.show(
      this,
      message: message,
      type: isError ? DsSnackBarType.error : DsSnackBarType.info,
    );
  }
}
