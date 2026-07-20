import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/browse_controller.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/widgets/kafi_nanny_card.dart';

class BrowseScreen extends GetView<BrowseController> {
  const BrowseScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    final subs = Get.find<SubscriptionController>();
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _hero(),
            _filterPills(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppStrings.browseTopMatches.tr,
                        style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w800)),
                  ),
                  GestureDetector(
                    onTap: () => controller.onFilterTap('All'),
                    child: Text(AppStrings.seeAll.tr,
                        style: KafiTheme.nunito(10, color: KafiColors.pur, w: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator(color: KafiColors.roseD));
                  }
                  final items = controller.filteredResults;
                  if (items.isEmpty) {
                    final err = controller.loadError.value;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            err ?? AppStrings.browseNoMatch.tr,
                            textAlign: TextAlign.center,
                            style: KafiTheme.nunito(
                              12,
                              color: err != null ? KafiColors.roseD : KafiColors.tm,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              controller.searchCtrl.clear();
                              controller.query.value = '';
                              controller.onFilterTap('All');
                            },
                            child: Text(AppStrings.seeAll.tr, style: KafiTheme.fredoka(11, color: KafiColors.roseD)),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                        children: [
                          if (subs.isExpired) _expiredBanner(),
                          if (subs.state.value == SubscriptionState.paymentGrace) _graceBanner(),
                          Expanded(
                            child: RefreshIndicator(
                        onRefresh: controller.refreshList,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final card = items[i];
                            return KafiNannyCard(
                              card: card,
                              jobLabel: controller.matchJobTitle,
                              onTap: () async {
                                final wasViewed = subs.viewedNannyIds.contains(card.id);
                                final allowed = await controller.recordView(card.id);

                                // Route resolution:
                                // - subscribed → unlocked
                                // - expired + previously viewed → re-locked
                                // - expired + new → locked (no contacts)
                                // - free + allowed (not over limit) → locked or unlocked depending on sub
                                // - free + over limit → nudge to pricing
                                if (subs.isSubscribed) {
                                  Get.toNamed(Routes.profileUnlocked, arguments: card);
                                  return;
                                }
                                if (subs.isExpired) {
                                  Get.toNamed(
                                    wasViewed ? Routes.profileRelocked : Routes.profileLocked,
                                    arguments: card,
                                  );
                                  return;
                                }
                                if (!allowed) {
                                  Get.snackbar(
                                    AppStrings.subscriptionRequired.tr,
                                    AppStrings.noFreeViewsLeft.tr,
                                  );
                                  Get.toNamed(Routes.pricing);
                                  return;
                                }
                                // Free-tier hint when running low.
                                final remaining = subs.freeViewsRemaining;
                                if (!subs.isSubscribed && remaining > 0 && remaining <= 2) {
                                  Get.snackbar(
                                    '',
                                    '$remaining ${AppStrings.freeViewsRemaining.tr}',
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                                Get.toNamed(Routes.profileLocked, arguments: card);
                              },
                            );
                          },
                        ),
                      ),
                          ),
                        ],
                      );
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _graceBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KafiColors.ambL,
        border: Border.all(color: const Color(0xFFFFD080), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFA06010), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment issue', style: KafiTheme.nunito(11, color: const Color(0xFF7A4A00), w: FontWeight.w800)),
                Text('Update payment to avoid losing access.',
                    style: KafiTheme.nunito(10, color: const Color(0xFF7A4A00), w: FontWeight.w400)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed(Routes.pricing),
            child: Text('Fix now', style: KafiTheme.fredoka(10, color: KafiColors.roseD)),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 17),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEE0FF), Color(0xFFF0D8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + notification bell
          Row(
            children: [
              Text(AppStrings.appName.tr, style: KafiTheme.pacifico(18, color: const Color(0xFF5A2090))),
              const Spacer(),
              GestureDetector(
                onTap: AppNavigation.openNotifications,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x269B6EDB), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, color: KafiColors.pur, size: 15),
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
                              color: KafiColors.pur,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(AppStrings.browseGoodMorning.tr,
              style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
          const SizedBox(height: 1),
          _greeting(),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: const [BoxShadow(color: Color(0x149B6EDB), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: KafiColors.purB, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          controller: controller.searchCtrl,
                          onChanged: (v) => controller.query.value = v,
                          style: KafiTheme.nunito(11, color: KafiColors.td),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: AppStrings.browseSearchHint.tr,
                            hintStyle: KafiTheme.nunito(11, color: KafiColors.ts),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showJobFilter,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [KafiColors.pur, Color(0xFFC084FC)]),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(color: KafiColors.pur.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Obx(() => Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.tune, color: Colors.white, size: 18),
                          if (controller.selectedJob.value != null)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: KafiColors.grnD,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      )),
                ),
              ),
            ],
          ),
          Obx(() {
            final job = controller.selectedJob.value;
            if (job == null) return const SizedBox(height: 9);
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => controller.selectJob(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KafiColors.pur, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Matches for: ${_jobName(job)}',
                          style: KafiTheme.nunito(9.5, color: KafiColors.pur, w: FontWeight.w800)),
                      const SizedBox(width: 5),
                      const Icon(Icons.close, size: 12, color: KafiColors.pur),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 9),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.familyForm),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [KafiColors.pur, Color(0xFFC084FC)]),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(color: KafiColors.pur.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Text('🏡  ${AppStrings.postNewJob.tr}',
                  style: KafiTheme.fredoka(12.5, color: Colors.white, w: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  /// "Hello, NAME!" with the family's first name accented in rose.
  Widget _greeting() {
    final name = controller.familyFirstName;
    final full = AppStrings.browseHello.trParams({'name': name});
    final base = KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w900);
    final idx = name.isEmpty ? -1 : full.indexOf(name);
    if (idx < 0) {
      return Text(full, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: full.substring(0, idx)),
          TextSpan(text: name, style: base.copyWith(color: KafiColors.pur)),
          TextSpan(text: full.substring(idx + name.length)),
        ],
      ),
    );
  }

  String _jobName(JobPostModel j) =>
      j.jobTitle.isNotEmpty ? j.jobTitle : '${j.jobType == JobType.liveOut ? 'Live-out' : 'Live-in'} · ${j.city}';

  // Bottom sheet to filter Top Matches by one of the family's posted jobs.
  void _showJobFilter() {
    final jobs = controller.myJobs;
    Get.bottomSheet(
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: KafiColors.purB, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Filter by job',
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w900)),
            const SizedBox(height: 2),
            Text('Show nannies matching one of your posted jobs',
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
            const SizedBox(height: 12),
            if (jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text("You haven't posted any jobs yet.",
                        style: KafiTheme.nunito(11, color: KafiColors.tm, w: FontWeight.w600)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.toNamed(Routes.familyForm);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [KafiColors.pur, Color(0xFFC084FC)]),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text('🏡  ${AppStrings.postNewJob.tr}',
                            style: KafiTheme.fredoka(11.5, color: Colors.white, w: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              )
            else
              Obx(() {
                final sel = controller.selectedJob.value;
                return Column(
                  children: [
                    _jobFilterRow(null, 'All matches', sel == null),
                    for (final j in jobs) _jobFilterRow(j, _jobName(j), sel?.id == j.id),
                  ],
                );
              }),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _jobFilterRow(JobPostModel? job, String label, bool selected) {
    return GestureDetector(
      onTap: () {
        controller.selectJob(job);
        Get.back();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? KafiColors.purL : KafiColors.inputBgP,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? KafiColors.pur : KafiColors.purB, width: 1.5),
        ),
        child: Row(
          children: [
            Text(job == null ? '🌸' : '🏡', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w800)),
            ),
            if (selected) const Icon(Icons.check_circle, color: KafiColors.pur, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _filterPills() {
    return SizedBox(
      height: 38,
      child: Obx(
        () {
          final active = controller.activeFilter.value;
          return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, i) {
            final f = BrowseController.filters[i];
            final isActive = active == f;
            return GestureDetector(
              onTap: () => controller.onFilterTap(f),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? KafiColors.pur : KafiColors.purL,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  f,
                  style: KafiTheme.fredoka(10,
                      color: isActive ? Colors.white : KafiColors.pur, w: FontWeight.w700),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemCount: BrowseController.filters.length,
        );
        },
      ),
    );
  }

  /// Slim banner shown above the browse list when subscription expired.
  /// Per spec, families can still browse profiles (locked view), so we don't
  /// hide the list — just nudge the user to renew.
  Widget _expiredBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KafiColors.redL,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KafiColors.redD.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: KafiColors.redD, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.chatExpiredTitle.tr,
                    style: KafiTheme.nunito(12,
                        color: KafiColors.td, w: FontWeight.w800)),
                Text(AppStrings.subExpiredBanner.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.tm)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KafiColors.roseD,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Get.toNamed(Routes.pricing),
            child: Text(AppStrings.renewNow.tr,
                style: KafiTheme.nunito(10,
                    color: Colors.white, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
