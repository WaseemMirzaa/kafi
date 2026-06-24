import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_step_scaffold.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';
import 'package:uuid/uuid.dart';

class NannyRefsScreen extends GetView<NannyProfileController> {
  const NannyRefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editMode = Get.arguments is Map && (Get.arguments as Map)['editMode'] == true;
    return KafiStepScaffold(
      step: 4,
      title: AppStrings.refsTitle.tr,
      subtitle: AppStrings.refsSubtitle.tr,
      onBack: editMode ? Get.back : null,
      footer: Obx(
        () => KafiPrimaryButton(
          label: editMode ? AppStrings.saveAndClose.tr : AppStrings.nextDocs.tr,
          icon: editMode ? Icons.check : Icons.arrow_forward,
          loading: controller.isLoading.value,
          onPressed: () => controller.saveRefsAndNext(advance: !editMode),
        ),
      ),
      children: [
        _fsecHeader(),
        _howItWorksBanner(),
        const SizedBox(height: 12),
        _fieldLabel(AppStrings.refsHas.tr),
        const SizedBox(height: 5),
        Obx(() => Row(
              children: [
                Expanded(child: _declarationTile(
                  emoji: '✅',
                  label: AppStrings.refsHasYes.tr,
                  selected: controller.hasReferences.value,
                  onTap: () => controller.hasReferences.value = true,
                )),
                const SizedBox(width: 6),
                Expanded(child: _declarationTile(
                  emoji: '❌',
                  label: AppStrings.refsHasNo.tr,
                  selected: !controller.hasReferences.value,
                  onTap: () => controller.hasReferences.value = false,
                )),
              ],
            )),
        const SizedBox(height: 12),
        Text(AppStrings.refsAboutThem.tr,
            style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w800)),
        const SizedBox(height: 6),
        Obx(() => Column(
              children: [
                for (var i = 0; i < controller.references.length; i++)
                  _RefCard(
                    key: ValueKey(controller.references[i].id),
                    index: i,
                    ref: controller.references[i],
                    onChanged: (r) => controller.references[i] = r,
                    onDelete: () => controller.removeReference(i),
                  ),
                _addBtn(),
              ],
            )),
        const SizedBox(height: 11),
        _commitmentBox(),
      ],
    );
  }

  Widget _fsecHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFFE8F0), width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KafiColors.grn, KafiColors.grnD],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.phone_outlined, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(AppStrings.refsSectionHeader.tr,
                style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800).copyWith(letterSpacing: 0.54)),
          ),
        ],
      ),
    );
  }

  Widget _howItWorksBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F8EE), Color(0xFFD0F5E0)],
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.refsHowWork.tr,
              style: KafiTheme.fredoka(10.5, color: KafiColors.grnD, w: FontWeight.w800)),
          const SizedBox(height: 6),
          _howStep('1', 'You declare here that you have callable references — no names or numbers on the app', isWarn: false),
          const SizedBox(height: 5),
          _howStep('2', 'Families see "✓ Has callable references" on your profile', isWarn: false),
          const SizedBox(height: 5),
          _howStep('3', 'During your interview or trial, you share the contact directly — face to face', isWarn: false),
          const SizedBox(height: 5),
          _howStep('!', 'You must follow through — families trust what you declare here', isWarn: true),
        ],
      ),
    );
  }

  Widget _howStep(String num, String text, {required bool isWarn}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: isWarn ? const Color(0xFFF59E0B) : KafiColors.grn,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(text, style: KafiTheme.nunito(9.5, color: const Color(0xFF2A7A50), w: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) =>
      Text(text, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800));

  Widget _declarationTile({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KafiColors.roseP : const Color(0xFFFFF7FA),
          border: Border.all(color: selected ? KafiColors.roseD : const Color(0xFFFFD8E8), width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: KafiTheme.nunito(9.5, color: selected ? KafiColors.roseD : KafiColors.tm, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addBtn() {
    return GestureDetector(
      onTap: () => controller.addReference(ReferenceContact(
        id: const Uuid().v4(),
        relationship: NannyConstants.referenceRelations.first,
        city: 'Dubai',
        yearsWorked: 1,
        canConfirm: '',
      )),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          border: Border.all(color: KafiColors.roseL, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 13, color: KafiColors.roseD),
            const SizedBox(width: 5),
            Text(AppStrings.refsAddAnother.tr, style: KafiTheme.fredoka(11, color: KafiColors.roseD, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _commitmentBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: KafiColors.roseP,
        border: Border.all(color: KafiColors.roseL, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(() => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: controller.commitsToShare.value,
                  activeColor: KafiColors.roseD,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) => controller.commitsToShare.value = v ?? false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppStrings.refsCommit.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.tm, w: FontWeight.w700).copyWith(height: 1.5)),
              ),
            ],
          )),
    );
  }
}

/// Inline-editable reference card (mirrors the web `.ref-card`).
class _RefCard extends StatefulWidget {
  const _RefCard({
    super.key,
    required this.index,
    required this.ref,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final ReferenceContact ref;
  final ValueChanged<ReferenceContact> onChanged;
  final VoidCallback onDelete;

  @override
  State<_RefCard> createState() => _RefCardState();
}

class _RefCardState extends State<_RefCard> {
  static const _cities = [
    'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Ras Al Khaimah',
    'Umm Al Quwain', 'Fujairah', 'Al Ain', 'Outside UAE',
  ];

  late final TextEditingController _years;
  late final TextEditingController _canConfirm;
  late String _relationship;
  late String _city;

  @override
  void initState() {
    super.initState();
    final r = widget.ref;
    _years = TextEditingController(text: r.yearsWorked > 0 ? '${r.yearsWorked}' : '');
    _canConfirm = TextEditingController(text: r.canConfirm);
    _relationship = NannyConstants.referenceRelations.contains(r.relationship)
        ? r.relationship
        : NannyConstants.referenceRelations.first;
    _city = _cities.contains(r.city) ? r.city : _cities.first;
    for (final c in [_years, _canConfirm]) {
      c.addListener(_emit);
    }
  }

  void _emit() {
    widget.onChanged(ReferenceContact(
      id: widget.ref.id,
      relationship: _relationship,
      city: _city,
      yearsWorked: int.tryParse(_years.text) ?? 0,
      canConfirm: _canConfirm.text,
    ));
  }

  @override
  void dispose() {
    for (final c in [_years, _canConfirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFD8E8), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [KafiColors.grn, KafiColors.grnD]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 7),
              Text(AppStrings.refsReferenceNum.trParams({'num': '${widget.index + 1}'}),
                  style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: KafiColors.grnL, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 7, color: KafiColors.grnD),
                    const SizedBox(width: 3),
                    Text(AppStrings.refsCallable.tr, style: KafiTheme.fredoka(9, color: KafiColors.grnD, w: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 10, color: KafiColors.roseD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _label(AppStrings.refsRel.tr),
          const SizedBox(height: 4),
          _dropdown(_relationship, NannyConstants.referenceRelations, (v) {
            setState(() => _relationship = v ?? _relationship);
            _emit();
          }),
          const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(AppStrings.refsCity.tr),
                    const SizedBox(height: 4),
                    _dropdown(_city, _cities, (v) {
                      setState(() => _city = v ?? _city);
                      _emit();
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: KafiTextField(
                  label: AppStrings.refsYears.tr,
                  controller: _years,
                  keyboardType: TextInputType.number,
                  hint: 'e.g. 2',
                ),
              ),
            ],
          ),
          KafiTextField(
            label: AppStrings.refsCanConfirm.tr,
            controller: _canConfirm,
            hint: 'Newborn care, cooking, character, reliability',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(color: KafiColors.grnL, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, size: 10, color: KafiColors.grnD),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(AppStrings.refsShareNote.tr,
                      style: KafiTheme.nunito(9, color: KafiColors.grnD, w: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800));

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: KafiColors.inputBg,
        border: Border.all(color: KafiColors.cardBorder, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : items.first,
          style: KafiTheme.nunito(11, color: KafiColors.td),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
