import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/job_type_label.dart';
import 'package:kafi_app/views/family/profile_ui_tokens.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_media_image.dart';

/// Shared profile sections — gallery, experience list, salary, about, trial banner.
class ProfileSections {
  const ProfileSections._();

  static Widget statsRow(NannyCardModel card) {
    final rating = card.averageRating;
    return Row(
      children: [
        Expanded(child: _statBox('${card.yearsExp}', AppStrings.yearsExp.tr)),
        const SizedBox(width: 6),
        Expanded(
          child: _statBox(
            rating != null && rating > 0 ? '${rating.toStringAsFixed(1)}★' : '—',
            AppStrings.dashRating.tr,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _statBox('${card.reviewsCount}', AppStrings.profileReviews.tr),
        ),
      ],
    );
  }

  static Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KafiColors.purB.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(value, style: KafiTheme.nunito(13, color: KafiColors.pur, w: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KafiTheme.nunito(8, color: KafiColors.ts, w: FontWeight.w600)),
        ],
      ),
    );
  }

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

  static Widget mediaGallery(NannyCardModel card) {
    final hasVideo = (card.introVideoUrl ?? '').isNotEmpty;
    if (card.photoUrls.isEmpty && !hasVideo) return const SizedBox.shrink();
    return SizedBox(
      height: ProfileUi.galleryThumbSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: card.photoUrls.length + (hasVideo ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final size = ProfileUi.galleryThumbSize;
          if (i < card.photoUrls.length) {
            return GestureDetector(
              onTap: () => AppNavigation.openNannyPhotoViewer(
                photoUrls: card.photoUrls,
                initialIndex: i,
                nannyName: card.name,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ProfileUi.tileRadius),
                child: KafiMediaImage(
                  url: card.photoUrls[i],
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: size,
                    height: size,
                    color: KafiColors.purL,
                    child: const Icon(Icons.image_not_supported_outlined, color: KafiColors.pur),
                  ),
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () => AppNavigation.openIntroVideo(
              introVideoUrl: card.introVideoUrl,
              nannyName: card.name,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ProfileUi.tileRadius),
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (card.photoUrls.isNotEmpty)
                      KafiMediaImage(url: card.photoUrls.last, fit: BoxFit.cover)
                    else
                      Container(color: KafiColors.navy),
                    Container(color: Colors.black.withValues(alpha: 0.38)),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget experienceList(NannyCardModel card) {
    final langLine = card.tags.where((t) => !t.trimLeft().startsWith('✓')).take(4).join(', ');
    final handled = (card.handledChildrenNote ?? '').trim();
    final emirates = card.workEmirateLabels.isNotEmpty
        ? card.workEmirateLabels.join(', ')
        : (card.city.isNotEmpty ? card.city : '');

    final rows = <Widget>[
      _experienceRow(
        Icons.work_outline,
        AppStrings.yearsExp.tr,
        '${AppStrings.profileYearsFull.trParams({'n': '${card.yearsExp}'})} · ${AppStrings.profileUaeExperience.tr}',
      ),
      _experienceRow(
        Icons.child_care_outlined,
        AppStrings.profileHandledChildren.tr,
        handled.isNotEmpty ? handled : '—',
      ),
      _experienceRow(
        Icons.home_outlined,
        AppStrings.fldJobType.tr,
        localizeJobTypeLabel(card.jobType),
      ),
      _experienceRow(
        Icons.chat_bubble_outline,
        AppStrings.jobDetailFieldLanguages.tr,
        langLine.isNotEmpty ? langLine : '—',
      ),
      _experienceRow(
        Icons.videocam_outlined,
        AppStrings.profileCamerasLabel.tr,
        card.comfortableWithCameras
            ? AppStrings.profileCamerasAccepts.tr
            : AppStrings.profileCamerasDeclines.tr,
        positive: card.comfortableWithCameras,
      ),
      _experienceRow(
        Icons.pets_outlined,
        AppStrings.profilePetsLabel.tr,
        card.comfortableWithPets ? AppStrings.profilePetsAccepts.tr : AppStrings.profilePetsDeclines.tr,
        positive: card.comfortableWithPets,
      ),
      _experienceRow(
        Icons.monitor_heart_outlined,
        AppStrings.profileHealthIssuesLabel.tr,
        card.hasHealthConditions
            ? AppStrings.profileHealthIssuesPresent.tr
            : AppStrings.profileHealthIssuesNone.tr,
        positive: !card.hasHealthConditions,
      ),
      _experienceRow(
        Icons.location_on_outlined,
        AppStrings.profileWillingToWorkIn.tr,
        emirates.isNotEmpty ? emirates : '—',
        positive: emirates.isNotEmpty,
      ),
    ];

    return Container(
      decoration: ProfileUi.experienceCard(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: ProfileUi.experienceBorder),
            rows[i],
          ],
        ],
      ),
    );
  }

  static Widget _experienceRow(
    IconData icon,
    String title,
    String value, {
    bool positive = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileUi.experienceIcon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ProfileUi.listRowTitle),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: positive ? ProfileUi.listRowValue : ProfileUi.listRowValueMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget salaryExpectation(NannyCardModel card) {
    if (card.expectedSalaryMin <= 0 && card.expectedSalaryMax <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F8),
        borderRadius: BorderRadius.circular(ProfileUi.cardRadius),
        border: Border.all(color: ProfileUi.roseBorder, width: 1.2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [KafiColors.rose, KafiColors.roseD]),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'AED ${card.expectedSalaryMin} – ${card.expectedSalaryMax}',
                        style: KafiTheme.fredoka(16, color: KafiColors.roseD, w: FontWeight.w800),
                      ),
                      TextSpan(
                        text: ' ${AppStrings.profilePerMonth.tr}',
                        style: KafiTheme.nunito(11, color: KafiColors.rose, w: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: -4,
            bottom: -4,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.payments_outlined, color: KafiColors.rose, size: 26),
                    Icon(Icons.monetization_on_outlined, color: KafiColors.rose, size: 34),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget aboutMeSection(NannyCardModel card) {
    if (card.bio.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.bio,
          style: KafiTheme.nunito(11, color: KafiColors.tm, w: FontWeight.w500).copyWith(height: 1.55),
        ),
        const SizedBox(height: 10),
        paidTrialChip(),
      ],
    );
  }

  static Widget aboutMe(NannyCardModel card) {
    if (card.bio.trim().isEmpty) return const SizedBox.shrink();
    return Text(
      card.bio,
      style: KafiTheme.nunito(11, color: KafiColors.tm, w: FontWeight.w500).copyWith(height: 1.55),
    );
  }

  static Widget sectionTitle(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(label, style: ProfileUi.sectionHeading),
      );

  static Widget mediaGalleryTitle(NannyCardModel card) {
    final hasVideo = (card.introVideoUrl ?? '').isNotEmpty;
    if (card.photoUrls.isEmpty && !hasVideo) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: ProfileUi.sectionHeading,
          children: [
            TextSpan(text: '${AppStrings.profilePhotosVideos.tr} '),
            TextSpan(
              text: '(${AppStrings.profilePhotoCountBadge.trParams({
                    'photos': '${card.photoUrls.length}',
                    'videos': '${hasVideo ? 1 : 0}',
                  })})',
              style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  static Widget paidTrialChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: KafiColors.grnL,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(color: KafiColors.grnD, shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 10),
          ),
          const SizedBox(width: 6),
          Text(AppStrings.profilePaidTrialAvailable.tr,
              style: KafiTheme.fredoka(9.5, color: KafiColors.grnD, w: FontWeight.w700)),
        ],
      ),
    );
  }

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

