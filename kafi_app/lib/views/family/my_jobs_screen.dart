import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/family_jobs_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/validators.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

/// Family "My Jobs" — the family's posted jobs with hiring status and
/// per-job management (edit / pause / reopen / delete).
class MyJobsScreen extends GetView<FamilyJobsController> {
  const MyJobsScreen({super.key});

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
                if (controller.isLoading.value && controller.jobs.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: KafiColors.pur));
                }
                if (controller.error.value != null && controller.jobs.isEmpty) {
                  return _errorState();
                }
                if (controller.jobs.isEmpty) return _emptyState();
                return RefreshIndicator(
                  color: KafiColors.pur,
                  onRefresh: controller.load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                    itemCount: controller.jobs.length,
                    itemBuilder: (_, i) => _jobCard(controller.jobs[i]),
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
                Text(AppStrings.myJobsTitle.tr,
                    style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090))),
                Text(AppStrings.myJobsSubtitle.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.familyForm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: KafiColors.pur,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 15),
                  const SizedBox(width: 4),
                  Text(AppStrings.myJobsPostNew.tr,
                      style: KafiTheme.fredoka(10, color: Colors.white, w: FontWeight.w700)),
                ],
              ),
            ),
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
          Icon(Icons.work_outline, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.myJobsEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(AppStrings.myJobsEmptySub.tr,
              textAlign: TextAlign.center,
              style: KafiTheme.nunito(10, color: KafiColors.ts)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.familyForm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: KafiColors.pur,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(AppStrings.myJobsPostNew.tr,
                  style: KafiTheme.nunito(12, color: Colors.white, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the jobs read fails and the list is empty, so a live-read
  /// failure surfaces with a retry instead of the "no jobs posted" empty state.
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
            onPressed: controller.load,
            child: Text(AppStrings.retry.tr,
                style: KafiTheme.fredoka(12, color: KafiColors.pur, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _jobCard(JobPostModel job) {
    final hire = controller.hireForJob(job.id);
    final typeLine = [
      job.jobType == JobType.liveOut ? 'Live-out' : 'Live-in',
      job.employmentType == JobEmploymentType.partTime ? 'Part-time' : 'Full-time',
      if (job.city.isNotEmpty) job.city,
    ].join(' · ');

    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.localizedJobTitle().isNotEmpty ? job.localizedJobTitle() : typeLine,
                      style: KafiTheme.nunito(12.5, color: KafiColors.td, w: FontWeight.w800),
                    ),
                    const SizedBox(height: 1),
                    Text(typeLine,
                        style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
                  ],
                ),
              ),
              _statusChip(job.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _pill('⭐ ${AppStrings.jobApplicantsN.trParams({'n': '${job.applicationsCount}'})}',
                  const Color(0xFFEDE4FF), const Color(0xFF6D3BC7)),
              if (hire != null) ...[
                const SizedBox(width: 6),
                _pill(
                  AppStrings.jobHiredWith.trParams({'name': hire.nannyName ?? ''}).trim(),
                  KafiColors.grnL,
                  KafiColors.grnD,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 12),
          Row(
            children: [
              _action(Icons.edit_outlined, AppStrings.jobActionEdit.tr, KafiColors.pur,
                  () => _openEdit(job)),
              const SizedBox(width: 4),
              if (job.status == JobPostStatus.active)
                _action(Icons.pause_circle_outline, AppStrings.jobActionPause.tr, KafiColors.ambD,
                    () => controller.setStatus(job.id, JobPostStatus.paused))
              else
                _action(Icons.play_circle_outline, AppStrings.jobActionReopen.tr, KafiColors.grnD,
                    () => controller.setStatus(job.id, JobPostStatus.active)),
              const Spacer(),
              _action(Icons.delete_outline, AppStrings.jobActionDelete.tr, KafiColors.redD,
                  () => _confirmDelete(job)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: KafiTheme.fredoka(9, color: fg, w: FontWeight.w700)),
    );
  }

  Widget _statusChip(JobPostStatus status) {
    final (label, bg, fg) = switch (status) {
      JobPostStatus.active => (AppStrings.jobStatusActiveLabel.tr, KafiColors.grnL, KafiColors.grnD),
      JobPostStatus.paused => (AppStrings.jobStatusPausedLabel.tr, KafiColors.ambL, KafiColors.ambD),
      JobPostStatus.closed => (AppStrings.jobStatusClosedLabel.tr, KafiColors.redL, KafiColors.redD),
      JobPostStatus.expired =>
        (AppStrings.jobStatusExpiredLabel.tr, KafiColors.grey.withValues(alpha: 0.2), KafiColors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: KafiTheme.fredoka(9, w: FontWeight.w700, color: fg)),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 3),
            Text(label, style: KafiTheme.nunito(10, color: color, w: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(JobPostModel job) {
    Get.dialog(AlertDialog(
      title: Text(AppStrings.jobDeleteTitle.tr),
      content: Text(AppStrings.jobDeleteBody.tr),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel.tr)),
        TextButton(
          onPressed: () {
            Get.back();
            controller.deleteJob(job.id);
          },
          child: Text(AppStrings.jobActionDelete.tr, style: const TextStyle(color: KafiColors.redD)),
        ),
      ],
    ));
  }

  void _openEdit(JobPostModel job) {
    Get.bottomSheet(
      _JobEditSheet(job: job, onSave: controller.saveEdited),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// Bottom-sheet form to edit a job's headline fields (title, schedule, salary
/// range). A stateful widget so its text controllers are disposed cleanly.
class _JobEditSheet extends StatefulWidget {
  const _JobEditSheet({required this.job, required this.onSave});

  final JobPostModel job;
  final Future<void> Function(JobPostModel) onSave;

  @override
  State<_JobEditSheet> createState() => _JobEditSheetState();
}

class _JobEditSheetState extends State<_JobEditSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.job.jobTitle);
  late final TextEditingController _schedule =
      TextEditingController(text: widget.job.schedule);
  late final TextEditingController _salaryMin =
      TextEditingController(text: widget.job.salaryMin > 0 ? '${widget.job.salaryMin}' : '');
  late final TextEditingController _salaryMax =
      TextEditingController(text: widget.job.salaryMax > 0 ? '${widget.job.salaryMax}' : '');

  @override
  void dispose() {
    _title.dispose();
    _schedule.dispose();
    _salaryMin.dispose();
    _salaryMax.dispose();
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
          Text(AppStrings.jobEditTitle.tr, style: KafiTheme.pacifico(16, color: KafiColors.pur)),
          const SizedBox(height: 14),
          KafiTextField(label: AppStrings.jobFieldTitle.tr, controller: _title, purple: true),
          const SizedBox(height: 10),
          KafiTextField(label: AppStrings.jobFieldSchedule.tr, controller: _schedule, purple: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: KafiTextField(
                  label: AppStrings.jobFieldSalaryMin.tr,
                  controller: _salaryMin,
                  purple: true,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KafiTextField(
                  label: AppStrings.jobFieldSalaryMax.tr,
                  controller: _salaryMax,
                  purple: true,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KafiColors.pur,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: Text(AppStrings.save.tr,
                  style: KafiTheme.fredoka(13, color: Colors.white, w: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _save() {
    final min = int.tryParse(_salaryMin.text.trim()) ?? widget.job.salaryMin;
    final max = int.tryParse(_salaryMax.text.trim()) ?? widget.job.salaryMax;
    // Guard the quick-edit the same way the full job form does — otherwise an
    // inverted range (min 5000 / max 1000) saves and renders oddly to nannies.
    final salaryError = Validators.salaryRange(min, max);
    if (salaryError != null) {
      Get.snackbar(AppStrings.errorTitle.tr, salaryError.tr);
      return;
    }
    final updated = widget.job.copyWith(
      jobTitle: _title.text.trim(),
      schedule: _schedule.text.trim(),
      salaryMin: min,
      salaryMax: max,
    );
    Get.back();
    widget.onSave(updated);
  }
}
