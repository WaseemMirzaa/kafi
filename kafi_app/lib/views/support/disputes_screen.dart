import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// The user's filed reports (disputes). Each opens the support conversation
/// with the Kafi team. Disputes are filed contextually (e.g. a payment issue
/// during a trial), so there is no "new report" flow here — only viewing.
class DisputesScreen extends GetView<DisputeController> {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.disputes.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: KafiColors.pur));
                }
                if (controller.error.value != null && controller.disputes.isEmpty) {
                  return _errorState();
                }
                if (controller.disputes.isEmpty) return _emptyState();
                return RefreshIndicator(
                  color: KafiColors.pur,
                  onRefresh: controller.loadDisputes,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: controller.disputes.length,
                    itemBuilder: (_, i) => _disputeCard(controller.disputes[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
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
            onTap: AppNavigation.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.disputesTitle.tr,
                    style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090))),
                Text(AppStrings.disputesSubtitle.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: KafiColors.pur.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(AppStrings.loadErrorTitle.tr,
              style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w700)),
          const SizedBox(height: 14),
          TextButton(
            onPressed: controller.loadDisputes,
            child: Text(AppStrings.retry.tr,
                style: KafiTheme.fredoka(12, color: KafiColors.pur, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.disputesEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(AppStrings.disputesEmptySub.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(10, color: KafiColors.ts)),
          ),
        ],
      ),
    );
  }

  Widget _disputeCard(DisputeModel d) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.disputeChat, arguments: d),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFEFE2FF), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x129B6EDB), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(disputeCategoryLabel(d.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(12.5, color: KafiColors.td, w: FontWeight.w800)),
                ),
                disputeStatusChip(d.status),
              ],
            ),
            if (d.description.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(d.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KafiTheme.nunito(10, color: KafiColors.tm)),
            ],
            const SizedBox(height: 7),
            Text(_time(d.createdAt),
                style: KafiTheme.nunito(8.5, color: KafiColors.ts, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _time(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return AppStrings.supportJustNow.tr;
  }
}

/// Shared label + status-chip helpers (also used by the dispute chat screen).
String disputeCategoryLabel(DisputeCategory c) => switch (c) {
      DisputeCategory.fraud => AppStrings.disputeCatFraud.tr,
      DisputeCategory.abuse => AppStrings.disputeCatAbuse.tr,
      DisputeCategory.noShow => AppStrings.disputeCatNoShow.tr,
      DisputeCategory.payment => AppStrings.disputeCatPayment.tr,
      DisputeCategory.other => AppStrings.disputeCatOther.tr,
    };

Widget disputeStatusChip(DisputeStatus s) {
  final (label, bg, fg) = switch (s) {
    DisputeStatus.open => (AppStrings.disputeStatusOpen.tr, KafiColors.ambL, KafiColors.ambD),
    DisputeStatus.investigating =>
      (AppStrings.disputeStatusInvestigating.tr, KafiColors.purpL, KafiColors.purpD),
    DisputeStatus.resolved => (AppStrings.disputeStatusResolved.tr, KafiColors.grnL, KafiColors.grnD),
    DisputeStatus.dismissed =>
      (AppStrings.disputeStatusDismissed.tr, KafiColors.grey.withValues(alpha: 0.2), KafiColors.grey),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: KafiTheme.fredoka(9, w: FontWeight.w700, color: fg)),
  );
}
