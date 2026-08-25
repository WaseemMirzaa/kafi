import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/hire_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';

/// Backs the family "My Jobs" screen: the family's own posted jobs plus the
/// active hires that resulted from them, so each job can show its hiring
/// status and be paused/reopened/closed/edited/deleted.
class FamilyJobsController extends GetxController {
  final IJobService _jobs = Get.find<IJobService>();
  final IHireService _hires = Get.find<IHireService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<JobPostModel> jobs = <JobPostModel>[].obs;
  final RxList<HireModel> _activeHires = <HireModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final fid = currentUserId(_auth);
    if (fid == null) {
      jobs.clear();
      _activeHires.clear();
      return;
    }
    isLoading.value = true;
    error.value = null;
    try {
      final loaded = List<JobPostModel>.from(await _jobs.getJobsByFamily(fid))
        ..sort((a, b) => (b.createdAt ?? DateTime(1970))
            .compareTo(a.createdAt ?? DateTime(1970)));
      // Overlay live applicant counts from the applications collection so My
      // Jobs pills stay accurate even when jobs.applicationsCount is stale.
      if (Get.isRegistered<IApplicationService>()) {
        final apps =
            await Get.find<IApplicationService>().getApplicationsForFamily(fid);
        final counts = <String, int>{};
        for (final a in apps) {
          if (a.status == ApplicationStatus.withdrawn) continue;
          counts[a.jobPostId] = (counts[a.jobPostId] ?? 0) + 1;
        }
        for (var i = 0; i < loaded.length; i++) {
          final c = counts[loaded[i].id];
          if (c != null) {
            loaded[i] = loaded[i].copyWith(applicationsCount: c);
          }
        }
      }
      final hires = await _hires.getHiresForFamily(fid);
      jobs.assignAll(loaded);
      _activeHires.assignAll(hires.where((h) => h.isActive));
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// The active hire tied to [jobPostId], if the family already hired someone
  /// for this specific job. Null otherwise.
  HireModel? hireForJob(String jobPostId) =>
      _activeHires.firstWhereOrNull((h) => h.jobPostId == jobPostId);

  Future<void> setStatus(String jobId, JobPostStatus status) async {
    try {
      await _jobs.updateJobStatus(jobId, status);
      await load();
      // Confirm the pause/reopen, like delete/edit already do (HIRE-8).
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.jobUpdatedToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await _jobs.deleteJob(jobId);
      jobs.removeWhere((j) => j.id == jobId);
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.jobDeletedToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }

  /// Persists an in-place edit of the job (upsert). Reloads so the list and any
  /// hiring status stay in sync.
  Future<void> saveEdited(JobPostModel job) async {
    try {
      await _jobs.saveJobPost(job);
      await load();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.jobUpdatedToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }
}
