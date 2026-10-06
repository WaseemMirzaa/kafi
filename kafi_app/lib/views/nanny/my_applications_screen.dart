import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/relative_time.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_avatar.dart';
import 'package:kafi_app/views/widgets/kafi_search_field.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final controller = Get.find<ApplicationController>();

  @override
  void initState() {
    super.initState();
    // Reload on entry so family-driven status transitions (viewed → shortlisted
    // → trial-offered → hired) surface without an app restart.
    controller.subscribeNannyOutbox();
    // Opened from a Jobs-page stat tile → land on that tab; otherwise All.
    final arg = Get.arguments;
    controller.sentFilter.value = arg is SentFilter ? arg : SentFilter.all;
    controller.sentQuery.value = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            KafiSearchField(
              hint: AppStrings.searchHint.tr,
              onChanged: (v) => controller.sentQuery.value = v,
            ),
            _tabs(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: KafiColors.roseD));
                }
                if (controller.loadError.value != null && controller.myApplications.isEmpty) {
                  return _errorState();
                }
                if (controller.myApplications.isEmpty) {
                  return _emptyState();
                }
                final apps = controller.filteredSent;
                if (apps.isEmpty) return _noneInTab();
                return RefreshIndicator(
                  color: KafiColors.roseD,
                  onRefresh: controller.loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: apps.length,
                    itemBuilder: (_, i) => Obx(() => _applicationCard(apps[i])),
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
          colors: [Color(0xFFFFE0EC), Color(0xFFFFF4EE)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: AppNavigation.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.roseD, size: 20),
            ),
          ),
          Expanded(
            child: Text(AppStrings.nannyMyApplications.tr, style: KafiTheme.pacifico(17)),
          ),
        ],
      ),
    );
  }

  static const _tabOrder = SentFilter.values;

  String _tabLabel(SentFilter f) {
    switch (f) {
      case SentFilter.all:
        return AppStrings.filterAll.tr;
      case SentFilter.pending:
        return AppStrings.nannyAppStatusPending.tr;
      case SentFilter.viewed:
        return AppStrings.nannyAppStatusViewed.tr;
      case SentFilter.shortlisted:
        return AppStrings.nannyAppStatusShortlisted.tr;
      case SentFilter.offers:
        return AppStrings.nannyStatsOffers.tr;
      case SentFilter.hired:
        return AppStrings.nannyAppStatusHired.tr;
      case SentFilter.declined:
        return AppStrings.nannyAppStatusDeclined.tr;
      case SentFilter.withdrawn:
        return AppStrings.nannyAppStatusWithdrawn.tr;
    }
  }

  /// Horizontally scrolling status tabs with live counts.
  Widget _tabs() {
    return SizedBox(
      height: 46,
      child: Obx(() {
        final active = controller.sentFilter.value;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: _tabOrder.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final f = _tabOrder[i];
            final on = f == active;
            return GestureDetector(
              onTap: () => controller.sentFilter.value = f,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: on ? KafiColors.roseD : KafiColors.roseP,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${_tabLabel(f)} ${controller.sentCount(f)}',
                  style: KafiTheme.fredoka(12.5,
                      color: on ? Colors.white : KafiColors.roseD, w: FontWeight.w700),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _noneInTab() {
    return Center(
      child: Text(AppStrings.nannyNoApplicationsFiltered.tr,
          style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: KafiColors.roseD.withValues(alpha: 0.7)),
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
                style: KafiTheme.fredoka(12, color: KafiColors.roseD, w: FontWeight.w700)),
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
          Icon(Icons.inbox_outlined, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.nannyNoApplications.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(AppStrings.nannyNoApplicationsSub.tr,
              style: KafiTheme.nunito(10, color: KafiColors.ts)),
        ],
      ),
    );
  }

  Widget _applicationCard(ApplicationModel app) {
    final job = Get.find<JobPostController>().allJobs.firstWhereOrNull((j) => j.id == app.jobPostId);
    // Prefer the denormalized fields on the application so a job that isn't in
    // the browse set doesn't fall back to fabricated 'Dubai'/'Live-in' (NAP-12).
    final profile = controller.familyProfiles[app.familyId];
    final famName = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : (app.familyName?.isNotEmpty ?? false)
            ? app.familyName!
            : (job?.familyName ?? '');
    final displayFamily = famName.isNotEmpty
        ? (famName.toLowerCase().endsWith('family')
            ? famName
            : '$famName ${AppStrings.jobDetailFamilySuffix.tr}')
        : AppStrings.jobDetailFamilySuffix.tr;
    final role = (app.jobTitle?.isNotEmpty ?? false)
        ? app.jobTitle!
        : job != null
            ? '${job.jobType.name == 'liveOut' ? AppStrings.jobLiveOut.tr : AppStrings.jobLiveIn.tr} ${AppStrings.nannySuffix.tr}'
            : AppStrings.nannySuffix.tr;
    final photoSeed = (job?.familyId.isNotEmpty ?? false)
        ? job!.familyId
        : (app.familyId.isNotEmpty ? app.familyId : famName);
    final canWithdraw =
        app.status == ApplicationStatus.pending || app.status == ApplicationStatus.viewed;

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.nannyApplicationDetail, arguments: app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFD6E4), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square, centre-cropped family photo on the left.
            KafiAvatar(
              photoUrl: FamilyConstants.resolvedPhotoUrl(
                  (profile?.profilePhoto?.trim().isNotEmpty ?? false)
                      ? profile!.profilePhoto
                      : job?.familyPhotoUrl,
                  photoSeed),
              fallbackText: famName.isNotEmpty ? famName : 'F',
              size: 100,
              gradient: const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
              fontSize: 34,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(displayFamily,
                              style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _statusBadge(app.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KafiColors.roseP,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(role,
                        style: KafiTheme.nunito(12, color: KafiColors.roseD, w: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 5),
                  Text(
                      '${AppStrings.appDetailApplied.tr} ${formatRelativeTime(app.createdAt)}',
                      style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w600)),
                  if (app.coverMessage != null && app.coverMessage!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(app.coverMessage!,
                        style: KafiTheme.nunito(12.5, color: KafiColors.tm, w: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (canWithdraw) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: GestureDetector(
                        onTap: () => _confirmWithdraw(app.id),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(AppStrings.nannyWithdraw.tr,
                              style: KafiTheme.nunito(13, color: KafiColors.roseD, w: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(ApplicationStatus status) {
    Color bg, fg;
    String label;
    switch (status) {
      case ApplicationStatus.pending:
        bg = KafiColors.ambL;
        fg = KafiColors.ambD;
        label = AppStrings.nannyAppStatusPending.tr;
      case ApplicationStatus.viewed:
        bg = KafiColors.purpL;
        fg = KafiColors.purpD;
        label = AppStrings.nannyAppStatusViewed.tr;
      case ApplicationStatus.shortlisted:
        bg = KafiColors.grnL;
        fg = KafiColors.grnD;
        label = AppStrings.nannyAppStatusShortlisted.tr;
      case ApplicationStatus.trialOffered:
        bg = KafiColors.roseL;
        fg = KafiColors.roseD;
        label = AppStrings.nannyAppStatusTrialOffered.tr;
      case ApplicationStatus.declined:
        bg = KafiColors.redL;
        fg = KafiColors.redD;
        label = AppStrings.nannyAppStatusDeclined.tr;
      case ApplicationStatus.withdrawn:
        bg = KafiColors.grey.withValues(alpha: 0.2);
        fg = KafiColors.grey;
        label = AppStrings.nannyAppStatusWithdrawn.tr;
      case ApplicationStatus.hired:
        bg = KafiColors.grnL;
        fg = KafiColors.grnD;
        label = AppStrings.nannyAppStatusHired.tr;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: KafiTheme.fredoka(12, w: FontWeight.w700, color: fg)),
    );
  }

  /// Confirm before withdrawing (the in-card action was previously
  /// fire-and-forget with no confirm or error feedback).
  void _confirmWithdraw(String appId) {
    Get.dialog(AlertDialog(
      title: Text(AppStrings.nannyWithdraw.tr),
      content: Text(AppStrings.appDetailWithdrawConfirm.tr),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
        TextButton(
          onPressed: () async {
            Get.back();
            await controller.withdrawApplication(appId);
          },
          child: Text(AppStrings.appDetailWithdrawYes.tr,
              style: const TextStyle(color: KafiColors.redD)),
        ),
      ],
    ));
  }
}
