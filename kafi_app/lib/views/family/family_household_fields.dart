import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
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

  FamilyProfileController get _c => Get.find<FamilyProfileController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KafiSection(
          title: 'Household',
          icon: Icons.home_outlined,
          accent: KafiSectionAccent.purple,
          children: [
            _label('Your nationality'),
            const SizedBox(height: 4),
            Obx(() => KafiSearchablePicker(
                  value: _c.nationality.value,
                  options: NannyConstants.nationalities,
                  title: 'Your nationality',
                  hint: 'Your nationality',
                  icon: Icons.flag_outlined,
                  purple: true,
                  onSelected: (v) => _c.nationality.value = v,
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
                        selected: _c.hasCameras.value,
                        onTap: () => _c.hasCameras.value = true,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: KafiToggleTile(
                        label: 'No cameras',
                        icon: Icons.videocam_off_outlined,
                        purple: true,
                        selected: !_c.hasCameras.value,
                        onTap: () => _c.hasCameras.value = false,
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
        ),
        KafiSection(
          title: 'Religion & Household Culture',
          icon: Icons.shield_outlined,
          accent: KafiSectionAccent.purple,
          children: [
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
                      .map((r) => _religionTile(r.$2, r.$1, _c.religion.value == r.$1))
                      .toList(),
                )),
            const SizedBox(height: 8),
            _label('Do you require the nanny to follow any religious practices?'),
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
            Text(type,
                style: KafiTheme.nunito(10.5, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _religionTile(String emoji, String label, bool selected) {
    return GestureDetector(
      onTap: () => _c.religion.value = selected ? '' : label,
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
