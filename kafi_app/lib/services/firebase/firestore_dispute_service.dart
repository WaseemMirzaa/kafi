import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';

class FirestoreDisputeService implements IDisputeService {
  final _disputes = FirebaseFirestore.instance.collection('disputes');

  @override
  Future<String> fileDispute({
    required String reporterId,
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
  }) async {
    final dispute = DisputeModel(
      id: '',
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      category: category,
      description: description,
      relatedTrialId: relatedTrialId,
      createdAt: DateTime.now(),
    );
    final ref = await _disputes.add(dispute.toMap());
    return ref.id;
  }

  @override
  Future<List<DisputeModel>> getMyDisputes(String userId) async {
    final snap = await _disputes
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => DisputeModel.fromMap(d.id, d.data())).toList();
  }
}
