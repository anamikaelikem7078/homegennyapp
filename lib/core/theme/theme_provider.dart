import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import '../di/injection.dart';

/// Manages app theme mode with persistence.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._ref) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  final Ref _ref;

  Future<void> _loadThemeMode() async {
    final hive = _ref.read(hiveServiceProvider);
    final saved = hive.getSetting<String>(StorageKeys.themeMode);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final hive = _ref.read(hiveServiceProvider);
    await hive.saveSetting(StorageKeys.themeMode, mode.name);
  }

  void toggleTheme() {
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
    setThemeMode(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});
