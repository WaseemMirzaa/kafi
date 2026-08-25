import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/report_user_sheet.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final JobPostModel job = Get.arguments as JobPostModel;

    return Scaffold(
      backgroundColor: KafiColors.nannyBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(job),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _familyCard(job),
                    const SizedBox(height: 16),
                    // The nanny-side "% match" is intentionally not shown: the
                    // canonical match is scored from the family's household +
                    // job, which the nanny can't compute (M8).
                    _jobDetailsSection(job),
                    const SizedBox(height: 16),
                    _requirementsSection(job),
                    const SizedBox(height: 16),
                    _benefitsSection(job),
                    const SizedBox(height: 16),
                    _visaSection(job),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _applyButton(job),
    );
  }

  Widget _hero(JobPostModel job) {
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
          Expanded(child: Text(AppStrings.jobDetailsTitle.tr, style: KafiTheme.pacifico(17))),
          // Report this family — files a report under Settings → My reports.
          GestureDetector(
            onTap: () => showReportUserSheet(
                reportedUserId: job.familyId, reportedUserName: job.familyName),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.flag_outlined, color: KafiColors.roseD, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _familyCard(JobPostModel job) {
    final initial = job.familyName.isNotEmpty ? job.familyName[0].toUpperCase() : 'F';
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
              ),
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
                Text('${job.familyName} ${AppStrings.jobDetailFamilySuffix.tr}',
                    style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w900)),
                if (job.city.isNotEmpty)
                  Text(job.city,
                      style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _jobDetailsSection(JobPostModel job) {
    return _sectionCard(
      AppStrings.jobDetailSectionTitle.tr,
      [
        _detailRow(
            AppStrings.jobDetailFieldJobType.tr,
            job.jobType == JobType.liveOut
                ? AppStrings.jobLiveOut.tr
                : AppStrings.jobLiveIn.tr),
        _detailRow(AppStrings.fldDaysOff.tr,
            job.daysOff.isNotEmpty ? job.daysOff : AppStrings.jobDetailNotSpecified.tr),
        _detailRow(
            AppStrings.jobDetailFieldStartDate.tr,
            job.startImmediate
                ? AppStrings.jobDetailImmediate.tr
                : (job.startDate != null
                    ? '${job.startDate!.day}/${job.startDate!.month}/${job.startDate!.year}'
                    : AppStrings.jobDetailFlexible.tr)),
        _detailRow(
            AppStrings.jobDetailFieldDuration.tr,
            job.duration == JobDuration.permanent
                ? AppStrings.jobDetailPermanent.tr
                : (job.contractMonths != null
                    ? AppStrings.jobDetailContractMonths
                        .trParams({'months': '${job.contractMonths}'})
                    : AppStrings.jobDetailContract.tr)),
        _detailRow(
            AppStrings.jobDetailFieldSalary.tr,
            AppStrings.jobDetailSalaryRange.trParams({
              'min': '${job.salaryMin}',
              'max': '${job.salaryMax}',
            })),
      ],
    );
  }

  Widget _requirementsSection(JobPostModel job) {
    return _sectionCard(
      AppStrings.jobDetailRequirementsTitle.tr,
      [
        ...job.duties.map((d) => _detailRow('', d, icon: Icons.check)),
        if (job.languagesRequired.isNotEmpty)
          _detailRow(AppStrings.jobDetailFieldLanguages.tr, job.languagesRequired.join(', ')),
      ],
    );
  }

  Widget _benefitsSection(JobPostModel job) {
    return _sectionCard(
      AppStrings.jobDetailBenefitsTitle.tr,
      job.benefits.map((b) => _detailRow('', b, icon: Icons.card_giftcard)).toList(),
    );
  }

  Widget _visaSection(JobPostModel job) {
    final isSponsored = job.visaSponsorship == VisaSponsorship.full;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isSponsored ? KafiColors.grnL : KafiColors.ambL,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          
            color: isSponsored
                ? KafiColors.grnD.withValues(alpha: 0.3)
                : KafiColors.ambD.withValues(alpha: 0.3),
            width: 1.5),
      ),
      child: Row(
        children: [
          Icon(isSponsored ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isSponsored ? KafiColors.grnD : KafiColors.ambD, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isSponsored
                        ? AppStrings.jobDetailVisaSponsoredTitle.tr
                        : AppStrings.jobDetailVisaOwnTitle.tr,
                    style: KafiTheme.nunito(11,
                        color: isSponsored ? KafiColors.grnD : KafiColors.ambD,
                        w: FontWeight.w800)),
                Text(
                    isSponsored
                        ? AppStrings.jobDetailVisaSponsoredSub.tr
                        : AppStrings.jobDetailVisaOwnSub.tr,
                    style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: KafiColors.grnD),
            const SizedBox(width: 7),
          ],
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 90,
              child: Text(label,
                  style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w700)),
            ),
          ],
          Expanded(
              child: Text(value,
                  style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _applyButton(JobPostModel job) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x18FF5F96), blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Obx(() {
            // Reflect the already-applied state up front instead of letting the
            // nanny run the whole smart-match + cover flow only to be blocked by
            // the duplicate guard at the end.
            final applied = Get.isRegistered<ApplicationController>() &&
                Get.find<ApplicationController>().myApplications.any((a) =>
                    a.jobPostId == job.id &&
                    a.status != ApplicationStatus.withdrawn);
            return KafiPrimaryButton(
              label: applied
                  ? AppStrings.nannyJobAlreadyApplied.tr
                  : AppStrings.nannyJobApply.tr,
              onPressed: applied
                  ? null
                  : () => Get.toNamed(Routes.smartMatch, arguments: job),
            );
          }),
        ),
      ),
    );
  }
}
