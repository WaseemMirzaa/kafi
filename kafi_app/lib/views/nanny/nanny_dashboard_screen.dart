import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/controllers/nanny_shell_controller.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class NannyDashboardScreen extends GetView<NannyProfileController> {
  const NannyDashboardScreen({
    super.key,
    this.embedInShell = false,
    this.onSeeAllJobs,
  });

  final bool embedInShell;
  final VoidCallback? onSeeAllJobs;

  void _openJobsTab() {
    if (onSeeAllJobs != null) {
      onSeeAllJobs!();
      return;
    }
    if (Get.isRegistered<NannyShellController>()) {
      Get.find<NannyShellController>().goToTab(1);
    } else {
      Get.toNamed(Routes.nannyHome);
      if (Get.isRegistered<NannyShellController>()) {
        Get.find<NannyShellController>().goToTab(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsCtrl = Get.find<JobPostController>();
    return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _hero(),
              _statusCard(),
              _qualityCard(),
              _jobsSection(jobsCtrl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pink gradient hero ──────────────────────────────────────────
  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 17),
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
          // Profile row
          Obx(() {
            final n = controller.nanny.value;
            final initial =
                (n?.fullName.isNotEmpty == true ? n!.fullName[0] : '?').toUpperCase();
            // No fabricated identity while the profile loads — a neutral greeting
            // and no fake city (was "Sarah Reyes" / "Dubai").
            final name =
                n?.fullName.isNotEmpty == true ? n!.fullName : AppStrings.dashboardGreeting.tr;
            final area = n?.currentArea.isNotEmpty == true ? n!.currentArea : '';
            final role =
                '${n?.jobTypePreference.name == 'liveOut' ? 'Live-out' : 'Live-in'} Nanny${area.isEmpty ? '' : ' · $area'}';
            return Row(
              children: [
                // Avatar square with verified badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [KafiColors.rose, KafiColors.roseD],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(initial,
                            style: KafiTheme.fredoka(17, color: Colors.white,
                                w: FontWeight.w900)),
                      ),
                    ),
                    if (n?.isVerified == true)
                      Positioned(
                        bottom: -3,
                        right: -3,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: KafiColors.grn,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 7, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: KafiTheme.nunito(13, color: KafiColors.td,
                              w: FontWeight.w900)),
                      Text(role,
                          style: KafiTheme.nunito(9.5, color: KafiColors.ts,
                              w: FontWeight.w600)),
                    ],
                  ),
                ),
                if (n?.isVerified == true) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: KafiColors.grnL,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('Kafi Verified ✓',
                        style:
                            KafiTheme.fredoka(9, color: KafiColors.grnD, w: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                ],
                _notifBell(),
              ],
            );
          }),
          const SizedBox(height: 12),
          // Stats row
          Obx(() {
            final stats = controller.nanny.value?.stats;
            // "Your rating" cell removed — peer ratings retired for app-store ratings.
            return Row(
              children: [
                _statCell('${stats?.shortlists ?? 0}', 'Shortlists'),
                _statCell('${stats?.profileViews ?? 0}', 'Profile views'),
              ],
            );
          }),
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
            // Dot only when there are genuinely unread notifications.
            Positioned(
              top: 5,
              right: 6,
              child: Obx(() {
                final unread = Get.isRegistered<NotificationController>()
                    ? Get.find<NotificationController>().unreadCount.value
                    : 0;
                if (unread == 0) return const SizedBox.shrink();
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: KafiColors.roseD,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: KafiTheme.nunito(14, color: KafiColors.roseD,
                    w: FontWeight.w900)),
            Text(label,
                style: KafiTheme.nunito(9, color: KafiColors.ts,
                    w: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ── Employment status card (hired / on trial) ──────────────────
  Widget _statusCard() {
    return Obx(() {
      final hire = controller.activeHire.value;
      final trial = controller.activeTrial.value;
      if (hire == null && trial == null) return const SizedBox.shrink();
      final hired = hire != null;
      final accent = hired ? KafiColors.grnD : KafiColors.roseD;
      final light = hired ? KafiColors.grnL : KafiColors.roseL;
      final title =
          hired ? AppStrings.nannyHomeHiredTitle.tr : AppStrings.nannyHomeOnTrialTitle.tr;
      final familyName = hire?.familyName ?? '';
      final sub = familyName.isNotEmpty
          ? familyName
          : (hired ? AppStrings.nannyHomeHiredSub.tr : AppStrings.nannyHomeOnTrialSub.tr);

      return GestureDetector(
        onTap: () {
          if (Get.isRegistered<NannyShellController>()) {
            Get.find<NannyShellController>().goToTab(2);
          }
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [light, Colors.white],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(11)),
                    child: Icon(hired ? Icons.workspace_premium : Icons.handshake,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: KafiTheme.nunito(12.5, color: KafiColors.td, w: FontWeight.w800)),
                        const SizedBox(height: 1),
                        Text(sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KafiTheme.nunito(10, color: accent, w: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(AppStrings.nannyHomeViewChat.tr,
                          style: KafiTheme.nunito(9.5, color: accent, w: FontWeight.w800)),
                      Icon(Icons.chevron_right, color: accent, size: 16),
                    ],
                  ),
                ],
              ),
              // A hired nanny can resign here (ends the employment).
              if (hired) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _confirmResign,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, left: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.logout, size: 13, color: KafiColors.redD),
                          const SizedBox(width: 4),
                          Text(AppStrings.hireResignAction.tr,
                              style: KafiTheme.nunito(10, color: KafiColors.redD, w: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  void _confirmResign() {
    Get.dialog(AlertDialog(
      title: Text(AppStrings.hireResignTitle.tr),
      content: Text(AppStrings.hireResignBody.tr),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
        TextButton(
          onPressed: () {
            Get.back();
            controller.resignHire();
          },
          child: Text(AppStrings.hireResignAction.tr,
              style: const TextStyle(color: KafiColors.redD)),
        ),
      ],
    ));
  }

  // ── Profile quality card ────────────────────────────────────────
  Widget _qualityCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: Color(0x14FF5F96), blurRadius: 9, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + score
          Obx(() {
            // Real server-maintained score; 0 (the model default) until loaded —
            // never a fabricated placeholder.
            final score = controller.nanny.value?.profileScore ?? 0;
            return Row(
              children: [
                Expanded(
                  child: Text('Profile quality score',
                      style: KafiTheme.nunito(11.5, color: KafiColors.td,
                          w: FontWeight.w800)),
                ),
                Text('$score%',
                    style: KafiTheme.nunito(18, color: KafiColors.roseD,
                        w: FontWeight.w900)),
              ],
            );
          }),
          const SizedBox(height: 8),
          // Progress bar (rose gradient fill, like the web .qc-fill)
          Obx(() {
            final score = ((controller.nanny.value?.profileScore ?? 0) / 100).clamp(0.0, 1.0);
            return ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(height: 6, color: const Color(0xFFFFF0F5)),
                  FractionallySizedBox(
                    widthFactor: score,
                    child: Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [KafiColors.rose, KafiColors.roseD]),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          // Quality items
          Obx(() {
            final n = controller.nanny.value;
            final hasPhoto = controller.photoUrls.isNotEmpty;
            final hasVideo = controller.introVideoUrl.value != null;
            final isVerified = n?.isVerified ?? false;
            final hasPolice = controller.documents[DocumentType.policeClearance]?.status !=
                DocumentStatus.missing;
            final hasCert = controller.documents[DocumentType.trainingCert]?.status !=
                DocumentStatus.missing;
            return Column(
              children: [
                _qcItem(done: hasPhoto, label: 'Profile photo added'),
                _qcItem(done: isVerified, label: 'Kafi Verified badge'),
                _qcItem(done: hasVideo, label: 'Video introduction uploaded'),
                _qcItem(
                    done: controller.photoUrls.length > 1,
                    label: 'Multiple photos added'),
                _qcItem(
                    done: hasPolice,
                    label: 'Add police clearance',
                    bonus: hasPolice ? null : '→ +10pts'),
                _qcItem(
                    done: hasCert,
                    label: 'Add training certificate',
                    bonus: hasCert ? null : '→ +7pts'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _qcItem({required bool done, required String label, String? bonus}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: done ? KafiColors.grnL : const Color(0xFFF0F0F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                done ? '✓' : '+',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: done ? KafiColors.grnD : const Color(0xFF999999),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: KafiTheme.nunito(10,
                    color: done ? KafiColors.grnD : KafiColors.ts,
                    w: FontWeight.w700)),
          ),
          if (bonus != null)
            Text(bonus,
                style: KafiTheme.fredoka(10, color: KafiColors.ts)),
        ],
      ),
    );
  }

  // ── Jobs for you ────────────────────────────────────────────────
  Widget _jobsSection(JobPostController jobsCtrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('🌟 ${AppStrings.dashJobsForYou.tr}',
                    style: KafiTheme.nunito(12, color: KafiColors.td,
                        w: FontWeight.w800)),
              ),
              GestureDetector(
                onTap: _openJobsTab,
                child: Text('See all',
                    style: KafiTheme.nunito(10, color: KafiColors.roseD,
                        w: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Obx(() {
            if (jobsCtrl.isLoading.value && jobsCtrl.allJobs.isEmpty) {
              return const Center(
                  child:
                      CircularProgressIndicator(color: KafiColors.roseD));
            }
            // Real attribute-based match for the signed-in nanny (the same
            // MatchService scorer used on the jobs tab and job detail), not a
            // decorative placeholder. Rank by match BEFORE taking the top 2 so
            // "Jobs for you" surfaces the best matches, not the first two.
            final nanny = controller.nanny.value;
            final matchService = MatchService();
            final ranked = jobsCtrl.filteredJobs.toList();
            if (nanny != null) {
              ranked.sort((a, b) => matchService
                  .calculateJobMatch(nanny, b)
                  .compareTo(matchService.calculateJobMatch(nanny, a)));
            }
            final preview = ranked.take(2).toList();
            if (preview.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(AppStrings.nannyJobsEmpty.tr,
                    style: KafiTheme.nunito(11, color: KafiColors.tm)),
              );
            }
            return Column(
              children: [
                for (final job in preview)
                  _jobCard(
                      job,
                      nanny == null
                          ? null
                          : matchService.calculateJobMatch(nanny, job)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _jobCard(JobPostModel job, int? matchScore) {
    final isHot = (matchScore ?? 0) >= 90;
    final typeLabel = job.jobType == JobType.liveOut ? 'Live-out' : 'Live-in';
    final initial = job.familyName.isNotEmpty ? job.familyName[0].toUpperCase() : 'F';
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.nannyJobDetail, arguments: job),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: isHot ? KafiColors.roseL : Colors.transparent, width: 1.5),
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
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHot
                          ? const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)]
                          : const [Color(0xFFFFB347), Color(0xFFFF8042)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: KafiTheme.fredoka(14, color: Colors.white,
                            w: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$typeLabel Nanny · ${job.city}',
                          style: KafiTheme.nunito(11, color: KafiColors.td,
                              w: FontWeight.w800)),
                      Text(
                          'AED ${job.salaryMin}–${job.salaryMax}/mo · ${job.familyName}',
                          style: KafiTheme.nunito(9, color: KafiColors.ts,
                              w: FontWeight.w600)),
                      if (matchScore != null) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
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
                _chip(typeLabel),
                if (job.city.isNotEmpty) _chip(job.city),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w700)),
      );
}
