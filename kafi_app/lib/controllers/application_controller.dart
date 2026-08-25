import 'dart:async';

import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class ApplicationController extends GetxController {
  final IApplicationService _appService = Get.find<IApplicationService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<ApplicationModel> myApplications = <ApplicationModel>[].obs;
  final RxList<ApplicationModel> receivedApplications = <ApplicationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();

  // Search queries for the applicants (family) and my-applications (nanny) lists.
  final RxString receivedQuery = ''.obs;
  final RxString sentQuery = ''.obs;

  /// Optional job filter on the family Applicants screen (`''` = all jobs).
  final RxString receivedJobFilter = ''.obs;

  StreamSubscription<List<ApplicationModel>>? _appsSub;
  Worker? _authWorker;
  int _watchEpoch = 0;
  String? _watchingUid;
  bool? _watchingAsNanny;

  /// Family "Applicants" filtered by search + optional job chip.
  /// Includes applications for every job the family has posted.
  List<ApplicationModel> get filteredReceived {
    final q = receivedQuery.value.trim().toLowerCase();
    final jobId = receivedJobFilter.value;
    return receivedApplications.where((a) {
      if (jobId.isNotEmpty && a.jobPostId != jobId) return false;
      if (q.isEmpty) return true;
      return (a.nannyName ?? '').toLowerCase().contains(q) ||
          (a.jobTitle ?? '').toLowerCase().contains(q);
    }).toList();
  }

  /// Distinct jobs represented in the received inbox (for filter chips).
  /// Labels prefer the family's job post title / roles — never raw job ids.
  List<({String jobPostId, String label})> get receivedJobFilters {
    final jobNames = <String, String>{};
    if (Get.isRegistered<JobPostController>()) {
      for (final j in Get.find<JobPostController>().myJobs) {
        final name = displayJobName(j);
        if (name.isNotEmpty) jobNames[j.id] = name;
      }
    }
    final seen = <String, String>{};
    for (final a in receivedApplications) {
      if (a.jobPostId.isEmpty || seen.containsKey(a.jobPostId)) continue;
      seen[a.jobPostId] = jobLabelForApplication(a, jobNames: jobNames);
    }
    final entries = seen.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return [
      for (final e in entries) (jobPostId: e.key, label: e.value),
    ];
  }

  /// Human-readable job name for Applicants chips / cards (never a Firestore id).
  static String displayJobName(JobPostModel j) {
    final title = j.jobTitle.trim();
    if (title.isNotEmpty) return title;
    if (j.rolesNeeded.isNotEmpty) return j.rolesNeeded.join(' · ');
    final type = j.jobType == JobType.liveOut
        ? AppStrings.jobLiveOut.tr
        : AppStrings.jobLiveIn.tr;
    if (j.city.trim().isNotEmpty) return '$type · ${j.city.trim()}';
    return type;
  }

  /// Resolve a label for an application row / filter chip.
  String jobLabelForApplication(
    ApplicationModel a, {
    Map<String, String>? jobNames,
  }) {
    final fromJob = jobNames?[a.jobPostId];
    if (fromJob != null && fromJob.isNotEmpty) return fromJob;
    if (Get.isRegistered<JobPostController>()) {
      final j = Get.find<JobPostController>()
          .myJobs
          .firstWhereOrNull((x) => x.id == a.jobPostId);
      if (j != null) {
        final name = displayJobName(j);
        if (name.isNotEmpty) return name;
      }
    }
    final fromApp = (a.jobTitle ?? '').trim();
    if (fromApp.isNotEmpty && !_looksLikeId(fromApp)) return fromApp;
    return AppStrings.applicantsUntitledJob.tr;
  }

  static bool _looksLikeId(String s) {
    // Firestore auto-ids / job_* tokens — never show these as chip labels.
    if (s.startsWith('job_')) return true;
    if (s.length >= 18 && !s.contains(' ') && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(s)) {
      return true;
    }
    return false;
  }

  /// Nanny "My Applications" filtered by the search box (family name / job title).
  List<ApplicationModel> get filteredSent {
    final q = sentQuery.value.trim().toLowerCase();
    if (q.isEmpty) return myApplications;
    return myApplications
        .where((a) =>
            (a.familyName ?? '').toLowerCase().contains(q) ||
            (a.jobTitle ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadApplications();
    _authWorker = ever<dynamic>(_auth.currentUser, (_) {
      final uid = currentUserId(_auth);
      final asNanny = _auth.currentUser.value?.isNanny ?? false;
      // Only restart the watch when the signed-in identity/role actually changes
      // — avoid clearing a populated Applicants list on unrelated user refreshes.
      if (uid == _watchingUid && asNanny == _watchingAsNanny) return;
      loadApplications();
    });
  }

  @override
  void onClose() {
    _appsSub?.cancel();
    _authWorker?.dispose();
    super.onClose();
  }

  /// Role-aware entry used by bindings / pull-to-refresh.
  Future<void> loadApplications() async {
    final asNanny = _auth.currentUser.value?.isNanny ?? false;
    if (asNanny) {
      await subscribeNannyOutbox();
    } else {
      await subscribeFamilyInbox();
    }
  }

  /// Family Applicants screen — always the family inbox (never the nanny path),
  /// so a permanent controller that previously served a nanny session can't
  /// leave this screen stuck on an empty `receivedApplications` list.
  Future<void> subscribeFamilyInbox() async {
    final userId = currentUserId(_auth);
    await _startWatch(
      userId: userId,
      asNanny: false,
      onData: (apps) async {
        if (userId == null) {
          receivedApplications.clear();
          return;
        }
        try {
          receivedApplications.assignAll(
            await _withCanonicalMatch(apps, userId),
          );
        } catch (e) {
          receivedApplications.assignAll(apps);
          Get.log('applicant match recompute failed: $e', isError: true);
        }
      },
    );
  }

  /// Nanny My Applications — always the sent-applications watch.
  Future<void> subscribeNannyOutbox() async {
    final userId = currentUserId(_auth);
    await _startWatch(
      userId: userId,
      asNanny: true,
      onData: (apps) {
        myApplications.assignAll(apps);
      },
    );
  }

  Future<void> _startWatch({
    required String? userId,
    required bool asNanny,
    required FutureOr<void> Function(List<ApplicationModel> apps) onData,
  }) async {
    final epoch = ++_watchEpoch;
    await _appsSub?.cancel();
    _appsSub = null;
    _watchingUid = userId;
    _watchingAsNanny = asNanny;

    isLoading.value = true;
    loadError.value = null;

    if (userId == null || userId.isEmpty) {
      myApplications.clear();
      receivedApplications.clear();
      isLoading.value = false;
      return;
    }

    if (asNanny) {
      receivedApplications.clear();
      receivedJobFilter.value = '';
    } else {
      myApplications.clear();
    }

    final stream = asNanny
        ? _appService.watchApplicationsForNanny(userId)
        : _appService.watchApplicationsForFamily(userId);

    _appsSub = stream.listen(
      (apps) async {
        if (epoch != _watchEpoch) return;
        try {
          await onData(apps);
          loadError.value = null;
        } catch (e) {
          loadError.value = e.toString();
        } finally {
          if (epoch == _watchEpoch) isLoading.value = false;
        }
      },
      onError: (Object e) {
        if (epoch != _watchEpoch) return;
        loadError.value = e.toString();
        isLoading.value = false;
      },
    );
  }

  /// Returns true when the application was submitted.
  /// The stored applicant `matchScore` was computed at apply time WITHOUT the
  /// family's household — a nanny can't read the family doc, so 3 of the match
  /// dimensions (religion / household comfort / household load) defaulted to
  /// neutral. The viewing family CAN read its own household, so recompute each
  /// applicant's score against the canonical family + job context for the inbox.
  Future<List<ApplicationModel>> _withCanonicalMatch(
      List<ApplicationModel> apps, String familyId) async {
    if (apps.isEmpty) return apps;
    try {
      final users = Get.find<IUserService>();
      final jobs = Get.find<IJobService>();
      final family = await users.getFamily(familyId);
      if (family == null) return apps;
      final jobById = {
        for (final j in await jobs.getJobsByFamily(familyId)) j.id: j,
      };
      final matcher = MatchService();
      return await Future.wait(apps.map((app) async {
        try {
          final job = jobById[app.jobPostId];
          if (job == null) return app;
          final nanny = await users.getNanny(app.nannyId);
          if (nanny == null) return app;
          return app.copyWith(
              matchScore: matcher.calculateJobMatch(nanny, job, family: family));
        } catch (_) {
          return app;
        }
      }));
    } catch (e) {
      Get.log('applicant match recompute failed: $e', isError: true);
      return apps;
    }
  }

  Future<bool> applyToJob(String jobId, {String? coverMessage}) async {
    isLoading.value = true;
    try {
      if (Get.isRegistered<TrialController>()) {
        final hasActive = Get.find<TrialController>()
            .all
            .any((t) => t.isLiveTrial);
        if (hasActive) {
          Get.snackbar(
            AppStrings.errorTitle.tr,
            AppStrings.trialActiveNoApply.tr,
          );
          return false;
        }
      }
      final nannyId = currentUserId(_auth);
      if (nannyId == null) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authSessionLost.tr);
        return false;
      }
      final alreadyApplied = myApplications.any(
          (a) => a.jobPostId == jobId && a.status != ApplicationStatus.withdrawn);
      if (alreadyApplied) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.applyAlreadyApplied.tr);
        return false;
      }
      await _appService.apply(nannyId: nannyId, jobId: jobId, coverMessage: coverMessage);
      await subscribeNannyOutbox();
      return true;
    } catch (e) {
      final raw = e.toString();
      final msg = raw.contains('already_applied')
          ? AppStrings.applyAlreadyApplied.tr
          : raw.contains('job_missing_family') || raw.contains('job_not_found')
              ? AppStrings.applyJobUnavailable.tr
              : raw;
      Get.snackbar(AppStrings.errorTitle.tr, msg);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> withdrawApplication(String appId) async {
    try {
      await _appService.withdraw(appId);
      myApplications.removeWhere((a) => a.id == appId);
      return true;
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
      return false;
    }
  }

  Future<void> markAsViewed(String appId) async {
    try {
      await _appService.markViewed(appId);
      final idx = receivedApplications.indexWhere((a) => a.id == appId);
      if (idx >= 0) {
        receivedApplications[idx] =
            receivedApplications[idx].copyWith(status: ApplicationStatus.viewed);
      }
    } catch (e) {
      Get.log('markAsViewed failed: $e', isError: true);
    }
  }

  Future<void> shortlist(String appId) async {
    try {
      await _appService.shortlist(appId);
      final idx = receivedApplications.indexWhere((a) => a.id == appId);
      if (idx >= 0) {
        final app = receivedApplications[idx];
        receivedApplications[idx] = app.copyWith(status: ApplicationStatus.shortlisted);
        if (Get.isRegistered<ShortlistController>()) {
          await Get.find<ShortlistController>().addToShortlist(app.nannyId);
        }
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }

  Future<void> decline(String appId) async {
    try {
      await _appService.decline(appId);
      final idx = receivedApplications.indexWhere((a) => a.id == appId);
      if (idx >= 0) {
        receivedApplications[idx] =
            receivedApplications[idx].copyWith(status: ApplicationStatus.declined);
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }
}
