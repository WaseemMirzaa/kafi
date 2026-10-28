import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// In-app intro-video recorder with a hard [NannyConstants.maxVideoSeconds]
/// cap. System camera apps (via `image_picker`) often ignore
/// `EXTRA_DURATION_LIMIT` / `videoMaximumDuration` and stop at ~10s on some
/// OEMs — this screen owns the limit.
///
/// The screen is kept awake while open (an untouched phone auto-locks after
/// ~30s, which interrupts the camera session and used to close the recorder),
/// both the front and back cameras are selectable, and if the app is
/// interrupted mid-take (call, app switch) the clip recorded so far is kept
/// instead of being lost.
class IntroVideoRecorderScreen extends StatefulWidget {
  const IntroVideoRecorderScreen({super.key});

  @override
  State<IntroVideoRecorderScreen> createState() =>
      _IntroVideoRecorderScreenState();
}

class _IntroVideoRecorderScreenState extends State<IntroVideoRecorderScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _lens;
  /// Clip saved when the app was interrupted mid-take; delivered on resume.
  String? _interruptedPath;
  /// Serialises suspend/resume so rapid lifecycle changes can't race.
  Future<void> _lifecycleQueue = Future<void>.value();
  bool _initializing = true;
  String? _initError;
  bool _recording = false;
  int _elapsedSec = 0;
  Timer? _ticker;

  static const _max = NannyConstants.maxVideoSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Without this the OS auto-locks an untouched phone and the camera session
    // is interrupted. Best-effort — never block opening the camera on it.
    unawaited(WakelockPlus.enable().catchError((_) {}));
    _initCamera();
  }

  bool get _canFlip =>
      _cameras.any((c) => c.lensDirection == CameraLensDirection.front) &&
      _cameras.any((c) => c.lensDirection == CameraLensDirection.back);

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _initError = AppStrings.mediaRecorderNoCamera.tr;
        });
        return;
      }
      // Intro videos are normally a selfie, so start on the front camera; the
      // flip button reaches the back one.
      final lens = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      await _openCamera(lens);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = AppStrings.mediaRecorderInitFailed.tr;
      });
    }
  }

  /// (Re)opens [lens], disposing any camera already open.
  Future<void> _openCamera(CameraDescription lens) async {
    final previous = _camera;
    _camera = null;
    if (mounted) setState(() => _initializing = true);
    await previous?.dispose();
    // medium keeps a 1–4 min clip under the Storage size cap more reliably
    // than `high` (which often exceeds 50–100 MB past ~45s).
    final ctrl = CameraController(
      lens,
      ResolutionPreset.medium,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await ctrl.initialize();
    } catch (_) {
      await ctrl.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _initError = AppStrings.mediaRecorderInitFailed.tr;
      });
      return;
    }
    if (!mounted) {
      await ctrl.dispose();
      return;
    }
    setState(() {
      _camera = ctrl;
      _lens = lens;
      _initializing = false;
      _initError = null;
    });
  }

  /// Swaps between the front and back camera. Not possible mid-recording.
  Future<void> _switchCamera() async {
    if (_recording || _initializing || !_canFlip) return;
    final target = _lens?.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final next = _cameras.firstWhere(
      (c) => c.lensDirection == target,
      orElse: () => _lens ?? _cameras.first,
    );
    await _openCamera(next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _lifecycleQueue = _lifecycleQueue.then((_) => _suspendCamera());
    } else if (state == AppLifecycleState.resumed) {
      _lifecycleQueue = _lifecycleQueue.then((_) => _resumeCamera());
    }
  }

  /// The OS takes the camera when the app is interrupted. Keep whatever was
  /// recorded, then release the camera cleanly.
  Future<void> _suspendCamera() async {
    final cam = _camera;
    if (cam == null) return;
    _camera = null;
    _ticker?.cancel();
    _ticker = null;
    if (cam.value.isRecordingVideo) {
      try {
        final file = await cam.stopVideoRecording();
        if (_elapsedSec >= 1) _interruptedPath = file.path;
      } catch (_) {}
    }
    await cam.dispose();
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _resumeCamera() async {
    if (!mounted || _camera != null) return;
    final saved = _interruptedPath;
    if (saved != null) {
      _interruptedPath = null;
      Get.snackbar(AppStrings.mediaRecorderTitle.tr, AppStrings.mediaRecorderInterrupted.tr);
      Get.back(result: saved);
      return;
    }
    final lens = _lens;
    if (lens != null) await _openCamera(lens);
  }

  Future<void> _toggleRecord() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (_recording) {
      await _stopRecord(save: true);
      return;
    }
    try {
      await cam.startVideoRecording();
      setState(() {
        _recording = true;
        _elapsedSec = 0;
      });
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
        if (!mounted) return;
        final next = _elapsedSec + 1;
        setState(() => _elapsedSec = next);
        if (next >= _max) {
          await _stopRecord(save: true);
        }
      });
    } catch (_) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        AppStrings.mediaRecorderStartFailed.tr,
      );
    }
  }

  Future<void> _stopRecord({required bool save}) async {
    _ticker?.cancel();
    _ticker = null;
    final cam = _camera;
    if (cam == null || !cam.value.isRecordingVideo) {
      if (mounted) setState(() => _recording = false);
      return;
    }
    try {
      final file = await cam.stopVideoRecording();
      if (!mounted) return;
      setState(() => _recording = false);
      if (!save) {
        try {
          await File(file.path).delete();
        } catch (_) {}
        return;
      }
      // Prefer the camera plugin path; fall back to our planned temp path.
      final path = file.path;
      if (_elapsedSec < 1) {
        Get.snackbar(
          AppStrings.errorTitle.tr,
          AppStrings.mediaRecorderTooShort.tr,
        );
        return;
      }
      Get.back(result: path);
    } catch (_) {
      if (mounted) setState(() => _recording = false);
      Get.snackbar(
        AppStrings.errorTitle.tr,
        AppStrings.mediaRecorderStopFailed.tr,
      );
    }
  }

  String get _timerLabel {
    final m = (_elapsedSec ~/ 60).toString().padLeft(1, '0');
    final s = (_elapsedSec % 60).toString().padLeft(2, '0');
    final maxM = (_max ~/ 60).toString();
    final maxS = (_max % 60).toString().padLeft(2, '0');
    return '$m:$s / $maxM:$maxS';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(WakelockPlus.disable().catchError((_) {}));
    _ticker?.cancel();
    final cam = _camera;
    _camera = null;
    cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (_recording) await _stopRecord(save: false);
                      if (mounted) Get.back();
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.mediaRecorderTitle.tr,
                      textAlign: TextAlign.center,
                      style: KafiTheme.fredoka(16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(child: _preview()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                children: [
                  Text(
                    _recording
                        ? _timerLabel
                        : AppStrings.mediaRecorderHint.trParams({
                            'mins': '${_max ~/ 60}',
                          }),
                    style: KafiTheme.nunito(
                      13,
                      color: _recording ? KafiColors.rose : Colors.white70,
                      w: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: SizedBox.shrink()),
                      GestureDetector(
                        onTap: _initializing || _initError != null
                            ? null
                            : _toggleRecord,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _recording ? KafiColors.roseD : Colors.white24,
                          ),
                          child: Icon(
                            _recording ? Icons.stop : Icons.videocam,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _canFlip
                              ? IconButton(
                                  tooltip: AppStrings.mediaRecorderSwitchCamera.tr,
                                  onPressed: _recording || _initializing
                                      ? null
                                      : _switchCamera,
                                  icon: Icon(
                                    Icons.cameraswitch_outlined,
                                    size: 30,
                                    color: _recording || _initializing
                                        ? Colors.white24
                                        : Colors.white,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _recording
                        ? AppStrings.mediaRecorderTapStop.tr
                        : AppStrings.mediaRecorderTapStart.tr,
                    style: KafiTheme.nunito(11, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: KafiColors.pur),
      );
    }
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _initError!,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(13, color: Colors.white),
          ),
        ),
      );
    }
    final cam = _camera!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CameraPreview(cam),
    );
  }
}
