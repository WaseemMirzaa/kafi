import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadApplications();
  }

  Future<void> loadApplications() async {
    isLoading.value = true;
    try {
      final userId = currentUserId(_auth);
      if (userId == null) return;
      final isNanny = _auth.currentUser.value?.isNanny ?? false;
      if (isNanny) {
        myApplications.value = await _appService.getApplicationsForNanny(userId);
      } else {
        receivedApplications.value = await _appService.getApplicationsForFamily(userId);
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
      await _appService.apply(nannyId: nannyId, jobId: jobId, coverMessage: coverMessage);
      await loadApplications();
      // Success feedback is surfaced by the caller as a popup (see SmartMatchScreen).
      return true;
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
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
      receivedApplications[idx] = receivedApplications[idx].copyWith(status: ApplicationStatus.shortlisted);
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
