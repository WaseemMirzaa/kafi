import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/nanny_map_codec.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/utils/localized_text.dart';

class FirestoreJobService implements IJobService {
  final _jobs = FirebaseFirestore.instance.collection('jobs');
  final _nannies = FirebaseFirestore.instance.collection('nannies');

  @override
  Future<List<NannyCardModel>> browseNannies({
    String? filter,
    JobFilter? jobFilter,
    JobPostModel? matchJob,
    FamilyModel? family,
  }) async {
    // Must mirror firestore.rules: families may read only approved + verified nannies.
    Query<Map<String, dynamic>> query = _nannies
        .where('status', isEqualTo: 'approved')
        .where('isVerified', isEqualTo: true);

    if (filter != null && filter != 'All') {
      if (filter == 'Live-in') {
        query = query.where('jobTypePreference', whereIn: ['liveIn', 'both']);
      } else if (filter == 'Filipino' || filter == 'Indian') {
        query = query.where('nationality', isEqualTo: filter);
      }
    }

    final snap = await query.limit(50).get();
    final nannies = <NannyModel>[];
    for (final d in snap.docs) {
      final m = d.data();
      if (m['blocked'] == true) continue;
      nannies.add(nannyModelFromMap(d.id, m));
    }

    var eligible = nannies;
    if (filter != null && filter != 'All') {
      final f = filter.toLowerCase();
      eligible = nannies.where((n) {
        final card = NannyCardModel.fromNanny(n);
        return n.nationality.toLowerCase().contains(f) ||
            card.jobType.toLowerCase().contains(f) ||
            card.tags.any((t) => t.toLowerCase().contains(f));
      }).toList();
    }

    if (matchJob != null) {
      return MatchService().rankNannies(eligible, matchJob, family: family);
    }
    return eligible.map(NannyCardModel.fromNanny).toList();
  }

  @override
  Future<void> saveJobPost(JobPostModel post) async {
    final ref = _jobs.doc(post.id);
    final exists = (await ref.get()).exists;
    final data = post.toMap()
      ..remove('createdAt')
      ..remove('expiresAt')
      ..remove('updatedAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (!exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['expiresAt'] =
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)));
    }
    await ref.set(data, SetOptions(merge: true));
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

  @override
  Future<void> deleteJob(String jobId) async {
    await _jobs.doc(jobId).delete();
  }

  JobPostModel _jobFromMap(String id, Map<String, dynamic> m) => JobPostModel(
        id: id,
        familyId: m['familyId'] ?? '',
        familyName: m['familyName'] ?? '',
        status: _enumByName(JobPostStatus.values, m['status'], JobPostStatus.active),
        createdAt: _date(m['createdAt']),
        updatedAt: _date(m['updatedAt']),
        expiresAt: _date(m['expiresAt']),
        jobTitle: m['jobTitle'] ?? '',
        rolesNeeded: List<String>.from(m['rolesNeeded'] ?? const []),
        jobType: _enumByName(JobType.values, m['jobType'], JobType.liveIn),
        employmentType: _enumByName(
            JobEmploymentType.values, m['employmentType'], JobEmploymentType.fullTime),
        schedule: m['schedule'] ?? '',
        startDate: _date(m['startDate']),
        startImmediate: m['startImmediate'] ?? true,
        duration: _enumByName(JobDuration.values, m['duration'], JobDuration.permanent),
        contractMonths: (m['contractMonths'] as num?)?.toInt(),
        experienceYears: (m['experienceYears'] as num?)?.toInt() ?? 0,
        languagesRequired: List<String>.from(m['languagesRequired'] ?? const []),
        languagesPreferred: List<String>.from(m['languagesPreferred'] ?? const []),
        skillsRequired: List<String>.from(m['skillsRequired'] ?? const []),
        nationalityPreference: List<String>.from(m['nationalityPreference'] ?? const []),
        religionPreference: _religionPref(m['religionPreference']),
        duties: List<String>.from(m['duties'] ?? const []),
        salaryMin: (m['salaryMin'] as num?)?.toInt() ?? 0,
        salaryMax: (m['salaryMax'] as num?)?.toInt() ?? 0,
        currency: m['currency'] ?? 'AED',
        benefits: List<String>.from(m['benefits'] ?? const []),
        visaSponsorship: _enumByName(
            VisaSponsorship.values, m['visaSponsorship'], VisaSponsorship.full),
        trialDurationDays: (m['trialDurationDays'] as num?)?.toInt() ?? 0,
        trialDailyRate: (m['trialDailyRate'] as num?)?.toInt() ?? 0,
        additionalNotes: m['additionalNotes'] as String?,
        viewsCount: (m['viewsCount'] as num?)?.toInt() ?? 0,
        applicationsCount: (m['applicationsCount'] as num?)?.toInt() ?? 0,
        city: m['city'] ?? '',
        commitmentAgreed: m['commitmentAgreed'] ?? false,
        i18n: i18nMapsFrom(m, const ['jobTitle', 'schedule', 'additionalNotes']),
      );

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere((e) => e.name == name, orElse: () => fallback);

  static NannyReligionPreference? _religionPref(Object? name) {
    if (name == null) return null;
    for (final e in NannyReligionPreference.values) {
      if (e.name == name) return e;
    }
    return null;
  }
}
