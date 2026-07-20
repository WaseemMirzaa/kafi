import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
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
    controller.loadApplications();
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
                return RefreshIndicator(
                  color: KafiColors.roseD,
                  onRefresh: controller.loadApplications,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: apps.length,
                    itemBuilder: (_, i) => _applicationCard(apps[i]),
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
    final famName = (app.familyName?.isNotEmpty ?? false) ? app.familyName! : (job?.familyName ?? '');
    final initial = famName.isNotEmpty ? famName[0].toUpperCase() : 'F';
    final title = (app.jobTitle?.isNotEmpty ?? false)
        ? app.jobTitle!
        : job != null
            ? '${job.jobType.name == 'liveOut' ? 'Live-out' : 'Live-in'} Nanny${job.city.isNotEmpty ? ' · ${job.city}' : ''}'
            : AppStrings.nannyMyApplications.tr;

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.nannyApplicationDetail, arguments: app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
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
                      colors: [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
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
                      Text(title,
                          style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
                      Text('Applied ${_formatDate(app.createdAt)}',
                          style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
                    ],
                  ),
                ),
                _statusBadge(app.status),
              ],
            ),
            if (app.coverMessage != null && app.coverMessage!.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(app.coverMessage!,
                  style: KafiTheme.nunito(9.5, color: KafiColors.tm),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 7),
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
                if (app.status == ApplicationStatus.pending ||
                    app.status == ApplicationStatus.viewed)
                  GestureDetector(
                    onTap: () => _confirmWithdraw(app.id),
                    child: Text(AppStrings.nannyWithdraw.tr,
                        style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w700)),
                  ),
              ],
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
        label = 'Pending';
      case ApplicationStatus.viewed:
        bg = KafiColors.purpL;
        fg = KafiColors.purpD;
        label = 'Viewed';
      case ApplicationStatus.shortlisted:
        bg = KafiColors.grnL;
        fg = KafiColors.grnD;
        label = 'Shortlisted';
      case ApplicationStatus.trialOffered:
        bg = KafiColors.roseL;
        fg = KafiColors.roseD;
        label = 'Trial Offered!';
      case ApplicationStatus.declined:
        bg = KafiColors.redL;
        fg = KafiColors.redD;
        label = 'Declined';
      case ApplicationStatus.withdrawn:
        bg = KafiColors.grey.withValues(alpha: 0.2);
        fg = KafiColors.grey;
        label = 'Withdrawn';
      case ApplicationStatus.hired:
        bg = KafiColors.grnL;
        fg = KafiColors.grnD;
        label = 'Hired! 🎉';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: KafiTheme.fredoka(9, w: FontWeight.w700, color: fg)),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
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
