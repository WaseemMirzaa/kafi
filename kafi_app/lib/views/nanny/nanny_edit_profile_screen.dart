import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_input.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Screen 27A — Nanny edit profile.
/// Per System Spec §6.7: nannies can update bio, photos, and languages after
/// approval without re-verification.
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
                  children: NannyConstants.languages
                      .map((lang) => KafiChip(
                            label: lang,
                            selected: ctrl.selectedLanguages.contains(lang),
                            onTap: () => ctrl.toggleLanguage(lang),
                          ))
                      .toList(),
                ),
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
                  final ok = await ctrl.saveProfileDraft();
                  if (!ok) return; // stay on the screen; error already shown
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
