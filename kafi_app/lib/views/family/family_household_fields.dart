import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_searchable_picker.dart';
import 'package:kafi_app/views/widgets/kafi_section.dart';

/// The household & religion profile fields (nationality, home cameras, pets,
/// family religion, and the nanny-religion preference), bound to the shared
/// [FamilyProfileController]. Extracted so the family EDIT screen has parity
/// with the create form, which previously captured these but the edit screen
/// omitted them (so they were uneditable post-onboarding).
class FamilyHouseholdFields extends StatelessWidget {
  const FamilyHouseholdFields({super.key});

  // The first element of each tuple is the stored value (kept in English so
  // it matches existing profile data); the display label is localized
  // separately via [_religionLabel] — mirrors FamilyFormScreen._religions.
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

  String _petLabel(String stored) => switch (stored) {
        'Dog' => AppStrings.petDog.tr,
        'Cat' => AppStrings.petCat.tr,
        _ => stored,
      };

  // Labels are localized at read time, so this can't be `const`.
  List<(NannyReligionPreference, String)> get _religionPrefs => [
    (NannyReligionPreference.noPreference, AppStrings.familyReligionPrefNone.tr),
    (NannyReligionPreference.preferMuslim, AppStrings.familyReligionPrefMuslim.tr),
    (NannyReligionPreference.preferSame, AppStrings.familyReligionPrefSame.tr),
    (NannyReligionPreference.openWithRespect, AppStrings.familyReligionPrefOpen.tr),
  ];

  FamilyProfileController get _c => Get.find<FamilyProfileController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KafiSection(
          title: AppStrings.familySectionYou.tr,
          icon: Icons.home_outlined,
          accent: KafiSectionAccent.purple,
          children: [
            _label(AppStrings.familyYourNationality.tr),
            const SizedBox(height: 4),
            Obx(() => KafiSearchablePicker(
                  value: _c.nationality.value,
                  options: NannyConstants.nationalities,
                  title: AppStrings.familyYourNationality.tr,
                  hint: AppStrings.familyYourNationality.tr,
                  icon: Icons.flag_outlined,
                  purple: true,
                  onSelected: (v) => _c.nationality.value = v,
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
                        selected: _c.hasCameras.value,
                        onTap: () => _c.hasCameras.value = true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: KafiToggleTile(
                        label: AppStrings.familyNoCameras.tr,
                        icon: Icons.videocam_off_outlined,
                        purple: true,
                        selected: !_c.hasCameras.value,
                        onTap: () => _c.hasCameras.value = false,
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
        ),
        KafiSection(
          title: AppStrings.familySectionReligion.tr,
          icon: Icons.shield_outlined,
          accent: KafiSectionAccent.purple,
          children: [
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
                      .map((r) => _religionTile(r.$2, r.$1, _religionLabel(r.$1), _c.religion.value == r.$1))
                      .toList(),
                )),
            const SizedBox(height: 8),
            _label(AppStrings.familyReligionPrefPrompt.tr),
            const SizedBox(height: 5),
            Obx(() => Column(
                  children: _religionPrefs
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: _radioTile(p.$2, _c.religionPref.value == p.$1,
                                () => _c.religionPref.value = p.$1),
                          ))
                      .toList(),
                )),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: KafiTheme.nunito(9, color: const Color(0xFF5A2090), w: FontWeight.w800)),
      );

  Widget _petTile(String emoji, String type) {
    final selected = _c.petTypes.contains(type);
    return GestureDetector(
      onTap: () => _c.toggle(_c.petTypes, type),
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
                style: KafiTheme.nunito(10.5, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _religionTile(String emoji, String storedValue, String label, bool selected) {
    return GestureDetector(
      onTap: () => _c.religion.value = selected ? '' : storedValue,
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
}
