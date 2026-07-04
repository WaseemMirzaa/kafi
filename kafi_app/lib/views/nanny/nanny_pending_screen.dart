import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class NannyPendingScreen extends StatefulWidget {
  const NannyPendingScreen({super.key});

  @override
  State<NannyPendingScreen> createState() => _NannyPendingScreenState();
}

class _NannyPendingScreenState extends State<NannyPendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NannyProfileController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5EEFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => ctrl.nanny.value?.status == NannyOnboardingStatus.rejected
                  ? _rejectedHero(ctrl)
                  : _pendingHero()),
              _docStatusList(ctrl),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Obx(() =>
                    ctrl.nanny.value?.status == NannyOnboardingStatus.rejected
                        ? _resubmitFooter(ctrl)
                        : _updateDocsLink()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pendingHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5EEFF), Color(0xFFFFE8F5)],
        ),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFB5C8), Color(0xFFFF8FAB)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5C8A)
                        .withValues(alpha: 0.25 + _pulse.value * 0.15),
                    blurRadius: 10 + _pulse.value * 14,
                    spreadRadius: _pulse.value * 4,
                  ),
                ],
              ),
              child: const Icon(Icons.schedule, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 11),
          Text(
            AppStrings.pendingTitle.tr,
            style: KafiTheme.nunito(16, color: KafiColors.td, w: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            AppStrings.pendingSub.tr,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600)
                .copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x26FF8FAB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppStrings.pendingWhile.tr,
              style: KafiTheme.nunito(9.5, color: KafiColors.tm, w: FontWeight.w600)
                  .copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectedHero(NannyProfileController ctrl) {
    final reason = ctrl.nanny.value?.rejectionReason;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1E8), Color(0xFFFFE8EE)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFB088), Color(0xFFFF7E6B)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 11),
          Text(
            AppStrings.nannyRejectedTitle.tr,
            style: KafiTheme.nunito(16, color: KafiColors.td, w: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            AppStrings.nannyRejectedSub.tr,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600)
                .copyWith(height: 1.5),
          ),
          if (reason != null && reason.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFFC9B0), width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.nannyRejectedReasonLabel.tr,
                    style: KafiTheme.nunito(9.5,
                        color: const Color(0xFFA0500F), w: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w600)
                        .copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _updateDocsLink() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.nannyDocs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          border: Border.all(color: KafiColors.roseL, width: 2),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          AppStrings.nannyUpdateDocuments.tr,
          textAlign: TextAlign.center,
          style: KafiTheme.fredoka(12, color: KafiColors.roseD, w: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _resubmitFooter(NannyProfileController ctrl) {
    return Column(
      children: [
        _updateDocsLink(),
        const SizedBox(height: 10),
        Obx(() => KafiPrimaryButton(
              label: AppStrings.nannyResubmit.tr,
              variant: KafiButtonVariant.green,
              loading: ctrl.isLoading.value,
              onPressed: ctrl.isLoading.value ? null : ctrl.submitForReview,
            )),
      ],
    );
  }

  Widget _docStatusList(NannyProfileController ctrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFD8E8), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: KafiColors.roseP,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Text('📋 ${AppStrings.nannyDocStatusTitle.tr}',
                style: KafiTheme.nunito(10, color: KafiColors.tm, w: FontWeight.w800)),
          ),
          Obx(() {
            final docMap = ctrl.documents;
            final n = ctrl.nanny.value;
            final rows = <Widget>[
              _docRow(Icons.book_outlined, AppStrings.docPassport.tr,
                  KafiColors.grnL, KafiColors.grnD, docMap[DocumentType.passport]),
              _docRow(Icons.credit_card_outlined, AppStrings.docVisa.tr,
                  KafiColors.grnL, KafiColors.grnD, docMap[DocumentType.visa]),
              _docRow(Icons.badge_outlined, AppStrings.docEid.tr,
                  KafiColors.ambL, const Color(0xFFA06010), docMap[DocumentType.emiratesId]),
              _introVideoRow(n),
            ];
            return Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == rows.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: Color(0xFFFFF0F5), width: 1)),
                    ),
                    child: rows[i],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _docRow(IconData icon, String name, Color icBg, Color icColor,
      NannyDocument? doc) {
    final status = doc?.status;
    final (label, bg, fg) = _statusStyle(status);
    final subtitle = switch (status) {
      DocumentStatus.uploaded => AppStrings.docUploaded.tr,
      DocumentStatus.reviewing => AppStrings.docReviewing.tr,
      DocumentStatus.approved => AppStrings.docApproved.tr,
      DocumentStatus.rejected => AppStrings.docRejected.tr,
      _ => AppStrings.docMissing.tr,
    };
    return _statusTile(
      icon: icon,
      name: name,
      subtitle: subtitle,
      icBg: icBg,
      icColor: icColor,
      statusLabel: label,
      statusBg: bg,
      statusFg: fg,
      reason: status == DocumentStatus.rejected ? doc?.rejectionReason : null,
    );
  }

  Widget _introVideoRow(NannyModel? n) {
    final vs = n?.introVideoStatus;
    final hasVideo = (n?.introVideoUrl ?? '').isNotEmpty;
    final (label, bg, fg) = switch (vs) {
      IntroVideoStatus.approved => (AppStrings.docApproved.tr, KafiColors.grnL, KafiColors.grnD),
      IntroVideoStatus.rejected => (AppStrings.docRejected.tr, KafiColors.roseP, KafiColors.roseD),
      _ => hasVideo
          ? (AppStrings.docReviewing.tr, KafiColors.purL, KafiColors.pur)
          : (AppStrings.docMissing.tr, KafiColors.ambL, const Color(0xFFA06010)),
    };
    final subtitle = switch (vs) {
      IntroVideoStatus.approved => AppStrings.docApproved.tr,
      IntroVideoStatus.rejected => AppStrings.docRejected.tr,
      _ => hasVideo ? AppStrings.docReviewing.tr : AppStrings.docMissing.tr,
    };
    return _statusTile(
      icon: Icons.videocam_outlined,
      name: AppStrings.nannyIntroVideo.tr,
      subtitle: subtitle,
      icBg: KafiColors.purL,
      icColor: KafiColors.pur,
      statusLabel: label,
      statusBg: bg,
      statusFg: fg,
      reason: vs == IntroVideoStatus.rejected ? n?.introVideoRejectionReason : null,
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String name,
    required String subtitle,
    required Color icBg,
    required Color icColor,
    required String statusLabel,
    required Color statusBg,
    required Color statusFg,
    String? reason,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: icBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: icColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: KafiTheme.nunito(10.5,
                            color: KafiColors.td, w: FontWeight.w800)),
                    Text(subtitle,
                        style: KafiTheme.nunito(9,
                            color: KafiColors.ts, w: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(statusLabel,
                    style: KafiTheme.fredoka(9, color: statusFg, w: FontWeight.w700)),
              ),
            ],
          ),
          if (reason != null && reason.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 37),
              child: Text(
                reason,
                style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w600)
                    .copyWith(height: 1.35),
              ),
            ),
        ],
      ),
    );
  }

  (String, Color, Color) _statusStyle(DocumentStatus? status) {
    return switch (status) {
      DocumentStatus.uploaded || DocumentStatus.reviewing =>
        (AppStrings.docReviewing.tr, KafiColors.grnL, KafiColors.grnD),
      DocumentStatus.approved =>
        (AppStrings.docApproved.tr, KafiColors.grnL, KafiColors.grnD),
      DocumentStatus.rejected =>
        (AppStrings.docRejected.tr, KafiColors.roseP, KafiColors.roseD),
      _ => (AppStrings.docMissing.tr, KafiColors.ambL, const Color(0xFFA06010)),
    };
  }
}
