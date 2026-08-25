import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

const _heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFE0EC), Color(0xFFFFF4EE)],
);

const _avatarGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
);

BoxDecoration _cardDecoration({Color border = const Color(0xFFFFE8EF)}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    border: Border.all(color: border, width: 1.5),
    boxShadow: const [
      BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );
}

class ApplicationDetailScreen extends StatefulWidget {
  const ApplicationDetailScreen({super.key});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  late final ApplicationModel _arg = Get.arguments as ApplicationModel;

  @override
  void initState() {
    super.initState();
    // Defer Rx writes until after this route finishes building. Calling
    // loadApplications/refreshAll here (they set isLoading / all synchronously
    // before the first await) marks the still-mounted My Applications Obx dirty
    // mid-transition → "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Get.isRegistered<ApplicationController>()) {
        Get.find<ApplicationController>().loadApplications();
      }
      // Pending trial offers need TrialController.all hydrated so Accept/Decline
      // render on this screen (Screen 32A), not only "View in Messages".
      if (Get.isRegistered<TrialController>()) {
        Get.find<TrialController>().refreshAll();
      }
    });
  }

  /// The live application from the controller (falls back to the passed
  /// argument) so the screen reflects status changes, not a frozen snapshot.
  ApplicationModel get _app {
    if (Get.isRegistered<ApplicationController>()) {
      return Get.find<ApplicationController>()
              .myApplications
              .firstWhereOrNull((a) => a.id == _arg.id) ??
          _arg;
    }
    return _arg;
  }

  JobPostModel? get _job {
    if (!Get.isRegistered<JobPostController>()) return null;
    return Get.find<JobPostController>().allJobs.firstWhereOrNull((j) => j.id == _app.jobPostId);
  }

  TrialModel? get _trial {
    if (!Get.isRegistered<TrialController>()) return null;
    final tc = Get.find<TrialController>();
    return tc.all.firstWhereOrNull(
      (t) => t.nannyId == _app.nannyId && t.familyId == _app.familyId,
    );
  }

  String? get _threadId {
    if (!Get.isRegistered<ChatController>()) return null;
    final ct = Get.find<ChatController>();
    return ct.threads.firstWhereOrNull(
      (t) => t.familyId == _app.familyId,
    )?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Register trial loading so Accept/Decline buttons rebuild without a
      // nested Obx (nested Obx under an outer Obx is a common GetX pitfall).
      final trialLoading = Get.isRegistered<TrialController>() &&
          Get.find<TrialController>().isLoading.value;
      final app = _app;
      final bottomBar = _buildActionBar(app, trialLoading: trialLoading);
      return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14, 14, 14, bottomBar != null ? 14 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _statusBanner(app.status),
                    const SizedBox(height: 12),
                    _jobCard(_job, app),
                    const SizedBox(height: 12),
                    _buildBody(app),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        bottomNavigationBar: bottomBar,
      );
    });
  }

  Widget? _buildActionBar(ApplicationModel app, {required bool trialLoading}) {
    switch (app.status) {
      case ApplicationStatus.pending:
      case ApplicationStatus.viewed:
        return _actionBar(
          child: _destructiveOutlineButton(
            label: AppStrings.nannyWithdraw.tr,
            icon: Icons.undo,
            onPressed: () => _confirmWithdraw(app.id),
          ),
        );
      case ApplicationStatus.shortlisted:
        return _actionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KafiPrimaryButton(
                label: '💬 ${AppStrings.appDetailMessageFamily.tr}',
                // Pops the pushed detail/list routes to root THEN opens the
                // Messages tab, so the CTA visibly navigates (nannyGoToTab alone
                // left the pushed route covering the shell → button looked dead).
                onPressed: () => AppNavigation.openChatWithFamily(familyId: app.familyId, familyName: app.familyName),
              ),
              const SizedBox(height: 8),
              _destructiveOutlineButton(
                label: AppStrings.nannyWithdraw.tr,
                icon: Icons.undo,
                onPressed: () => _confirmWithdraw(app.id),
              ),
            ],
          ),
        );
      case ApplicationStatus.trialOffered:
        final trial = _trial;
        // Only pending offers get Accept / Counter / Decline (Screen 32A).
        if (trial != null && trial.status == TrialStatus.pending) {
          return _actionBar(child: _trialActions(trial, isLoading: trialLoading));
        }
        // Trial still loading, or already responded — keep a path into chat.
        return _actionBar(
          child: KafiPrimaryButton(
            label: AppStrings.appDetailViewInMessages.tr,
            icon: Icons.chat_bubble_outline,
            onPressed: () => AppNavigation.openChatWithFamily(
                familyId: app.familyId, familyName: app.familyName),
          ),
        );
      case ApplicationStatus.hired:
        // Hired → the ongoing relationship lives in Messages (hire badge +
        // chat). "View Active Trial" was wrong (a hire is not a trial, and
        // there is no nanny trials tab).
        return _actionBar(
          child: KafiPrimaryButton(
            label: '💬 ${AppStrings.appDetailMessageFamily.tr}',
            icon: Icons.chat_bubble_outline,
            onPressed: () => AppNavigation.openChatWithFamily(familyId: app.familyId, familyName: app.familyName),
          ),
        );
      case ApplicationStatus.declined:
      case ApplicationStatus.withdrawn:
        return null;
    }
  }

  Widget _actionBar({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFFFE8EF), width: 1.5)),
        boxShadow: [BoxShadow(color: Color(0x18FF5F96), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: child,
        ),
      ),
    );
  }

  Widget _destructiveOutlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KafiColors.redD.withValues(alpha: 0.35), width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: KafiColors.redD),
                const SizedBox(width: 6),
                Text(label, style: KafiTheme.fredoka(12, color: KafiColors.redD)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmWithdraw(String appId) async {
    final confirm = await _showNannyDialog(
      icon: Icons.undo,
      accentColor: KafiColors.redD,
      title: AppStrings.appDetailWithdrawTitle.tr,
      message: AppStrings.appDetailWithdrawConfirm.tr,
      confirmLabel: AppStrings.appDetailWithdrawYes.tr,
      confirmVariant: KafiButtonVariant.red,
    );
    if (confirm == true && Get.isRegistered<ApplicationController>()) {
      await Get.find<ApplicationController>().withdrawApplication(appId);
      Get.back();
    }
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(gradient: _heroGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.roseD, size: 20),
            ),
          ),
          Expanded(
            child: Text(AppStrings.appDetailTitle.tr, style: KafiTheme.pacifico(17)),
          ),
        ],
      ),
    );
  }

  Widget _statusBanner(ApplicationStatus status) {
    final cfg = _bannerConfig(status);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cfg.border, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cfg.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cfg.icon, color: cfg.fg, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cfg.title,
                    style: KafiTheme.nunito(12, color: cfg.fg, w: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(cfg.message,
                    style: KafiTheme.nunito(9.5,
                        color: cfg.fg.withValues(alpha: 0.75), w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _BannerConfig _bannerConfig(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pending:
        return _BannerConfig(
          icon: Icons.schedule,
          title: AppStrings.appDetailPendingTitle.tr,
          message: AppStrings.appDetailPendingMsg.tr,
          bg: KafiColors.ambL,
          border: const Color(0xFFFFD080),
          fg: KafiColors.ambD,
          iconBg: const Color(0xFFFFE8B0),
        );
      case ApplicationStatus.viewed:
        return _BannerConfig(
          icon: Icons.visibility_outlined,
          title: AppStrings.appDetailViewedTitle.tr,
          message: AppStrings.appDetailViewedMsg.tr,
          bg: KafiColors.purpL,
          border: KafiColors.purpD.withValues(alpha: 0.25),
          fg: KafiColors.purpD,
          iconBg: KafiColors.purpL,
        );
      case ApplicationStatus.shortlisted:
        return _BannerConfig(
          icon: Icons.star_outline,
          title: AppStrings.appDetailShortlisted.tr,
          message: AppStrings.appDetailShortlistedMsg.tr,
          bg: KafiColors.grnL,
          border: KafiColors.grnD.withValues(alpha: 0.25),
          fg: KafiColors.grnD,
          iconBg: const Color(0xFFD4F5DE),
        );
      case ApplicationStatus.trialOffered:
        return _BannerConfig(
          icon: Icons.handshake_outlined,
          title: AppStrings.appDetailTrialOffered.tr,
          message: AppStrings.appDetailTrialOfferedMsg.tr,
          bg: KafiColors.roseL,
          border: const Color(0xFFFFC0D4),
          fg: KafiColors.roseD,
          iconBg: const Color(0xFFFFE0EC),
        );
      case ApplicationStatus.hired:
        return _BannerConfig(
          icon: Icons.celebration_outlined,
          title: AppStrings.appDetailHired.tr,
          message: AppStrings.appDetailHiredMsg.tr,
          bg: KafiColors.grnL,
          border: KafiColors.grnD.withValues(alpha: 0.25),
          fg: KafiColors.grnD,
          iconBg: const Color(0xFFD4F5DE),
        );
      case ApplicationStatus.declined:
        return _BannerConfig(
          icon: Icons.cancel_outlined,
          title: AppStrings.appDetailDeclined.tr,
          message: AppStrings.appDetailDeclinedMsg.tr,
          bg: KafiColors.redL,
          border: KafiColors.redD.withValues(alpha: 0.25),
          fg: KafiColors.redD,
          iconBg: const Color(0xFFFFE0E0),
        );
      case ApplicationStatus.withdrawn:
        return _BannerConfig(
          icon: Icons.undo,
          title: AppStrings.appDetailWithdrawn.tr,
          message: AppStrings.appDetailWithdrawnMsg.tr,
          bg: const Color(0xFFF8F8F8),
          border: const Color(0xFFE8E8E8),
          fg: KafiColors.ts,
          iconBg: const Color(0xFFEEEEEE),
        );
    }
  }

  Widget _jobCard(JobPostModel? job, ApplicationModel app) {
    final typeLabel =
        job?.jobType.name == 'liveOut' ? AppStrings.jobLiveOut.tr : AppStrings.jobLiveIn.tr;
    final city = job?.city ?? '—';
    final title = job?.jobTitle ?? '$typeLabel ${AppStrings.nannySuffix.tr}';
    final family = job?.familyName ?? '—';
    final initial = family.isNotEmpty ? family[0].toUpperCase() : 'F';
    final salary = job != null && job.salaryMax > 0
        ? AppStrings.jobSalaryRange.trParams({
            'min': '${job.salaryMin}',
            'max': '${job.salaryMax}',
          })
        : null;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _avatarGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(initial,
                      style: KafiTheme.fredoka(18, color: Colors.white, w: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w900)),
                    Text('$family · $city',
                        style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
                    // Nanny-side "% match" suppressed (M8) — the canonical match
                    // is the family's household+job score the nanny can't compute.
                  ],
                ),
              ),
            ],
          ),
          if (salary != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(Icons.payments_outlined, salary),
                _chip(Icons.location_on_outlined, city),
              ],
            ),
          ],
          const SizedBox(height: 10),
          _timelineRow(app),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: KafiColors.roseP,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: KafiColors.roseD),
          const SizedBox(width: 4),
          Text(label,
              style: KafiTheme.nunito(9, color: KafiColors.roseD, w: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _timelineRow(ApplicationModel app) {
    final steps = _timelineSteps(app.status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: KafiColors.nannyBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: step.done ? KafiColors.grnL : const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            step.done ? '✓' : '${i + 1}',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: step.done ? KafiColors.grnD : KafiColors.ts,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(step.label,
                          style: KafiTheme.nunito(8,
                              color: step.done ? KafiColors.grnD : KafiColors.ts,
                              w: step.done ? FontWeight.w700 : FontWeight.w500),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 1,
                    width: 6,
                    color: const Color(0xFFFFE8EF),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<_TimelineStep> _timelineSteps(ApplicationStatus s) {
    final applied = _TimelineStep(AppStrings.appDetailApplied.tr, true);
    final viewed = _TimelineStep(AppStrings.nannyAppStatusViewed.tr, s != ApplicationStatus.pending);
    final responded = _TimelineStep(
      AppStrings.appDetailStepResponded.tr,
      [
        ApplicationStatus.shortlisted,
        ApplicationStatus.trialOffered,
        ApplicationStatus.declined,
        ApplicationStatus.hired,
      ].contains(s),
    );
    final hired = _TimelineStep(AppStrings.appDetailStepHired.tr, s == ApplicationStatus.hired);
    if (s == ApplicationStatus.withdrawn) {
      return [applied, _TimelineStep(AppStrings.nannyAppStatusWithdrawn.tr, true)];
    }
    if (s == ApplicationStatus.hired) {
      return [applied, viewed, responded, hired];
    }
    return [applied, viewed, responded];
  }

  Widget _buildBody(ApplicationModel app) {
    switch (app.status) {
      case ApplicationStatus.pending:
      case ApplicationStatus.viewed:
        return _buildPendingViewedBody(app);
      case ApplicationStatus.shortlisted:
        return _buildShortlistedBody(app);
      case ApplicationStatus.trialOffered:
        return _buildTrialOfferedBody(app);
      case ApplicationStatus.hired:
        return _buildHiredBody(app);
      case ApplicationStatus.declined:
      case ApplicationStatus.withdrawn:
        return _buildClosedBody(app);
    }
  }

  Widget _buildPendingViewedBody(ApplicationModel app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (app.coverMessage != null && app.coverMessage!.isNotEmpty)
          _sectionCard(
            title: AppStrings.appDetailCoverMsg.tr,
            icon: Icons.message_outlined,
            child: Text(app.coverMessage!,
                style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w600)),
          ),
        if (app.coverMessage != null && app.coverMessage!.isNotEmpty) const SizedBox(height: 10),
        _sectionCard(
          title: AppStrings.appDetailTimelineTitle.tr,
          icon: Icons.schedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateRow(AppStrings.appDetailApplied.tr, app.createdAt),
              if (app.viewedAt != null) _dateRow(AppStrings.nannyAppStatusViewed.tr, app.viewedAt!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortlistedBody(ApplicationModel app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (app.coverMessage != null && app.coverMessage!.isNotEmpty)
          _sectionCard(
            title: AppStrings.appDetailCoverMsg.tr,
            icon: Icons.message_outlined,
            child: Text(app.coverMessage!,
                style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w600)),
          ),
        if (app.coverMessage != null && app.coverMessage!.isNotEmpty) const SizedBox(height: 10),
        _sectionCard(
          title: AppStrings.appDetailTimelineTitle.tr,
          icon: Icons.schedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dateRow(AppStrings.appDetailApplied.tr, app.createdAt),
              if (app.viewedAt != null) _dateRow(AppStrings.nannyAppStatusViewed.tr, app.viewedAt!),
              if (app.respondedAt != null)
                _dateRow(AppStrings.nannyAppStatusShortlisted.tr, app.respondedAt!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrialOfferedBody(ApplicationModel app) {
    final trial = _trial;
    if (trial != null) {
      return _trialOfferCard(trial);
    }
    return _sectionCard(
      title: AppStrings.appDetailNoTrialTitle.tr,
      icon: Icons.handshake_outlined,
      child: Text(
        AppStrings.appDetailNoTrialBody.tr,
        style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w600),
      ),
    );
  }

  Widget _trialOfferCard(TrialModel trial) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(border: const Color(0xFFFFC0D4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: KafiColors.roseP,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('🤝 ${AppStrings.appDetailTrialOfferDetails.tr}',
                style: KafiTheme.fredoka(10, color: KafiColors.roseD, w: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          _trialRow(Icons.calendar_month_outlined,
              AppStrings.appDetailTrialDuration.tr,
              AppStrings.familyTrialDaysN.trParams({'n': '${trial.durationDays}'})),
          _trialRow(Icons.payments_outlined,
              AppStrings.appDetailTrialRate.tr,
              AppStrings.aedPerDay.trParams({'rate': '${trial.dailyRate}'})),
          _trialRow(Icons.today_outlined, AppStrings.appDetailTrialStart.tr,
              _fmtDate(trial.startDate)),
          _trialRow(Icons.home_work_outlined, AppStrings.appDetailTrialType.tr,
              trial.trialType == 'live-in' ? AppStrings.jobLiveIn.tr : AppStrings.jobLiveOut.tr),
          if (trial.location.isNotEmpty)
            _trialRow(Icons.location_on_outlined,
                AppStrings.appDetailTrialLocation.tr, trial.location),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: KafiColors.nannyBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.appDetailTrialTotal.tr,
                    style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
                Text(AppStrings.aedAmount.trParams({'amount': '${trial.totalAmount}'}),
                    style: KafiTheme.nunito(14, color: KafiColors.roseD, w: FontWeight.w900)),
              ],
            ),
          ),
          if (trial.notes != null && trial.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(AppStrings.appDetailTrialNotes.tr,
                style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(trial.notes!,
                style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _trialRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: KafiColors.roseP,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: KafiColors.roseD),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
          ),
          Text(value,
              style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _trialActions(TrialModel trial, {required bool isLoading}) {
    final threadId = _threadId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KafiPrimaryButton(
          label: AppStrings.trialOfferAccept.tr,
          icon: Icons.check_circle_outline,
          variant: KafiButtonVariant.green,
          loading: isLoading,
          onPressed: () => _confirmAndAccept(trial.id, threadId),
        ),
        const SizedBox(height: 8),
        _outlineButton(
          label: AppStrings.trialOfferCounter.tr,
          icon: Icons.swap_horiz,
          onPressed: isLoading ? null : () => _showCounterSheet(trial),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: isLoading ? null : () => _confirmAndDecline(trial.id, threadId),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(AppStrings.trialOfferDecline.tr,
              style: KafiTheme.nunito(11, color: KafiColors.redD, w: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFC0D4), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x0AFF5F96), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: KafiColors.roseD),
                const SizedBox(width: 6),
                Text(label, style: KafiTheme.fredoka(12, color: KafiColors.roseD)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHiredBody(ApplicationModel app) {
    return _sectionCard(
      title: AppStrings.appDetailTimelineTitle.tr,
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dateRow(AppStrings.appDetailApplied.tr, app.createdAt),
          if (app.viewedAt != null) _dateRow(AppStrings.nannyAppStatusViewed.tr, app.viewedAt!),
          if (app.respondedAt != null)
            _dateRow(AppStrings.appDetailLabelHired.tr, app.respondedAt!),
        ],
      ),
    );
  }

  Widget _buildClosedBody(ApplicationModel app) {
    return _sectionCard(
      title: AppStrings.appDetailTimelineTitle.tr,
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _dateRow(AppStrings.appDetailApplied.tr, app.createdAt),
          if (app.viewedAt != null) _dateRow(AppStrings.nannyAppStatusViewed.tr, app.viewedAt!),
          if (app.respondedAt != null)
            _dateRow(
              app.status == ApplicationStatus.declined
                  ? AppStrings.nannyAppStatusDeclined.tr
                  : AppStrings.appDetailStepResponded.tr,
              app.respondedAt!,
            ),
          if (app.withdrawnAt != null)
            _dateRow(AppStrings.nannyAppStatusWithdrawn.tr, app.withdrawnAt!),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: KafiColors.roseP,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 13, color: KafiColors.roseD),
              ),
              const SizedBox(width: 7),
              Text(title,
                  style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _dateRow(String label, DateTime dt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w700)),
          Text(_fmtDate(dt), style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<bool?> _showNannyDialog({
    required IconData icon,
    required Color accentColor,
    required String title,
    String? message,
    required String confirmLabel,
    String? cancelLabel,
    KafiButtonVariant confirmVariant = KafiButtonVariant.green,
  }) {
    final resolvedCancelLabel = cancelLabel ?? AppStrings.cancel.tr;
    return Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x24FF5F96), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(height: 12),
              Text(title,
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w900)),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(message,
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              KafiPrimaryButton(
                label: confirmLabel,
                variant: confirmVariant,
                onPressed: () => Get.back(result: true),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(resolvedCancelLabel,
                    style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _confirmAndAccept(String trialId, String? threadId) async {
    final ok = await _showNannyDialog(
      icon: Icons.check_circle_outline,
      accentColor: KafiColors.grnD,
      title: AppStrings.appDetailAcceptConfirm.tr,
      confirmLabel: AppStrings.appDetailAcceptOfferLabel.tr,
      confirmVariant: KafiButtonVariant.green,
    );
    if (ok == true && Get.isRegistered<TrialController>()) {
      await Get.find<TrialController>().acceptTrial(trialId, threadId: threadId);
      Get.back();
    }
  }

  void _confirmAndDecline(String trialId, String? threadId) async {
    final ok = await _showNannyDialog(
      icon: Icons.cancel_outlined,
      accentColor: KafiColors.redD,
      title: AppStrings.appDetailDeclineConfirm.tr,
      confirmLabel: AppStrings.appDetailDeclineOfferLabel.tr,
      confirmVariant: KafiButtonVariant.red,
    );
    if (ok == true && Get.isRegistered<TrialController>()) {
      await Get.find<TrialController>().declineTrial(trialId, threadId: threadId);
      Get.back();
    }
  }

  void _showCounterSheet(TrialModel trial) {
    final rateCtrl = TextEditingController(text: '${trial.dailyRate}');
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Color(0xFFFFE8EF), width: 1.5)),
          boxShadow: [
            BoxShadow(color: Color(0x24FF5F96), blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 10,
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC0D4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  gradient: _heroGradient,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.appDetailCounterTitle.tr,
                        style: KafiTheme.pacifico(16, color: KafiColors.roseD)),
                    const SizedBox(height: 4),
                    Text(
                        AppStrings.appDetailOriginalOffer
                            .trParams({'rate': '${trial.dailyRate}'}),
                        style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.appDetailCounterHint.tr,
                  style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: rateCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w800),
                decoration: InputDecoration(
                  prefixText: AppStrings.currencyAedPrefix.tr,
                  suffixText: AppStrings.perDaySuffix.tr,
                  filled: true,
                  fillColor: KafiColors.nannyBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: Color(0xFFFFE8EF), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: Color(0xFFFFE8EF), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: KafiColors.roseD, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final isLoading = Get.isRegistered<TrialController>()
                    ? Get.find<TrialController>().isLoading.value
                    : false;
                return KafiPrimaryButton(
                  label: AppStrings.appDetailCounterSend.tr,
                  icon: Icons.send_outlined,
                  loading: isLoading,
                  onPressed: () async {
                    final rate = int.tryParse(rateCtrl.text.trim());
                    if (rate == null || rate <= 0) return;
                    if (Get.isRegistered<TrialController>()) {
                      await Get.find<TrialController>()
                          .counterTrial(trial.id, dailyRate: rate, threadId: _threadId);
                      Get.back();
                      Get.back();
                    }
                  },
                );
              }),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(AppStrings.cancel.tr,
                    style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _BannerConfig {
  const _BannerConfig({
    required this.icon,
    required this.title,
    required this.message,
    required this.bg,
    required this.border,
    required this.fg,
    required this.iconBg,
  });
  final IconData icon;
  final String title;
  final String message;
  final Color bg;
  final Color border;
  final Color fg;
  final Color iconBg;
}

class _TimelineStep {
  const _TimelineStep(this.label, this.done);
  final String label;
  final bool done;
}
