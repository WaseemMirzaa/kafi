import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/views/family/family_household_fields.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_location_picker.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_section.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

/// Screen 27B — Edit family profile.
/// Reuses [FamilyProfileController] which already hydrates from saved data
/// in `onInit`, so this screen just renders the form and calls `saveEdit()`.
class FamilyEditScreen extends GetView<FamilyProfileController> {
  const FamilyEditScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: KafiColors.purL,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KafiColors.purB, width: 1.2),
                      ),
                      child: Text(
                        AppStrings.familyEditSubtitle.tr,
                        style: KafiTheme.nunito(10, color: KafiColors.pur),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _youSection(),
                    // Nationality, cameras, pets, religion & religion-preference —
                    // captured at create but previously omitted from edit.
                    const FamilyHouseholdFields(),
                    _roleSection(),
                    _dutiesSection(),
                    _benefitsSection(),
                    _salarySection(),
                    _visaSection(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Obx(
                () => KafiPrimaryButton(
                  label: AppStrings.familyEditSave.tr,
                  variant: KafiButtonVariant.purple,
                  loading: controller.isLoading.value,
                  onPressed: controller.saveEdit,
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
      child: Row(
        children: [
          GestureDetector(
            onTap: AppNavigation.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
            ),
          ),
          Expanded(
            child: Text(AppStrings.familyEditTitle.tr,
                style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090))),
          ),
        ],
      ),
    );
  }

  Widget _youSection() => KafiSection(
        title: AppStrings.familySectionYou.tr,
        icon: Icons.family_restroom,
        accent: KafiSectionAccent.purple,
        children: [
          KafiTextField(
            label: AppStrings.fldFullName.tr,
            controller: controller.fullNameCtrl,
            purple: true,
          ),
          KafiTextField(
            label: AppStrings.fldChildrenCount.tr,
            controller: controller.childrenCtrl,
            keyboardType: TextInputType.number,
            purple: true,
          ),
          Text(AppStrings.fldCity.tr,
              style: KafiTheme.nunito(9,
                  color: const Color(0xFF5A2090), w: FontWeight.w800)),
          const SizedBox(height: 4),
          Obx(
            () => KafiLocationPicker(
              initialValue: controller.city.value,
              onChanged: (v) => controller.city.value = v,
            ),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.fldHomeLanguages.tr,
              style: KafiTheme.nunito(9,
                  color: const Color(0xFF5A2090), w: FontWeight.w800)),
          const SizedBox(height: 4),
          Obx(
            () => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.homeLanguages
                  .map(
                    (l) => KafiChip(
                      label: l,
                      purple: true,
                      selected: controller.languages.contains(l),
                      onTap: () => controller.toggle(controller.languages, l),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 6),
          KafiTextField(
            label: AppStrings.fldChildrenAges.tr,
            controller: controller.childrenAgesCtrl,
            // Comma-separated to match the parser (was "2 & 5", which the
            // comma-only split rejected) — FAM-5.
            hint: 'e.g. 2, 5',
            purple: true,
          ),
          KafiTextField(
            label: AppStrings.fldAboutFamily.tr,
            controller: controller.aboutFamilyCtrl,
            maxLines: 3,
            purple: true,
          ),
          KafiTextField(
            label: AppStrings.fldHouseRules.tr,
            controller: controller.houseRulesCtrl,
            maxLines: 2,
            purple: true,
          ),
        ],
      );

  Widget _roleSection() => KafiSection(
        title: AppStrings.familySectionRole.tr,
        icon: Icons.work_outline,
        accent: KafiSectionAccent.purple,
        children: [
          Obx(
            () => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.roles
                  .map(
                    (r) => KafiChip(
                      label: r,
                      purple: true,
                      selected: controller.roles.contains(r),
                      onTap: () => controller.toggle(controller.roles, r),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text(AppStrings.fldJobType.tr,
              style: KafiTheme.nunito(9,
                  color: const Color(0xFF5A2090), w: FontWeight.w800)),
          const SizedBox(height: 4),
          Obx(
            () => Row(
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
                    icon: Icons.directions_walk,
                    purple: true,
                    selected: controller.jobType.value == JobType.liveOut,
                    onTap: () => controller.jobType.value = JobType.liveOut,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(AppStrings.fldEmployment.tr,
              style: KafiTheme.nunito(9, color: const Color(0xFF5A2090), w: FontWeight.w800)),
          const SizedBox(height: 4),
          Obx(
            () => Row(
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
            ),
          ),
          const SizedBox(height: 6),
          KafiTextField(
            label: AppStrings.fldSchedule.tr,
            controller: controller.scheduleCtrl,
            purple: true,
          ),
        ],
      );

  Widget _dutiesSection() => KafiSection(
        title: AppStrings.familySectionDuties.tr,
        icon: Icons.checklist,
        children: [
          Obx(
            () => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.duties
                  .map(
                    (d) => KafiChip(
                      label: d,
                      selected: controller.duties.contains(d),
                      onTap: () => controller.toggle(controller.duties, d),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );

  Widget _benefitsSection() => KafiSection(
        title: AppStrings.familySectionBenefits.tr,
        icon: Icons.card_giftcard,
        accent: KafiSectionAccent.green,
        children: [
          Obx(
            () => Wrap(
              spacing: 4,
              runSpacing: 4,
              children: FamilyConstants.benefits
                  .map(
                    (b) => KafiChip(
                      label: b,
                      selected: controller.benefits.contains(b),
                      onTap: () => controller.toggle(controller.benefits, b),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );

  Widget _salarySection() => KafiSection(
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
                child: Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.fldTrialDays.tr,
                            style: KafiTheme.nunito(9,
                                color: KafiColors.tm, w: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: KafiColors.inputBg,
                            border: Border.all(
                                color: KafiColors.cardBorder, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: controller.trialDays.value,
                              items: FamilyConstants.trialDurations
                                  .map((d) => DropdownMenuItem(
                                      value: d, child: Text('$d days')))
                                  .toList(),
                              onChanged: (v) => controller.trialDays.value =
                                  v ?? controller.trialDays.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
        ],
      );

  Widget _visaSection() => KafiSection(
        title: AppStrings.familySectionVisa.tr,
        icon: Icons.shield_outlined,
        accent: KafiSectionAccent.teal,
        children: [
          Obx(
            () => Column(
              children: [
                _vt(AppStrings.spFull.tr, VisaSponsorship.full),
                _vt(AppStrings.spShared.tr, VisaSponsorship.shared),
                _vt(AppStrings.spResidence.tr, VisaSponsorship.residenceOnly),
                _vt(AppStrings.spNone.tr, VisaSponsorship.none),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Row(
              children: [
                Checkbox(
                  value: controller.commit.value,
                  activeColor: KafiColors.pur,
                  onChanged: (v) => controller.commit.value = v ?? false,
                ),
                Expanded(
                  child: Text(AppStrings.spCommit.tr,
                      style: KafiTheme.nunito(10, color: KafiColors.tm)),
                ),
              ],
            ),
          ),
        ],
      );

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
}
