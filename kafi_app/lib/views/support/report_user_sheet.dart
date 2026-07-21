import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/ticket_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/disputes_screen.dart' show disputeCategoryLabel;
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Opens the "Report" sheet shown on a counterparty's profile — a family viewing
/// a nanny, or a nanny viewing a family/job. Files a **support ticket** about
/// [reportedUserId] via [TicketController]; the report reaches the admin team
/// under Settings → Support and is never shown to the reported user. No-ops if
/// the counterparty is unknown or [TicketController] isn't registered for the
/// current role.
void showReportUserSheet({
  required String reportedUserId,
  required String reportedUserName,
  String? relatedTrialId,
}) {
  if (reportedUserId.isEmpty || !Get.isRegistered<TicketController>()) return;
  Get.bottomSheet(
    _ReportUserSheet(
      reportedUserId: reportedUserId,
      reportedUserName: reportedUserName,
      relatedTrialId: relatedTrialId,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _ReportUserSheet extends StatefulWidget {
  const _ReportUserSheet({
    required this.reportedUserId,
    required this.reportedUserName,
    this.relatedTrialId,
  });

  final String reportedUserId;
  final String reportedUserName;
  final String? relatedTrialId;

  @override
  State<_ReportUserSheet> createState() => _ReportUserSheetState();
}

class _ReportUserSheetState extends State<_ReportUserSheet> {
  // Same report vocabulary as the trial/chat report sheet, most-common first.
  // These label the reason only — the report itself is filed as a support ticket.
  static const List<DisputeCategory> _reasons = [
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
    setState(() => _submitting = true);
    final name = widget.reportedUserName.trim();
    final subjectName = name.isEmpty ? 'user' : name;
    // Fold the reason + the reported user's identity into the ticket body so the
    // admin team can action it (the ticket subject also names who was reported).
    final body = StringBuffer()
      ..writeln(text)
      ..writeln()
      ..writeln('— Reason: ${disputeCategoryLabel(_selected)}')
      ..write('— Reported user: $subjectName (id: ${widget.reportedUserId})');
    if ((widget.relatedTrialId ?? '').isNotEmpty) {
      body
        ..writeln()
        ..write('— Trial: ${widget.relatedTrialId}');
    }
    final ticket = await Get.find<TicketController>().createTicket(
      subject: 'Report: $subjectName',
      category: TicketCategory.other,
      message: body.toString(),
      relatedTrialId: widget.relatedTrialId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Get.back();
    if (ticket != null) {
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.reportSentToast.tr);
    }
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
            children: _reasons.map(_reasonChip).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 4,
            maxLength: 800,
            style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w600),
            decoration: InputDecoration(
              hintText: AppStrings.reportProblemDescHint.tr,
              hintStyle: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w500),
              filled: true,
              fillColor: KafiColors.inputBgP,
              counterText: '',
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

  Widget _reasonChip(DisputeCategory c) {
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
