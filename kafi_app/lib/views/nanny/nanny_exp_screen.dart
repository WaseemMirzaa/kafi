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

class NannyExpScreen extends GetView<NannyProfileController> {
  const NannyExpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editMode = Get.arguments is Map && (Get.arguments as Map)['editMode'] == true;
    return KafiStepScaffold(
      step: 3,
      title: AppStrings.expTitle.tr,
      subtitle: 'Show families your background',
      onBack: editMode ? Get.back : null,
      footer: Obx(
        () => KafiPrimaryButton(
          label: editMode ? AppStrings.saveAndClose.tr : AppStrings.nextRefs.tr,
          icon: editMode ? Icons.check : Icons.arrow_forward,
          loading: controller.isLoading.value,
          onPressed: () => controller.saveExpAndNext(advance: !editMode),
        ),
      ),
      children: [
        _fsecHeader(),
        Obx(() => Column(
              children: [
                for (var i = 0; i < controller.experiences.length; i++)
                  _ExpCard(
                    key: ValueKey(controller.experiences[i].id),
                    index: i,
                    exp: controller.experiences[i],
                    onChanged: (e) => controller.experiences[i] = e,
                    onDelete: () => controller.removeExperience(i),
                  ),
                _addBtn(),
              ],
            )),
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
                colors: [KafiColors.rose, KafiColors.roseD],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.work_outline, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Text('WORK EXPERIENCE',
              style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800).copyWith(letterSpacing: 0.54)),
        ],
      ),
    );
  }

  Widget _addBtn() {
    return GestureDetector(
      onTap: () => controller.addExperience(WorkExperience(
        id: const Uuid().v4(),
        jobTitle: NannyConstants.jobTitles.first,
        employer: '',
        cityCountry: '',
        fromDate: DateTime(DateTime.now().year - 1),
        toDate: DateTime.now(),
        children: '',
        duties: '',
        reasonLeaving: NannyConstants.reasonsLeaving.first,
      )),
      child: Container(
        width: double.infinity,
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
            Text('Add another job', style: KafiTheme.fredoka(11, color: KafiColors.roseD, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Inline-editable experience card (mirrors the web `.exp-card`).
class _ExpCard extends StatefulWidget {
  const _ExpCard({
    super.key,
    required this.index,
    required this.exp,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final WorkExperience exp;
  final ValueChanged<WorkExperience> onChanged;
  final VoidCallback onDelete;

  @override
  State<_ExpCard> createState() => _ExpCardState();
}

class _ExpCardState extends State<_ExpCard> {
  late final TextEditingController _employer;
  late final TextEditingController _city;
  late final TextEditingController _children;
  late final TextEditingController _duties;
  late String _jobTitle;
  late String _reason;
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final e = widget.exp;
    _employer = TextEditingController(text: e.employer);
    _city = TextEditingController(text: e.cityCountry);
    _children = TextEditingController(text: e.children);
    _duties = TextEditingController(text: e.duties);
    _jobTitle = NannyConstants.jobTitles.contains(e.jobTitle) ? e.jobTitle : NannyConstants.jobTitles.first;
    _reason = NannyConstants.reasonsLeaving.contains(e.reasonLeaving) ? e.reasonLeaving : NannyConstants.reasonsLeaving.first;
    _from = e.fromDate;
    _to = e.toDate;
    for (final c in [_employer, _city, _children, _duties]) {
      c.addListener(_emit);
    }
  }

  void _emit() {
    widget.onChanged(WorkExperience(
      id: widget.exp.id,
      jobTitle: _jobTitle,
      employer: _employer.text,
      cityCountry: _city.text,
      fromDate: _from,
      toDate: _to,
      children: _children.text,
      duties: _duties.text,
      reasonLeaving: _reason,
    ));
  }

  @override
  void dispose() {
    for (final c in [_employer, _city, _children, _duties]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2005),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => isFrom ? _from = picked : _to = picked);
      _emit();
    }
  }

  String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.year}';
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
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [KafiColors.rose, KafiColors.roseD]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${widget.index + 1}',
                      style: KafiTheme.nunito(9.5, color: Colors.white, w: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text('Previous job', style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
              ),
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
          _label('Job title'),
          const SizedBox(height: 4),
          _dropdown(_jobTitle, NannyConstants.jobTitles, (v) {
            setState(() => _jobTitle = v ?? _jobTitle);
            _emit();
          }),
          KafiTextField(label: 'Family / Employer name', controller: _employer, hint: 'e.g. Al Mansoori Family'),
          KafiTextField(label: 'City & Country', controller: _city, hint: 'e.g. Dubai, UAE'),
          Row(
            children: [
              Expanded(child: _dateField('From', _from, () => _pickDate(true))),
              const SizedBox(width: 6),
              Expanded(child: _dateField('To', _to, () => _pickDate(false))),
            ],
          ),
          const SizedBox(height: 7),
          KafiTextField(label: 'Children cared for', controller: _children, hint: 'e.g. 2 kids, ages 1 & 4'),
          KafiTextField(label: 'Main duties', controller: _duties, maxLines: 3, hint: 'Cooking, school pickup, homework help…'),
          _label('Reason for leaving'),
          const SizedBox(height: 4),
          _dropdown(_reason, NannyConstants.reasonsLeaving, (v) {
            setState(() => _reason = v ?? _reason);
            _emit();
          }),
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

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: KafiColors.inputBg,
              border: Border.all(color: KafiColors.cardBorder, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: KafiColors.rose),
                const SizedBox(width: 7),
                Text(_fmt(value), style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
      ],
    );
  }
}
