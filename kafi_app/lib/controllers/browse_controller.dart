import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
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

  /// The job that Top Matches are currently ranked against (explicit selection
  /// or the family's most recent post).
  JobPostModel? get matchJob => selectedJob.value ?? (myJobs.isNotEmpty ? myJobs.first : null);

  String? get matchJobTitle {
    final j = matchJob;
    if (j == null) return null;
    return j.jobTitle.isNotEmpty ? j.jobTitle : '${j.jobType == JobType.liveOut ? 'Live-out' : 'Live-in'} · ${j.city}';
  }

  // 'Live-out' replaces the old 'Newborn' pill, which could never match: filters
  // post-match on nationality/jobType/language-tags, and no card carries a
  // "newborn" tag. 'Live-out' matches on the card's jobType.
  static const filters = ['All', 'Live-in', 'Live-out', 'Arabic', 'Filipino', 'Indian'];

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
    loadError.value = null;
    try {
      final currentUser = _auth.currentUser.value;
      if (currentUser == null || currentUser.isNanny) {
        myJobs.clear();
        results.clear();
        familyContext = null;
        return;
      }
      // Load the family's posted jobs first so matches can be linked to a job.
      final fid = currentUser.id;
      myJobs.value = await _jobs.getJobsByFamily(fid);
      familyContext = await _users.getFamily(fid);
      // Default to the family's most recent job so Top Matches is accurate even
      // before the user opens the filter; an explicit selection overrides it.
      final matchJob = selectedJob.value ?? (myJobs.isNotEmpty ? myJobs.first : null);
      final ranked = await _jobs.browseNannies(
        filter: activeFilter.value,
        matchJob: matchJob,
        family: familyContext,
      );
      // Hide nannies who are currently employed or mid-trial from discovery
      // (M5) — a hired/on-trial nanny isn't available to take on a new family.
      final engaged = await _engagedNannyIds();
      results.value = engaged.isEmpty
          ? ranked
          : ranked.where((c) => !engaged.contains(c.id)).toList();
    } catch (e) {
      // Log the raw error; the UI surfaces a friendly localized message (DISC-1).
      Get.log('browse load failed: $e', isError: true);
      results.clear();
      loadError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
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
