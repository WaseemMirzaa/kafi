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

  @override
  Future<DisputeModel?> getDispute(String disputeId) async {
    final doc = await _disputes.doc(disputeId).get();
    if (!doc.exists) return null;
    return DisputeModel.fromMap(doc.id, doc.data()!);
  }

  Query<Map<String, dynamic>> _msgQuery(String disputeId) => _disputes
      .doc(disputeId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .limit(200);

  @override
  Stream<List<DisputeMessage>> watchMessages(String disputeId) => _msgQuery(disputeId)
      .snapshots()
      .map((s) => s.docs.map((d) => DisputeMessage.fromMap(d.id, d.data())).toList());

  @override
  Future<List<DisputeMessage>> loadMessages(String disputeId) async {
    final snap = await _msgQuery(disputeId).get();
    return snap.docs.map((d) => DisputeMessage.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> sendMessage(String disputeId, DisputeMessage message) async {
    // Rules pin a non-admin to senderType 'user'; the timestamp is server-set.
    await _disputes.doc(disputeId).collection('messages').add({
      'disputeId': disputeId,
      'senderId': message.senderId,
      'senderType': 'user',
      if (message.senderName != null) 'senderName': message.senderName,
      'content': message.content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
