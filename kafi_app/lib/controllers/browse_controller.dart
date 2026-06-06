import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/family_model.dart' show JobType;
import 'package:kafi_app/services/interfaces/i_job_service.dart';

class BrowseController extends GetxController {
  final IJobService _jobs = Get.find<IJobService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<NannyCardModel> results = <NannyCardModel>[].obs;
  final RxString activeFilter = 'All'.obs;
  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  final searchCtrl = TextEditingController();

  /// The family's posted jobs, used to filter Top Matches by a specific job.
  final RxList<JobPostModel> myJobs = <JobPostModel>[].obs;
  final Rxn<JobPostModel> selectedJob = Rxn<JobPostModel>();

  /// The job that Top Matches are currently ranked against (explicit selection
  /// or the family's most recent post).
  JobPostModel? get matchJob => selectedJob.value ?? (myJobs.isNotEmpty ? myJobs.first : null);

  String? get matchJobTitle {
    final j = matchJob;
    if (j == null) return null;
    return j.jobTitle.isNotEmpty ? j.jobTitle : '${j.jobType == JobType.liveOut ? 'Live-out' : 'Live-in'} · ${j.city}';
  }

  static const filters = ['All', 'Live-in', 'Newborn', 'Arabic', 'Filipino', 'Indian'];

  String get familyFirstName => _auth.currentUser.value?.fullName?.split(' ').first ?? 'Fatima';

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> refreshList() async {
    isLoading.value = true;
    try {
      // Load the family's posted jobs first so matches can be linked to a job.
      final fid = _auth.currentUser.value?.id;
      if (fid != null) {
        myJobs.value = await _jobs.getJobsByFamily(fid);
      }
      // Default to the family's most recent job so Top Matches is accurate even
      // before the user opens the filter; an explicit selection overrides it.
      final matchJob = selectedJob.value ?? (myJobs.isNotEmpty ? myJobs.first : null);
      results.value = await _jobs.browseNannies(filter: activeFilter.value, matchJob: matchJob);
    } finally {
      isLoading.value = false;
    }
  }

  void onFilterTap(String f) {
    activeFilter.value = f;
    refreshList();
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
