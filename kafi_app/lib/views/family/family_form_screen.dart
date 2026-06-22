import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_location_picker.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_section.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

class FamilyFormScreen extends GetView<FamilyProfileController> {
  const FamilyFormScreen({super.key});

  static const _purpleLabel = Color(0xFF5A2090);

  static const List<(String, String)> _religions = [
    ('Muslim', '☪️'), ('Christian', '✝️'), ('Hindu', '🕉️'),
    ('Buddhist', '☸️'), ('Jewish', '✡️'), ('Other', '🌍'),
  ];

  static const List<(NannyReligionPreference, String)> _religionPrefs = [
    (NannyReligionPreference.noPreference, 'No — nanny can be of any religion'),
    (NannyReligionPreference.preferMuslim, 'We prefer a Muslim nanny (halal diet, prayer respect)'),
    (NannyReligionPreference.preferSame, 'We prefer a nanny of the same religion as ours'),
    (NannyReligionPreference.openWithRespect, 'We are open — but nanny must respect our home rules'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
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
    );
  }

  Widget _hero() {
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
            padding: const EdgeInsets.only(left: 28),
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
          hint: 'e.g. Al Rashid Family',
          purple: true,
        ),
        _label('Your nationality'),
        const SizedBox(height: 4),
        Obx(() => _dropdown(
              value: controller.nationality.value,
              items: NannyConstants.nationalities,
              onChanged: (v) => controller.nationality.value = v ?? controller.nationality.value,
            )),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(AppStrings.fldCity.tr),
                  const SizedBox(height: 4),
                  Obx(() => controller.detectingCity.value
                      ? _detectingCity()
                      : KafiLocationPicker(
                          initialValue: controller.city.value,
                          onChanged: (v) => controller.city.value = v,
                        )),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: KafiTextField(
                label: AppStrings.fldChildrenCount.tr,
                controller: controller.childrenCtrl,
                keyboardType: TextInputType.number,
                purple: true,
              ),
            ),
          ],
        ),
        KafiTextField(
          label: "Children's ages",
          controller: controller.childrenAgesCtrl,
          hint: 'e.g. 6 months, 3 years, 7 years',
          purple: true,
        ),
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
        _label('Home cameras?'),
        const SizedBox(height: 4),
        Obx(() => Row(
              children: [
                Expanded(
                  child: KafiToggleTile(
                    label: 'Yes, we have cameras',
                    icon: Icons.videocam_outlined,
                    purple: true,
                    selected: controller.hasCameras.value,
                    onTap: () => controller.hasCameras.value = true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: KafiToggleTile(
                    label: 'No cameras',
                    icon: Icons.videocam_off_outlined,
                    purple: true,
                    selected: !controller.hasCameras.value,
                    onTap: () => controller.hasCameras.value = false,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 8),
        _label('Pets?'),
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
            Text(type,
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
      title: 'About Your Family',
      icon: Icons.favorite_border,
      accent: KafiSectionAccent.purple,
      children: [
        _label('Tell nannies a little about your family'),
        const SizedBox(height: 5),
        KafiTextField(
          label: 'Family information',
          controller: controller.aboutFamilyCtrl,
          hint: 'e.g. We are a warm family of four in Dubai. Both parents work. '
              'We value kindness, routine and good communication. Our home is '
              'smoke-free and we love weekend outings with the kids.',
          maxLines: 5,
          purple: true,
        ),
      ],
    );
  }

  Widget _religion() {
    return KafiSection(
      title: 'Religion & Household Culture',
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
            'This helps us match you with nannies whose lifestyle and practices are compatible with your home. All information is treated with full respect and privacy.',
            style: KafiTheme.nunito(9.5, color: const Color(0xFF4A2080), w: FontWeight.w600).copyWith(height: 1.5),
          ),
        ),
        const SizedBox(height: 10),
        _label("Your family's religion (optional)"),
        const SizedBox(height: 5),
        Obx(() => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 2.6,
              children: _religions
                  .map((r) => _religionTile(r.$2, r.$1, controller.religion.value == r.$1))
                  .toList(),
            )),
        const SizedBox(height: 8),
        _label('Do you require the nanny to follow any religious practices?'),
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
          label: 'Any faith-related house rules to mention? (optional)',
          controller: controller.houseRulesCtrl,
          hint: 'e.g. Halal food only · No pork · Prayer times respected · No alcohol',
          maxLines: 2,
          purple: true,
        ),
      ],
    );
  }

  Widget _religionTile(String emoji, String label, bool selected) {
    return GestureDetector(
      onTap: () => controller.religion.value = selected ? '' : label,
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
        _label('Role(s) needed'),
        const SizedBox(height: 4),
        Obx(() => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.roles
                  .map((r) => KafiChip(
                        label: r,
                        purple: true,
                        selected: controller.roles.contains(r),
                        onTap: () => controller.toggle(controller.roles, r),
                      ))
                  .toList(),
            )),
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
        Obx(() => Row(
              children: [
                Expanded(
                  child: KafiToggleTile(
                    label: AppStrings.employmentFullTime.tr,
                    icon: Icons.work_outline,
                    purple: true,
                    selected: controller.employmentType.value == JobEmploymentType.fullTime,
                    onTap: () => controller.employmentType.value = JobEmploymentType.fullTime,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: KafiToggleTile(
                    label: AppStrings.employmentPartTime.tr,
                    icon: Icons.schedule,
                    purple: true,
                    selected: controller.employmentType.value == JobEmploymentType.partTime,
                    onTap: () => controller.employmentType.value = JobEmploymentType.partTime,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 6),
        KafiTextField(
          label: AppStrings.fldSchedule.tr,
          controller: controller.scheduleCtrl,
          hint: 'e.g. Sun–Thu, 8am–6pm or 6 days/week',
          purple: true,
        ),
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

  /// Placeholder shown while the city is being auto-detected from GPS.
  Widget _detectingCity() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: KafiColors.cardBorder),
          borderRadius: BorderRadius.circular(12),
          color: KafiColors.inputBg,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: KafiColors.roseD),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(AppStrings.locationDetecting.tr,
                  style: KafiTheme.nunito(13, color: KafiColors.ts)),
            ),
          ],
        ),
      );

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safe = items.contains(value) ? value : (items.isNotEmpty ? items.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: KafiColors.inputBgP,
        border: Border.all(color: KafiColors.purB, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safe,
          style: KafiTheme.nunito(11, color: KafiColors.td),
          items: items.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

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
          items: items.map((d) => DropdownMenuItem(value: d, child: Text('$d days'))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
