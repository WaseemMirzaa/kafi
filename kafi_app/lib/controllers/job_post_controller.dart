import 'dart:async';

import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';

class JobPostController extends GetxController {
  final IJobService _jobService = Get.find<IJobService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<JobPostModel> allJobs = <JobPostModel>[].obs;
  final RxList<JobPostModel> myJobs = <JobPostModel>[].obs;
  final Rx<JobPostModel?> currentJob = Rx<JobPostModel?>(null);
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  final RxString searchQuery = ''.obs;
  final Rx<JobFilter> filter = JobFilter().obs;

  StreamSubscription<List<JobPostModel>>? _activeJobsSub;

  @override
  void onInit() {
    super.onInit();
    loadJobs();
  }

  @override
  void onClose() {
    _activeJobsSub?.cancel();
    super.onClose();
  }

  /// Nanny: live Firestore/mock watch so a family post appears without pull-to-refresh.
  /// Family: one-shot load of own posts.
  Future<void> loadJobs() async {
    final user = _auth.currentUser.value;
    if (user?.isNanny ?? false) {
      _startActiveJobsWatch();
      return;
    }

    isLoading.value = true;
    loadError.value = null;
    try {
      final familyId = user?.id;
      if (familyId == null) return;
      myJobs.value = await _jobService.getJobsByFamily(familyId);
    } catch (e) {
      loadError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void _startActiveJobsWatch() {
    _activeJobsSub?.cancel();
    isLoading.value = true;
    loadError.value = null;
    // Emirate is the only server-side filter; jobType/duties stay client-side.
    final serverFilter = filter.value.emirate != null
        ? JobFilter(emirate: filter.value.emirate)
        : null;
    _activeJobsSub = _jobService.watchActiveJobs(filter: serverFilter).listen(
      (jobs) {
        jobs.sort((a, b) =>
            (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
        allJobs.value = jobs;
        loadError.value = null;
        isLoading.value = false;
      },
      onError: (Object e) {
        loadError.value = e.toString();
        isLoading.value = false;
      },
    );
  }

  void applyFilter(JobFilter newFilter) {
    filter.value = newFilter;
    loadJobs();
  }

  /// Sets the active filter WITHOUT a server round-trip. jobType/duties are
  /// applied client-side by [filteredJobs], so the chip filters re-filter the
  /// already-loaded list instead of re-fetching (and flashing a full spinner).
  void setFilter(JobFilter newFilter) => filter.value = newFilter;

  List<JobPostModel> get filteredJobs {
    var list = allJobs.toList();
    final f = filter.value;
    if (f.jobType != null) {
      list = list.where((j) => j.jobType.name == f.jobType).toList();
    }
    if (f.duties.isNotEmpty) {
      list = list
          .where((j) => j.duties.any((d) => f.duties.any((fd) => d.toLowerCase().contains(fd))))
          .toList();
    }
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      list = list.where((j) {
        return j.familyName.toLowerCase().contains(q) ||
            j.city.toLowerCase().contains(q) ||
            j.rolesNeeded.any((r) => r.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  Future<void> createJobPost(JobPostModel job) async {
    isLoading.value = true;
    try {
      await _jobService.saveJobPost(job);
      await loadJobs();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.jobPostedToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pauseJob(String jobId) async {
    await _jobService.updateJobStatus(jobId, JobPostStatus.paused);
    await loadJobs();
  }

  Future<void> closeJob(String jobId) async {
    await _jobService.updateJobStatus(jobId, JobPostStatus.closed);
    await loadJobs();
  }

  Future<void> reopenJob(String jobId) async {
    await _jobService.updateJobStatus(jobId, JobPostStatus.active);
    await loadJobs();
  }
}

class JobFilter {
  final String? emirate;
  final String? jobType;
  final int? minSalary;
  final int? maxSalary;
  final List<String> languages;
  final List<String> duties;
  final bool? hasVisa;

  JobFilter({
    this.emirate,
    this.jobType,
    this.minSalary,
    this.maxSalary,
    this.languages = const [],
    this.duties = const [],
    this.hasVisa,
  });

  JobFilter copyWith({
    String? emirate,
    String? jobType,
    int? minSalary,
    int? maxSalary,
    List<String>? languages,
    List<String>? duties,
    bool? hasVisa,
  }) =>
      JobFilter(
        emirate: emirate ?? this.emirate,
        jobType: jobType ?? this.jobType,
        minSalary: minSalary ?? this.minSalary,
        maxSalary: maxSalary ?? this.maxSalary,
        languages: languages ?? this.languages,
        duties: duties ?? this.duties,
        hasVisa: hasVisa ?? this.hasVisa,
      );
}
