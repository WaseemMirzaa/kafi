import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/nanny_card_resolver.dart';
import 'package:kafi_app/views/family/profile_hero.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Screen 16A — shown when the family had previously unlocked this profile
/// but their subscription has since EXPIRED. Contacts must be re-locked
/// per System Spec §6.4.
class ProfileRelockedScreen extends StatelessWidget {
  const ProfileRelockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final card = resolveNannyCard();
    final subs = Get.find<SubscriptionController>();

    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHero(card: card),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _expiredBanner(subs),
                    const SizedBox(height: 12),
                    _statsRow(card),
                    const SizedBox(height: 14),
                    _relockedBox(card),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expiredBanner(SubscriptionController subs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFEEEE), Color(0xFFFFD8D8)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53E3E).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock, color: Color(0xFFE53E3E), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.subExpiredBanner.tr,
                  style: KafiTheme.nunito(12, color: const Color(0xFFB91C1C), w: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.relockedSubtext.tr,
                  style: KafiTheme.nunito(10, color: const Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(NannyCardModel card) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.cardBorder),
      ),
      child: Row(
        children: [
          // Peer rating/reviews stats retired in favour of app-store ratings.
          _stat('${card.yearsExp}', AppStrings.yearsExp.tr),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w900)),
          Text(label, style: KafiTheme.nunito(9, color: KafiColors.tm)),
        ],
      ),
    );
  }

  Widget _relockedBox(NannyCardModel card) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KafiColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _blurredItem(Icons.phone, AppStrings.lockedPhoneNumber.tr, '+971 50 ••• ••••'),
          _blurredItem(Icons.description, AppStrings.lockedFullCv.tr, '${card.name}_CV.pdf'),
          _blurredItem(Icons.play_arrow, AppStrings.lockedIntroVideo.tr, AppStrings.watchLabel.tr),
          const SizedBox(height: 12),
          KafiPrimaryButton(
            label: AppStrings.renewNow.tr,
            onPressed: () => Get.toNamed(Routes.pricing, arguments: {'reason': 'expired'}),
          ),
        ],
      ),
    );
  }

  Widget _blurredItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: KafiColors.roseP,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: KafiColors.roseD, size: 16),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KafiTheme.nunito(9.5, color: KafiColors.tm, w: FontWeight.w700)),
                ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
                    child: Text(
                      value,
                      style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: KafiColors.tm,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 8),
                const SizedBox(width: 2),
                Text(AppStrings.contactLocked.tr, style: KafiTheme.fredoka(8, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
