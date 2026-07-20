import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_search_field.dart';

/// Family "Applicants" inbox — the nannies who applied to this family's jobs
/// (Spec §6: family receives applications). Backed by
/// [ApplicationController.receivedApplications], which is loaded for families.
class FamilyApplicantsScreen extends GetView<ApplicationController> {
  const FamilyApplicantsScreen({super.key});

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
            KafiSearchField(
              hint: AppStrings.searchHint.tr,
              onChanged: (v) => controller.receivedQuery.value = v,
            ),
            Expanded(
              child: Obx(() {
                final all = controller.receivedApplications;
                if (controller.isLoading.value && all.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(color: KafiColors.pur));
                }
                if (controller.loadError.value != null && all.isEmpty) {
                  return _errorState();
                }
                if (all.isEmpty) return _emptyState();
                final apps = controller.filteredReceived;
                if (apps.isEmpty) return _noMatchState();
                return RefreshIndicator(
                  color: KafiColors.pur,
                  onRefresh: controller.loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: apps.length,
                    itemBuilder: (_, i) => _applicantCard(apps[i]),
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
                Text(AppStrings.familyApplicants.tr,
                    style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090))),
                Text(AppStrings.familyApplicantsSub.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when a search filters out every applicant (the list was previously a
  /// blank ListView) — HIRE-4.
  Widget _noMatchState() {
    return Center(
      child: Text(AppStrings.applicantsNoMatch.tr,
          style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w600)),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.familyApplicantsEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(AppStrings.familyApplicantsEmptySub.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(10, color: KafiColors.ts)),
          ),
        ],
      ),
    );
  }

  /// Shown when the applicants read fails and the list is empty, so a live-read
  /// failure surfaces as an error with a retry instead of a misleading "no
  /// applicants yet" empty state.
  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: KafiColors.pur.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(AppStrings.loadErrorTitle.tr,
              style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(AppStrings.loadErrorSub.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(10, color: KafiColors.ts)),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: controller.loadApplications,
            child: Text(AppStrings.retry.tr,
                style: KafiTheme.fredoka(12, color: KafiColors.pur, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _applicantCard(ApplicationModel app) {
    final name = (app.nannyName?.isNotEmpty ?? false) ? app.nannyName! : 'Nanny';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'N';
    final canAct = app.status == ApplicationStatus.pending ||
        app.status == ApplicationStatus.viewed;

    return GestureDetector(
      onTap: () => _openApplicant(app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFEFE2FF), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x129B6EDB), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF9B6EDB), Color(0xFFC084FC)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: KafiTheme.fredoka(14, color: Colors.white, w: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w800)),
                      if ((app.jobTitle ?? '').isNotEmpty)
                        Text(app.jobTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
                      Text(_formatDate(app.createdAt),
                          style: KafiTheme.nunito(8.5, color: KafiColors.ts, w: FontWeight.w500)),
                    ],
                  ),
                ),
                _statusBadge(app.status),
              ],
            ),
            if ((app.coverMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(app.coverMessage!,
                  style: KafiTheme.nunito(9.5, color: KafiColors.tm),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('⭐ ${app.matchScore}% match',
                      style: KafiTheme.fredoka(9, color: const Color(0xFF2A8A50), w: FontWeight.w700)),
                ),
                const Spacer(),
                if (canAct) ...[
                  _smallBtn(AppStrings.applicantDecline.tr, KafiColors.redL,
                      KafiColors.redD, () => controller.decline(app.id)),
                  const SizedBox(width: 8),
                  _smallBtn(AppStrings.applicantShortlist.tr, KafiColors.grnL,
                      KafiColors.grnD, () => controller.shortlist(app.id)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openApplicant(ApplicationModel app) async {
    try {
      if (app.status == ApplicationStatus.pending) {
        await controller.markAsViewed(app.id);
      }
      final subs = Get.find<SubscriptionController>();
      await subs.recordViewIfAllowed(app.nannyId);
      await _syncMockEntitlementsIfNeeded(app.familyId);
      final nanny = await Get.find<IUserService>().getNanny(app.nannyId);
      if (nanny == null) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.applicantProfileUnavailable.tr);
        return;
      }
      final card =
          NannyCardModel.fromNanny(nanny).copyWith(matchPercent: app.matchScore);
      AppNavigation.openNannyProfile(card);
    } catch (e) {
      // A failed view/reveal must not throw uncaught from the tap (HIRE-1).
      Get.log('open applicant failed: $e', isError: true);
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.applicantProfileUnavailable.tr);
    }
  }

  Future<void> _syncMockEntitlementsIfNeeded(String familyId) async {
    if (!AppConfig.subscriptionUsesMock) return;
    final service = Get.find<ISubscriptionService>();
    if (service is! MockSubscriptionService) return;
    await service.syncEntitlementsToFirestore(familyId);
  }

  Widget _smallBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Text(label, style: KafiTheme.fredoka(10, color: fg, w: FontWeight.w700)),
      ),
    );
  }

  Widget _statusBadge(ApplicationStatus status) {
    final (label, bg, fg) = switch (status) {
      ApplicationStatus.pending => (AppStrings.appStatusPending.tr, KafiColors.ambL, KafiColors.ambD),
      ApplicationStatus.viewed => (AppStrings.appStatusViewed.tr, KafiColors.purpL, KafiColors.purpD),
      ApplicationStatus.shortlisted => (AppStrings.appStatusShortlisted.tr, KafiColors.grnL, KafiColors.grnD),
      ApplicationStatus.trialOffered => (AppStrings.appStatusTrialOffered.tr, KafiColors.roseL, KafiColors.roseD),
      ApplicationStatus.declined => (AppStrings.appStatusDeclined.tr, KafiColors.redL, KafiColors.redD),
      ApplicationStatus.withdrawn =>
        (AppStrings.appStatusWithdrawn.tr, KafiColors.grey.withValues(alpha: 0.2), KafiColors.grey),
      ApplicationStatus.hired => (AppStrings.appStatusHired.tr, KafiColors.grnL, KafiColors.grnD),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: KafiTheme.fredoka(9, w: FontWeight.w700, color: fg)),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
