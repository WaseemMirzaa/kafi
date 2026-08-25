import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:video_player/video_player.dart';

/// Full-screen intro video player (Screen 16 perk / browse watch-intro).
///
/// Accepts an HTTPS download URL, local file path, Storage path, or `gs://`
/// URI. Non-HTTP values are resolved via [IStorageService.resolveDownloadUrl]
/// before [VideoPlayerController.networkUrl] is created.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    this.videoUrl = '',
    this.nannyName,
  });

  final String videoUrl;
  final String? nannyName;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _resolving = true;
  bool _hasError = false;
  late String _rawUrl;

  @override
  void initState() {
    super.initState();
    _rawUrl = widget.videoUrl.trim();
    if (_rawUrl.isEmpty) {
      final raw = Get.arguments;
      if (raw is Map) {
        _rawUrl = (raw['videoUrl'] as String? ?? '').trim();
      }
    }
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _initialized = false;
      _resolving = true;
      _hasError = false;
    });
    final previous = _controller;
    _controller = null;
    previous?.dispose();

    if (_rawUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _resolving = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      if (_isLocalPath(_rawUrl)) {
        await _initFilePlayer(_rawUrl.replaceFirst('file://', ''));
        return;
      }

      var playable = _rawUrl;
      if (!_isHttp(playable)) {
        if (!Get.isRegistered<IStorageService>()) {
          throw StateError('storage unavailable');
        }
        final resolved =
            await Get.find<IStorageService>().resolveDownloadUrl(playable);
        if (resolved == null || resolved.isEmpty) {
          throw StateError('unresolvable video url');
        }
        playable = resolved;
      }

      if (_isLocalPath(playable)) {
        await _initFilePlayer(playable.replaceFirst('file://', ''));
      } else {
        await _initNetworkPlayer(playable);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolving = false;
          _hasError = true;
          _initialized = false;
        });
      }
    }
  }

  bool _isHttp(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  bool _isLocalPath(String url) {
    if (url.startsWith('file://')) return true;
    if (_isHttp(url) || url.startsWith('gs://')) return false;
    // Absolute device paths only (mock uploads / camera picks). Relative
    // Storage object paths like `nannies/{uid}/videos/video.mp4` must not
    // be treated as local files.
    return url.startsWith('/');
  }

  Future<void> _initFilePlayer(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await _finishInit(controller);
  }

  Future<void> _initNetworkPlayer(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) throw FormatException('bad video url');
    final controller = VideoPlayerController.networkUrl(uri);
    await _finishInit(controller);
  }

  Future<void> _finishInit(VideoPlayerController controller) async {
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
        _resolving = false;
        _hasError = false;
      });
      await controller.play();
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _resolving = false;
          _hasError = true;
          _initialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final raw = Get.arguments;
    final argName = raw is Map ? raw['nannyName'] as String? : null;
    final name = (widget.nannyName ?? argName ?? '').trim();
    final title = name.isEmpty
        ? AppStrings.watchIntroVideo.tr
        : AppStrings.videoIntroTitle.trParams({'name': name});

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: AppNavigation.back,
        ),
        title: Text(
          title,
          style: KafiTheme.fredoka(16, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _initialized ? _realPlayer() : _fallbackPlayer(),
    );
  }

  Widget _realPlayer() {
    final ctrl = _controller!;
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: ctrl.value.aspectRatio == 0
                ? 16 / 9
                : ctrl.value.aspectRatio,
            child: VideoPlayer(ctrl),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _realControls(ctrl),
        ),
      ],
    );
  }

  Widget _realControls(VideoPlayerController ctrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: ctrl,
            builder: (_, value, __) {
              final pos = value.position.inMilliseconds.toDouble();
              final dur = value.duration.inMilliseconds.toDouble();
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: KafiColors.roseD,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: KafiColors.roseD,
                    ),
                    child: Slider(
                      value: dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0,
                      onChanged: (v) => ctrl.seekTo(
                        Duration(milliseconds: (v * dur).toInt()),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fmt(value.position),
                          style: KafiTheme.nunito(11, color: Colors.white70)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => ctrl.seekTo(
                              value.position - const Duration(seconds: 10),
                            ),
                            icon: const Icon(Icons.replay_10,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              value.isPlaying ? ctrl.pause() : ctrl.play();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: KafiColors.roseD,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => ctrl.seekTo(
                              value.position + const Duration(seconds: 10),
                            ),
                            icon: const Icon(Icons.forward_10,
                                color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      Text(_fmt(value.duration),
                          style: KafiTheme.nunito(11, color: Colors.white70)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fallbackPlayer() {
    if (_hasError) {
      return _statusView(
        Icons.error_outline,
        AppStrings.videoLoadFailed.tr,
        actionLabel: AppStrings.retry.tr,
        onAction: _start,
      );
    }
    if (_rawUrl.isEmpty) {
      return _statusView(
        Icons.videocam_off_outlined,
        AppStrings.videoUnavailable.tr,
      );
    }
    if (_resolving) {
      return _statusView(null, AppStrings.videoLoading.tr);
    }
    return _statusView(
      Icons.error_outline,
      AppStrings.videoLoadFailed.tr,
      actionLabel: AppStrings.retry.tr,
      onAction: _start,
    );
  }

  Widget _statusView(
    IconData? icon,
    String label, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(icon, size: 60, color: KafiColors.roseD)
          else
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: KafiColors.roseD),
            ),
          const SizedBox(height: 16),
          Text(label,
              textAlign: TextAlign.center,
              style: KafiTheme.nunito(14, color: Colors.white70)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: KafiColors.roseD,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