/// Four quick-action pills (Call · WhatsApp · Chat · Book Trial) — reference styling.
class ProfileQuickActions extends StatelessWidget {
  const ProfileQuickActions({
    super.key,
    required this.onCall,
    required this.onWhatsapp,
    required this.onChat,
    required this.onBookTrial,
    this.loading = false,
    this.failed = false,
    this.onRetry,
  });

  final VoidCallback onCall;
  final VoidCallback onWhatsapp;
  final VoidCallback onChat;
  final VoidCallback onBookTrial;
  final bool loading;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _btn(Icons.phone_outlined, AppStrings.profileCallLabel.tr, onCall)),
            const SizedBox(width: 6),
            Expanded(
              child: _btn(Icons.chat_rounded, AppStrings.contactWhatsappLabel.tr, onWhatsapp),
            ),
            const SizedBox(width: 6),
            Expanded(child: _btn(Icons.chat_bubble_outline, AppStrings.chatActionLabel.tr, onChat)),
            const SizedBox(width: 6),
            Expanded(
              child: _btn(
                Icons.calendar_today_outlined,
                AppStrings.profileBookTrial.tr,
                onBookTrial,
                highlighted: true,
              ),
            ),
          ],
        ),
        if (loading || failed) ...[
          const SizedBox(height: 8),
          if (loading)
            Row(
              children: [
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: KafiColors.roseD),
                ),
                const SizedBox(width: 7),
                Text(AppStrings.contactRevealing.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w700)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(AppStrings.contactLoadFailed.tr,
                      style: KafiTheme.nunito(10, color: KafiColors.tm, w: FontWeight.w700)),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: Text(AppStrings.retry.tr,
                        style: KafiTheme.fredoka(10, color: KafiColors.roseD)),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap, {bool highlighted = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: ProfileUi.actionHeight,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: ProfileUi.actionButton(highlighted: highlighted),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: KafiColors.roseD, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ProfileUi.actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width gradient CTA at the bottom of the unlocked profile.
class ProfileHireCta extends StatelessWidget {
  const ProfileHireCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [KafiColors.rose, KafiColors.pur],
          ),
          borderRadius: BorderRadius.circular(ProfileUi.pillRadius),
          boxShadow: [
            BoxShadow(
              color: KafiColors.pur.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, color: Colors.white, size: 17),
            const SizedBox(width: 8),
            Text(AppStrings.profileHireProceed.tr,
                style: KafiTheme.fredoka(14, color: Colors.white, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
