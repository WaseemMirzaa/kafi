import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';

class FirestoreApplicationService implements IApplicationService {
  final _apps = FirebaseFirestore.instance.collection('applications');

  @override
  Future<List<ApplicationModel>> getApplicationsForNanny(String nannyId) async {
    final snap = await _apps
        .where('nannyId', isEqualTo: nannyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList();
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForFamily(String familyId) async {
    final snap = await _apps
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList();
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForJob(String jobId) async {
    final snap = await _apps
        .where('jobPostId', isEqualTo: jobId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ApplicationModel.fromMap(d.data())).toList();
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
    final existing = await ref.get();
    if (existing.exists &&
        existing.data()?['status'] != ApplicationStatus.withdrawn.name) {
      throw Exception('already_applied');
    }

    final jobSnap =
        await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final jobData = jobSnap.data();
    final nannySnap =
        await FirebaseFirestore.instance.collection('nannies').doc(nannyId).get();

    final app = ApplicationModel(
      id: id,
      jobPostId: jobId,
      nannyId: nannyId,
      familyId: (jobData?['familyId'] as String?) ?? '',
      status: ApplicationStatus.pending,
      matchScore: 80,
      coverMessage: coverMessage,
      createdAt: DateTime.now(),
      // Denormalized so admin/family lists render without extra lookups.
      nannyName: nannySnap.data()?['fullName'] as String?,
      jobTitle: jobData?['jobTitle'] as String?,
      familyName: jobData?['familyName'] as String?,
    );

    await ref.set(app.toMap());
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
}
