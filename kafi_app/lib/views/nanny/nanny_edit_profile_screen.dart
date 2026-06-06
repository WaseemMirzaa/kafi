import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';
import 'package:kafi_app/views/widgets/kafi_input.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Screen 27A — Nanny edit profile.
/// Per System Spec §6.7: nannies can update bio, photos, languages, and
/// emergency contact after approval without re-verification.
class NannyEditProfileScreen extends StatelessWidget {
  const NannyEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NannyProfileController>();

    return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      appBar: KafiAppBar(title: AppStrings.editProfile.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _section(
              AppStrings.editBio.tr,
              KafiInput(
                controller: ctrl.bioCtrl,
                hint: AppStrings.editBioHint.tr,
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 14),
            _section(
              AppStrings.editLanguages.tr,
              Obx(
                () => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    'English',
                    'Arabic',
                    'French',
                    'Hindi',
                    'Tagalog',
                    'Amharic',
                  ].map((lang) {
                    final selected = ctrl.selectedLanguages.contains(lang);
                    return GestureDetector(
                      onTap: () {
                        if (selected) {
                          ctrl.selectedLanguages.remove(lang);
                        } else {
                          ctrl.selectedLanguages.add(lang);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? KafiColors.roseD : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KafiColors.cardBorder),
                        ),
                        child: Text(
                          lang,
                          style: KafiTheme.fredoka(
                            10,
                            color: selected ? Colors.white : KafiColors.tm,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _section(
              AppStrings.editEmergencyContact.tr,
              Column(
                children: [
                  KafiInput(
                    controller: ctrl.emergencyNameCtrl,
                    hint: AppStrings.fldEmergencyName.tr,
                  ),
                  const SizedBox(height: 8),
                  KafiInput(
                    controller: ctrl.emergencyRelCtrl,
                    hint: AppStrings.fldEmergencyRel.tr,
                  ),
                  const SizedBox(height: 8),
                  KafiInput(
                    controller: ctrl.emergencyPhoneCtrl,
                    hint: AppStrings.fldEmergencyPhone.tr,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _section(
              AppStrings.editComfort.tr,
              Column(
                children: [
                  _toggleRow(
                    AppStrings.fldComfortCameras.tr,
                    ctrl.comfortCameras,
                  ),
                  _toggleRow(
                    AppStrings.fldComfortPets.tr,
                    ctrl.comfortPets,
                  ),
                  _toggleRow(
                    AppStrings.fldCooks.tr,
                    ctrl.cooks,
                  ),
                  _toggleRow(
                    AppStrings.fldNightShifts.tr,
                    ctrl.nightShifts,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => KafiPrimaryButton(
                label: AppStrings.save.tr,
                loading: ctrl.isLoading.value,
                onPressed: () async {
                  await ctrl.saveProfileDraft();
                  Get.snackbar(
                    AppStrings.successTitle.tr,
                    AppStrings.profileUpdated.tr,
                  );
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KafiColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _toggleRow(String label, RxBool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: KafiTheme.nunito(11, color: KafiColors.tm)),
          ),
          Obx(
            () => Switch(
              value: value.value,
              activeThumbColor: KafiColors.roseD,
              onChanged: (v) => value.value = v,
            ),
          ),
        ],
      ),
    );
  }
}
