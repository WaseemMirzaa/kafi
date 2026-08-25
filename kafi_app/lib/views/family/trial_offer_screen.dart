import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/emirate_ui.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_chip.dart';
import 'package:kafi_app/views/widgets/kafi_location_picker.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_section.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';
import 'package:kafi_app/views/widgets/kafi_toggle_box.dart';

class TrialOfferScreen extends StatefulWidget {
  const TrialOfferScreen({super.key});

  @override
  State<TrialOfferScreen> createState() => _TrialOfferScreenState();
}

class _TrialOfferScreenState extends State<TrialOfferScreen> {
  late final TrialController controller;
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<TrialController>();
    // Prefill location from the family's job emirate when empty (Screen 31).
    if (controller.location.value.trim().isEmpty &&
        Get.isRegistered<FamilyProfileController>()) {
      final emirate = Get.find<FamilyProfileController>().cityEmirate.value;
      if (emirate != null) controller.location.value = emirateLabel(emirate);
    }
    if (controller.dailyRate.value > 0) {
      _rateCtrl.text = '${controller.dailyRate.value}';
    }
    _notesCtrl.text = controller.notes.value;
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nannyName = Get.arguments?['nannyName'] ?? AppStrings.roleFallbackNanny.tr;
    final nannyId = Get.arguments?['nannyId'] ?? '';

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
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _nannyPreview(nannyName),
                    const SizedBox(height: 12),
                    _infoBanner(
                      icon: '🤝',
                      text: AppStrings.trialOfferInfoBanner.tr,
                    ),
                    const SizedBox(height: 12),
                    _detailsSection(),
                    _arrangementSection(),
                    _locationNotesSection(),
                    _disclaimer(),
                    const SizedBox(height: 8),
                    Obx(
                      () => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: KafiColors.pur,
                        value: controller.paymentAcknowledged.value,
                        onChanged: (v) =>
                            controller.paymentAcknowledged.value = v ?? false,
                        title: Text(
                          AppStrings.trialOfferAckLabel.tr,
                          style: KafiTheme.nunito(10,
                              color: KafiColors.tm, w: FontWeight.w600),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _sendButton(nannyId),
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
            onTap: Get.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
            ),
          ),
          Expanded(
            child: Text(AppStrings.trialOfferTitle.tr,
                style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090))),
          ),
        ],
      ),
    );
  }

  Widget _nannyPreview(String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KafiColors.purB, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x149B6EDB), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B6EDB), Color(0xFFC084FC)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'N',
                  style: KafiTheme.fredoka(18,
                      color: Colors.white, w: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: KafiTheme.nunito(13,
                        color: KafiColors.td, w: FontWeight.w900)),
                Text(AppStrings.trialOfferTo.tr,
                    style: KafiTheme.nunito(9.5,
                        color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: KafiColors.grnL, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 11, color: KafiColors.grnD),
                const SizedBox(width: 3),
                Text(AppStrings.verifiedBadge.tr,
                    style: KafiTheme.fredoka(9,
                        color: KafiColors.grnD, w: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsSection() {
    return KafiSection(
      title: AppStrings.trialOfferDuration.tr,
      icon: Icons.event_note,
      accent: KafiSectionAccent.purple,
      children: [
        _fieldLabel(AppStrings.trialOfferDuration.tr),
        const SizedBox(height: 5),
        Obx(() => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: FamilyConstants.trialDurations.map((d) {
                return KafiChip(
                  label: AppStrings.trialOfferDurationDays
                      .trParams({'days': '$d'}),
                  selected: controller.durationDays.value == d,
                  variant: KafiChipVariant.purple,
                  onTap: () => controller.durationDays.value = d,
                );
              }).toList(),
            )),
        const SizedBox(height: 10),
        KafiTextField(
          label: '${AppStrings.trialOfferRate.tr} (${AppStrings.trialOfferRateUnit.tr})',
          hint: AppStrings.trialOfferRateHint.tr,
          controller: _rateCtrl,
          keyboardType: TextInputType.number,
          purple: true,
          onChanged: (v) =>
              controller.dailyRate.value = int.tryParse(v.trim()) ?? 0,
        ),
        _fieldLabel(AppStrings.trialOfferStart.tr),
        const SizedBox(height: 5),
        _dateField(),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _dateField() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final date = await showDatePicker(
          context: context,
          initialDate: controller.startDate.value ?? today.add(const Duration(days: 1)),
          firstDate: today,
          lastDate: today.add(const Duration(days: 90)),
        );
        if (date != null) controller.startDate.value = date;
      },
      child: Obx(
        () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: KafiColors.inputBgP,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: KafiColors.purB, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: KafiColors.pur, size: 15),
              const SizedBox(width: 10),
              Text(
                controller.startDate.value != null
                    ? '${controller.startDate.value!.day}/${controller.startDate.value!.month}/${controller.startDate.value!.year}'
                    : AppStrings.trialOfferSelectDate.tr,
                style: KafiTheme.nunito(11.5,
                    color: controller.startDate.value != null
                        ? KafiColors.td
                        : KafiColors.ts,
                    w: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrangementSection() {
    return KafiSection(
      title: AppStrings.trialOfferType.tr,
      icon: Icons.home_work_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        Obx(() => Row(
              children: [
                Expanded(
                  child: KafiToggleBox(
                    icon: '🏠',
                    label: AppStrings.trialOfferLiveInTitle.tr,
                    selected: controller.trialType.value == 'live-in',
                    variant: KafiToggleVariant.purple,
                    onTap: () => controller.trialType.value = 'live-in',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: KafiToggleBox(
                    icon: '🏡',
                    label: AppStrings.trialOfferLiveOutTitle.tr,
                    selected: controller.trialType.value == 'live-out',
                    variant: KafiToggleVariant.purple,
                    onTap: () => controller.trialType.value = 'live-out',
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Widget _locationNotesSection() {
    return KafiSection(
      title: AppStrings.trialLocation.tr,
      icon: Icons.location_on_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        _fieldLabel(AppStrings.trialLocation.tr),
        const SizedBox(height: 5),
        Obx(() => KafiLocationPicker(
              initialValue: controller.location.value,
              onChanged: (v) => controller.location.value = v,
            )),
        const SizedBox(height: 8),
        KafiTextField(
          label: AppStrings.trialOfferNotes.tr,
          hint: AppStrings.trialOfferNotesHint.tr,
          controller: _notesCtrl,
          maxLines: 3,
          maxLength: FamilyConstants.maxTrialNotesLength,
          purple: true,
          onChanged: (v) => controller.notes.value = v,
        ),
        Obx(() {
          final n = controller.notes.value.length;
          return Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$n/${FamilyConstants.maxTrialNotesLength}',
              style: KafiTheme.nunito(9,
                  color: n > FamilyConstants.maxTrialNotesLength
                      ? KafiColors.roseD
                      : KafiColors.ts,
                  w: FontWeight.w600),
            ),
          );
        }),
      ],
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: KafiColors.ambL,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFFFD080), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: KafiColors.ambD, size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              AppStrings.trialOfferDisclaimer.tr,
              style: KafiTheme.nunito(10,
                      color: const Color(0xFF7A4A00), w: FontWeight.w600)
                  .copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) =>
      Text(text, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800));

  Widget _infoBanner({required String icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [KafiColors.purL, Color(0xFFEDE4FF)]),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(text,
                style: KafiTheme.nunito(9.5,
                        color: const Color(0xFF4A2080), w: FontWeight.w700)
                    .copyWith(height: 1.45)),
          ),
        ],
      ),
    );
  }

  Widget _sendButton(String nannyId) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x18FF5F96), blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => Text(
                  AppStrings.trialOfferTotal.trParams({
                    'total':
                        '${controller.dailyRate.value * controller.durationDays.value}',
                  }),
                  style: KafiTheme.nunito(14,
                      color: KafiColors.td, w: FontWeight.w900),
                ),
              ),
              Obx(() {
                final err = controller.trialOfferFormError;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    err.tr,
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(10,
                        color: KafiColors.roseD, w: FontWeight.w700),
                  ),
                );
              }),
              const SizedBox(height: 9),
              Obx(
                () => KafiPrimaryButton(
                  label: AppStrings.trialOfferSend.tr,
                  variant: KafiButtonVariant.purple,
                  loading: controller.isLoading.value,
                  onPressed: () async {
                    final ok = await controller.sendTrialOffer(
                      nannyId: nannyId,
                      nannyName: Get.arguments?['nannyName'] ?? AppStrings.roleFallbackNanny.tr,
                      threadId: Get.arguments?['threadId'] as String?,
                    );
                    if (ok) {
                      AppNavigation.openChat(
                        nannyId: nannyId,
                        nannyName: Get.arguments?['nannyName'] ?? AppStrings.roleFallbackNanny.tr,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
