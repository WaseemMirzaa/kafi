import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_doc_item.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_step_scaffold.dart';

class NannyDocsScreen extends GetView<NannyProfileController> {
  const NannyDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final editMode = Get.arguments is Map && (Get.arguments as Map)['editMode'] == true;
    return KafiStepScaffold(
      step: 5,
      title: AppStrings.docsScreenTitle.tr,
      subtitle: AppStrings.docsScreenSubtitle.tr,
      onBack: editMode ? Get.back : null,
      showSignOut: !editMode,
      footer: Obx(
        () => KafiPrimaryButton(
          label: editMode ? AppStrings.saveAndClose.tr : AppStrings.submitReview.tr,
          variant: editMode ? KafiButtonVariant.rose : KafiButtonVariant.green,
          icon: editMode ? Icons.check : null,
          loading: controller.isLoading.value,
          onPressed: editMode ? controller.saveDocumentsAndClose : controller.submitForReview,
        ),
      ),
      children: [
        // Amber warning banner
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF4E0), Color(0xFFFFE8CC)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 14),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  AppStrings.docsWarning.tr,
                  style: KafiTheme.nunito(10, color: const Color(0xFFA06010), w: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),

        // Mandatory section
        _fsecHeader(
          icon: Icons.assignment_outlined,
          label: AppStrings.docsMandatoryHeader.tr,
          purple: false,
        ),
        _doc(DocumentType.passport, AppStrings.docPassport.tr,
            AppStrings.docPassportSub.tr, Icons.book_outlined,
            variant: KafiDocVariant.rose),
        _doc(DocumentType.visa, AppStrings.docVisa.tr,
            AppStrings.docVisaSub.tr, Icons.credit_card_outlined,
            variant: KafiDocVariant.rose),
        _emiratesIdRow(),
        const SizedBox(height: 16),

        // Optional section
        _fsecHeader(
          icon: Icons.shield_outlined,
          label: AppStrings.docsOptionalHeader.tr,
          purple: true,
        ),
        _doc(DocumentType.trainingCert, AppStrings.docTraining.tr,
            AppStrings.docTrainingSub.tr, Icons.school_outlined,
            variant: KafiDocVariant.purple),
        _doc(DocumentType.policeClearance, AppStrings.docPolice.tr,
            AppStrings.docPoliceSub.tr, Icons.verified_user_outlined,
            variant: KafiDocVariant.green),
      ],
    );
  }

  Widget _fsecHeader({
    required IconData icon,
    required String label,
    required bool purple,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: purple
                    ? const [KafiColors.pur, Color(0xFFC084FC)]
                    : [KafiColors.rose, KafiColors.roseD],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)
                  .copyWith(letterSpacing: 0.06 * 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doc(DocumentType t, String label, String sub, IconData icon,
      {required KafiDocVariant variant}) {
    return Obx(() {
      final d = controller.documents[t]!;
      return KafiDocItem(
        label: label,
        subtitle: sub,
        icon: icon,
        required: t == DocumentType.passport || t == DocumentType.visa,
        status: d.status,
        variant: variant,
        onTap: () => _chooseDocSource(t),
      );
    });
  }

  /// Album (photo library) + Files — same pattern as media source sheet.
  void _chooseDocSource(DocumentType type) {
    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KafiColors.ts.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.docChooseSource.tr,
                style: KafiTheme.fredoka(18, color: KafiColors.td),
              ),
              const SizedBox(height: 10),
              _docSourceTile(
                icon: Icons.photo_library_outlined,
                label: AppStrings.docChooseAlbum.tr,
                onTap: () => controller.pickDocumentFromGallery(type),
              ),
              const SizedBox(height: 8),
              _docSourceTile(
                icon: Icons.insert_drive_file_outlined,
                label: AppStrings.docChooseFile.tr,
                onTap: () => controller.pickDocumentFromFile(type),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _docSourceTile({
    required IconData icon,
    required String label,
    required Future<void> Function() onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        Get.back();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          border: Border.all(color: KafiColors.roseL),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: KafiColors.roseD, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right, color: KafiColors.ts, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _emiratesIdRow() {
    return Obx(() {
      final d = controller.documents[DocumentType.emiratesId]!;
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFBF0), Color(0xFFFFF7E0)],
          ),
          border: Border.all(color: const Color(0xFFFFD080), width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E0),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.badge_outlined, color: Color(0xFFA06010), size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.docEid.tr,
                      style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(
                    AppStrings.docEidSub.tr,
                    style: KafiTheme.nunito(9, color: const Color(0xFFA06010), w: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      GestureDetector(
                        onTap: () => _chooseDocSource(DocumentType.emiratesId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: KafiColors.grnL,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(AppStrings.docEidHave.tr,
                              style: KafiTheme.fredoka(8.5, color: KafiColors.grnD, w: FontWeight.w700)),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.markNoEid,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: KafiColors.roseP,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(AppStrings.docEidNone.tr,
                              style: KafiTheme.fredoka(8.5, color: KafiColors.roseD, w: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                d.status == DocumentStatus.uploaded ? '✓ ${AppStrings.docUploaded.tr}' : AppStrings.docConditional.tr,
                style: KafiTheme.fredoka(9,
                    color: d.status == DocumentStatus.uploaded
                        ? KafiColors.grnD
                        : const Color(0xFFA06010)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
