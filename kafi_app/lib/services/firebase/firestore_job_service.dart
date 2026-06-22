import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/match_service.dart';

class FirestoreJobService implements IJobService {
  final _jobs = FirebaseFirestore.instance.collection('jobs');
  final _nannies = FirebaseFirestore.instance.collection('nannies');

  @override
  Future<List<NannyCardModel>> browseNannies({String? filter, JobFilter? jobFilter, JobPostModel? matchJob}) async {
    Query<Map<String, dynamic>> query = _nannies.where('status', isEqualTo: 'approved');

    if (filter != null && filter != 'All') {
      if (filter == 'Live-in') {
        query = query.where('jobTypePreference', whereIn: ['liveIn', 'both']);
      } else if (filter == 'Filipino' || filter == 'Indian') {
        query = query.where('nationality', isEqualTo: filter);
      }
    }

    final snap = await query.limit(50).get();
    var cards = snap.docs.map((d) {
      final m = d.data();
      final name = m['fullName'] ?? '';
      final expCount = (m['experiences'] as List?)?.length ?? 0;
      return NannyCardModel(
        id: d.id,
        initials: name.isNotEmpty ? name[0].toUpperCase() : 'N',
        name: name,
        nationality: m['nationality'] ?? '',
        yearsExp: expCount,
        jobType: m['jobTypePreference'] == 'liveIn' ? 'Live-in' : 'Live-out',
        city: m['currentArea'] ?? 'Dubai',
        matchPercent: 85,
        tags: List<String>.from(m['languages'] ?? []).take(3).toList(),
        verified: m['isVerified'] ?? false,
        availableNow: m['availability'] == 'availableNow',
      );
    }).toList();

    if (filter != null && filter != 'All') {
      final f = filter.toLowerCase();
      cards = cards
          .where(
            (n) =>
                n.nationality.toLowerCase().contains(f) ||
                n.jobType.toLowerCase().contains(f) ||
                n.tags.any((t) => t.toLowerCase().contains(f)),
          )
          .toList();
    }
    // Link nannies to the posted job via the single source of truth
    // (MatchService): real, deterministic match % + ranking with the
    // nationality tie-breaker.
    if (matchJob != null) {
      cards = MatchService().rankCards(cards, matchJob);
    }
    return cards;
  }

  @override
  Future<void> saveJobPost(JobPostModel post) async {
    await _jobs.doc(post.id).set(post.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<JobPostModel>> getJobsByFamily(String familyId) async {
    final snap = await _jobs.where('familyId', isEqualTo: familyId).get();
    return snap.docs.map((d) => _jobFromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<JobPostModel>> browseJobs({JobFilter? filter}) async {
    Query<Map<String, dynamic>> query = _jobs.where('status', isEqualTo: 'active');

    if (filter?.emirate != null) {
      query = query.where('city', isEqualTo: filter!.emirate);
    }

    final snap = await query.limit(50).get();
    return snap.docs.map((d) => _jobFromMap(d.id, d.data())).toList();
  }

  @override
  Future<JobPostModel?> getJob(String id) async {
    final snap = await _jobs.doc(id).get();
    if (!snap.exists) return null;
    return _jobFromMap(snap.id, snap.data()!);
  }

  @override
  Future<void> updateJobStatus(String jobId, JobPostStatus status) async {
    await _jobs.doc(jobId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  JobPostModel _jobFromMap(String id, Map<String, dynamic> m) => JobPostModel(
        id: id,
        familyId: m['familyId'] ?? '',
        familyName: m['familyName'] ?? '',
        status: JobPostStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => JobPostStatus.active),
        jobTitle: m['jobTitle'] ?? '',
        rolesNeeded: List<String>.from(m['rolesNeeded'] ?? []),
        jobType: m['jobType'] == 'liveOut' ? JobType.liveOut : JobType.liveIn,
        employmentType: m['employmentType'] == 'partTime'
            ? JobEmploymentType.partTime
            : JobEmploymentType.fullTime,
        duties: List<String>.from(m['duties'] ?? []),
        benefits: List<String>.from(m['benefits'] ?? []),
        salaryMin: (m['salaryMin'] as num?)?.toInt() ?? 0,
        salaryMax: (m['salaryMax'] as num?)?.toInt() ?? 0,
        languagesRequired: List<String>.from(m['languagesRequired'] ?? []),
        city: m['city'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
      );
}
