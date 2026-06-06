import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:uuid/uuid.dart';

class FirestoreApplicationService implements IApplicationService {
  final _apps = FirebaseFirestore.instance.collection('applications');
  final _uuid = const Uuid();

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
    final jobSnap = await FirebaseFirestore.instance.collection('jobs').doc(jobId).get();
    final familyId = jobSnap.data()?['familyId'] ?? '';

    final app = ApplicationModel(
      id: _uuid.v4(),
      jobPostId: jobId,
      nannyId: nannyId,
      familyId: familyId,
      status: ApplicationStatus.pending,
      matchScore: 80,
      coverMessage: coverMessage,
      createdAt: DateTime.now(),
    );

    await _apps.doc(app.id).set(app.toMap());
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
