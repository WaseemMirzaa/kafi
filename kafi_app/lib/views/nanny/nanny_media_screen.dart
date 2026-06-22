import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_step_scaffold.dart';

class NannyMediaScreen extends GetView<NannyProfileController> {
  const NannyMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editMode = Get.arguments is Map && (Get.arguments as Map)['editMode'] == true;
    return KafiStepScaffold(
      step: 2,
      title: AppStrings.mediaTitle.tr,
      subtitle: AppStrings.mediaSubtitle.tr,
      onBack: editMode ? Get.back : null,
      footer: Obx(
        () => KafiPrimaryButton(
          label: editMode ? AppStrings.saveAndClose.tr : AppStrings.nextExp.tr,
          icon: editMode ? Icons.check : Icons.arrow_forward,
          loading: controller.isLoading.value,
          onPressed: () => controller.saveMediaAndNext(advance: !editMode),
        ),
      ),
      children: [
        // ── Photos section ──────────────────────────────────────
        _fsecHeader(
          icon: Icons.photo_camera_outlined,
          label: AppStrings.mediaPhotosHeader.tr,
          purple: false,
        ),
        _photoUploadArea(),
        Obx(() => _photoRow()),
        const SizedBox(height: 16),

        // ── Video section ───────────────────────────────────────
        _fsecHeader(
          icon: Icons.videocam_outlined,
          label: AppStrings.mediaVideoHeader.tr,
          purple: true,
        ),
        _videoArea(),
      ],
    );
  }

  // ── Section header with icon pill ──────────────────────────────
  Widget _fsecHeader({
    required IconData icon,
    required String label,
    required bool purple,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFFE8F0), width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: purple
                    ? const [KafiColors.pur, Color(0xFFC084FC)]
                    : [KafiColors.rose, KafiColors.roseD],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)
                .copyWith(letterSpacing: 0.06 * 9),
          ),
        ],
      ),
    );
  }

  // ── Photo upload tap area / cover ───────────────────────────────
  Widget _photoUploadArea() {
    return Obx(() {
      final photos = controller.photoUrls;
      return photos.isEmpty ? _photoPrompt() : _coverCard(photos.first);
    });
  }

  Widget _photoPrompt() {
    return GestureDetector(
      onTap: controller.pickAndUploadPhoto,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          border: Border.all(color: KafiColors.roseL, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [KafiColors.rose, KafiColors.roseD],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_outlined, size: 20, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.mediaTapAdd.tr,
              style: KafiTheme.fredoka(12, color: KafiColors.roseD, w: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              AppStrings.mediaPhotoRule.tr,
              style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: KafiColors.roseP,
                border: Border.all(color: KafiColors.roseL),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                AppStrings.mediaPhotoViews.tr,
                style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cover card: first photo fills the pink container ────────────
  Widget _coverCard(String url) {
    return GestureDetector(
      onTap: controller.pickAndUploadPhoto,
      child: Container(
        width: double.infinity,
        height: 150,
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          border: Border.all(color: KafiColors.roseL, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (url.startsWith('http') || url.startsWith('data:'))
                  ? Image.network(url, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _coverPlaceholder())
                  : _coverPlaceholder(),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: KafiColors.roseD,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('⭐ ${AppStrings.mediaCover.tr}',
                      style: KafiTheme.nunito(9, color: Colors.white, w: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
        color: KafiColors.roseP,
        child: const Center(
          child: Icon(Icons.person_outline, color: KafiColors.roseD, size: 40),
        ),
      );

  // ── Photo thumbnails row ────────────────────────────────────────
  Widget _photoRow() {
    final photos = controller.photoUrls;
    final maxPhotos = NannyConstants.maxPhotos;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          ...List.generate(photos.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _photoThumb(photos[i]),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: GestureDetector(
                      onTap: () => controller.removePhoto(i),
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: const BoxDecoration(
                          color: KafiColors.roseD,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 7),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          ...List.generate(maxPhotos - photos.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: controller.pickAndUploadPhoto,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: KafiColors.roseP,
                    border: Border.all(
                      color: KafiColors.roseL,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.add, color: KafiColors.roseL, size: 14),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Full video tips + player card ───────────────────────────────
  Widget _videoArea() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        border: Border.all(color: KafiColors.purB, width: 2, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video icon + title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [KafiColors.pur, Color(0xFFC084FC)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x479B6EDB),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.videocam_outlined, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.mediaRecordTitle.tr,
                      style: KafiTheme.fredoka(12, color: const Color(0xFF3A1060), w: FontWeight.w800)),
                  Text(AppStrings.mediaRecordSub.tr,
                      style: KafiTheme.nunito(9, color: KafiColors.pur, w: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rules
          _vidRule(ok: true, text: 'Maximum 60 seconds — strict limit'),
          const SizedBox(height: 4),
          _vidRule(ok: true, text: 'Speak clearly, smile, good lighting'),
          const SizedBox(height: 4),
          _vidRule(ok: false, text: 'Do NOT share phone number in video'),
          const SizedBox(height: 8),

          // What to say box
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0x179B6EDB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What to say:',
                    style: KafiTheme.nunito(9, color: const Color(0xFF5A2090), w: FontWeight.w800)),
                const SizedBox(height: 3),
                _sayItem('Your name, nationality, years experience'),
                _sayItem("Children ages you've cared for"),
                _sayItem('One thing families love about you'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Video preview (always shown as mockup does)
          Obx(() => controller.introVideoUrl.value != null
              ? Column(
                  children: [
                    _IntroVideoPreview(
                      url: controller.introVideoUrl.value!,
                      name: controller.introVideoName.value,
                      onRemove: () {
                        controller.introVideoUrl.value = null;
                        controller.introVideoName.value = null;
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox.shrink()),

          // Record button
          GestureDetector(
            onTap: controller.pickAndUploadVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [KafiColors.pur, Color(0xFFC084FC)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x479B6EDB), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_outlined, size: 11, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('Record or upload video',
                      style: KafiTheme.fredoka(11.5, color: Colors.white, w: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vidRule({required bool ok, required String text}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: ok ? KafiColors.grnL : const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              ok ? '✓' : '!',
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w900,
                color: ok ? KafiColors.grnD : const Color(0xFFA06010),
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style: KafiTheme.nunito(9.5, color: const Color(0xFF7A50B0), w: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _sayItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 9)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text,
                style: KafiTheme.nunito(9, color: const Color(0xFF7A50B0), w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _photoThumb(String url) {
    final child = (url.startsWith('data:') || url.startsWith('http'))
        ? Image.network(url,
            width: 46, height: 46, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder())
        : _thumbPlaceholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: child,
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KafiColors.rose, KafiColors.roseD],
          ),
        ),
        child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
      );
}

/// Real intro-video preview backed by `video_player`: play/pause, a scrubbable
/// seekbar, live position/duration, and a remove control. Degrades to a static
/// "ready" row if the video fails to initialise.
class _IntroVideoPreview extends StatefulWidget {
  const _IntroVideoPreview({required this.url, this.name, required this.onRemove});

  final String url;
  final String? name;
  final VoidCallback onRemove;

  @override
  State<_IntroVideoPreview> createState() => _IntroVideoPreviewState();
}

class _IntroVideoPreviewState extends State<_IntroVideoPreview> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _ctrl = c;
      await c.initialize();
      c.addListener(_onTick);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onTick);
    _ctrl?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  void _toggle() {
    final c = _ctrl;
    if (c == null || !_ready) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    final pos = c?.value.position ?? Duration.zero;
    final dur = c?.value.duration ?? Duration.zero;
    final playing = c?.value.isPlaying ?? false;
    final name = (widget.name != null && widget.name!.isNotEmpty)
        ? widget.name!
        : AppStrings.mediaIntroVideo.tr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KafiColors.pur, Color(0xFFC084FC)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: Icon(
                _failed ? Icons.error_outline : (playing ? Icons.pause : Icons.play_arrow),
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KafiTheme.nunito(10, color: Colors.white, w: FontWeight.w800)),
                Text(
                  _ready
                      ? '⏱ ${_fmt(pos)} / ${_fmt(dur)} · ${AppStrings.mediaVideoReady.tr}'
                      : AppStrings.mediaVideoReady.tr,
                  style: KafiTheme.nunito(9, color: Colors.white70, w: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                (_ready && c != null)
                    ? SizedBox(
                        height: 6,
                        child: VideoProgressIndicator(
                          c,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xB3FFFFFF),
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xB3FFFFFF)),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: widget.onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 9),
            ),
          ),
        ],
      ),
    );
  }
}
