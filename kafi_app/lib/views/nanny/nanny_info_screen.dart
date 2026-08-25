import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_chip_wrap.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_searchable_picker.dart';
import 'package:kafi_app/views/widgets/kafi_section.dart';
import 'package:kafi_app/views/widgets/kafi_step_scaffold.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';
import 'package:kafi_app/views/widgets/kafi_toggle_box.dart';

class NannyInfoScreen extends GetView<NannyProfileController> {
  const NannyInfoScreen({super.key});

  /// Single source of truth for the emirate grids (emoji + subtitle; the name
  /// comes from [EmirateX.label]) — drives both the current-emirate and
  /// preferred-emirates boxes so they can never drift out of sync with the
  /// [Emirate] enum the way the old hardcoded 8-box list once did (Al Ain bug).
  static const List<(Emirate, String, String)> _emirates = [
    (Emirate.dubai, '🏙️', 'Most jobs'),
    (Emirate.abuDhabi, '🕌', 'Capital · High demand'),
    (Emirate.sharjah, '🌆', 'Near Dubai'),
    (Emirate.ajman, '🏘️', 'Compact · Affordable'),
    (Emirate.rak, '⛵', 'RAK · Growing fast'),
    (Emirate.fujairah, '🌊', 'East coast · Quiet'),
    (Emirate.uaq, '🤿', 'UAQ · Relaxed pace'),
  ];

  /// Weekday (1=Mon…7=Sun, matches [DateTime.weekday]) → day-chip label key,
  /// driving the part-time availability day picker.
  static const List<(int, String)> _weekdays = [
    (1, AppStrings.dayMon),
    (2, AppStrings.dayTue),
    (3, AppStrings.dayWed),
    (4, AppStrings.dayThu),
    (5, AppStrings.dayFri),
    (6, AppStrings.daySat),
    (7, AppStrings.daySun),
  ];

  @override
  Widget build(BuildContext context) {
    final editMode = Get.arguments is Map && (Get.arguments as Map)['editMode'] == true;
    return KafiStepScaffold(
      step: 1,
      title: AppStrings.nannyAboutYou.tr,
      subtitle: AppStrings.nannyAboutYouSub.tr,
      onBack: editMode ? Get.back : () => Get.offAllNamed(Routes.loginNanny),
      footer: Obx(
        () => KafiPrimaryButton(
          label: editMode ? AppStrings.saveAndClose.tr : AppStrings.nextPhotos.tr,
          icon: editMode ? Icons.check : Icons.arrow_forward,
          loading: controller.isLoading.value,
          onPressed: () => controller.savePersonalInfoAndNext(advance: !editMode),
        ),
      ),
      children: [
        _basic(),
        _visa(),
        _workLocation(),
        _workPrefs(),
        _employment(),
        _personal(),
        _health(),
        _comfort(),
        _religion(),
        _bio(),
      ],
    );
  }

