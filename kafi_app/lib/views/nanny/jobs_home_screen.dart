import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
class JobsHomeScreen extends GetView<JobPostController> {
  const JobsHomeScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  ApplicationController get _appCtrl => Get.find<ApplicationController>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(_appCtrl),
            _buildFilters(),
            Expanded(child: _buildJobList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE0EC), Color(0xFFFFF4EE)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.nannyJobsTitle.tr,
                    style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900)),
              ),
              if (embedInShell)
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.nannyApplications),
                  child: Text(AppStrings.nannyStatsApplied.tr,
                      style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w700)),
                ),
              const SizedBox(width: 10),
              _notifBell(),
            ],
          ),
          const SizedBox(height: 3),
          Obx(() => Text(
                '${controller.allJobs.length} ${AppStrings.nannyJobsMatching.tr}',
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
              )),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 4)],
            ),
            child: TextField(
              onChanged: (v) => controller.searchQuery.value = v,
              style: KafiTheme.nunito(11, color: KafiColors.td),
              decoration: InputDecoration(
                hintText: AppStrings.nannyJobsSearch.tr,
                hintStyle: KafiTheme.nunito(11, color: KafiColors.ts),
                prefixIcon: const Icon(Icons.search, color: KafiColors.ts, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Notification bell (white circle, rose icon + dot) → opens notifications.
  Widget _notifBell() {
    return GestureDetector(
      onTap: AppNavigation.openNotifications,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1AFF5F96), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_outlined, color: KafiColors.roseD, size: 15),
            Positioned(
              top: 5,
              right: 6,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: KafiColors.roseD,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(ApplicationController appCtrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Obx(() => _statItem('${appCtrl.myApplications.length}', AppStrings.nannyStatsApplied.tr)),
          _divider(),
          Obx(() {
            final viewed = appCtrl.myApplications
                .where((a) => a.status != ApplicationStatus.pending && a.status != ApplicationStatus.withdrawn)
                .length;
            return _statItem('$viewed', AppStrings.nannyStatsViewed.tr);
          }),
          _divider(),
          Obx(() {
            final offers = appCtrl.myApplications
                .where((a) => a.status == ApplicationStatus.trialOffered)
                .length;
            return _statItem('$offers', AppStrings.nannyStatsOffers.tr);
          }),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(value, style: KafiTheme.nunito(15, color: KafiColors.roseD, w: FontWeight.w900)),
            Text(label, style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: const Color(0xFFFFE8EF));

  Widget _buildFilters() {
    final filters = ['All', 'Live-in', 'Live-out', 'Newborn'];
    return Obx(() {
      final active = controller.filter.value.jobType ?? 'All';
      return Container(
        height: 38,
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: filters.length,
          itemBuilder: (_, i) {
            final label = filters[i];
            final isActive = active == label;
            return GestureDetector(
              onTap: () {
                if (label == 'All') {
                  controller.applyFilter(JobFilter());
                } else if (label == 'Live-in') {
                  controller.applyFilter(JobFilter(jobType: 'liveIn'));
                } else if (label == 'Live-out') {
                  controller.applyFilter(JobFilter(jobType: 'liveOut'));
                } else {
                  controller.applyFilter(JobFilter(duties: [label.toLowerCase()]));
                }
              },
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? KafiColors.roseD : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? KafiColors.roseD : KafiColors.roseL,
                      width: 1.5,
                    ),
                  ),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: KafiTheme.nunito(10,
                          color: isActive ? Colors.white : KafiColors.td,
                          w: FontWeight.w700)),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildJobList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: KafiColors.roseD));
      }
      final jobs = controller.filteredJobs;
      if (jobs.isEmpty) {
        return _emptyState();
      }
      // Real attribute-based match for the signed-in nanny (Spec §9 /
      // MatchService — the same scorer used on job detail & smart match), not a
      // hardcoded placeholder. Reading nanny.value inside this Obx also makes
      // the list re-rank once the profile finishes loading. Best matches first.
      final nanny = Get.isRegistered<NannyProfileController>()
          ? Get.find<NannyProfileController>().nanny.value
          : null;
      final matchService = MatchService();
      final scored = [
        for (final job in jobs)
          (job, nanny == null ? null : matchService.calculateJobMatch(nanny, job)),
      ];
      if (nanny != null) {
        scored.sort((a, b) => (b.$2 ?? 0).compareTo(a.$2 ?? 0));
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        itemCount: scored.length,
        itemBuilder: (_, i) => _jobCard(scored[i].$1, scored[i].$2),
      );
    });
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.nannyJobsEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(AppStrings.nannyJobsEmptySub.tr,
              style: KafiTheme.nunito(10, color: KafiColors.ts)),
        ],
      ),
    );
  }

  Widget _jobCard(JobPostModel job, int? matchScore) {
    final isHotMatch = (matchScore ?? 0) >= 90;
    final typeLabel = job.jobType == JobType.liveOut ? 'Live-out' : 'Live-in';
    final initial = job.familyName.isNotEmpty ? job.familyName[0].toUpperCase() : 'F';

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.nannyJobDetail, arguments: job),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: isHotMatch
              ? Border.all(color: KafiColors.roseL, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2)),
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHotMatch
                          ? const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)]
                          : const [Color(0xFFFFB347), Color(0xFFFF8042)],
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
                      Text('$typeLabel Nanny · ${job.city}',
                          style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
                      Text('AED ${job.salaryMin}–${job.salaryMax}/mo · ${job.familyName}',
                          style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
                      if (matchScore != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: matchScore >= 85
                                ? const Color(0xFFE8F8EE)
                                : KafiColors.ambL,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            matchScore >= 85
                                ? '⭐ $matchScore% match'
                                : '$matchScore% match',
                            style: KafiTheme.fredoka(9,
                                color: matchScore >= 85
                                    ? const Color(0xFF2A8A50)
                                    : const Color(0xFFC07A10),
                                w: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                _tag(typeLabel),
                if (job.city.isNotEmpty) _tag(job.city),
                for (final duty in job.duties.take(2)) _tag(duty),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: KafiColors.roseP,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w700)),
    );
  }
}
