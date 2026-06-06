import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';

abstract class IJobService {
  /// Browse nannies. When [matchJob] is provided, each card's match % is
  /// computed against that posted job and the list is sorted best-match first.
  Future<List<NannyCardModel>> browseNannies({String? filter, JobFilter? jobFilter, JobPostModel? matchJob});
  Future<void> saveJobPost(JobPostModel post);
  Future<List<JobPostModel>> getJobsByFamily(String familyId);
  Future<List<JobPostModel>> browseJobs({JobFilter? filter});
  Future<JobPostModel?> getJob(String id);
  Future<void> updateJobStatus(String jobId, JobPostStatus status);
}
