import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/nanny_card_resolver.dart';
import 'package:kafi_app/views/family/profile_hero.dart';
import 'package:kafi_app/views/family/profile_sections.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches an external app for the revealed contact (dialer / WhatsApp).
Future<void> _launchContact(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    Get.snackbar(AppStrings.errorTitle.tr, AppStrings.contactLaunchFailed.tr,
        snackPosition: SnackPosition.BOTTOM);
  }
}

/// Reveals the nanny's real phone (via the gated onContactRevealRequested
/// function) and rebuilds [builder] with it. Isolates the async so the profile
/// screen stays a StatelessWidget.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.nannyId, required this.builder});
  final String nannyId;
  final Widget Function(String? phone, bool loading, bool failed, VoidCallback retry)
      builder;
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  String? _phone;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  Future<void> _reveal() async {
    // On a retry the widget is no longer in its initial loading state, so flip
    // back into it before re-fetching. Guarded so the first (initState) call
    // never calls setState before the first build.
    if (!_loading || _failed) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    final familyId = Get.find<AuthController>().currentUser.value?.id;
    try {
      final phone = familyId == null
          ? null
          : await Get.find<IUserService>().revealContact(familyId, widget.nannyId);
      if (mounted) {
        setState(() {
          _phone = phone;
          _loading = false;
          _failed = false;
        });
      }
    } catch (_) {
      // A reveal FETCH failure (not a dialer-launch failure). Surface it inline
      // with a Retry affordance rather than a transient snackbar (FAM-7), so the
      // family can re-attempt without leaving the profile.
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(_phone, _loading, _failed, _reveal);
}

class ProfileUnlockedScreen extends StatelessWidget {
  const ProfileUnlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final card = resolveNannyCard();
    final subs = Get.find<SubscriptionController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHero(card: card),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 4, 15, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() => subs.isExpired ? _expiredBanner() : const SizedBox.shrink()),
                    // Direct contacts are gated when an expired subscription
                    // hides them (§8.5); a trial bypass keeps them visible.
                    Obx(() => subs.contactsHidden
                        ? _contactsLockedBanner()
                        : _Reveal(
                            nannyId: card.id,
                            builder: (phone, loading, failed, retry) =>
                                _actionButtons(card, phone, loading, failed, retry),
                          )),
                    _trialBadge(card.id),
                    const SizedBox(height: 18),
                    ProfileSections.mediaGalleryTitle(card),
                    ProfileSections.mediaGallery(card),
                    const SizedBox(height: 18),
                    ProfileSections.sectionTitle(AppStrings.profileExperiencePreferences.tr),
                    ProfileSections.experienceGrid(card),
                    const SizedBox(height: 18),
                    ProfileSections.sectionTitle(AppStrings.profileSalaryExpectation.tr),
                    ProfileSections.salaryExpectation(card),
                    const SizedBox(height: 18),
                    ProfileSections.sectionTitle(AppStrings.profileAboutMe.tr),
                    ProfileSections.aboutMe(card),
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerLeft, child: ProfileSections.paidTrialChip()),
                    const SizedBox(height: 14),
                    _bottomCta(card),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Call / WhatsApp / Chat / Book Trial — one row, like the reference ──
  Widget _actionButtons(NannyCardModel card, String? phone, bool loading, bool failed,
      VoidCallback retry) {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final canContact = !loading && digits.isNotEmpty;
    void call() {
      if (canContact) _launchContact(Uri.parse('tel:$phone'));
    }

    void whatsapp() {
      if (canContact) _launchContact(Uri.parse('https://wa.me/$digits'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionBtn(Icons.call_outlined, AppStrings.profileCallLabel.tr, call),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _actionBtn(Icons.chat_bubble_outline, AppStrings.contactWhatsappLabel.tr, whatsapp),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _actionBtn(Icons.forum_outlined, AppStrings.chatActionLabel.tr,
                  () => AppNavigation.openChat(nannyId: card.id, nannyName: card.name)),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _actionBtn(Icons.calendar_month_outlined, AppStrings.profileBookTrial.tr,
                  () => AppNavigation.openTrialOffer(nannyId: card.id, nannyName: card.name),
                  highlighted: true),
            ),
          ],
        ),
        // Inline reveal status — spinner while the gated reveal is in flight,
        // an error + Retry if it failed, otherwise nothing (the number itself
        // is only surfaced via the dialer once Call/WhatsApp is tapped).
        if (loading || failed) ...[
          const SizedBox(height: 8),
          _revealStatus(loading, failed, retry),
        ],
      ],
    );
  }

  // Light outline pill — same rose accent for every action, matching the
  // reference (no per-service brand colors). `highlighted` gives the primary
  // action (Book Trial) a filled pale-rose background instead of white.
  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {bool highlighted = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        decoration: BoxDecoration(
          color: highlighted ? KafiColors.roseP : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: KafiColors.cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: KafiColors.roseD, size: 18),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KafiTheme.fredoka(9.5, color: KafiColors.roseD, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _revealStatus(bool loading, bool failed, VoidCallback retry) {
    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: KafiColors.grnD),
          ),
          const SizedBox(width: 7),
          Text(AppStrings.contactRevealing.tr,
              style: KafiTheme.nunito(10, color: KafiColors.grnD, w: FontWeight.w700)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(AppStrings.contactLoadFailed.tr,
              style: KafiTheme.nunito(10, color: const Color(0xFF7A4A00), w: FontWeight.w700)),
        ),
        TextButton(
          onPressed: retry,
          child: Text(AppStrings.retry.tr, style: KafiTheme.fredoka(10, color: KafiColors.roseD)),
        ),
      ],
    );
  }

  Widget _bottomCta(NannyCardModel card) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => AppNavigation.openTrialOffer(nannyId: card.id, nannyName: card.name),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [KafiColors.rose, KafiColors.pur]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: KafiColors.pur.withValues(alpha: 0.28), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(AppStrings.sendTrialOffer.tr,
                style: KafiTheme.fredoka(13, color: Colors.white, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _contactsLockedBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
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
      margin: const EdgeInsets.only(bottom: 10),
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
      // Exact status match (was a fragile substring check that missed
      // "accepted" and wrongly matched "pending") — DISC-13.
      final s = trial.status.name;
      final isActive = s == 'active' || s == 'accepted';
      if (!isActive) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: KafiColors.purL, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Text('🧪', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    AppStrings.trialActiveDaysN.trParams({'n': '${trial.durationDays}'}),
                    style: KafiTheme.nunito(10, color: KafiColors.pur, w: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.trial),
                child: Text(AppStrings.detailsLabel.tr, style: KafiTheme.fredoka(10, color: KafiColors.pur)),
              ),
            ],
          ),
        ),
      );
    });
  }
}
