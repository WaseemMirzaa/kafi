import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/services/interfaces/i_ticket_service.dart';

class FirestoreTicketService implements ITicketService {
  final _tickets = FirebaseFirestore.instance.collection('tickets');

  @override
  Future<String> openTicket({
    required String openerId,
    required String openerType,
    required String subject,
    required TicketCategory category,
    required String firstMessage,
    String? relatedTrialId,
  }) async {
    final ref = await _tickets.add({
      'openerId': openerId,
      'openerType': openerType,
      'subject': subject,
      'category': category.name,
      'status': TicketStatus.open.name,
      if (relatedTrialId != null) 'relatedTrialId': relatedTrialId,
      'lastMessage': firstMessage,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    // Seed the conversation with the opener's first message.
    await ref.collection('messages').add({
      'ticketId': ref.id,
      'senderId': openerId,
      'senderType': 'user',
      'content': firstMessage,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  @override
  Future<List<TicketModel>> getMyTickets(String userId) async {
    final snap = await _tickets
        .where('openerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => TicketModel.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<TicketModel?> getTicket(String ticketId) async {
    final doc = await _tickets.doc(ticketId).get();
    if (!doc.exists) return null;
    return TicketModel.fromMap(doc.id, doc.data()!);
  }

  @override
  Stream<TicketModel?> watchTicket(String ticketId) =>
      _tickets.doc(ticketId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return TicketModel.fromMap(doc.id, doc.data()!);
      });

  Query<Map<String, dynamic>> _msgQuery(String ticketId) => _tickets
      .doc(ticketId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .limit(200);

  @override
  Stream<List<TicketMessage>> watchMessages(String ticketId) => _msgQuery(ticketId)
      .snapshots()
      .map((s) => s.docs.map((d) => TicketMessage.fromMap(d.id, d.data())).toList());

  @override
  Future<List<TicketMessage>> loadMessages(String ticketId) async {
    final snap = await _msgQuery(ticketId).get();
    return snap.docs.map((d) => TicketMessage.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<void> sendMessage(String ticketId, TicketMessage message) async {
    final ticketRef = _tickets.doc(ticketId);
    final batch = FirebaseFirestore.instance.batch();
    batch.set(ticketRef.collection('messages').doc(), {
      'ticketId': ticketId,
      'senderId': message.senderId,
      'senderType': message.senderType,
      'content': message.content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // The opener may bump lastMessage/lastMessageAt but not status (rules pin
    // status to admin), so this update is allowed for both parties.
    batch.update(ticketRef, {
      'lastMessage': message.content,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
