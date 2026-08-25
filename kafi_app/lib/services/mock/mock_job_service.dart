import 'dart:async';

import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/data/mock/mock_jobs.dart';
import 'package:kafi_app/data/mock/mock_nannies.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/services/mock/mock_browse_bus.dart';
import 'package:kafi_app/services/mock/mock_user_service.dart';
import 'package:kafi_app/utils/nanny_listing_activity.dart';

class MockJobService implements IJobService {
  final Map<String, JobPostModel> _posts = {
    for (final j in mockJobPosts) j.id: j,
  };

  /// Mirrors admin `hideInactiveNannies` for mock-mode browse tests.
  bool hideInactiveNannies = false;

  /// Notifies [watchActiveJobs] listeners when the in-memory job map changes
  /// (same service instance is shared family ↔ nanny in mock mode).
  final _jobsChanged = StreamController<void>.broadcast();

  void _notifyJobsChanged() {
    if (!_jobsChanged.isClosed) _jobsChanged.add(null);
  }

  @override
  Future<List<NannyCardModel>> browseNannies({
    String? filter,
    JobFilter? jobFilter,
    JobPostModel? matchJob,
    FamilyModel? family,
  }) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _browseCards(filter: filter, matchJob: matchJob, family: family);
  }

  @override
  Stream<List<NannyCardModel>> watchBrowseNannies({
    String? filter,
    JobFilter? jobFilter,
    JobPostModel? matchJob,
    FamilyModel? family,
  }) async* {
    yield _browseCards(filter: filter, matchJob: matchJob, family: family);
    await for (final _ in MockBrowseBus.stream) {
      yield _browseCards(filter: filter, matchJob: matchJob, family: family);
    }
  }

  List<NannyCardModel> _browseCards({
    String? filter,
    JobPostModel? matchJob,
    FamilyModel? family,
  }) {
    // Seed demo cards + any nannies created/approved in this mock session.
    final byId = <String, NannyCardModel>{
      for (final c in mockNannyCards)
        if (_cardMatchesFilter(c, filter)) c.id: c,
    };
    if (Get.isRegistered<IUserService>()) {
      final users = Get.find<IUserService>();
      if (users is MockUserService) {
        for (final n in users.browseableNannies) {
          if (NannyListingActivity.shouldHideFromListing(
            n,
            hideInactiveEnabled: hideInactiveNannies,
          )) {
            continue;
          }
          if (!_nannyMatchesFilter(n, filter)) continue;
          byId[n.id] = NannyCardModel.fromNanny(n);
        }
      }
    }
    // Seed cards have no lastActiveAt — when hide-inactive is on, drop them
    // (same rule as missing stamp on live profiles).
    if (hideInactiveNannies) {
      byId.removeWhere((_, card) {
        // Prefer live MockUserService profile when present.
        if (Get.isRegistered<IUserService>()) {
          final users = Get.find<IUserService>();
          if (users is MockUserService) {
            final live = users.browseableNannies.where((n) => n.id == card.id);
            if (live.isNotEmpty) {
              return NannyListingActivity.shouldHideFromListing(
                live.first,
                hideInactiveEnabled: true,
              );
            }
          }
        }
        // Seed-only card: treat as inactive (no stamp).
        return true;
      });
    }
    var list = byId.values.toList();
    if (matchJob != null) {
      list = MatchService().rankCards(list, matchJob);
    }
    return list;
  }

  /// Mirrors Firestore browse filter pills (All / Live-in / Live-out / nationality / language).
  bool _nannyMatchesFilter(NannyModel n, String? filter) {
    if (filter == null || filter == 'All') return true;
    final f = filter.toLowerCase();
    final card = NannyCardModel.fromNanny(n);
    if (filter == 'Live-in') {
      return n.jobTypePreference == JobTypePreference.liveIn ||
          n.jobTypePreference == JobTypePreference.both;
    }
    if (filter == 'Live-out') {
      return n.jobTypePreference == JobTypePreference.liveOut ||
          n.jobTypePreference == JobTypePreference.both;
    }
    return n.nationality.toLowerCase().contains(f) ||
        card.jobType.toLowerCase().contains(f) ||
        n.languages.any((l) => l.toLowerCase().contains(f)) ||
        card.tags.any((t) => t.toLowerCase().contains(f));
  }

  bool _cardMatchesFilter(NannyCardModel n, String? filter) {
    if (filter == null || filter == 'All') return true;
    final f = filter.toLowerCase();
    return n.nationality.toLowerCase().contains(f) ||
        n.jobType.toLowerCase().contains(f) ||
        n.tags.any((t) => t.toLowerCase().contains(f));
  }

  @override
  Future<void> saveJobPost(JobPostModel post) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _posts[post.id] = post;
    _notifyJobsChanged();
  }

  @override
  Future<List<JobPostModel>> getJobsByFamily(String familyId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _posts.values.where((p) => p.familyId == familyId).toList();
  }

  @override
  Future<JobPostModel?> getJob(String id) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _posts[id];
  }

  @override
  Future<List<JobPostModel>> browseJobs({JobFilter? filter}) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _activeJobs(filter);
  }

  @override
  Stream<List<JobPostModel>> watchActiveJobs({JobFilter? filter}) async* {
    yield _activeJobs(filter);
    await for (final _ in _jobsChanged.stream) {
      yield _activeJobs(filter);
    }
  }

  List<JobPostModel> _activeJobs(JobFilter? filter) {
    var list = _posts.values.where((j) => j.status == JobPostStatus.active);
    if (filter?.emirate != null) {
      list = list.where((j) => j.city == filter!.emirate);
    }
    return list.toList();
  }

  @override
  Future<void> updateJobStatus(String jobId, JobPostStatus status) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final job = _posts[jobId];
    if (job != null) {
      _posts[jobId] = job.copyWith(status: status);
      _notifyJobsChanged();
    }
  }

  @override
  Future<void> deleteJob(String jobId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _posts.remove(jobId);
    _notifyJobsChanged();
  }
}