  // ─── DATE PICKERS ────────────────────────────────────────────────────────

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latest = DateTime(now.year - 18, now.month, now.day); // must be 18+
    final current = controller.dob.value;
    final initial = (current != null && !current.isAfter(latest))
        ? current
        : DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: DateTime(now.year - 70),
      lastDate: latest,
      helpText: AppStrings.fldDob.tr,
    );
    if (picked != null) controller.setDob(picked);
  }

  Future<void> _pickAvailableFrom() async {
    final now = DateTime.now();
    final current = controller.availableFrom.value;
    final initial = (current != null && !current.isBefore(now)) ? current : now;
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2, now.month, now.day),
      helpText: AppStrings.nannyAvailableFromDate.tr,
    );
    if (picked != null) controller.setAvailableFrom(picked);
  }

  // ─── WORK PREFERENCES ────────────────────────────────────────────────────

  Widget _workPrefs() {
    return KafiSection(
      title: AppStrings.nannySecWorkPrefs.tr,
      icon: Icons.work_outline,
      accent: KafiSectionAccent.purple,
      children: [
        Text(AppStrings.fldJobType.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => Row(children: [
          Expanded(child: KafiToggleBox(icon: '🏠', label: AppStrings.jobLiveIn.tr, selected: controller.jobTypePref.value == JobTypePreference.liveIn, variant: KafiToggleVariant.purple, onTap: () => controller.jobTypePref.value = JobTypePreference.liveIn)),
          const SizedBox(width: 6),
          Expanded(child: KafiToggleBox(icon: '🚪', label: AppStrings.jobLiveOut.tr, selected: controller.jobTypePref.value == JobTypePreference.liveOut, variant: KafiToggleVariant.purple, onTap: () => controller.jobTypePref.value = JobTypePreference.liveOut)),
          const SizedBox(width: 6),
          Expanded(child: KafiToggleBox(icon: '🔄', label: AppStrings.jobBoth.tr, selected: controller.jobTypePref.value == JobTypePreference.both, variant: KafiToggleVariant.purple, onTap: () => controller.jobTypePref.value = JobTypePreference.both)),
        ])),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: KafiTextField(label: AppStrings.fldSalaryMin.tr, controller: controller.salaryMinCtrl, keyboardType: TextInputType.number, purple: true)),
          const SizedBox(width: 6),
          Expanded(child: KafiTextField(label: AppStrings.fldSalaryMax.tr, controller: controller.salaryMaxCtrl, keyboardType: TextInputType.number, purple: true)),
        ]),
        Text(AppStrings.nannyAvailability.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => Row(children: [
          Expanded(child: KafiToggleBox(icon: '✅', label: AppStrings.availableNow.tr, selected: controller.availability.value == AvailabilityStatus.availableNow, variant: KafiToggleVariant.purple, onTap: () => controller.availability.value = AvailabilityStatus.availableNow)),
          const SizedBox(width: 6),
          Expanded(child: KafiToggleBox(icon: '📅', label: AppStrings.nannyAvailableFrom.tr, selected: controller.availability.value == AvailabilityStatus.availableFrom, variant: KafiToggleVariant.purple, onTap: () => controller.availability.value = AvailabilityStatus.availableFrom)),
        ])),
        Obx(() => controller.availability.value == AvailabilityStatus.availableFrom
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: GestureDetector(
                  onTap: _pickAvailableFrom,
                  child: AbsorbPointer(
                    child: KafiTextField(label: AppStrings.nannyAvailableFromDate.tr, controller: controller.availableFromCtrl, hint: 'DD/MM/YYYY', purple: true),
                  ),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  // ─── BASIC ───────────────────────────────────────────────────────────────

  Widget _basic() {
    return KafiSection(
      title: AppStrings.secBasic.tr,
      icon: Icons.person_outline,
      children: [
        KafiTextField(label: AppStrings.fldFullName.tr, controller: controller.fullNameCtrl, hint: 'e.g. Maria Santos Reyes'),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickDob,
              child: AbsorbPointer(
                child: KafiTextField(label: AppStrings.fldDob.tr, controller: controller.dobCtrl, hint: 'DD/MM/YYYY'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            // Auto-calculated from date of birth — read-only, never typed into.
            child: KafiTextField(
              label: AppStrings.fldAge.tr,
              controller: controller.ageCtrl,
              readOnly: true,
              hint: '—',
            ),
          ),
        ]),
        Obx(() => Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppStrings.fldNationality.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
            const SizedBox(height: 3),
            // Uber-style searchable picker instead of a long dropdown.
            KafiSearchablePicker(
              value: controller.nationality.value,
              options: NannyConstants.nationalities,
              title: AppStrings.fldNationality.tr,
              hint: AppStrings.fldNationality.tr,
              icon: Icons.flag_outlined,
              onSelected: (v) => controller.nationality.value = v,
            ),
          ]),
        )),
        Text(AppStrings.fldLanguages.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() {
          final selected = controller.selectedLanguages; // explicit read keeps the Obx subscribed
          return Wrap(
            spacing: 4, runSpacing: 4,
            children: NannyConstants.languages.map((l) => KafiChip(
              label: l,
              selected: selected.contains(l),
              onTap: () => controller.toggleLanguage(l),
            )).toList(),
          );
        }),
      ],
    );
  }

  // ─── VISA ────────────────────────────────────────────────────────────────

  Widget _visa() {
    return KafiSection(
      title: AppStrings.secVisa.tr,
      icon: Icons.credit_card,
      accent: KafiSectionAccent.teal,
      children: [
        _infoBanner(
          color: const Color(0xFFE0F8F7),
          borderColor: const Color(0xFF80DEEA),
          icon: '🛡️',
          text: 'This helps families understand your availability and whether they need to provide visa sponsorship. Be honest — it is used for matching only.',
        ),
        const SizedBox(height: 8),
        Text(AppStrings.fldVisaStatus.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 5),
        Column(children: [
          _visaTile(AppStrings.visaVisit.tr, 'First time in UAE · Short-term · Needs sponsorship', VisaStatus.visit),
          _visaTile(AppStrings.visaSponsored.tr, 'Currently employed · Active work permit · Valid EID', VisaStatus.residenceSponsored),
          _visaTile(AppStrings.visaOwn.tr, 'Self-sponsored · Golden visa · Family visa holder', VisaStatus.ownResidence),
          _visaTile(AppStrings.visaCancelled.tr, 'Previous visa cancelled · Still in UAE · Needs urgent sponsorship', VisaStatus.cancelled),
          _visaTile(AppStrings.visaOutside.tr, 'Ready to come to UAE · Needs entry visa + sponsorship', VisaStatus.outsideUae),
        ]),
        const SizedBox(height: 8),
        // EID amber card
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF4E0), Color(0xFFFFE8C0)]),
            border: Border.all(color: KafiColors.amb, width: 1.5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFF7A4A00)),
              const SizedBox(width: 5),
              Text('About your Emirates ID', style: KafiTheme.nunito(10, color: const Color(0xFF7A4A00), w: FontWeight.w800)),
            ]),
            const SizedBox(height: 5),
            Text(
              'Emirates ID is not required if you are on a visit visa or applying from outside UAE. You can still create a complete, verified profile without it.',
              style: KafiTheme.nunito(9, color: const Color(0xFF7A4A00)),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.fldHasEid.tr, style: KafiTheme.nunito(9, color: const Color(0xFF7A4A00), w: FontWeight.w800)),
            const SizedBox(height: 5),
            Obx(() => Row(children: [
              Expanded(child: KafiToggleBox(
                icon: '🪪',
                label: 'Yes — I have valid EID',
                selected: controller.hasEid.value,
                onTap: () => controller.hasEid.value = true,
              )),
              const SizedBox(width: 6),
              Expanded(child: KafiToggleBox(
                icon: '🚫',
                label: 'No — visit visa / new to UAE',
                selected: !controller.hasEid.value,
                onTap: () => controller.hasEid.value = false,
              )),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        Text(AppStrings.fldTransferVisa.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => Column(children: [
          _visaTile("Yes — I'm open to visa transfer / sponsorship", null, null, selected: controller.willingTransferVisa.value == true, onTap: () => controller.willingTransferVisa.value = true),
          _visaTile('No — I have my own visa / self-sponsored', null, null, selected: controller.willingTransferVisa.value == false, onTap: () => controller.willingTransferVisa.value = false),
          _visaTile('Depends on the family and the offer', null, null, selected: controller.willingTransferVisa.value == null, onTap: () => controller.willingTransferVisa.value = null),
        ])),
      ],
    );
  }

  Widget _visaTile(String label, String? subtitle, VisaStatus? value, {bool? selected, VoidCallback? onTap}) {
    final isSelected = selected ?? (value != null && controller.visaStatus.value == value);
    final tap = onTap ?? (value != null ? () => controller.visaStatus.value = value : () {});
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: value != null
          ? Obx(() => _buildVisaTileContent(label, subtitle, controller.visaStatus.value == value, tap))
          : _buildVisaTileContent(label, subtitle, isSelected, tap),
    );
  }

  Widget _buildVisaTileContent(String label, String? subtitle, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? KafiColors.roseP : KafiColors.inputBg,
          border: Border.all(color: selected ? KafiColors.roseD : KafiColors.cardBorder, width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? KafiColors.roseD : Colors.transparent,
              border: Border.all(color: selected ? KafiColors.roseD : KafiColors.roseL, width: 2),
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 8) : null,
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: KafiTheme.nunito(10.5, color: selected ? KafiColors.roseD : KafiColors.td, w: FontWeight.w800)),
            if (subtitle != null) Text(subtitle, style: KafiTheme.nunito(8.5, color: selected ? KafiColors.roseD.withValues(alpha: 0.8) : KafiColors.ts)),
          ])),
        ]),
      ),
    );
  }

  // ─── WORK LOCATION ───────────────────────────────────────────────────────

  Widget _workLocation() {
    return KafiSection(
      title: AppStrings.secWorkLoc.tr,
      icon: Icons.location_on_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        // 1) Current emirate — single-select, replaces the free-text + GPS picker.
        Text(AppStrings.nannyCurrentEmirateLabel.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 5),
        Obx(() => GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.2,
          children: [
            for (final (e, emoji, _) in _emirates)
              _currentEmirateBox(emoji, e.label, e, controller.currentEmirate.value == e),
          ],
        )),
        const SizedBox(height: 12),
        // 2) Preferred job locations — multi-select ("Any Emirate" selects all 7).
        _infoBannerPurple(
          icon: Icons.location_on_outlined,
          text: 'Select every emirate you are willing to work in. Families can only find you for their emirate if you select it. You can select all if you are flexible.',
        ),
        const SizedBox(height: 8),
        Text(AppStrings.fldEmirates.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 5),
        Obx(() => KafiChip(
          label: AppStrings.nannyAnyEmirate.tr,
          selected: controller.allEmiratesSelected,
          onTap: controller.toggleAnyEmirate,
          purple: true,
        )),
        const SizedBox(height: 6),
        Obx(() {
          final selected = controller.workEmirates; // explicit read keeps the Obx subscribed
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 2.2,
            children: [
              for (final (e, emoji, subtitle) in _emirates)
                _emirateBox(emoji, e.label, subtitle, e, selected.contains(e)),
            ],
          );
        }),
        const SizedBox(height: 8),
        // 3) Relocate toggle.
        Text(AppStrings.fldRelocate.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => Row(children: [
          Expanded(child: KafiToggleBox(
            icon: '✈️',
            label: 'Yes — for the right family',
            selected: controller.willingRelocate.value,
            variant: KafiToggleVariant.purple,
            onTap: () => controller.willingRelocate.value = true,
          )),
          const SizedBox(width: 6),
          Expanded(child: KafiToggleBox(
            icon: '📍',
            label: 'Prefer to stay in current emirate',
            selected: !controller.willingRelocate.value,
            variant: KafiToggleVariant.purple,
            onTap: () => controller.willingRelocate.value = false,
          )),
        ])),
      ],
    );
  }

  Widget _emirateBox(String emoji, String name, String subtitle, Emirate value, bool selected) {
    return GestureDetector(
      onTap: () => controller.toggleEmirate(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(name, textAlign: TextAlign.center, style: KafiTheme.nunito(10.5, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w800)),
          Text(subtitle, textAlign: TextAlign.center, style: KafiTheme.nunito(8, color: selected ? KafiColors.pur.withValues(alpha: 0.75) : KafiColors.ts)),
        ]),
      ),
    );
  }

  /// Single-select variant of [_emirateBox] for the current-emirate grid (no
  /// subtitle — that copy is specific to the "where do you want to work"
  /// context). Copies the same box styling; `onTap` sets the single
  /// [NannyProfileController.currentEmirate] instead of toggling membership.
  Widget _currentEmirateBox(String emoji, String name, Emirate value, bool selected) {
    return GestureDetector(
      onTap: () => controller.currentEmirate.value = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 3),
          Text(name, textAlign: TextAlign.center, style: KafiTheme.nunito(10.5, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w800)),
        ]),
      ),
    );
  }

  // ─── PERSONAL ────────────────────────────────────────────────────────────

  Widget _personal() {
    return KafiSection(
      title: AppStrings.secPersonal.tr,
      icon: Icons.group_outlined,
      children: [
        Text(AppStrings.fldMarital.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 5),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.8,
          children: [
            _maritalBox('💍', 'Married', MaritalStatus.married),
            _maritalBox('🌸', 'Single', MaritalStatus.single),
            _maritalBox('💔', 'Divorced', MaritalStatus.divorced),
            _maritalBox('🕊️', 'Widowed', MaritalStatus.widowed),
          ],
        ),
        const SizedBox(height: 8),
        Text(AppStrings.fldChildren.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => Row(children: [
          Expanded(child: KafiToggleBox(icon: '👶', label: 'Yes, I have children', selected: controller.hasChildren.value, onTap: () => controller.hasChildren.value = true)),
          const SizedBox(width: 6),
          Expanded(child: KafiToggleBox(icon: '🚫', label: 'No children', selected: !controller.hasChildren.value, onTap: () => controller.hasChildren.value = false)),
        ])),
        const SizedBox(height: 6),
        Obx(() => controller.hasChildren.value
            ? KafiTextField(label: AppStrings.fldChildrenCount.tr, controller: controller.childrenCountCtrl, keyboardType: TextInputType.number)
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _maritalBox(String emoji, String label, MaritalStatus value) {
    return Obx(() => KafiToggleBox(
      icon: emoji, label: label,
      selected: controller.maritalStatus.value == value,
      onTap: () => controller.maritalStatus.value = value,
    ));
  }

  // ─── HEALTH ──────────────────────────────────────────────────────────────

  Widget _health() {
    return KafiSection(
      title: AppStrings.secHealth.tr,
      icon: Icons.favorite_outline,
      accent: KafiSectionAccent.green,
      children: [
        _infoBanner(
          color: KafiColors.grnL,
          borderColor: KafiColors.grn,
          icon: '💚',
          text: 'Health information is kept private and only shared with families you apply to.',
        ),
        const SizedBox(height: 10),
        Text(AppStrings.fldHealth.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        _healthToggle(controller.healthCtrl, '⚕️', 'Yes — I\'ll describe', '✅', 'No health conditions'),
        const SizedBox(height: 8),
        Text(AppStrings.fldMeds.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        _healthToggle(controller.medsCtrl, '💊', 'Yes — I\'ll describe', '✅', 'No medication'),
        const SizedBox(height: 8),
        Text(AppStrings.fldAllergies.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        _healthToggle(controller.allergiesCtrl, '🤧', 'Yes — I\'ll describe', '✅', 'No allergies'),
      ],
    );
  }

  Widget _healthToggle(TextEditingController ctrl, String yesEmoji, String yesLabel, String noEmoji, String noLabel) {
    return _HealthToggleField(
      controller: ctrl,
      yesEmoji: yesEmoji,
      yesLabel: yesLabel,
      noEmoji: noEmoji,
      noLabel: noLabel,
    );
  }

  // ─── COMFORT ─────────────────────────────────────────────────────────────

  Widget _comfort() {
    return KafiSection(
      title: AppStrings.secComfort.tr,
      icon: Icons.home_work_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        _infoBanner(
          color: KafiColors.purL,
          borderColor: KafiColors.purB,
          icon: '✨',
          text: 'Be honest — families filter by these preferences to find the best match for their household.',
        ),
        const SizedBox(height: 10),
        Text(AppStrings.fldComfortCameras.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => _comfortRow(controller.comfortCameras.value, (v) => controller.comfortCameras.value = v, '📹', 'Yes, I\'m comfortable', '🚫', 'Not comfortable')),
        const SizedBox(height: 8),
        Text(AppStrings.fldComfortPets.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => _comfortRow(controller.comfortPets.value, (v) => controller.comfortPets.value = v, '🐾', 'Yes, I love pets', '🚫', 'No pets please')),
        const SizedBox(height: 8),
        Text(AppStrings.fldCooks.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => _comfortRow(controller.cooks.value, (v) => controller.cooks.value = v, '🍳', 'Yes, I can cook', '🚫', 'Childcare only')),
        const SizedBox(height: 8),
        Text(AppStrings.fldNightShifts.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => _comfortRow(controller.nightShifts.value, (v) => controller.nightShifts.value = v, '🌙', 'Yes, night shifts ok', '🌞', 'Day shifts only')),
      ],
    );
  }

  Widget _comfortRow(bool selected, ValueChanged<bool> onChanged, String yesEmoji, String yesLabel, String noEmoji, String noLabel) {
    return Row(children: [
      Expanded(child: KafiToggleBox(icon: yesEmoji, label: yesLabel, selected: selected, variant: KafiToggleVariant.purple, onTap: () => onChanged(true))),
      const SizedBox(width: 6),
      Expanded(child: KafiToggleBox(icon: noEmoji, label: noLabel, selected: !selected, variant: KafiToggleVariant.purple, onTap: () => onChanged(false))),
    ]);
  }

  // ─── RELIGION ────────────────────────────────────────────────────────────

  Widget _religion() {
    return KafiSection(
      title: AppStrings.secReligion.tr,
      icon: Icons.auto_awesome_outlined,
      accent: KafiSectionAccent.purple,
      children: [
        _infoBanner(
          color: KafiColors.purL,
          borderColor: KafiColors.purB,
          icon: '🔒',
          text: AppStrings.nannyReligionPrivacyNote.tr,
        ),
        const SizedBox(height: 8),
        Text(AppStrings.fldReligion.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 5),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.5,
          children: [
            _religionTile('☪️', 'Muslim'),
            _religionTile('✝️', 'Christian'),
            _religionTile('🕉️', 'Hindu'),
            _religionTile('☸️', 'Buddhist'),
            _religionTile('✡️', 'Jewish'),
            _religionTile('🌐', 'Other'),
          ],
        ),
        const SizedBox(height: 8),
        Text(AppStrings.nannyComfortFaith.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 4),
        Obx(() => Row(children: [
          Expanded(child: KafiToggleBox(icon: '✅', label: 'Yes — fully comfortable', selected: controller.comfortDifferentFaith.value, variant: KafiToggleVariant.purple, onTap: () => controller.comfortDifferentFaith.value = true)),
          const SizedBox(width: 6),
          Expanded(child: KafiToggleBox(icon: '🤔', label: 'Prefer same faith home', selected: !controller.comfortDifferentFaith.value, variant: KafiToggleVariant.purple, onTap: () => controller.comfortDifferentFaith.value = false)),
        ])),
        const SizedBox(height: 6),
        KafiTextField(
          label: AppStrings.nannyReligiousPractices.tr,
          controller: controller.religionCtrl,
          maxLines: 2,
          hint: 'e.g. Prayer times, dietary restrictions, fasting periods...',
        ),
      ],
    );
  }

  Widget _religionTile(String emoji, String label) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.religionCtrl,
      builder: (_, value, __) {
        final selected = value.text == label;
        return GestureDetector(
          onTap: () => controller.religionCtrl.text = selected ? '' : label,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? KafiColors.purL : KafiColors.inputBgP,
              border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(label, textAlign: TextAlign.center, style: KafiTheme.nunito(9, color: selected ? KafiColors.pur : KafiColors.tm, w: FontWeight.w700)),
            ]),
          ),
        );
      },
    );
  }

  // ─── EMPLOYMENT ──────────────────────────────────────────────────────────

  Widget _employment() {
    return KafiSection(
      title: AppStrings.nannySecEmployment.tr,
      icon: Icons.work_outline,
      accent: KafiSectionAccent.purple,
      children: [
        Text(AppStrings.nannyEmploymentQuestion.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
        const SizedBox(height: 5),
        Obx(() => Column(children: [
          _employmentTile(AppStrings.nannyEmpFullLiveIn.tr, EmploymentType.fullTimeLiveIn),
          const SizedBox(height: 6),
          _employmentTile(AppStrings.nannyEmpFullLiveOut.tr, EmploymentType.fullTimeLiveOut),
          const SizedBox(height: 6),
          _employmentTile(AppStrings.nannyEmpPartTime.tr, EmploymentType.partTime),
        ])),
        Obx(() => controller.employmentTypes.contains(EmploymentType.partTime)
            ? _partTimeAvailability()
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _employmentTile(String label, EmploymentType type) {
    return KafiToggleTile(
      label: label,
      selected: controller.employmentTypes.contains(type),
      onTap: () => controller.toggleEmploymentType(type),
      purple: true,
    );
  }

  Widget _partTimeAvailability() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.nannyPartTimeQuestion.tr, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
          const SizedBox(height: 5),
          Obx(() {
            final days = controller.partTimeAvailability; // explicit read keeps the Obx subscribed
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final (weekday, labelKey) in _weekdays)
                  KafiChip(
                    label: labelKey.tr,
                    selected: days.any((d) => d.weekday == weekday),
                    onTap: () => controller.toggleDay(weekday),
                    purple: true,
                  ),
              ],
            );
          }),
          Obx(() {
            final days = List.of(controller.partTimeAvailability)
              ..sort((a, b) => a.weekday.compareTo(b.weekday));
            if (days.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(children: [for (final d in days) _dayTimeRow(d)]),
            );
          }),
        ],
      ),
    );
  }

  Widget _dayTimeRow(DayAvailability d) {
    final dayLabel = _weekdays.firstWhere((w) => w.$1 == d.weekday).$2.tr;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(dayLabel, style: KafiTheme.nunito(9.5, color: KafiColors.td, w: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _timeField(
              AppStrings.nannyPartTimeFrom.tr,
              d.from,
              (t) => controller.setDayFrom(d.weekday, t),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _timeField(
              AppStrings.nannyPartTimeUntil.tr,
              d.until,
              (t) => controller.setDayUntil(d.weekday, t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeField(String label, String value, ValueChanged<String> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: Get.context!,
          initialTime: _parseTimeOfDay(value) ?? TimeOfDay.now(),
          helpText: label,
        );
        if (picked != null) onPicked(_fmtTimeOfDay(picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: KafiColors.inputBgP,
          border: Border.all(color: KafiColors.purB, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 12, color: KafiColors.pur),
            const SizedBox(width: 7),
            Text(value.isEmpty ? '—' : value, style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  TimeOfDay? _parseTimeOfDay(String v) {
    final parts = v.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ─── BIO ─────────────────────────────────────────────────────────────────

  Widget _bio() {
    return KafiSection(
      title: AppStrings.secBio.tr,
      icon: Icons.edit_note,
      children: [
        KafiTextField(
          label: AppStrings.fldBio.tr,
          controller: controller.bioCtrl,
          maxLines: 4,
          maxLength: NannyConstants.maxBioChars,
          hint: 'Tell families a little about yourself...',
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller.bioCtrl,
          builder: (_, value, __) {
            final count = value.text.length;
            return Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$count / ${NannyConstants.maxBioChars}',
                style: KafiTheme.nunito(9, color: count > NannyConstants.maxBioChars ? KafiColors.redD : KafiColors.ts),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── SHARED ──────────────────────────────────────────────────────────────

  Widget _infoBanner({required Color color, required Color borderColor, required String icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color, border: Border.all(color: borderColor, width: 1), borderRadius: BorderRadius.circular(9)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w600))),
      ]),
    );
  }

  Widget _infoBannerPurple({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.purL, Color(0xFFEDE4FF)]),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 12, color: const Color(0xFF4A2080)),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: KafiTheme.nunito(9.5, color: const Color(0xFF4A2080), w: FontWeight.w700))),
      ]),
    );
  }
}

/// Yes/No toggle for the health questions. Tapping "Yes" reveals a description
/// field even when empty; "No" hides it and clears any text. The Yes/No choice
/// is local UI state, seeded from whether the controller already has text.
class _HealthToggleField extends StatefulWidget {
  const _HealthToggleField({
    required this.controller,
    required this.yesEmoji,
    required this.yesLabel,
    required this.noEmoji,
    required this.noLabel,
  });

  final TextEditingController controller;
  final String yesEmoji;
  final String yesLabel;
  final String noEmoji;
  final String noLabel;

  @override
  State<_HealthToggleField> createState() => _HealthToggleFieldState();
}

class _HealthToggleFieldState extends State<_HealthToggleField> {
  late bool _yes = widget.controller.text.trim().isNotEmpty;

  void _selectYes() => setState(() => _yes = true);

  void _selectNo() {
    widget.controller.clear();
    setState(() => _yes = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: _selectYes,
          child: _tile(widget.yesEmoji, widget.yesLabel, _yes),
        )),
        const SizedBox(width: 6),
        Expanded(child: GestureDetector(
          onTap: _selectNo,
          child: _tile(widget.noEmoji, widget.noLabel, !_yes),
        )),
      ]),
      if (_yes) ...[
        const SizedBox(height: 6),
        KafiTextField(
          label: 'Please describe',
          controller: widget.controller,
          maxLines: 2,
          hint: 'Describe briefly...',
        ),
      ],
    ]);
  }

  Widget _tile(String emoji, String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? KafiColors.roseP : KafiColors.inputBg,
        border: Border.all(color: selected ? KafiColors.roseD : KafiColors.cardBorder, width: 1.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: KafiTheme.nunito(10, color: selected ? KafiColors.roseD : KafiColors.td, w: FontWeight.w700))),
      ]),
    );
  }
}
