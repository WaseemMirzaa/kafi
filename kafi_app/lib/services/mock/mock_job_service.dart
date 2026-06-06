import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/data/mock/mock_jobs.dart';
import 'package:kafi_app/data/mock/mock_nannies.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/match_service.dart';

class MockJobService implements IJobService {
  final Map<String, JobPostModel> _posts = {
    for (final j in mockJobPosts) j.id: j,
  };

  @override
  Future<List<NannyCardModel>> browseNannies({String? filter, JobFilter? jobFilter, JobPostModel? matchJob}) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    var list = mockNannyCards.toList();
    if (filter != null && filter != 'All') {
      final f = filter.toLowerCase();
      list = list.where((n) {
        return n.nationality.toLowerCase().contains(f) ||
            n.jobType.toLowerCase().contains(f) ||
            n.tags.any((t) => t.toLowerCase().contains(f));
      }).toList();
    }
    // Link nannies to the posted job via the single source of truth
    // (MatchService): real, deterministic match % + ranking with the
    // nationality tie-breaker.
    if (matchJob != null) {
      list = MatchService().rankCards(list, matchJob);
    }
    return list;
  }

  @override
  Future<void> saveJobPost(JobPostModel post) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _posts[post.id] = post;
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
    return _posts.values.where((j) => j.status == JobPostStatus.active).toList();
  }

  @override
  Future<void> updateJobStatus(String jobId, JobPostStatus status) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final job = _posts[jobId];
    if (job != null) {
      _posts[jobId] = job.copyWith(status: status);
    }
  }
}
