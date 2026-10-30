import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Full-screen live camera that takes one photo and pops it as an [XFile]
/// (null if closed). Used on web, where `image_picker`'s camera source is a
/// file input whose `capture` hint desktop browsers ignore — this goes
/// through `getUserMedia` instead, so the browser asks for the camera.
class DsCameraCapturePage extends StatefulWidget {
  const DsCameraCapturePage({super.key, this.preferFront = true});

  final bool preferFront;

  static Future<XFile?> open(BuildContext context, {bool preferFront = true}) =>
      Navigator.of(context).push<XFile>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DsCameraCapturePage(preferFront: preferFront),
        ),
      );

  @override
  State<DsCameraCapturePage> createState() => _DsCameraCapturePageState();
}

class _DsCameraCapturePageState extends State<DsCameraCapturePage> {
  List<CameraDescription> _cameras = const [];
  int _index = 0;
  CameraController? _controller;
  String? _error;
  bool _taking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final wanted = widget.preferFront ? CameraLensDirection.front : CameraLensDirection.back;
      final i = _cameras.indexWhere((c) => c.lensDirection == wanted);
      _index = i == -1 ? 0 : i;
      await _start(_cameras[_index]);
    } on CameraException catch (e) {
      setState(() => _error = _message(e));
    } catch (_) {
      setState(() => _error = 'Unable to open the camera.');
    }
  }

  static String _message(CameraException e) => switch (e.code) {
        'CameraAccessDenied' || 'cameraPermission' || 'permissionDenied' || 'notAllowed' =>
          'Camera access was blocked. Allow the camera for this site in the browser and try again.',
        _ => e.description ?? 'Unable to open the camera.',
      };

  Future<void> _start(CameraDescription d) async {
    final controller = CameraController(d, ResolutionPreset.high, enableAudio: false);
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _error = null;
    });
  }

  Future<void> _flip() async {
    if (_cameras.length < 2 || _taking) return;
    final old = _controller;
    setState(() => _controller = null);
    await old?.dispose();
    _index = (_index + 1) % _cameras.length;
    try {
      await _start(_cameras[_index]);
    } on CameraException catch (e) {
      setState(() => _error = _message(e));
    }
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || _taking) return;
    setState(() => _taking = true);
    try {
      final photo = await c.takePicture();
      if (mounted) Navigator.of(context).pop(photo);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take a photo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 48),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                setState(() => _error = null);
                                _init();
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      )
                    : c == null || !c.value.isInitialized
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CameraPreview(c),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 48),
                  GestureDetector(
                    onTap: c == null ? null : _shoot,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c == null || _taking ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _cameras.length < 2 ? null : _flip,
                    icon: const Icon(Icons.flip_camera_android_rounded),
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    iconSize: 32,
                    tooltip: 'Switch camera',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
