import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart' show JobType;
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/smart_match.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

enum _CkState { pass, fail, warn }

class SmartMatchScreen extends GetView<ApplicationController> {
  const SmartMatchScreen({super.key});

  static JobPostModel? jobFromArgs(dynamic args) {
    if (args is JobPostModel) return args;
    if (args is Map) {
      final job = args['job'];
      if (job is JobPostModel) return job;
    }
    return null;
  }

  MatchResult _evaluate(JobPostModel? job, dynamic args) {
    if (args is MatchResult) return args;
    NannyModel? nanny;
    if (args is Map && args['nanny'] is NannyModel) {
      nanny = args['nanny'] as NannyModel;
    } else if (Get.isRegistered<NannyProfileController>()) {
      nanny = Get.find<NannyProfileController>().nanny.value;
    }
    return SmartMatch.evaluate(job: job, nanny: nanny);
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final job = jobFromArgs(args);
    final match = _evaluate(job, args);
    final score = match.score;
    final good = score >= 70;
    final color = good ? KafiColors.grnD : const Color(0xFFFF6B6B);

    final liveOut = job?.jobType == JobType.liveOut;
    final reqYears = job?.experienceYears ?? 0;
    final langs = (job?.languagesRequired ?? const <String>[]).join(' + ');
    // Contextual checklist with pass / fail / warn states (mirrors the web .ck rows).
    final checks = <(_CkState, String)>[
      (
        match.language ? _CkState.pass : _CkState.fail,
        match.language
            ? '${langs.isNotEmpty ? langs : 'Languages'} — matches perfectly'
            : '${langs.isNotEmpty ? langs : 'Languages'} required — not all on your profile',
      ),
      (
        match.experience ? _CkState.pass : _CkState.fail,
        match.experience
            ? '${reqYears > 0 ? '$reqYears+ yrs exp' : 'Experience'} — requirement met'
            : 'Needs $reqYears+ years — more than your profile shows',
      ),
      (
        match.role ? _CkState.pass : _CkState.fail,
        '${liveOut ? 'Live-out' : 'Live-in'} availability — ${match.role ? 'matches' : "doesn't match"}',
      ),
      (
        match.visa ? _CkState.pass : _CkState.fail,
        match.visa ? 'Visa status — aligned with the family' : 'Visa requirement — not aligned',
      ),
      (
        match.salary ? _CkState.pass : _CkState.warn,
        match.salary ? 'Salary range — within your expectation' : 'Salary slightly above range — discuss',
      ),
    ];
    final failCount = checks.where((c) => c.$1 != _CkState.pass).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(job),
              const SizedBox(height: 13),
              _scoreBlock(score, good, color, failCount),
              const SizedBox(height: 12),
              _checkList(checks),
              const SizedBox(height: 12),
              _buttons(job, good),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: back + title + job card (.sm-hdr / .sm-job) ────────────────────
  Widget _header(JobPostModel? job) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE0EC), Color(0xFFFFF5F0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: AppNavigation.back,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.arrow_back, size: 14, color: KafiColors.rose),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.smartApplyingTitle.tr,
                        style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w900)),
                    const SizedBox(height: 1),
                    Text(AppStrings.smartApplyingSub.tr,
                        style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          if (job != null) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 9, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${job.jobTitle.isNotEmpty ? job.jobTitle : job.jobType.name} · ${job.city}',
                    style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w800),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${job.experienceYears}+ yrs · ${job.languagesRequired.join(' + ')} · AED ${job.salaryMin}–${job.salaryMax}/mo',
                    style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Score ring + message (.score-wrap) ─────────────────────────────────────
  Widget _scoreBlock(int score, bool good, Color color, int failCount) {
    return Column(
      children: [
        // The numeric match score is intentionally hidden on the nanny side
        // (M8): a job-only score (the nanny can't read the family household)
        // can't equal the family's canonical match, so a divergent number here
        // would mislead. A qualitative icon + the "Great/Low match" label below
        // convey fit without a number.
        SizedBox(
          width: 84,
          height: 84,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(good ? Icons.thumb_up_alt_rounded : Icons.info_outline,
                color: color, size: 34),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          good ? AppStrings.smartGood.tr : AppStrings.smartLow.tr,
          textAlign: TextAlign.center,
          style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          good
              ? AppStrings.smartScoreSubGood.tr
              : AppStrings.smartScoreSubLow.trParams({'count': '$failCount'}),
          textAlign: TextAlign.center,
          style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
        ),
      ],
    );
  }

  // ── Check list (.check-list / .ck) ─────────────────────────────────────────
  Widget _checkList(List<(_CkState, String)> checks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        children: [
          for (final c in checks) ...[
            _checkRow(c.$1, c.$2),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  Widget _checkRow(_CkState state, String label) {
    final (bg, fg, icBg, icon) = switch (state) {
      _CkState.pass => (const Color(0xFFE8F8EE), const Color(0xFF1A6A38), KafiColors.grn, Icons.check),
      _CkState.fail => (const Color(0xFFFFF0F0), const Color(0xFFA02020), const Color(0xFFFF6B6B), Icons.close),
      _CkState.warn => (const Color(0xFFFFF8E8), const Color(0xFF905010), KafiColors.amb, Icons.priority_high),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 15,
            height: 15,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: icBg, shape: BoxShape.circle),
            child: Icon(icon, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: KafiTheme.nunito(10, color: fg, w: FontWeight.w700).copyWith(height: 1.3)),
          ),
        ],
      ),
    );
  }

  // ── Buttons (.sm-btns / .sm-apply-g) ───────────────────────────────────────
  Widget _buttons(JobPostModel? job, bool good) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Obx(() {
        final busy = controller.isLoading.value;
        if (good) {
          return _gradientButton(
            label: AppStrings.smartSendApp.tr,
            icon: Icons.check,
            colors: const [KafiColors.grn, KafiColors.grnD],
            shadow: const Color(0x473DAA65),
            busy: busy,
            onTap: () => _apply(job),
          );
        }
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : Get.back,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: KafiColors.roseL, width: 2),
                  ),
                  child: Text('← ${AppStrings.smartGoBack.tr}',
                      style: KafiTheme.fredoka(11.5, color: KafiColors.roseD, w: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 13,
              child: _gradientButton(
                label: AppStrings.smartApplyAnyway.tr,
                colors: const [KafiColors.rose, KafiColors.roseD],
                shadow: const Color(0x47FF5C8A),
                busy: busy,
                onTap: () => _apply(job),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _gradientButton({
    required String label,
    required List<Color> colors,
    required Color shadow,
    required bool busy,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(11),
          boxShadow: [BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                  ],
                  Text(label, style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Future<void> _apply(JobPostModel? job) async {
    if (job == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.smartJobMissing.tr);
      return;
    }
    // Collect an optional cover message before submitting — it's stored on the
    // application and shown to the family (previously never captured).
    final cover = await Get.bottomSheet<String>(
      const _ApplyCoverSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (cover == null) return; // sheet dismissed → don't apply
    final trimmed = cover.trim();
    final ok = await controller.applyToJob(
      job.id,
      coverMessage: trimmed.isEmpty ? null : trimmed,
    );
    if (ok) _showSuccessDialog();
  }

  // Friendly confirmation popup after the nanny sends an application.
  void _showSuccessDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
                  ),
                  boxShadow: [
                    BoxShadow(color: Color(0x33FF5C8A), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: const Center(child: Text('🎉', style: TextStyle(fontSize: 30))),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.smartAppSent.tr,
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(17, color: KafiColors.td, w: FontWeight.w900)),
              const SizedBox(height: 7),
              Text(AppStrings.smartAppSentSub.tr,
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(11.5, color: KafiColors.tm, w: FontWeight.w600)
                      .copyWith(height: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Get.back(); // close dialog
                    Get.back(); // leave the smart-match screen
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33FF5C8A), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Text(AppStrings.smartAppSentDone.tr,
                          style: KafiTheme.nunito(13, color: Colors.white, w: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

/// Optional cover-message sheet shown when a nanny applies to a job. Returns the
/// entered text via `Get.back(result:)` (empty string = send with no note); a
/// dismiss returns null so the caller skips the application.
class _ApplyCoverSheet extends StatefulWidget {
  const _ApplyCoverSheet();

  @override
  State<_ApplyCoverSheet> createState() => _ApplyCoverSheetState();
}

class _ApplyCoverSheetState extends State<_ApplyCoverSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KafiColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(AppStrings.applyCoverTitle.tr, style: KafiTheme.pacifico(16, color: KafiColors.roseD)),
          const SizedBox(height: 4),
          Text(AppStrings.applyCoverSub.tr, style: KafiTheme.nunito(10.5, color: KafiColors.ts)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            style: KafiTheme.nunito(12, color: KafiColors.td),
            decoration: InputDecoration(
              hintText: AppStrings.applyCoverHint.tr,
              hintStyle: KafiTheme.nunito(11, color: KafiColors.ts),
              filled: true,
              fillColor: const Color(0xFFFDF2F6),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: KafiPrimaryButton(
              label: AppStrings.applyCoverSend.tr,
              onPressed: () => Get.back<String>(result: _ctrl.text),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
