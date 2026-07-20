import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/disputes_screen.dart' show disputeCategoryLabel;
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Opens the shared "Report a problem" sheet to file a dispute about
/// [reportedUserId] (the other party in a chat or trial). [relatedTrialId] links
/// the report to a trial when filed from the trial screen. Files via
/// [DisputeController.createDispute]; the report then surfaces under
/// Settings → My reports and in the admin panel. No-ops if the counterparty is
/// unknown or the DisputeController isn't registered for the current role.
void showReportProblemSheet({
  required String reportedUserId,
  String? relatedTrialId,
}) {
  if (reportedUserId.isEmpty || !Get.isRegistered<DisputeController>()) return;
  Get.bottomSheet(
    _ReportProblemSheet(reportedUserId: reportedUserId, relatedTrialId: relatedTrialId),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ReportProblemSheet extends StatefulWidget {
  const _ReportProblemSheet({required this.reportedUserId, this.relatedTrialId});

  final String reportedUserId;
  final String? relatedTrialId;

  @override
  State<_ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends State<_ReportProblemSheet> {
  // No-show and abuse are the most common trial/hire reports, so surface them
  // first; payment stays available for reports filed outside the trial's
  // payment step.
  static const List<DisputeCategory> _categories = [
    DisputeCategory.noShow,
    DisputeCategory.abuse,
    DisputeCategory.fraud,
    DisputeCategory.payment,
    DisputeCategory.other,
  ];

  DisputeCategory _selected = DisputeCategory.noShow;
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final text = _descCtrl.text.trim();
    if (text.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.reportEmptyDesc.tr);
      return;
    }
    _submitting = true;
    final ok = await Get.find<DisputeController>().createDispute(
      reportedUserId: widget.reportedUserId,
      category: _selected,
      description: text,
      relatedTrialId: widget.relatedTrialId,
    );
    _submitting = false;
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KafiColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(AppStrings.reportProblemTitle.tr,
              style: KafiTheme.pacifico(16, color: KafiColors.pur)),
          const SizedBox(height: 3),
          Text(AppStrings.reportProblemSub.tr,
              style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(AppStrings.reportProblemCategory.tr,
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories.map(_catChip).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 4,
            style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w600),
            decoration: InputDecoration(
              hintText: AppStrings.reportProblemDescHint.tr,
              hintStyle: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w500),
              filled: true,
              fillColor: KafiColors.inputBgP,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.purB, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.pur, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          KafiPrimaryButton(
            label: AppStrings.reportProblemSend.tr,
            variant: KafiButtonVariant.purple,
            onPressed: _submit,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _catChip(DisputeCategory c) {
    final selected = _selected == c;
    return GestureDetector(
      onTap: () => setState(() => _selected = c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
        ),
        child: Text(disputeCategoryLabel(c),
            style: KafiTheme.nunito(10.5,
                color: selected ? KafiColors.pur : KafiColors.tm,
                w: selected ? FontWeight.w800 : FontWeight.w600)),
      ),
    );
  }
}
