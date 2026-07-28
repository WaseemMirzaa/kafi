import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/string_format.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/report_user_sheet.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final JobPostModel job = Get.arguments as JobPostModel;
    final nanny = Get.isRegistered<NannyProfileController>()
        ? Get.find<NannyProfileController>().nanny.value
        : null;
    final matchService = MatchService();
    final matchScore =
        nanny == null ? 0 : matchService.calculateJobMatch(nanny, job);
    final factors = nanny == null
        ? const <MatchFactor>[]
        : matchService.getMatchFactors(nanny, job);

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
                    _matchScoreSection(matchScore, factors),
                    const SizedBox(height: 16),
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
          // Report this family — files a support ticket to the admin team.
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
                Text('${job.familyName} Family',
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

  Widget _matchScoreSection(int score, List<MatchFactor> factors) {
    final isGood = score >= 80;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isGood ? KafiColors.grnL : KafiColors.ambL,
              border: Border.all(
                  color: isGood ? KafiColors.grnD : KafiColors.ambD, width: 2),
            ),
            child: Center(
              child: Text('$score%',
                  style: KafiTheme.nunito(15,
                      color: isGood ? KafiColors.grnD : KafiColors.ambD,
                      w: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 7),
          Text(isGood ? AppStrings.matchGreat.tr : AppStrings.matchLow.tr,
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
          const SizedBox(height: 10),
          ...factors.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(f.isStrong ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 14,
                        color: f.isStrong ? KafiColors.grnD : KafiColors.ambD),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(f.name,
                          style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w700)),
                    ),
                    Text('${f.score}%',
                        style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _jobDetailsSection(JobPostModel job) {
    return _sectionCard(
      'Job Details',
      [
        _detailRow('Job Type', job.jobType.name.titleCase),
        _detailRow('Schedule',
            job.schedule.isNotEmpty ? job.schedule : 'Not specified'),
        _detailRow(
            'Start Date',
            job.startImmediate
                ? 'Immediate'
                : (job.startDate != null
                    ? '${job.startDate!.day}/${job.startDate!.month}/${job.startDate!.year}'
                    : 'Flexible')),
        _detailRow(
            'Duration',
            job.duration == JobDuration.permanent
                ? 'Permanent'
                : (job.contractMonths != null
                    ? 'Contract · ${job.contractMonths} months'
                    : 'Contract')),
        _detailRow('Salary', 'AED ${job.salaryMin} - ${job.salaryMax}/month'),
      ],
    );
  }

  Widget _requirementsSection(JobPostModel job) {
    return _sectionCard(
      'Duties & Requirements',
      [
        ...job.duties.map((d) => _detailRow('', d, icon: Icons.check)),
        if (job.languagesRequired.isNotEmpty) _detailRow('Languages', job.languagesRequired.join(', ')),
      ],
    );
  }

  Widget _benefitsSection(JobPostModel job) {
    return _sectionCard(
      'Benefits Offered',
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
                Text(isSponsored ? 'Visa Sponsorship Available' : 'Own Visa Required',
                    style: KafiTheme.nunito(11,
                        color: isSponsored ? KafiColors.grnD : KafiColors.ambD,
                        w: FontWeight.w800)),
                Text(
                    isSponsored
                        ? 'Family will sponsor your visa'
                        : 'You must have your own residence visa',
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
