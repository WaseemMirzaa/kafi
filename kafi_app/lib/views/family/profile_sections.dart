import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/job_type_label.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_media_image.dart';

/// Shared profile pieces used by both the locked and unlocked nanny-profile
/// screens, matching the web `.srow`/`.sbox`, `.sk-wrap`/`.sk`, and the
/// trial-active banner.
class ProfileSections {
  const ProfileSections._();

  // ── Stats row (Years exp) ─────────────────────────────────────────────────
  // Peer ratings/reviews were retired in favour of app-store ratings, so the
  // rating and reviews-count stats were removed here.
  static Widget statsRow(NannyCardModel card) {
    return Row(
      children: [
        Expanded(child: _statBox('${card.yearsExp}', AppStrings.yearsExp.tr)),
      ],
    );
  }

  static Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: KafiTheme.nunito(14, color: KafiColors.pur, w: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label,
              textAlign: TextAlign.center,
              style: KafiTheme.nunito(8, color: KafiColors.ts, w: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Skills & specialties ──────────────────────────────────────────────────
  static Widget skills(NannyCardModel card) {
    final chips = <Widget>[];
    if (card.verified) {
      chips.add(_skill(AppStrings.verifiedIdBadge.tr, green: true));
    }
    for (final t in card.tags) {
      final isGreen = t.trimLeft().startsWith('✓');
      chips.add(_skill(t, green: isGreen));
    }
    return Wrap(spacing: 4, runSpacing: 4, children: chips);
  }

  static Widget _skill(String label, {bool green = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: green ? KafiColors.grnL : KafiColors.purL,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: KafiTheme.fredoka(9, color: green ? KafiColors.grnD : KafiColors.pur, w: FontWeight.w700)),
    );
  }

  // ── Photos & Videos gallery ────────────────────────────────────────────────
  // Horizontal thumbnail strip; tapping a photo opens the full-size,
  // pinch-to-zoom viewer (NannyPhotoViewerScreen) at that index. Tapping the
  // trailing video tile opens the existing full-screen intro-video player.
  static Widget mediaGallery(NannyCardModel card) {
    final hasVideo = (card.introVideoUrl ?? '').isNotEmpty;
    if (card.photoUrls.isEmpty && !hasVideo) return const SizedBox.shrink();
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: card.photoUrls.length + (hasVideo ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i < card.photoUrls.length) {
            return GestureDetector(
              onTap: () => AppNavigation.openNannyPhotoViewer(
                photoUrls: card.photoUrls,
                initialIndex: i,
                nannyName: card.name,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: KafiMediaImage(
                  url: card.photoUrls[i],
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 84,
                    height: 84,
                    color: KafiColors.purL,
                    child: const Icon(Icons.image_not_supported_outlined, color: KafiColors.pur),
                  ),
                ),
              ),
            );
          }
          // Trailing video tile.
          return GestureDetector(
            onTap: () => AppNavigation.openIntroVideo(
              introVideoUrl: card.introVideoUrl,
              nannyName: card.name,
            ),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [KafiColors.pur, Color(0xFF7B5BD5)]),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
            ),
          );
        },
      ),
    );
  }

  // ── Experience & Preferences grid ──────────────────────────────────────────
  static Widget experienceGrid(NannyCardModel card) {
    final tiles = <Widget>[
      _gridTile('💼', '${card.yearsExp}', AppStrings.yearsExp.tr),
      if (card.handledChildrenNote != null)
        _gridTile('👶', AppStrings.profileHandledChildren.tr, card.handledChildrenNote!),
      _gridTile('🏠', localizeJobTypeLabel(card.jobType), ''),
      if (card.tags.isNotEmpty) _gridTile('💬', card.tags.take(3).join(', '), ''),
      _gridTile('📷', AppStrings.profileCamerasLabel.tr,
          card.comfortableWithCameras ? AppStrings.profileCamerasAccepts.tr : AppStrings.profileCamerasDeclines.tr),
      _gridTile('🐾', AppStrings.profilePetsLabel.tr,
          card.comfortableWithPets ? AppStrings.profilePetsAccepts.tr : AppStrings.profilePetsDeclines.tr),
      _gridTile('❤️', AppStrings.profileHealthIssuesLabel.tr,
          card.hasHealthConditions ? AppStrings.profileHealthIssuesPresent.tr : AppStrings.profileHealthIssuesNone.tr),
      if (card.workEmirateLabels.isNotEmpty)
        _gridTile('📍', AppStrings.profileWillingToWorkIn.tr, card.workEmirateLabels.join(', ')),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: tiles,
    );
  }

  static Widget _gridTile(String emoji, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KafiColors.bgLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KafiTheme.fredoka(11, color: KafiColors.td, w: FontWeight.w700)),
          if (sub.isNotEmpty)
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Salary expectation ─────────────────────────────────────────────────────
  static Widget salaryExpectation(NannyCardModel card) {
    if (card.expectedSalaryMin <= 0 && card.expectedSalaryMax <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.roseP, Color(0xFFFFE8EF)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: KafiColors.roseD, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            'AED ${card.expectedSalaryMin} – ${card.expectedSalaryMax} ${AppStrings.profilePerMonth.tr}',
            style: KafiTheme.fredoka(13, color: KafiColors.roseD, w: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ── About Me / bio ─────────────────────────────────────────────────────────
  static Widget aboutMe(NannyCardModel card) {
    if (card.bio.trim().isEmpty) return const SizedBox.shrink();
    return Text(card.bio, style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w500).copyWith(height: 1.5));
  }

  /// Section title used above each of the blocks above (Photos & Videos,
  /// Experience & Preferences, Salary Expectation, About Me).
  static Widget sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w800)),
      );

  // ── Trial-active banner (shown when contacts are unlocked via a trial) ─────
  static Widget trialBypassBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.grnL, Color(0xFFE8F8EE)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.grnD.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: KafiColors.grnD, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.trialActiveFullAccess.tr,
                    style: KafiTheme.nunito(11, color: KafiColors.grnD, w: FontWeight.w900)),
                Text(AppStrings.trialActiveFullAccessSub.tr,
                    style: KafiTheme.nunito(9.5, color: KafiColors.grnD, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
