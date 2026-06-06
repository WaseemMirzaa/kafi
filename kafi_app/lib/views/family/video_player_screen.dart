import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  String _videoUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>? ?? {};
      _videoUrl = args['videoUrl'] as String? ?? '';
      if (_videoUrl.startsWith('http://') || _videoUrl.startsWith('https://')) {
        _initPlayer(_videoUrl);
      } else {
        setState(() {}); // trigger mock UI
      }
    });
  }

  Future<void> _initPlayer(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      _controller!.play();
    } catch (_) {
      controller.dispose();
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final nannyName = args['nannyName'] as String? ?? 'Nanny';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "$nannyName's Intro",
          style: KafiTheme.fredoka(16, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _initialized ? _realPlayer() : _fallbackPlayer(),
    );
  }

  // ─── Real player (valid URL, initialized) ─────────────────────────────────

  Widget _realPlayer() {
    final ctrl = _controller!;
    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: ctrl.value.aspectRatio,
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

  // ─── Fallback UI (loading / no URL / error) ───────────────────────────────

  Widget _fallbackPlayer() {
    if (_hasError) return _statusView(Icons.error_outline, 'Could not load video');
    if (_videoUrl.isEmpty) return _statusView(Icons.videocam_off_outlined, 'No video available');
    // Valid URL but still initializing
    return _statusView(null, 'Loading…');
  }

  Widget _statusView(IconData? icon, String label) {
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
              style: KafiTheme.nunito(14, color: Colors.white70)),
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
