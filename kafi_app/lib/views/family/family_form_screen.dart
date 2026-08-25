import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/family_job_selectors.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_section.dart';
import 'package:kafi_app/views/widgets/kafi_searchable_picker.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

class FamilyFormScreen extends StatefulWidget {
  const FamilyFormScreen({super.key});

  @override
  State<FamilyFormScreen> createState() => _FamilyFormScreenState();
}

class _FamilyFormScreenState extends State<FamilyFormScreen> {
  static const _purpleLabel = Color(0xFF5A2090);

  // The first element of each tuple is the stored value (kept in English so
  // it matches existing profile data); the display label is localized
  // separately via [_religionLabel].
  static const List<(String, String)> _religions = [
    ('Muslim', '☪️'), ('Christian', '✝️'), ('Hindu', '🕉️'),
    ('Buddhist', '☸️'), ('Jewish', '✡️'), ('Other', '🌍'),
  ];

  String _religionLabel(String stored) => switch (stored) {
        'Muslim' => AppStrings.religionMuslim.tr,
        'Christian' => AppStrings.religionChristian.tr,
        'Hindu' => AppStrings.religionHindu.tr,
        'Buddhist' => AppStrings.religionBuddhist.tr,
        'Jewish' => AppStrings.religionJewish.tr,
        'Other' => AppStrings.religionOther.tr,
        _ => stored,
      };

  // Labels are localized at read time, so this can't be `const`. The enum in
  // each tuple is the stored value; only the second element is display text.
  List<(NannyReligionPreference, String)> get _religionPrefs => [
    (NannyReligionPreference.noPreference, AppStrings.familyReligionPrefNone.tr),
    (NannyReligionPreference.preferMuslim, AppStrings.familyReligionPrefMuslim.tr),
    (NannyReligionPreference.preferSame, AppStrings.familyReligionPrefSame.tr),
    (NannyReligionPreference.openWithRespect, AppStrings.familyReligionPrefOpen.tr),
  ];

