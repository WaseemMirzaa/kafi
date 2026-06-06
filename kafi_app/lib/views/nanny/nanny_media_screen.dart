import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      title: 'Your nanny profile',
      subtitle: 'Let families see & hear you 🌸',
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
          label: 'Profile Photos (min 1, max 5)',
          purple: false,
        ),
        _photoUploadArea(),
        Obx(() => _photoRow()),
        const SizedBox(height: 16),

        // ── Video section ───────────────────────────────────────
        _fsecHeader(
          icon: Icons.videocam_outlined,
          label: 'Intro Video (max 60 seconds)',
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

  // ── Photo upload tap area ───────────────────────────────────────
  Widget _photoUploadArea() {
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
              'Tap to add photos',
              style: KafiTheme.fredoka(12, color: KafiColors.roseD, w: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'No sunglasses · No heavy filters',
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
                '📈 Profiles with photos get 3× more views',
                style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                onTap: i == 0 && photos.isEmpty ? controller.pickAndUploadPhoto : null,
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
                  Text('Record your intro video',
                      style: KafiTheme.fredoka(12, color: const Color(0xFF3A1060), w: FontWeight.w800)),
                  Text('Let families meet the real you 🌸',
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
                    _videoPreviewRow(),
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

  Widget _videoPreviewRow() {
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
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My intro video',
                    style: KafiTheme.nunito(10, color: Colors.white, w: FontWeight.w800)),
                Text('⏱ 0:47 / 1:00 · Ready to submit',
                    style: KafiTheme.nunito(9, color: Colors.white70, w: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 0.47,
                    minHeight: 3,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xB3FFFFFF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: () => controller.introVideoUrl.value = null,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 9),
            ),
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
