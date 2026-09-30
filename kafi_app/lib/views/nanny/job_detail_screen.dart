import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/report_user_sheet.dart';
import 'package:kafi_app/views/widgets/kafi_avatar.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late final JobPostModel job;
  FamilyModel? _family;
  bool _loadingFamily = true;

  @override
  void initState() {
    super.initState();
    job = Get.arguments as JobPostModel;
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    if (job.familyId.isEmpty) {
      setState(() => _loadingFamily = false);
      return;
    }
    try {
      final fam = await Get.find<IUserService>().getFamily(job.familyId);
      if (mounted) {
        setState(() {
          _family = fam;
          _loadingFamily = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFamily = false);
    }
  }

  bool get _alreadyApplied =>
      Get.isRegistered<ApplicationController>() &&
      Get.find<ApplicationController>().myApplications.any((a) =>
          a.jobPostId == job.id && a.status != ApplicationStatus.withdrawn);

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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingFamily)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: CircularProgressIndicator(color: KafiColors.roseD)),
                      )
                    else ...[
                      _familyHeader(),
                      if ((_family?.aboutFamily ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _aboutSection(),
                      ],
                      if (job.trialDurationDays > 0) ...[
                        const SizedBox(height: 12),
                        _trialCallout(),
                      ],
                      const SizedBox(height: 12),
                      _midActions(),
                      const SizedBox(height: 16),
                      _familyDetailsSection(),
                      const SizedBox(height: 16),
                    ],
                    _jobDetailsSection(),
                    const SizedBox(height: 16),
                    _requirementsSection(),
                    const SizedBox(height: 16),
                    _benefitsSection(),
                    const SizedBox(height: 16),
                    _visaSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _applyButton(),
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
          Expanded(child: Text(AppStrings.jobDetailsTitle.tr, style: KafiTheme.pacifico(17))),
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

  String get _familyDisplayName {
    final raw = (_family?.fullName.isNotEmpty ?? false) ? _family!.fullName : job.familyName;
    if (raw.isEmpty) return AppStrings.jobDetailFamilySuffix.tr;
    if (raw.toLowerCase().endsWith('family')) return raw;
    return '$raw ${AppStrings.jobDetailFamilySuffix.tr}';
  }

  String get _childrenLine {
    final count = _family?.childrenCount ?? 0;
    final ages = _family?.childrenAges ?? const <String>[];
    if (count <= 0 && ages.isEmpty) return AppStrings.jobDetailNotSpecified.tr;
    final agesStr = ages.isNotEmpty ? ages.join(', ') : '';
    if (agesStr.isEmpty) return '$count';
    return AppStrings.jobDetailChildAges.trParams({'count': '$count', 'ages': agesStr});
  }

  String? get _membersLine {
    final count = _family?.childrenCount ?? 0;
    if (count <= 0) return null;
    return AppStrings.jobDetailMembersCount.trParams({'n': '${count + 2}'});
  }

  Widget _familyHeader() {
    final city = (_family?.city.isNotEmpty ?? false) ? _family!.city : job.city;
    final langs = _family?.languagesAtHome ?? const <String>[];
    final religion = _family?.religion ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KafiAvatar(
            photoUrl: FamilyConstants.resolvedPhotoUrl(
              _family?.profilePhoto ?? job.familyPhotoUrl,
              job.familyId.isNotEmpty ? job.familyId : job.familyName,
            ),
            fallbackText: _familyDisplayName,
            size: 80,
            gradient: const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
            fontSize: 28,
            radius: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_familyDisplayName,
                    style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w900)),
                if (city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: KafiColors.roseD),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(city,
                            style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                if (_membersLine != null)
                  _quickFact(Icons.groups_outlined, _membersLine!),
                _quickFact(Icons.child_care_outlined, _childrenLine),
                if (langs.isNotEmpty)
                  _quickFact(Icons.chat_bubble_outline, langs.join(' & ')),
                if (religion.isNotEmpty)
                  _quickFact(Icons.nightlight_round, religion),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickFact(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: KafiColors.ts),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: KafiTheme.nunito(10, color: KafiColors.tm, w: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.jobDetailAboutFamily.tr,
              style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_family!.aboutFamily!.trim(),
              style: KafiTheme.nunito(11, color: KafiColors.tm, w: FontWeight.w600)
                  .copyWith(height: 1.45)),
        ],
      ),
    );
  }

  Widget _trialCallout() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KafiColors.roseP,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.roseL, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 18, color: KafiColors.roseD),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.jobDetailTrialPeriod.tr,
                  style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
              Text(
                  AppStrings.jobDetailTrialDays.trParams({'n': '${job.trialDurationDays}'}),
                  style: KafiTheme.nunito(12, color: KafiColors.roseD, w: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _midActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: KafiPrimaryButton(
            label: AppStrings.jobDetailChatWithFamily.tr,
            onPressed: () => AppNavigation.openChatWithFamily(
              familyId: job.familyId,
              familyName: job.familyName,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final applied = _alreadyApplied;
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: applied
                  ? null
                  : () => Get.toNamed(Routes.smartMatch, arguments: job),
              icon: Icon(Icons.assignment_outlined,
                  size: 18, color: applied ? KafiColors.ts : KafiColors.roseD),
              label: Text(
                applied ? AppStrings.nannyJobAlreadyApplied.tr : AppStrings.nannyJobApply.tr,
                style: KafiTheme.nunito(13,
                    color: applied ? KafiColors.ts : KafiColors.roseD, w: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: applied ? KafiColors.ts.withValues(alpha: 0.3) : KafiColors.roseD,
                    width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _familyDetailsSection() {
    final langs = _family?.languagesAtHome ?? const <String>[];
    final pets = _family?.hasPets == true
        ? ((_family!.petTypes.isNotEmpty)
            ? '${AppStrings.yesShort.tr} (${_family!.petTypes.join(', ')})'
            : AppStrings.yesShort.tr)
        : AppStrings.noShort.tr;
    final cameras =
        _family?.hasCameras == true ? AppStrings.yesShort.tr : AppStrings.noShort.tr;
    final visa = job.visaSponsorship == VisaSponsorship.full
        ? AppStrings.jobDetailVisaProvided.tr
        : AppStrings.noShort.tr;
    final rows = <Widget>[
      if (_membersLine != null)
        _iconRow(Icons.groups_outlined, AppStrings.jobDetailFamilyMembers.tr, _membersLine!),
      _iconRow(Icons.child_care_outlined, AppStrings.jobDetailChildren.tr, _childrenLine),
      _iconRow(Icons.chat_bubble_outline, AppStrings.jobDetailLanguageAtHome.tr,
          langs.isNotEmpty ? langs.join(' & ') : AppStrings.jobDetailNotSpecified.tr),
      _iconRow(Icons.nightlight_round, AppStrings.jobDetailFamilyReligion.tr,
          (_family?.religion.isNotEmpty ?? false)
              ? _family!.religion
              : AppStrings.jobDetailNotSpecified.tr),
      _iconRow(Icons.pets_outlined, AppStrings.jobDetailPetsAtHome.tr, pets),
      _iconRow(Icons.videocam_outlined, AppStrings.jobDetailCamerasAtHome.tr, cameras),
      _iconRow(Icons.badge_outlined, AppStrings.jobDetailVisaSponsorship.tr, visa),
    ];
    return _sectionCard(AppStrings.jobDetailFamilyDetails.tr, rows);
  }

  Widget _jobDetailsSection() {
    return _sectionCard(
      AppStrings.jobDetailSectionTitle.tr,
      [
        _iconRow(
            Icons.work_outline,
            AppStrings.jobDetailFieldJobType.tr,
            job.jobType == JobType.liveOut
                ? AppStrings.jobLiveOut.tr
                : AppStrings.jobLiveIn.tr),
        _iconRow(
            Icons.event_outlined,
            AppStrings.jobDetailFieldStartDate.tr,
            job.startImmediate
                ? AppStrings.jobDetailImmediate.tr
                : (job.startDate != null
                    ? '${job.startDate!.day}/${job.startDate!.month}/${job.startDate!.year}'
                    : AppStrings.jobDetailFlexible.tr)),
        if (job.daysOff.isNotEmpty)
          _iconRow(Icons.schedule_outlined, AppStrings.jobDetailWorkingDays.tr,
              AppStrings.jobDetailWorkingDaysValue.tr),
        _iconRow(Icons.calendar_today_outlined, AppStrings.jobDetailDayOff.tr,
            job.daysOff.isNotEmpty ? job.daysOff : AppStrings.jobDetailNotSpecified.tr),
        _iconRow(
            Icons.payments_outlined,
            AppStrings.jobDetailFieldSalary.tr,
            AppStrings.jobDetailSalaryRange.trParams({
              'min': '${job.salaryMin}',
              'max': '${job.salaryMax}',
            })),
      ],
    );
  }

  Widget _requirementsSection() {
    return _sectionCard(
      AppStrings.jobDetailRequirementsTitle.tr,
      [
        ...job.duties.map((d) => _detailRow('', d, icon: Icons.check)),
        if (job.languagesRequired.isNotEmpty)
          _detailRow(AppStrings.jobDetailFieldLanguages.tr, job.languagesRequired.join(', ')),
      ],
    );
  }

  Widget _benefitsSection() {
    if (job.benefits.isEmpty) {
      return _sectionCard(AppStrings.jobDetailBenefitsTitle.tr, [
        Text(AppStrings.jobDetailNotSpecified.tr,
            style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
      ]);
    }
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.jobDetailBenefitsTitle.tr,
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: job.benefits.map(_benefitChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _benefitChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: KafiColors.roseP,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 14, color: KafiColors.roseD),
          const SizedBox(width: 5),
          Text(label,
              style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _visaSection() {
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

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
      );

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: KafiColors.ts),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w800)),
          ),
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

  Widget _applyButton() {
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
            final applied = _alreadyApplied;
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
