import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';

abstract class IJobService {
  /// Browse nannies. When [matchJob] is provided, each card's match % is
  /// computed with the canonical [MatchService] algorithm and sorted best-first.
  Future<List<NannyCardModel>> browseNannies({
    String? filter,
    JobFilter? jobFilter,
    JobPostModel? matchJob,
    FamilyModel? family,
  });
  Future<void> saveJobPost(JobPostModel post);
  Future<List<JobPostModel>> getJobsByFamily(String familyId);
  Future<List<JobPostModel>> browseJobs({JobFilter? filter});
  Future<JobPostModel?> getJob(String id);
  Future<void> updateJobStatus(String jobId, JobPostStatus status);

  /// Permanently deletes a job post (family owner or admin, per the rules).
  Future<void> deleteJob(String jobId);
}
