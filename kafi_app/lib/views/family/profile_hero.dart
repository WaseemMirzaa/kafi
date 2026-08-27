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

/// Nanny-profile header — Maria Santos reference layout.
class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.card,
    this.footer,
    this.compactBottom = false,
  });

  final NannyCardModel card;
  final Widget? footer;
  final bool compactBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ProfileUi.hPad, 8, ProfileUi.hPad, 6),
            child: Row(
              children: [
                _backBtn(),
                const Expanded(child: Center(child: KafiLogo(size: 26))),
                _heartBtn(),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              ProfileUi.hPad,
              0,
              ProfileUi.hPad,
              compactBottom ? 10 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profilePhoto(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _identityBlock(),
                          const SizedBox(height: 8),
                          _matchAndVerification(),
                        ],
                      ),
                    ),
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: 10),
                  footer!,
                ],
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
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 118,
          height: 128,
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
        const SizedBox(height: 2),
        Text(AppStrings.profileRoleNannyBabysitter.tr,
            style: KafiTheme.nunito(11.5, color: KafiColors.roseD, w: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          [
            if (card.age != null) AppStrings.profileAgeYrs.trParams({'n': '${card.age}'}),
            card.nationality,
            card.city,
          ].where((s) => s.isNotEmpty).join(' • '),
          style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            if (card.availableNow)
              _pill(AppStrings.profileAvailableNowChip.tr, KafiColors.grnL, KafiColors.grnD, dot: true),
            _pill(
              AppStrings.profilePaidTrialAvailable.tr,
              KafiColors.roseP,
              KafiColors.roseD,
              icon: Icons.event,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 10),
          const SizedBox(width: 2),
          Text('${card.photoUrls.length}',
              style: KafiTheme.nunito(9, color: Colors.white, w: FontWeight.w700)),
          if (hasVideo) ...[
            const SizedBox(width: 5),
            const Text('+', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
            const SizedBox(width: 3),
            const Icon(Icons.videocam_outlined, color: Colors.white, size: 10),
            const SizedBox(width: 2),
            Text('1', style: KafiTheme.nunito(9, color: Colors.white, w: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg, {bool dot = false, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          if (icon != null) ...[
            Icon(icon, color: fg, size: 10),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KafiTheme.fredoka(8.5, color: fg, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _matchAndVerification() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: ProfileUi.whiteCard(radius: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkRow(AppStrings.profileIdVerified.tr, card.verified),
                const SizedBox(height: 6),
                _checkRow(AppStrings.profileReferencesVerified.tr, card.hasReferences),
                const SizedBox(height: 6),
                _checkRow(AppStrings.profileKafiInterviewed.tr, card.verified),
              ],
            ),
          ),
          if (card.matchPercent > 0) ...[
            const SizedBox(width: 8),
            ProfileMatchRing(
              percent: card.matchPercent,
              matchLabel: AppStrings.profileKafiMatch.tr,
            ),
          ],
        ],
      ),
    );
  }

  Widget _checkRow(String label, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.verified : Icons.radio_button_unchecked,
          color: ok ? KafiColors.roseD : KafiColors.ts.withValues(alpha: 0.5),
          size: 15,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: KafiTheme.nunito(9.5, color: KafiColors.td, w: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _backBtn() {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: ProfileUi.tileBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: KafiColors.roseD, size: 13),
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
          size: 22,
        ),
      ),
    );
  }
}
