import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/job_type_label.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/report_user_sheet.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';
import 'package:kafi_app/views/widgets/kafi_media_image.dart';

/// Nanny-profile header: back/logo/favourite top bar, large cover photo with
/// a photo+video count badge, name/age/location, availability chips, and the
/// Kafi Match % ring + ID/References/Interview verification checklist.
///
/// Shared by all three profile screens (locked/unlocked/relocked) so the
/// identity block always looks identical regardless of subscription state.
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
          // ── Top bar: back · Kafi logo · report · favourite ──
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 8),
            child: Row(
              children: [
                _squareBackBtn(),
                const Expanded(child: Center(child: KafiLogo(size: 28))),
                // Report stays reachable (safety feature, never removed) but
                // rendered small/quiet next to the heart so it doesn't compete
                // with the reference's clean back+heart-only header.
                _iconOnlyBtn(
                  Icons.flag_outlined,
                  () => showReportUserSheet(reportedUserId: card.id, reportedUserName: card.name),
                  color: KafiColors.ts,
                  size: 15,
                ),
                const SizedBox(width: 10),
                _iconOnlyBtn(Icons.favorite, () => AppNavigation.toggleShortlist(card),
                    color: KafiColors.roseD, size: 22),
              ],
            ),
          ),
          // ── Cover photo + photo/video count badge ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GestureDetector(
              onTap: card.photoUrls.isEmpty
                  ? null
                  : () => AppNavigation.openNannyPhotoViewer(
                        photoUrls: card.photoUrls,
                        nannyName: card.name,
                      ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 0.82,
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
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: _mediaCountBadge(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 12, 17, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.name, style: KafiTheme.fredoka(19, color: KafiColors.navy, w: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(localizeJobTypeLabel(card.jobType),
                    style: KafiTheme.nunito(12.5, color: KafiColors.roseD, w: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (card.age != null)
                      AppStrings.profileAgeYrs.trParams({'n': '${card.age}'}),
                    card.nationality,
                    card.city,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (card.availableNow) _pill('🟢 ${AppStrings.profileAvailableNowChip.tr}', KafiColors.grnL, KafiColors.grnD),
                    _pill('📅 ${AppStrings.profilePaidTrialAvailable.tr}', KafiColors.purL, KafiColors.pur),
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
      child: Text(card.initials, style: KafiTheme.fredoka(48, color: Colors.white, w: FontWeight.w900)),
    );
  }

  // Compact icon+count overlay on the cover photo itself ("📷 5 🎬 1") — the
  // full-word "(5 photos + 1 video)" phrasing lives in the section title
  // below the gallery instead, matching the reference's two distinct formats.
  Widget _mediaCountBadge() {
    final hasVideo = (card.introVideoUrl ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_camera, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text('${card.photoUrls.length}',
              style: KafiTheme.nunito(10, color: Colors.white, w: FontWeight.w700)),
          if (hasVideo) ...[
            const SizedBox(width: 7),
            const Icon(Icons.videocam, color: Colors.white, size: 12),
            const SizedBox(width: 3),
            Text('1', style: KafiTheme.nunito(10, color: Colors.white, w: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: KafiTheme.fredoka(10.5, color: fg, w: FontWeight.w700)),
    );
  }

  // ── Kafi Match % ring + ID/References/Interview verification checklist ──
  Widget _matchAndVerification() {
    final checklist = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _checkRow(AppStrings.profileIdVerified.tr, card.verified),
        const SizedBox(height: 6),
        _checkRow(AppStrings.profileReferencesVerified.tr, card.hasReferences),
        const SizedBox(height: 6),
        // Kafi's onboarding review (which includes an interview pass) is the
        // same admin-verification signal as `verified` — no separate
        // "interviewed" field exists on the nanny model.
        _checkRow(AppStrings.profileKafiInterviewed.tr, card.verified),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (card.matchPercent > 0) ...[
            _matchRing(),
            const SizedBox(width: 14),
          ],
          Expanded(child: checklist),
        ],
      ),
    );
  }

  Widget _matchRing() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: card.matchPercent / 100,
                  strokeWidth: 5,
                  backgroundColor: KafiColors.purB.withValues(alpha: 0.4),
                  valueColor: const AlwaysStoppedAnimation(KafiColors.pur),
                ),
              ),
              Text('${card.matchPercent}%',
                  style: KafiTheme.fredoka(13, color: KafiColors.pur, w: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(AppStrings.profileKafiMatch.tr,
            style: KafiTheme.nunito(8.5, color: KafiColors.pur, w: FontWeight.w700)),
      ],
    );
  }

  Widget _checkRow(String label, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ok ? KafiColors.roseD : KafiColors.ts, size: 15),
        const SizedBox(width: 7),
        Expanded(
          child: Text(label,
              style: KafiTheme.nunito(10.5, color: KafiColors.td, w: FontWeight.w700)),
        ),
      ],
    );
  }

  // Rounded-square back button, pale-rose fill — matches the reference
  // exactly (the header's only "chrome" button besides the plain heart).
  Widget _squareBackBtn() {
    return GestureDetector(
      onTap: Get.back,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back, color: KafiColors.roseD, size: 18),
      ),
    );
  }

  // Bare icon, no background/shadow — matches the reference's plain heart
  // (and keeps the report flag quiet/secondary next to it).
  Widget _iconOnlyBtn(IconData icon, VoidCallback onTap, {required Color color, required double size}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
