import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';

class BrowseController extends GetxController {
  final IJobService _jobs = Get.find<IJobService>();
  final IUserService _users = Get.find<IUserService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<NannyCardModel> results = <NannyCardModel>[].obs;
  final RxString activeFilter = 'All'.obs;
  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final searchCtrl = TextEditingController();

  /// Cached household context for the canonical match scorer.
  FamilyModel? familyContext;

  /// The family's posted jobs, used to filter Top Matches by a specific job.
  final RxList<JobPostModel> myJobs = <JobPostModel>[].obs;
  final Rxn<JobPostModel> selectedJob = Rxn<JobPostModel>();

  StreamSubscription<List<NannyCardModel>>? _browseSub;
  int _browseEpoch = 0;

  /// The job that Top Matches are currently ranked against (explicit selection
  /// or the family's most recent post).
  JobPostModel? get matchJob => selectedJob.value ?? (myJobs.isNotEmpty ? myJobs.first : null);

  String? get matchJobTitle {
    final j = matchJob;
    if (j == null) return null;
    return j.jobTitle.isNotEmpty
        ? j.jobTitle
        : '${j.jobType == JobType.liveOut ? AppStrings.jobLiveOut.tr : AppStrings.jobLiveIn.tr} · ${j.city}';
  }

  // 'Live-out' replaces the old 'Newborn' pill, which could never match: filters
  // post-match on nationality/jobType/language-tags, and no card carries a
  // "newborn" tag. 'Live-out' matches on the card's jobType.
  static const filters = ['All', 'Live-in', 'Live-out', 'Arabic', 'Filipino', 'Indian'];

  String get familyFirstName =>
      _auth.currentUser.value?.fullName?.split(' ').first ?? AppStrings.roleFallbackFamily.tr;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  @override
  void onClose() {
    _browseSub?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  /// Loads family context once, then watches approved+verified nannies so a
  /// newly approved nanny appears without pull-to-refresh (same pattern as
  /// nanny Jobs ↔ [JobPostController] watchActiveJobs).
  Future<void> refreshList() async {
    final epoch = ++_browseEpoch;
    await _browseSub?.cancel();
    _browseSub = null;

    isLoading.value = true;
    loadError.value = null;
    try {
      final currentUser = _auth.currentUser.value;
      if (currentUser == null || currentUser.isNanny) {
        myJobs.clear();
        results.clear();
        familyContext = null;
        isLoading.value = false;
        return;
      }
      final fid = currentUser.id;
      myJobs.value = await _jobs.getJobsByFamily(fid);
      familyContext = await _users.getFamily(fid);
      if (epoch != _browseEpoch) return;

      final job = selectedJob.value ?? (myJobs.isNotEmpty ? myJobs.first : null);
      final engaged = await _engagedNannyIds();
      if (epoch != _browseEpoch) return;

      _browseSub = _jobs
          .watchBrowseNannies(
            filter: activeFilter.value,
            matchJob: job,
            family: familyContext,
          )
          .listen(
        (ranked) {
          if (epoch != _browseEpoch) return;
          results.value = engaged.isEmpty
              ? ranked
              : ranked.where((c) => !engaged.contains(c.id)).toList();
          loadError.value = null;
          isLoading.value = false;
        },
        onError: (Object e) {
          if (epoch != _browseEpoch) return;
          Get.log('browse watch failed: $e', isError: true);
          results.clear();
          loadError.value = e.toString();
          isLoading.value = false;
        },
      );
    } catch (e) {
      if (epoch != _browseEpoch) return;
      Get.log('browse load failed: $e', isError: true);
      results.clear();
      loadError.value = e.toString();
      isLoading.value = false;
    }
  }

  /// Re-fetch only the family's jobs (used when opening Filter-by-job / Post CTA).
  /// BrowseController is permanent and may still hold an empty [myJobs] from when
  /// it was first created on the job form — before the first post landed.
  Future<void> refreshMyJobs() async {
    final currentUser = _auth.currentUser.value;
    if (currentUser == null || !currentUser.isFamily) {
      myJobs.clear();
      return;
    }
    try {
      myJobs.value = await _jobs.getJobsByFamily(currentUser.id);
    } catch (e) {
      Get.log('refreshMyJobs failed: $e', isError: true);
    }
  }

  List<JobPostModel> get activeJobs =>
      myJobs.where((j) => j.status == JobPostStatus.active).toList();

  bool get hasActiveFullTime =>
      activeJobs.any((j) => j.employmentType == JobEmploymentType.fullTime);

  bool get hasActivePartTime =>
      activeJobs.any((j) => j.employmentType == JobEmploymentType.partTime);

  /// Null when both FT and PT slots are filled; otherwise the free employment type.
  JobEmploymentType? get freeEmploymentSlot {
    if (hasActiveFullTime && hasActivePartTime) return null;
    if (hasActiveFullTime) return JobEmploymentType.partTime;
    if (hasActivePartTime) return JobEmploymentType.fullTime;
    return JobEmploymentType.fullTime;
  }

  /// Opens Screen 13 for the free FT/PT slot, or My Jobs when both are filled.
  Future<void> openPostNewJob() async {
    await refreshMyJobs();
    final slot = freeEmploymentSlot;
    if (slot == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.familyBothJobSlotsFilled.tr);
      Get.toNamed(Routes.familyMyJobs);
      return;
    }
    Get.toNamed(Routes.familyForm, arguments: {
      'employmentType': slot.name,
      'lockEmployment': hasActiveFullTime || hasActivePartTime,
      'isNewPost': true,
    });
  }

  void onFilterTap(String f) {
    activeFilter.value = f;
    refreshList();
  }

  /// User ids of nannies to hide from browse because they are currently hired
  /// or on an accepted/active trial (M5). Two bounded queries fetched in
  /// parallel; any failure degrades to hiding nobody so browse still loads.
  Future<Set<String>> _engagedNannyIds() async {
    try {
      final sets = await Future.wait([
        Get.find<IHireService>().activeHiredNannyIds(),
        Get.find<ITrialService>().activeTrialNannyIds(),
      ]);
      return sets.expand((s) => s).toSet();
    } catch (e) {
      Get.log('engaged-nanny browse filter failed: $e', isError: true);
      return const <String>{};
    }
  }

  /// Re-rank Top Matches against [job] (null = back to the default job).
  void selectJob(JobPostModel? job) {
    selectedJob.value = job;
    refreshList();
  }

  Future<bool> recordView(String nannyId) =>
      Get.find<SubscriptionController>().recordViewIfAllowed(nannyId);

  List<NannyCardModel> get filteredResults {
    // Results are already ranked by job match in the service; apply text search.
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return results;
    return results
        .where(
          (n) =>
              n.name.toLowerCase().contains(q) ||
              n.nationality.toLowerCase().contains(q) ||
              n.city.toLowerCase().contains(q) ||
              n.jobType.toLowerCase().contains(q) ||
              n.tags.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }
}