  FamilyProfileController get controller => Get.find<FamilyProfileController>();
  AuthController get _auth => Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Re-assert the first-job gate whenever this screen is opened (cold start
    // already routes here; this covers resume / deep-link races).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _auth.enforceFamilyFirstJobGate();
      // Permanent FamilyProfileController — re-apply FT/PT slot + new-post args.
      final raw = Get.arguments;
      if (raw is Map && raw['isNewPost'] == true) {
        controller.prepareNewPostFromRoute();
      } else if (Get.currentRoute == Routes.familyForm) {
        controller.prepareNewPostFromRoute();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locked = _auth.familyMustPostFirstJob.value;
      return PopScope(
        canPop: !locked,
        child: Scaffold(
          backgroundColor: KafiColors.bgLight,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _hero(showBack: !locked),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Column(
                      children: [
                        _yourFamily(),
                        _aboutFamily(),
                        _religion(),
                        _roleJobType(),
                        _duties(),
                        _benefits(),
                        _salaryTrialVisa(),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2))],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    child: Obx(
                      () => KafiPrimaryButton(
                        label: AppStrings.findMyNanny.tr,
                        variant: KafiButtonVariant.purple,
                        loading: controller.isLoading.value,
                        onPressed: controller.savePostAndBrowse,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _hero({required bool showBack}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEE0FF), Color(0xFFF0D8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: AppNavigation.back,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
                  ),
                ),
              Expanded(
                child: Text(AppStrings.postNewJob.tr,
                    style: KafiTheme.pacifico(17, color: _purpleLabel)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: EdgeInsets.only(left: showBack ? 28 : 0),
            child: Text(AppStrings.familyFormSub.tr,
                style: KafiTheme.nunito(10, color: KafiColors.pur, w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Your Family ────────────────────────────────────────────────────────────
  Widget _yourFamily() {
    return KafiSection(
      title: AppStrings.familySectionYou.tr,
      icon: Icons.home_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        KafiTextField(
          label: AppStrings.fldFullName.tr,
          controller: controller.fullNameCtrl,
          hint: AppStrings.familyNameHint.tr,
          purple: true,
        ),
        _label(AppStrings.familyYourNationality.tr),
        const SizedBox(height: 4),
        Obx(() => KafiSearchablePicker(
              value: controller.nationality.value,
              options: NannyConstants.nationalities,
              title: AppStrings.familyYourNationality.tr,
              hint: AppStrings.familyYourNationality.tr,
              icon: Icons.flag_outlined,
              purple: true,
              onSelected: (v) => controller.nationality.value = v,
            )),
        const SizedBox(height: 8),
        _label(AppStrings.fldSelectEmirate.tr),
        const SizedBox(height: 4),
        FamilyEmirateSelector(controller),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: KafiTextField(
                label: AppStrings.fldChildrenCount.tr,
                controller: controller.childrenCtrl,
                keyboardType: TextInputType.number,
                purple: true,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: KafiTextField(
                label: AppStrings.fldChildrenAges.tr,
                controller: controller.childrenAgesCtrl,
                hint: AppStrings.familyChildrenAgesHint.tr,
                purple: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _label(AppStrings.fldHomeLanguages.tr),
        const SizedBox(height: 4),
        Obx(() => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.homeLanguages
                  .map((l) => KafiChip(
                        label: l,
                        purple: true,
                        selected: controller.languages.contains(l),
                        onTap: () => controller.toggle(controller.languages, l),
                      ))
                  .toList(),
            )),
        const SizedBox(height: 8),
        _label(AppStrings.familyHomeCameras.tr),
        const SizedBox(height: 4),
        Obx(() => Row(
              children: [
                Expanded(
                  child: KafiToggleTile(
                    label: AppStrings.familyHasCameras.tr,
                    icon: Icons.videocam_outlined,
                    purple: true,
                    selected: controller.hasCameras.value,
                    onTap: () => controller.hasCameras.value = true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: KafiToggleTile(
                    label: AppStrings.familyNoCameras.tr,
                    icon: Icons.videocam_off_outlined,
                    purple: true,
                    selected: !controller.hasCameras.value,
                    onTap: () => controller.hasCameras.value = false,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 8),
        _label(AppStrings.familyPets.tr),
        const SizedBox(height: 4),
        Obx(() => Row(
              children: [
                Expanded(child: _petTile('🐕', 'Dog')),
                const SizedBox(width: 6),
                Expanded(child: _petTile('🐈', 'Cat')),
              ],
            )),
      ],
    );
  }

  String _petLabel(String stored) => switch (stored) {
        'Dog' => AppStrings.petDog.tr,
        'Cat' => AppStrings.petCat.tr,
        _ => stored,
      };

  Widget _petTile(String emoji, String type) {
    final selected = controller.petTypes.contains(type);
    return GestureDetector(
      onTap: () => controller.toggle(controller.petTypes, type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(_petLabel(type),
                style: KafiTheme.nunito(10.5,
                    color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // ── Religion & Household Culture ───────────────────────────────────────────
  // ── About your family (free-text introduction) ──────────────────────────────
  Widget _aboutFamily() {
    return KafiSection(
      title: AppStrings.fldAboutFamily.tr,
      icon: Icons.favorite_border,
      accent: KafiSectionAccent.purple,
      children: [
        _label(AppStrings.familyAboutPrompt.tr),
        const SizedBox(height: 5),
        KafiTextField(
          label: AppStrings.familyAboutLabel.tr,
          controller: controller.aboutFamilyCtrl,
          hint: AppStrings.familyAboutHint.tr,
          maxLines: 5,
          purple: true,
        ),
      ],
    );
  }

  Widget _religion() {
    return KafiSection(
      title: AppStrings.familySectionReligion.tr,
      icon: Icons.shield_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: KafiColors.purL,
            border: Border.all(color: KafiColors.purB, width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            AppStrings.familyReligionBanner.tr,
            style: KafiTheme.nunito(9.5, color: const Color(0xFF4A2080), w: FontWeight.w600).copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 10),
        _label(AppStrings.familyReligionLabel.tr),
        const SizedBox(height: 5),
        Obx(() => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 2.6,
              children: _religions
                  .map((r) => _religionTile(r.$2, r.$1, _religionLabel(r.$1), controller.religion.value == r.$1))
                  .toList(),
            )),
        const SizedBox(height: 8),
        _label(AppStrings.familyReligionPrefPrompt.tr),
        const SizedBox(height: 5),
        Obx(() => Column(
              children: _religionPrefs
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _radioTile(p.$2, controller.religionPref.value == p.$1,
                            () => controller.religionPref.value = p.$1),
                      ))
                  .toList(),
            )),
        const SizedBox(height: 4),
        KafiTextField(
          label: AppStrings.familyHouseRulesLabel.tr,
          controller: controller.houseRulesCtrl,
          hint: AppStrings.familyHouseRulesHint.tr,
          maxLines: 2,
          purple: true,
        ),
      ],
    );
  }

  Widget _religionTile(String emoji, String storedValue, String label, bool selected) {
    return GestureDetector(
      onTap: () => controller.religion.value = selected ? '' : storedValue,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KafiTheme.nunito(10, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _radioTile(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: selected ? KafiColors.pur : Colors.transparent,
                shape: BoxShape.circle,
                border: selected ? null : Border.all(color: KafiColors.purB, width: 2),
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white, size: 9) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: KafiTheme.nunito(10, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Role & Job Type ────────────────────────────────────────────────────────
  Widget _roleJobType() {
    return KafiSection(
      title: AppStrings.familySectionRole.tr,
      icon: Icons.work_outline,
      accent: KafiSectionAccent.purple,
      children: [
        _label(AppStrings.fldRolePrompt.tr),
        const SizedBox(height: 4),
        FamilyRoleSelector(controller),
        const SizedBox(height: 8),
        _label(AppStrings.fldJobType.tr),
        const SizedBox(height: 4),
        Obx(() => Row(
              children: [
                Expanded(
                  child: KafiToggleTile(
                    label: AppStrings.jobLiveIn.tr,
                    icon: Icons.house,
                    purple: true,
                    selected: controller.jobType.value == JobType.liveIn,
                    onTap: () => controller.jobType.value = JobType.liveIn,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: KafiToggleTile(
                    label: AppStrings.jobLiveOut.tr,
                    icon: Icons.directions_car_outlined,
                    purple: true,
                    selected: controller.jobType.value == JobType.liveOut,
                    onTap: () => controller.jobType.value = JobType.liveOut,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 8),
        _label(AppStrings.fldEmployment.tr),
        const SizedBox(height: 4),
        Obx(() {
          final locked = controller.employmentLocked.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: KafiToggleTile(
                      label: AppStrings.employmentFullTime.tr,
                      icon: Icons.work_outline,
                      purple: true,
                      selected: controller.employmentType.value == JobEmploymentType.fullTime,
                      onTap: locked
                          ? () {}
                          : () => controller.employmentType.value =
                              JobEmploymentType.fullTime,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: KafiToggleTile(
                      label: AppStrings.employmentPartTime.tr,
                      icon: Icons.schedule,
                      purple: true,
                      selected: controller.employmentType.value == JobEmploymentType.partTime,
                      onTap: locked
                          ? () {}
                          : () => controller.employmentType.value =
                              JobEmploymentType.partTime,
                    ),
                  ),
                ],
              ),
              if (locked) ...[
                const SizedBox(height: 6),
                Text(AppStrings.familyEmploymentLockedHint.tr,
                    style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ],
          );
        }),
        const SizedBox(height: 6),
        _label(AppStrings.fldDaysOff.tr),
        const SizedBox(height: 4),
        FamilyDaysOffSelector(controller),
      ],
    );
  }

  Widget _duties() {
    return KafiSection(
      title: AppStrings.familySectionDuties.tr,
      icon: Icons.checklist,
      accent: KafiSectionAccent.purple,
      children: [
        Obx(() => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.duties
                  .map((d) => KafiChip(
                        label: d,
                        purple: true,
                        selected: controller.duties.contains(d),
                        onTap: () => controller.toggle(controller.duties, d),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  Widget _benefits() {
    return KafiSection(
      title: AppStrings.familySectionBenefits.tr,
      icon: Icons.card_giftcard,
      accent: KafiSectionAccent.green,
      children: [
        Obx(() => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.benefits
                  .map((b) => KafiChip(
                        label: b,
                        selected: controller.benefits.contains(b),
                        onTap: () => controller.toggle(controller.benefits, b),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  // ── Salary, Trial & Visa ───────────────────────────────────────────────────
  Widget _salaryTrialVisa() {
    return KafiSection(
      title: AppStrings.familySectionSalary.tr,
      icon: Icons.payments_outlined,
      accent: KafiSectionAccent.teal,
      children: [
        Row(
          children: [
            Expanded(
              child: KafiTextField(
                label: AppStrings.fldSalaryMin.tr,
                controller: controller.salaryMinCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: KafiTextField(
                label: AppStrings.fldSalaryMax.tr,
                controller: controller.salaryMaxCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Obx(() => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(AppStrings.fldTrialDays.tr),
                        const SizedBox(height: 3),
                        _dropdownInt(
                          value: FamilyConstants.trialDurations.contains(controller.trialDays.value)
                              ? controller.trialDays.value
                              : FamilyConstants.trialDurations.first,
                          items: FamilyConstants.trialDurations,
                          onChanged: (v) => controller.trialDays.value = v ?? controller.trialDays.value,
                        ),
                      ],
                    ),
                  )),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: KafiTextField(
                label: AppStrings.fldTrialRate.tr,
                controller: controller.trialRateCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        Obx(() => Column(
              children: [
                _vt(AppStrings.spFull.tr, VisaSponsorship.full),
                _vt(AppStrings.spShared.tr, VisaSponsorship.shared),
                _vt(AppStrings.spResidence.tr, VisaSponsorship.residenceOnly),
                _vt(AppStrings.spNone.tr, VisaSponsorship.none),
              ],
            )),
        const SizedBox(height: 6),
        Obx(() => Row(
              children: [
                Checkbox(
                  value: controller.commit.value,
                  activeColor: KafiColors.pur,
                  onChanged: (v) => controller.commit.value = v ?? false,
                ),
                Expanded(
                  child: Text(AppStrings.spCommit.tr, style: KafiTheme.nunito(10, color: KafiColors.tm)),
                ),
              ],
            )),
      ],
    );
  }

  Widget _vt(String label, VisaSponsorship v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: KafiToggleTile(
        label: label,
        selected: controller.visaSponsorship.value == v,
        onTap: () => controller.visaSponsorship.value = v,
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _label(String text) =>
      Text(text, style: KafiTheme.nunito(9, color: _purpleLabel, w: FontWeight.w800));

  Widget _dropdownInt({
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: KafiColors.inputBgP,
        border: Border.all(color: KafiColors.purB, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          items: items
              .map((d) => DropdownMenuItem(
                  value: d, child: Text(AppStrings.familyTrialDaysN.trParams({'n': '$d'}))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
