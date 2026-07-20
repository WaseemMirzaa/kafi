import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class ApplicationController extends GetxController {
  final IApplicationService _appService = Get.find<IApplicationService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<ApplicationModel> myApplications = <ApplicationModel>[].obs;
  final RxList<ApplicationModel> receivedApplications = <ApplicationModel>[].obs;
  final RxBool isLoading = false.obs;

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
        receivedApplications.value = await _appService.getApplicationsForFamily(userId);
        myApplications.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true when the application was submitted.
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

  Future<void> withdrawApplication(String appId) async {
    await _appService.withdraw(appId);
    myApplications.removeWhere((a) => a.id == appId);
  }

  Future<void> markAsViewed(String appId) async {
    await _appService.markViewed(appId);
    final idx = receivedApplications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      receivedApplications[idx] = receivedApplications[idx].copyWith(status: ApplicationStatus.viewed);
    }
  }

  Future<void> shortlist(String appId) async {
    await _appService.shortlist(appId);
    final idx = receivedApplications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      final app = receivedApplications[idx];
      receivedApplications[idx] = app.copyWith(status: ApplicationStatus.shortlisted);
      if (Get.isRegistered<ShortlistController>()) {
        await Get.find<ShortlistController>().addToShortlist(app.nannyId);
      }
    }
  }

  Future<void> decline(String appId) async {
    await _appService.decline(appId);
    final idx = receivedApplications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      receivedApplications[idx] = receivedApplications[idx].copyWith(status: ApplicationStatus.declined);
    }
  }
}
