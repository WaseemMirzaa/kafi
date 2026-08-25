import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/disputes_screen.dart' show disputeCategoryLabel;
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_report_attachments.dart';

/// Opens the shared "Report a problem" sheet to file a dispute about
/// [reportedUserId] (the other party in a chat or trial). [relatedTrialId] links
/// the report to a trial when filed from the trial screen. Files via
/// [DisputeController.createDispute]; the report then surfaces under
/// Settings → My reports and in the admin panel.
///
/// Prefer passing [context] so the sheet uses the root navigator (works inside
/// the nanny/family shell bottom nav). Falls back to [Get.bottomSheet] only
/// when no context is available.
void showReportProblemSheet({
  required String reportedUserId,
  String? relatedTrialId,
  String? reportedUserName,
  BuildContext? context,
}) {
  final id = reportedUserId.trim();
  if (id.isEmpty) {
    Get.snackbar(AppStrings.errorTitle.tr, AppStrings.reportUnavailable.tr);
    return;
  }
  if (!Get.isRegistered<DisputeController>()) {
    Get.put(DisputeController(), permanent: true);
  }
  final sheet = _ReportProblemSheet(
    reportedUserId: id,
    relatedTrialId: relatedTrialId,
    reportedUserName: reportedUserName,
  );
  final ctx = context ?? Get.context;
  if (ctx != null && ctx.mounted) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => sheet,
    );
    return;
  }
  Get.bottomSheet(
    sheet,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ReportProblemSheet extends StatefulWidget {
  const _ReportProblemSheet({
    required this.reportedUserId,
    this.relatedTrialId,
    this.reportedUserName,
  });

  final String reportedUserId;
  final String? relatedTrialId;
  final String? reportedUserName;

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
  final List<PendingReportAttachment> _attachments = [];
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
    setState(() => _submitting = true);
    final ok = await Get.find<DisputeController>().createDispute(
      reportedUserId: widget.reportedUserId,
      reportedUserName: widget.reportedUserName,
      category: _selected,
      description: text,
      relatedTrialId: widget.relatedTrialId,
      pendingAttachments: List.of(_attachments),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 12),
              KafiReportAttachments(
                files: _attachments,
                onChanged: (next) => setState(() {
                  _attachments
                    ..clear()
                    ..addAll(next);
                }),
              ),
              const SizedBox(height: 14),
              KafiPrimaryButton(
                label: AppStrings.reportProblemSend.tr,
                variant: KafiButtonVariant.purple,
                loading: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
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
