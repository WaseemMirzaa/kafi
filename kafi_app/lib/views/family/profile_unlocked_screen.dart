import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/nanny_card_resolver.dart';
import 'package:kafi_app/views/family/profile_hero.dart';
import 'package:kafi_app/views/family/profile_sections.dart';
import 'package:kafi_app/views/family/profile_ui_tokens.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchContact(Uri uri) async {
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    Get.snackbar(AppStrings.errorTitle.tr, AppStrings.contactLaunchFailed.tr,
        snackPosition: SnackPosition.BOTTOM);
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.nannyId, required this.builder});
  final String nannyId;
  final Widget Function(String? phone, bool loading, bool failed, VoidCallback retry) builder;
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
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_phone, _loading, _failed, _reveal);
}

class ProfileUnlockedScreen extends StatelessWidget {
  const ProfileUnlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final card = resolveNannyCard();
    final subs = Get.find<SubscriptionController>();

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
                padding: const EdgeInsets.fromLTRB(
                  ProfileUi.hPad,
                  12,
                  ProfileUi.hPad,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() => subs.isExpired ? _expiredBanner() : const SizedBox.shrink()),
                    Obx(() {
                      if (subs.contactsHidden) {
                        return Column(
                          children: [
                            _contactsLockedBanner(),
                            const SizedBox(height: ProfileUi.sectionGap),
                          ],
                        );
                      }
                      return _Reveal(
                        nannyId: card.id,
                        builder: (phone, loading, failed, retry) {
                          final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                          final canContact = !loading && digits.isNotEmpty;
                          return Column(
                            children: [
                              ProfileQuickActions(
                                loading: loading,
                                failed: failed,
                                onRetry: retry,
                                onCall: () {
                                  if (canContact) _launchContact(Uri.parse('tel:$phone'));
                                },
                                onWhatsapp: () {
                                  if (canContact) _launchContact(Uri.parse('https://wa.me/$digits'));
                                },
                                onChat: () => AppNavigation.openChat(
                                  nannyId: card.id,
                                  nannyName: card.name,
                                ),
                                onBookTrial: () => AppNavigation.openTrialOffer(
                                  nannyId: card.id,
                                  nannyName: card.name,
                                ),
                              ),
                              const SizedBox(height: ProfileUi.sectionGap),
                            ],
                          );
                        },
                      );
                    }),
                    _trialBadge(card.id),
                    ProfileSections.mediaGalleryTitle(card),
                    ProfileSections.mediaGallery(card),
                    const SizedBox(height: ProfileUi.sectionGap),
                    ProfileSections.sectionTitle(AppStrings.profileExperiencePreferences.tr),
                    ProfileSections.experienceGrid(card),
                    const SizedBox(height: ProfileUi.sectionGap),
                    ProfileSections.sectionTitle(AppStrings.profileSalaryExpectation.tr),
                    ProfileSections.salaryExpectation(card),
                    const SizedBox(height: ProfileUi.sectionGap),
                    ProfileSections.sectionTitle(AppStrings.profileAboutMe.tr),
                    ProfileSections.aboutMe(card),
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerLeft, child: ProfileSections.paidTrialChip()),
                    const SizedBox(height: 16),
                    ProfileHireCta(
                      onTap: () => AppNavigation.openTrialOffer(
                        nannyId: card.id,
                        nannyName: card.name,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      final s = trial.status.name;
      final isActive = s == 'active' || s == 'accepted';
      if (!isActive) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: ProfileUi.sectionGap),
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
