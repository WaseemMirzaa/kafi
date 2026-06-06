import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/nanny_card_resolver.dart';
import 'package:kafi_app/views/family/profile_hero.dart';
import 'package:kafi_app/views/family/profile_sections.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/controllers/trial_controller.dart';

class ProfileUnlockedScreen extends StatelessWidget {
  const ProfileUnlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final card = resolveNannyCard();
    final subs = Get.find<SubscriptionController>();
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
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() => subs.isExpired ? _expiredBanner() : _subscribedBadge()),
                    const SizedBox(height: 8),
                    ProfileSections.statsRow(card),
                    const SizedBox(height: 10),
                    Text(AppStrings.skillsSpecialties.tr,
                        style: KafiTheme.nunito(10.5, color: KafiColors.td, w: FontWeight.w800)),
                    const SizedBox(height: 7),
                    ProfileSections.skills(card),
                    const SizedBox(height: 10),
                    _trialBadge(card.id),
                    // Direct contacts are gated when an expired subscription
                    // hides them (§8.5); a trial bypass keeps them visible.
                    Obx(() => subs.contactsHidden
                        ? _contactsLockedBanner()
                        : _contactBlock(card, firstName)),
                    const SizedBox(height: 10),
                    _bottomActions(card),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Green "contact fully unlocked" box, followed by the WhatsApp/Email rows
  // and the download-CV button (which sit below the box, as in the design).
  Widget _contactBlock(NannyCardModel card, String firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Green ul-box: header + direct number + action grid ──
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFFF4FFF8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD0F0DC), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [KafiColors.grn, KafiColors.grnD]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🔓', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact fully unlocked ✅',
                            style: KafiTheme.nunito(11, color: const Color(0xFF1A6A38), w: FontWeight.w800)),
                        Text('Call or WhatsApp $firstName directly — right now',
                            style: KafiTheme.nunito(9, color: const Color(0xFF4A9A65), w: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [KafiColors.grnL, Color(0xFFD0F5E0)]),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFA0E0C0), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📞 $firstName\'s direct number',
                        style: KafiTheme.fredoka(8.5, color: KafiColors.grnD, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('+971 50 234 5678',
                        style: KafiTheme.nunito(17, color: const Color(0xFF1A4A30), w: FontWeight.w900)
                            .copyWith(letterSpacing: 0.6)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _gridBtn('💬', 'WhatsApp her', const [Color(0xFF25D366), Color(0xFF128C42)],
                        () => AppNavigation.mockContactAction('WhatsApp')),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _gridBtn('📞', 'Call her', const [Color(0xFF34B87A), Color(0xFF1A8A50)],
                        () => AppNavigation.mockContactAction('Call'), icon: Icons.call),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: _gridBtn('🗨️', AppStrings.inAppChat.tr,
                        const [KafiColors.rose, KafiColors.roseD],
                        () => AppNavigation.openChat(nannyId: card.id, nannyName: card.name),
                        small: true),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _gridBtn('📄', AppStrings.fullCv.tr,
                        const [KafiColors.pur, Color(0xFFC084FC)], () => AppNavigation.mockContactAction('CV'),
                        small: true),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── Contact rows (below the box, as in the design) ──
        _contactRow('💬', const Color(0xFF25D366), 'WhatsApp', '+971 50 234 5678',
            'Chat', KafiColors.grnD, KafiColors.grnL, () => AppNavigation.mockContactAction('WhatsApp')),
        _contactRow('✉️', KafiColors.amb, 'Email',
            '${firstName.toLowerCase()}@email.com', 'Email', const Color(0xFFA06010), KafiColors.ambL,
            () => AppNavigation.mockContactAction('Email')),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: KafiColors.pur,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => AppNavigation.mockContactAction('CV'),
            icon: const Text('📄', style: TextStyle(fontSize: 14)),
            label: Text('Download $firstName\'s full CV',
                style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _gridBtn(String emoji, String label, List<Color> colors, VoidCallback onTap,
      {bool small = false, IconData? icon}) {
    final size = small ? 17.0 : 22.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: small ? 10 : 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(color: colors.last.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon != null
                ? Icon(icon, color: Colors.white, size: size)
                : Text(emoji, style: TextStyle(fontSize: size)),
            SizedBox(height: small ? 4 : 5),
            Text(label,
                textAlign: TextAlign.center,
                style: KafiTheme.fredoka(small ? 11 : 12, color: Colors.white, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(String emoji, Color icColor, String label, String value, String action,
      Color actColor, Color actBg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE0F5E8), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: icColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(10.5, color: KafiColors.td, w: FontWeight.w800)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: actBg, borderRadius: BorderRadius.circular(6)),
              child: Text(action, style: KafiTheme.fredoka(9, color: actColor, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions(NannyCardModel card) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => AppNavigation.toggleShortlist(card),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: KafiColors.purL,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('⭐ ${AppStrings.shortlist.tr}',
                  style: KafiTheme.fredoka(11, color: KafiColors.pur, w: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => AppNavigation.openTrialOffer(nannyId: card.id, nannyName: card.name),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [KafiColors.grn, KafiColors.grnD]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: KafiColors.grnD.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Text('${AppStrings.sendTrialOffer.tr} →',
                  style: KafiTheme.fredoka(11, color: Colors.white, w: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _subscribedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: KafiColors.grnL, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Text('✅', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(AppStrings.monthlyActive.tr,
                style: KafiTheme.fredoka(10, color: KafiColors.grnD, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _contactsLockedBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: KafiColors.ambL,
        border: Border.all(color: const Color(0xFFFFD080), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(AppStrings.contactsHiddenBanner.tr,
                style: KafiTheme.nunito(10, color: const Color(0xFF7A4A00), w: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Get.toNamed(Routes.pricing),
            child: Text(AppStrings.renewNow.tr, style: KafiTheme.fredoka(10, color: KafiColors.roseD)),
          ),
        ],
      ),
    );
  }

  Widget _expiredBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: KafiColors.ambL,
        border: Border.all(color: const Color(0xFFFFD080), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(AppStrings.subExpiredBanner.tr,
                style: KafiTheme.nunito(10, color: const Color(0xFF7A4A00), w: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Get.toNamed(Routes.pricing),
            child: Text(AppStrings.renewNow.tr, style: KafiTheme.fredoka(10, color: KafiColors.roseD)),
          ),
        ],
      ),
    );
  }

  Widget _trialBadge(String nannyId) {
    if (!Get.isRegistered<TrialController>()) return const SizedBox.shrink();
    final trialCtrl = Get.find<TrialController>();
    return Obx(() {
      final trial = trialCtrl.all.firstWhereOrNull((t) => t.nannyId == nannyId);
      if (trial == null) return const SizedBox.shrink();
      final isActive = trial.status.name.contains('active') || trial.status.name.contains('pending');
      if (!isActive) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: KafiColors.purL, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Text('🧪', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Active trial — ${trial.durationDays} days',
                    style: KafiTheme.nunito(10, color: KafiColors.pur, w: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.trial),
                child: Text('Details', style: KafiTheme.fredoka(10, color: KafiColors.pur)),
              ),
            ],
          ),
        ),
      );
    });
  }
}
