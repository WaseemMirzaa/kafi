import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/utils/constants/subscription_constants.dart';
import 'package:kafi_app/utils/nanny_card_resolver.dart';
import 'package:kafi_app/views/family/profile_hero.dart';
import 'package:kafi_app/views/family/profile_sections.dart';
import 'package:kafi_app/views/family/profile_ui_tokens.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class ProfileLockedScreen extends StatelessWidget {
  const ProfileLockedScreen({super.key});

  bool _hasActiveTrial(NannyCardModel card) {
    if (!Get.isRegistered<TrialController>()) return false;
    return Get.find<TrialController>().all.any(
          (t) => t.nannyId == card.id && (t.status == TrialStatus.active || t.status == TrialStatus.accepted),
        );
  }

  @override
  Widget build(BuildContext context) {
    final card = resolveNannyCard();
    final hasTrial = _hasActiveTrial(card);
    final firstName = card.name.split(' ').first;

    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHero(card: card),
              Padding(
                padding: const EdgeInsets.fromLTRB(ProfileUi.hPad, 10, ProfileUi.hPad, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasTrial) ...[
                      ProfileSections.trialBypassBanner(),
                      const SizedBox(height: 10),
                    ],
                    ProfileSections.statsRow(card),
                    const SizedBox(height: 12),
                    ProfileSections.sectionTitle(AppStrings.skillsSpecialties.tr),
                    ProfileSections.skills(card),
                    const SizedBox(height: 12),
                    _lockedBox(card, firstName),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockedBox(NannyCardModel card, String firstName) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: KafiColors.purB, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFC084FC), KafiColors.pur]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.profileLockedTitle.tr,
                        style: KafiTheme.nunito(11, color: const Color(0xFF5A2090), w: FontWeight.w800)),
                    Text(AppStrings.profileLockedSubtitle.trParams({'name': firstName}),
                        style: KafiTheme.nunito(9, color: KafiColors.pur, w: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Neutral masked glyphs behind the blur — no fabricated phone/CV/length
          // that could read as the nanny's real (leaked) data (P24).
          _lockedRow(Icons.call, KafiColors.purL, KafiColors.pur, AppStrings.lockedPhoneNumber.tr, '••• ••• ••••'),
          _lockedRow(Icons.description_outlined, KafiColors.purL, KafiColors.pur, AppStrings.lockedFullCv.tr, '••••••••'),
          _lockedRow(Icons.videocam_outlined, KafiColors.purL, KafiColors.pur, AppStrings.lockedIntroVideo.tr, '••••••'),
          const SizedBox(height: 3),
          _subBox(firstName),
        ],
      ),
    );
  }

  Widget _lockedRow(IconData icon, Color icBg, Color icColor, String label, String value) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.pricing),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
        child: Stack(
          children: [
            // Row content (blurred value)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: icBg, borderRadius: BorderRadius.circular(7)),
                    child: Icon(icon, color: icColor, size: 13),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w700)),
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Text(value,
                                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Translucent purple "lock" overlay with the badge floated right.
            Positioned.fill(
              child: Container(
                color: const Color(0x85F5EEFF),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFC084FC), KafiColors.pur]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, color: Colors.white, size: 8),
                      const SizedBox(width: 2),
                      Text(AppStrings.contactLocked.tr,
                          style: KafiTheme.fredoka(8, color: Colors.white, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subBox(String firstName) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.pricing),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [KafiColors.pur, Color(0xFFC084FC)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(AppStrings.unlockProfileTitle.trParams({'name': firstName}),
                textAlign: TextAlign.center,
                style: KafiTheme.fredoka(12.5, color: Colors.white, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(AppStrings.unlockProfileSubtitle.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(9, color: Colors.white.withValues(alpha: 0.85), w: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${SubscriptionConstants.weeklyPriceAed}',
                      style: KafiTheme.nunito(16, color: Colors.white, w: FontWeight.w900)),
                  const SizedBox(width: 3),
                  Text(AppStrings.perWeek.tr,
                      style: KafiTheme.nunito(9.5, color: Colors.white.withValues(alpha: 0.8), w: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C3AED),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                onPressed: () => Get.toNamed(Routes.pricing),
                child: Text('${AppStrings.subscribeNow.tr} →',
                    style: KafiTheme.fredoka(11.5, color: const Color(0xFF7C3AED), w: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 6),
            _perk(AppStrings.perkUnlimited.tr),
            _perk(AppStrings.perkVideos.tr),
            _perk(AppStrings.perkTrials.tr),
            _perk(AppStrings.perkCancel.tr),
          ],
        ),
      ),
    );
  }

  Widget _perk(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(label,
                style: KafiTheme.nunito(9, color: Colors.white.withValues(alpha: 0.9), w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
