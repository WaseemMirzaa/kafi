import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class ApplicationController extends GetxController {
  final IApplicationService _appService = Get.find<IApplicationService>();
  final IUserService _users = Get.find<IUserService>();
  final IJobService _jobs = Get.find<IJobService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<ApplicationModel> myApplications = <ApplicationModel>[].obs;
  final RxList<ApplicationModel> receivedApplications = <ApplicationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();

  // Search queries for the applicants (family) and my-applications (nanny) lists.
  final RxString receivedQuery = ''.obs;
  final RxString sentQuery = ''.obs;

  /// Family "Applicants" filtered by the search box (nanny name / job title).
  List<ApplicationModel> get filteredReceived {
    final q = receivedQuery.value.trim().toLowerCase();
    if (q.isEmpty) return receivedApplications;
    return receivedApplications
        .where((a) =>
            (a.nannyName ?? '').toLowerCase().contains(q) ||
            (a.jobTitle ?? '').toLowerCase().contains(q))
        .toList();
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
    // Keep the inbox in sync across login, role switch, and route bindings.
    ever<dynamic>(_auth.currentUser, (_) {
      myApplications.clear();
      receivedApplications.clear();
      loadApplications();
    });
  }

  Future<void> loadApplications() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final userId = currentUserId(_auth);
      if (userId == null) {
        myApplications.clear();
        receivedApplications.clear();
        return;
      }
      final isNanny = _auth.currentUser.value?.isNanny ?? false;
      if (isNanny) {
        myApplications.value = await _appService.getApplicationsForNanny(userId);
        receivedApplications.clear();
      } else {
        final apps = await _appService.getApplicationsForFamily(userId);
        receivedApplications.value = await _withCanonicalMatch(apps, userId);
        myApplications.clear();
      }
    } catch (e) {
      // A live read failure must surface as an error, not an empty inbox.
      loadError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true when the application was submitted.
  /// The stored applicant `matchScore` was computed at apply time WITHOUT the
  /// family's household — a nanny can't read the family doc, so 3 of the match
  /// dimensions (religion / household comfort / household load) defaulted to
  /// neutral. The viewing family CAN read its own household, so recompute each
  /// applicant's score against the canonical family + job context for the inbox.
  ///
  /// Best-effort: any missing model or failure leaves that application's stored
  /// score untouched. Costs one nanny read per applicant (fetched in parallel,
  /// bounded by the applicant count) — acceptable for the inbox load.
  Future<List<ApplicationModel>> _withCanonicalMatch(
      List<ApplicationModel> apps, String familyId) async {
    if (apps.isEmpty) return apps;
    try {
      final family = await _users.getFamily(familyId);
      if (family == null) return apps;
      final jobById = {
        for (final j in await _jobs.getJobsByFamily(familyId)) j.id: j,
      };
      final matcher = MatchService();
      return await Future.wait(apps.map((app) async {
        try {
          final job = jobById[app.jobPostId];
          if (job == null) return app;
          final nanny = await _users.getNanny(app.nannyId);
          if (nanny == null) return app;
          return app.copyWith(
              matchScore: matcher.calculateJobMatch(nanny, job, family: family));
        } catch (_) {
          return app; // one bad applicant keeps its stored score; others recompute
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
            .any((t) => t.status == TrialStatus.active);
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
      // Guard against a duplicate application (Spec §14 J3). Fast-path on the
      // already-loaded list; the service enforces it authoritatively too.
      final alreadyApplied = myApplications.any(
          (a) => a.jobPostId == jobId && a.status != ApplicationStatus.withdrawn);
      if (alreadyApplied) {
        Get.snackbar(AppStrings.errorTitle.tr, AppStrings.applyAlreadyApplied.tr);
        return false;
      }
      await _appService.apply(nannyId: nannyId, jobId: jobId, coverMessage: coverMessage);
      await loadApplications();
      // Success feedback is surfaced by the caller as a popup (see SmartMatchScreen).
      return true;
    } catch (e) {
      final msg = e.toString().contains('already_applied')
          ? AppStrings.applyAlreadyApplied.tr
          : e.toString();
      Get.snackbar(AppStrings.errorTitle.tr, msg);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Withdraws an application. Returns true on success; shows an error on
  /// failure so a live write error isn't silently dropped.
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
    // Best-effort: the "viewed" marker is cosmetic and auto-fired when the
    // family opens an applicant, so a write failure must not throw and block
    // the profile from opening. Log it rather than swallow it silently.
    try {
      await _appService.markViewed(appId);
      final idx = receivedApplications.indexWhere((a) => a.id == appId);
      if (idx >= 0) {
        receivedApplications[idx] = receivedApplications[idx].copyWith(status: ApplicationStatus.viewed);
      }
    } catch (e) {
      Get.log('markAsViewed failed: $e', isError: true);
    }
  }

  Future<void> shortlist(String appId) async {
    // A deliberate family action: on failure the optimistic status update below
    // never runs, so tell the user instead of leaving the card unchanged.
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
        receivedApplications[idx] = receivedApplications[idx].copyWith(status: ApplicationStatus.declined);
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }
}
