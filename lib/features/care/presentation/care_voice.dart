import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../design_system/design_system.dart';
import 'care_providers.dart';

/// File extension for audio bytes, from their header — voice notes can be
/// m4a, mp3, aac, ogg, webm or wav, and the players need the right one.
String careAudioExtension(List<int> b) {
  bool at(int offset, List<int> sig) =>
      b.length >= offset + sig.length && [for (var i = 0; i < sig.length; i++) b[offset + i] == sig[i]].every((x) => x);
  if (at(4, 'ftyp'.codeUnits)) return 'm4a';
  if (at(0, 'ID3'.codeUnits) || (b.length > 1 && b[0] == 0xFF && (b[1] & 0xE6) == 0xE2)) return 'mp3';
  if (b.length > 1 && b[0] == 0xFF && (b[1] & 0xF6) == 0xF0) return 'aac';
  if (at(0, 'OggS'.codeUnits)) return 'ogg';
  if (at(0, [0x1A, 0x45, 0xDF, 0xA3])) return 'webm';
  if (at(0, 'RIFF'.codeUnits)) return 'wav';
  return 'm4a';
}

String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Plays a voice note stored as a care file (fetched with the Bearer token).
/// [big] makes Play the largest thing on the card — for staff who find
/// reading hard.
class VoiceNotePlayer extends ConsumerStatefulWidget {
  const VoiceNotePlayer({super.key, this.fileId, this.localPath, this.big = false});

  /// A stored voice note, or…
  final String? fileId;

  /// …a just-recorded file not yet sent.
  final String? localPath;
  final bool big;

  @override
  ConsumerState<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends ConsumerState<VoiceNotePlayer> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = false;
  String? _path;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_player.onPlayerStateChanged.listen((s) => mounted ? setState(() => _state = s) : null))
      ..add(_player.onPositionChanged.listen((p) => mounted ? setState(() => _position = p) : null))
      ..add(_player.onDurationChanged.listen((d) => mounted ? setState(() => _duration = d) : null))
      ..add(_player.onPlayerComplete.listen((_) => mounted ? setState(() => _position = Duration.zero) : null));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<String?> _resolvePath() async {
    if (widget.localPath != null) return widget.localPath;
    if (_path != null) return _path;
    final bytes = await ref.read(careFileBytesProvider(widget.fileId!).future);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/voice-${widget.fileId}.${careAudioExtension(bytes)}');
    if (!await file.exists()) await file.writeAsBytes(bytes);
    return _path = file.path;
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }
    if (_state == PlayerState.paused) {
      await _player.resume();
      return;
    }
    setState(() => _loading = true);
    try {
      final path = await _resolvePath();
      if (path != null) await _player.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) context.showDsSnackBar('Could not play the voice note.', type: DsSnackBarType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = _state == PlayerState.playing;
    final size = widget.big ? 72.0 : 44.0;
    final progress = _duration.inMilliseconds == 0 ? 0.0 : _position.inMilliseconds / _duration.inMilliseconds;
    return Container(
      padding: EdgeInsets.all(widget.big ? 12 : 8),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _loading ? null : _toggle,
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: size * 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playing ? 'Playing…' : 'Voice note',
                  style: GoogleFonts.plusJakartaSans(fontSize: widget.big ? 16 : 13, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AppColors.lightBorder),
                ),
                if (_duration > Duration.zero)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${_clock(_position)} / ${_clock(_duration)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.lightTextSecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Records a voice note (AAC .m4a). Calls [onRecorded] with the local file
/// path, or null when the recording is removed.
class VoiceNoteRecorder extends StatefulWidget {
  const VoiceNoteRecorder({super.key, required this.onRecorded});
  final ValueChanged<String?> onRecorded;

  /// Keeps a note well under the 5 MB upload limit.
  static const maxLength = Duration(minutes: 3);

  @override
  State<VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<VoiceNoteRecorder> {
  final _recorder = AudioRecorder();
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  String? _path;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) context.showDsSnackBar('Allow the microphone to record a voice note.', type: DsSnackBarType.warning);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/instruction-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000), path: path);
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= VoiceNoteRecorder.maxLength) _stop();
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _path = path;
    });
    widget.onRecorded(path);
  }

  void _discard() {
    setState(() => _path = null);
    widget.onRecorded(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_path != null && !_recording) {
      return Row(
        children: [
          Expanded(child: VoiceNotePlayer(localPath: _path)),
          IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), onPressed: _discard),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: dsCardDecoration(border: _recording ? AppColors.error : null),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Material(
              color: _recording ? AppColors.error : AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _recording ? _stop : _start,
                child: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _recording ? 'Recording… ${_clock(_elapsed)}  (tap to stop)' : 'Tap to record a voice note',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: _recording ? AppColors.error : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
