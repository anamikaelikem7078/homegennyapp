import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loads real glyph metrics for layout tests.
///
/// By default `flutter test` draws every glyph as a full em square, which is
/// ~1.5x wider than Plus Jakarta Sans and flags overflows that never happen
/// on a device. This registers the SDK's bundled Roboto (within ~5% of Plus
/// Jakarta Sans) under the family names `google_fonts` asks for, plus the
/// Material icon font.
Future<void> loadRealFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  // flutter_tester lives in <sdk>/bin/cache/artifacts/engine/<platform>/.
  final engineDir = File(Platform.resolvedExecutable).parent;
  final fontsDir = '${engineDir.parent.parent.path}/material_fonts';

  Future<void> load(String family, String file) async {
    final bytes = await File('$fontsDir/$file').readAsBytes();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }

  const byWeight = {
    '100': 'roboto-thin.ttf',
    '200': 'roboto-light.ttf',
    '300': 'roboto-light.ttf',
    'regular': 'roboto-regular.ttf',
    '500': 'roboto-medium.ttf',
    '600': 'roboto-bold.ttf',
    '700': 'roboto-bold.ttf',
    '800': 'roboto-black.ttf',
    '900': 'roboto-black.ttf',
  };
  for (final MapEntry(key: weight, value: file) in byWeight.entries) {
    await load('PlusJakartaSans_$weight', file);
  }
  await load('Roboto', 'roboto-regular.ttf');
  await load('MaterialIcons', 'materialicons-regular.otf');
}
