import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/family/profile_ui_tokens.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';
import 'package:kafi_app/views/widgets/kafi_media_image.dart';

/// Nanny-profile header — reference layout: back · logo · heart, photo + identity,
/// availability chips, Kafi Match card.
class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.card});

  final NannyCardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ProfileUi.hPad, 10, ProfileUi.hPad, 8),
            child: Row(
              children: [
                _backBtn(),
                const Expanded(child: Center(child: KafiLogo(size: 26))),
                _heartBtn(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(ProfileUi.hPad, 0, ProfileUi.hPad, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profilePhoto(),
                    const SizedBox(width: 12),
                    Expanded(child: _identityBlock()),
                  ],
                ),
                const SizedBox(height: 12),
                _matchAndVerification(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profilePhoto() {
    return GestureDetector(
      onTap: card.photoUrls.isEmpty
          ? null
          : () => AppNavigation.openNannyPhotoViewer(
                photoUrls: card.photoUrls,
                nannyName: card.name,
              ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ProfileUi.cardRadius),
        child: SizedBox(
          width: 112,
          height: 132,
          child: Stack(
            fit: StackFit.expand,
            children: [
              card.photoUrls.isNotEmpty
                  ? KafiMediaImage(
                      url: card.photoUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : _avatarFallback(),
              if (card.photoUrls.isNotEmpty || (card.introVideoUrl ?? '').isNotEmpty)
                Positioned(left: 6, bottom: 6, child: _mediaCountBadge()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(card.name, style: KafiTheme.fredoka(18, color: KafiColors.navy, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(AppStrings.profileRoleNannyBabysitter.tr,
            style: KafiTheme.nunito(11.5, color: KafiColors.roseD, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          [
            if (card.age != null) AppStrings.profileAgeYrs.trParams({'n': '${card.age}'}),
            card.nationality,
            card.city,
          ].where((s) => s.isNotEmpty).join(' · '),
          style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (card.availableNow)
              _pill(AppStrings.profileAvailableNowChip.tr, KafiColors.grnL, KafiColors.grnD, dot: true),
            _pill(AppStrings.profilePaidTrialAvailable.tr, KafiColors.purL, KafiColors.pur, icon: Icons.event),
          ],
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B6EDB), Color(0xFFC084FC)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(card.initials, style: KafiTheme.fredoka(36, color: Colors.white, w: FontWeight.w900)),
    );
  }

  Widget _mediaCountBadge() {
    final hasVideo = (card.introVideoUrl ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 11),
          const SizedBox(width: 3),
          Text('${card.photoUrls.length}',
              style: KafiTheme.nunito(9.5, color: Colors.white, w: FontWeight.w700)),
          if (hasVideo) ...[
            const SizedBox(width: 6),
            const Text('+', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.videocam_outlined, color: Colors.white, size: 11),
            const SizedBox(width: 2),
            Text('1', style: KafiTheme.nunito(9.5, color: Colors.white, w: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg, {bool dot = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          if (icon != null) ...[
            Icon(icon, color: fg, size: 11),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KafiTheme.fredoka(9, color: fg, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _matchAndVerification() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ProfileUi.whiteCard(radius: ProfileUi.cardRadius),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (card.matchPercent > 0) ...[
            Column(
              children: [
                ProfileMatchRing(percent: card.matchPercent),
                const SizedBox(height: 4),
                Text(AppStrings.profileKafiMatch.tr,
                    style: KafiTheme.nunito(8.5, color: KafiColors.roseD, w: FontWeight.w700)),
              ],
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkRow(AppStrings.profileIdVerified.tr, card.verified),
                const SizedBox(height: 8),
                _checkRow(AppStrings.profileReferencesVerified.tr, card.hasReferences),
                const SizedBox(height: 8),
                _checkRow(AppStrings.profileKafiInterviewed.tr, card.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkRow(String label, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.verified : Icons.radio_button_unchecked,
          color: ok ? KafiColors.roseD : KafiColors.ts,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: KafiTheme.nunito(10.5, color: KafiColors.td, w: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _backBtn() {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: ProfileUi.tileBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: KafiColors.roseD, size: 14),
      ),
    );
  }

  Widget _heartBtn() {
    if (!Get.isRegistered<ShortlistController>()) {
      return _heartIcon(false);
    }
    final sl = Get.find<ShortlistController>();
    return Obx(() => _heartIcon(sl.isShortlisted(card.id)));
  }

  Widget _heartIcon(bool saved) {
    return GestureDetector(
      onTap: () => AppNavigation.toggleShortlist(card),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          saved ? Icons.favorite : Icons.favorite_border,
          color: KafiColors.roseD,
          size: 24,
        ),
      ),
    );
  }
}
