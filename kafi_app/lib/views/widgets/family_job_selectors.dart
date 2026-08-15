import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/emirate_ui.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

/// Shared family/job selectors used by both the family onboarding form and
/// the family edit screen so the emirate/role/days-off UI is defined once
/// (previously duplicated between the two screens).

/// Single-select emirate chips — the 7 real UAE emirates, reusing the shared
/// [Emirate] enum via [kFamilyEmirates]/[emirateLabel].
class FamilyEmirateSelector extends StatelessWidget {
  const FamilyEmirateSelector(this.controller, {super.key});

  final FamilyProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
          spacing: 4,
          runSpacing: 4,
          children: kFamilyEmirates
              .map((e) => KafiChip(
                    label: emirateLabel(e),
                    purple: true,
                    selected: controller.cityEmirate.value == e,
                    onTap: () => controller.cityEmirate.value = e,
                  ))
              .toList(),
        ));
  }
}

/// Multi-select role chips with an "Other" reveal field for a custom role.
class FamilyRoleSelector extends StatelessWidget {
  const FamilyRoleSelector(this.controller, {super.key});

  final FamilyProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Obx(() => controller.roles.contains('Other')
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: KafiTextField(
                  label: AppStrings.fldRoleOther.tr,
                  controller: controller.rolesOtherCtrl,
                  purple: true,
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }
}

/// Single-select days-off chips (1 / 2 / Other) — no elaboration field for
/// "Other"; the value persisted is the canonical option label itself.
class FamilyDaysOffSelector extends StatelessWidget {
  const FamilyDaysOffSelector(this.controller, {super.key});

  final FamilyProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
          spacing: 4,
          runSpacing: 4,
          children: FamilyConstants.daysOffOptions
              .map((o) => KafiChip(
                    label: o,
                    purple: true,
                    selected: controller.daysOff.value == o,
                    onTap: () => controller.daysOff.value = o,
                  ))
              .toList(),
        ));
  }
}
