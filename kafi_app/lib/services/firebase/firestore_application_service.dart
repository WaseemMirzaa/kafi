import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_map_codec.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/match_service.dart';

class FirestoreApplicationService implements IApplicationService {
  final _apps = FirebaseFirestore.instance.collection('applications');
  final _jobs = FirebaseFirestore.instance.collection('jobs');

  ApplicationModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      ApplicationModel.fromMap({...d.data(), 'id': d.id});

  /// No `orderBy` — avoids a hard dependency on the composite index and includes
  /// docs whose `createdAt` is still resolving; sort newest-first on the client.
  /// Filtering by [familyId] returns applicants across **all** of that family's
  /// job posts (full-time, part-time, closed) in one inbox query.
  Query<Map<String, dynamic>> _forNanny(String nannyId) =>
      _apps.where('nannyId', isEqualTo: nannyId);

  Query<Map<String, dynamic>> _forFamily(String familyId) =>
      _apps.where('familyId', isEqualTo: familyId);

  List<ApplicationModel> _sorted(Iterable<ApplicationModel> apps) {
    final list = apps.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForNanny(String nannyId) async {
    final snap = await _forNanny(nannyId).get();
    return _sorted(snap.docs.map(_fromDoc));
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForFamily(String familyId) async {
    final snap = await _forFamily(familyId).get();
    return _sorted(snap.docs.map(_fromDoc));
  }

  @override
  Stream<List<ApplicationModel>> watchApplicationsForNanny(String nannyId) =>
      _forNanny(nannyId).snapshots().map((s) => _sorted(s.docs.map(_fromDoc)));

  @override
  Stream<List<ApplicationModel>> watchApplicationsForFamily(String familyId) =>
      _forFamily(familyId).snapshots().map((s) => _sorted(s.docs.map(_fromDoc)));

  @override
  Future<List<ApplicationModel>> getApplicationsForJob(String jobId) async {
    final snap = await _apps.where('jobPostId', isEqualTo: jobId).get();
    return _sorted(snap.docs.map(_fromDoc));
  }

  @override
  Future<ApplicationModel> apply({
    required String nannyId,
    required String jobId,
    String? coverMessage,
  }) async {
    // Deterministic id = one application per (job, nanny). A re-apply lands on
    // the same doc and is blocked unless the previous one was withdrawn
    // (Spec §14 J3). This also keeps apply idempotent against retries.
    final id = '${jobId}_$nannyId';
    final ref = _apps.doc(id);
    // Reading a not-yet-created application doc is denied by Firestore rules
    // because the read rule keys off existing document ownership. Query the
    // nanny's own applications instead, which the rules explicitly allow.
    final prior = (await getApplicationsForNanny(nannyId))
        .where((app) => app.jobPostId == jobId)
        .cast<ApplicationModel?>()
        .firstWhere((app) => app != null, orElse: () => null);
    if (prior != null && prior.status != ApplicationStatus.withdrawn) {
      throw Exception('already_applied');
    }

    final jobSnap = await _jobs.doc(jobId).get();
    final jobData = jobSnap.data();
    if (jobData == null) {
      throw Exception('job_not_found');
    }
    final familyId = (jobData['familyId'] as String?)?.trim() ?? '';
    if (familyId.isEmpty) {
      // Without familyId the family's Applicants query can never find this doc.
      throw Exception('job_missing_family');
    }
    final nannySnap =
        await FirebaseFirestore.instance.collection('nannies').doc(nannyId).get();

    // Do not read the private family profile here: nannies are allowed to read
    // jobs, but not the corresponding `families/{id}` document. Fetching it
    // causes the apply flow to fail with Firestore permission errors. The
    // application score therefore uses the job post + nanny profile only.
    final matchScore = nannySnap.data() != null
        ? MatchService().calculateJobMatch(
            nannyModelFromMap(nannyId, nannySnap.data()!),
            JobPostModel.fromMap(jobId, jobData),
          )
        : 0;

    final roles = (jobData['rolesNeeded'] as List?)?.map((e) => '$e').toList() ?? const [];
    final storedTitle = (jobData['jobTitle'] as String?)?.trim() ?? '';
    final jobTitle = storedTitle.isNotEmpty
        ? storedTitle
        : (roles.isNotEmpty ? roles.first : null);

    final app = ApplicationModel(
      id: id,
      jobPostId: jobId,
      nannyId: nannyId,
      familyId: familyId,
      status: ApplicationStatus.pending,
      matchScore: matchScore,
      coverMessage: coverMessage,
      createdAt: DateTime.now(),
      // Denormalized so admin/family lists render without extra lookups.
      nannyName: nannySnap.data()?['fullName'] as String?,
      jobTitle: jobTitle,
      familyName: jobData['familyName'] as String?,
    );

    final data = app.toMap()..remove('createdAt');
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    // jobs.applicationsCount is incremented by onNewApplication (admin SDK) —
    // nannies cannot update another family's job doc under Firestore rules.
    return app;
  }

  @override
  Future<void> withdraw(String appId) async {
    await _apps.doc(appId).update({
      'status': ApplicationStatus.withdrawn.name,
      'withdrawnAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markViewed(String appId) async {
    await _apps.doc(appId).update({
      'status': ApplicationStatus.viewed.name,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> shortlist(String appId) async {
    await _apps.doc(appId).update({
      'status': ApplicationStatus.shortlisted.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> decline(String appId) async {
    await _apps.doc(appId).update({
      'status': ApplicationStatus.declined.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> offerTrial(String appId) async {
    await _apps.doc(appId).update({
      'status': ApplicationStatus.trialOffered.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markHired(String appId) async {
    await _apps.doc(appId).update({
      'status': ApplicationStatus.hired.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
