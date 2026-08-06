import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';
import '../di/injection.dart';

/// Supported app locales.
abstract final class AppLocales {
  static const english = Locale('en');
  static const hindi = Locale('hi');

  static const supported = [english, hindi];
}

/// Persists and exposes the active [Locale].
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref) : super(AppLocales.english) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final saved = _ref.read(hiveServiceProvider).getSetting<String>(StorageKeys.locale);
    if (saved == null) return;
    state = Locale(saved);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _ref.read(hiveServiceProvider).saveSetting(StorageKeys.locale, locale.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});
