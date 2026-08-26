import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Streams the file in chunks instead of loading it fully into memory —
/// video-cert uploads can be up to 500MB (the backend's own upload limit).
/// Only usable when a real filesystem path is available (mobile/desktop).
Future<String> sha256OfFile(String path) async {
  Digest? result;
  final sink = ChunkedConversionSink<Digest>.withCallback((digests) {
    result = digests.single;
  });
  final input = sha256.startChunkedConversion(sink);
  await for (final chunk in File(path).openRead()) {
    input.add(chunk);
  }
  input.close();
  return result!.toString();
}

/// Hashes a file picked via `file_picker`, working on both native platforms
/// (streamed from `file.path`) and web, where there is no filesystem path —
/// `file_picker`'s `PlatformFile.path` getter *throws* on web the moment
/// it's read (not just returns null), so it must never be accessed there.
Future<String> sha256OfPlatformFile(PlatformFile file) async {
  if (!kIsWeb) {
    final path = file.path;
    if (path != null) {
      return sha256OfFile(path);
    }
  }
  final bytes = file.bytes;
  if (bytes == null) {
    throw StateError('Selected file has neither a path nor in-memory bytes.');
  }
  return sha256.convert(bytes).toString();
}
