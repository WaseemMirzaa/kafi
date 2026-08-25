import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_media_image.dart';

/// Full-size, pinch-to-zoom viewer for a nanny's profile photos — opened by
/// tapping any thumbnail in the "Photos & Videos" gallery section.
///
/// Video playback is handled separately by the existing [VideoPlayerScreen]
/// (via `AppNavigation.openIntroVideo`) — this screen only paginates photos.
class NannyPhotoViewerScreen extends StatefulWidget {
  const NannyPhotoViewerScreen({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
    this.nannyName,
  });

  final List<String> photoUrls;
  final int initialIndex;
  final String? nannyName;

  @override
  State<NannyPhotoViewerScreen> createState() => _NannyPhotoViewerScreenState();
}

class _NannyPhotoViewerScreenState extends State<NannyPhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photoUrls.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photoUrls;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: KafiMediaImage(
                    url: photos[i],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _circleBtn(Icons.close, Get.back),
            ),
            if (photos.length > 1)
              Positioned(
                top: 14,
                right: 0,
                left: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.profileGalleryCounter.trParams(
                          {'current': '${_index + 1}', 'total': '${photos.length}'}),
                      style: KafiTheme.nunito(11, color: Colors.white, w: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
