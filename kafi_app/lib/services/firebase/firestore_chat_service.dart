import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';

class FirestoreChatService implements IChatService {
  final _threads = FirebaseFirestore.instance.collection('chatThreads');

  @override
  Future<List<ChatThread>> listThreads(String userId) async {
    final byId = <String, ChatThread>{};

    Future<void> load(Query<Map<String, dynamic>> query) async {
      final snap = await query.get();
      for (final d in snap.docs) {
        byId[d.id] = _threadFromDoc(d);
      }
    }

    await load(_threads.where('familyId', isEqualTo: userId));
    await load(_threads.where('nannyId', isEqualTo: userId));

    final list = byId.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return list;
  }

  @override
  Stream<List<ChatThread>> watchThreads(String userId) {
    // A user's threads match on EITHER familyId or nannyId, so we merge two
    // snapshot streams: each query keeps its own slice and we re-emit the sorted
    // union whenever either side changes.
    final controller = StreamController<List<ChatThread>>();
    var asFamily = <ChatThread>[];
    var asNanny = <ChatThread>[];

    void emit() {
      final byId = <String, ChatThread>{};
      for (final t in asFamily) {
        byId[t.id] = t;
      }
      for (final t in asNanny) {
        byId[t.id] = t;
      }
      final list = byId.values.toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      if (!controller.isClosed) controller.add(list);
    }

    final subFamily = _threads.where('familyId', isEqualTo: userId).snapshots().listen((s) {
      asFamily = s.docs.map(_threadFromDoc).toList();
      emit();
    }, onError: controller.addError);
    final subNanny = _threads.where('nannyId', isEqualTo: userId).snapshots().listen((s) {
      asNanny = s.docs.map(_threadFromDoc).toList();
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await subFamily.cancel();
      await subNanny.cancel();
    };
    return controller.stream;
  }

  ChatThread _threadFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
      _threadFromMap(d.id, d.data());

  ChatThread _threadFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    if (data == null) {
      throw StateError('missing_thread');
    }
    return _threadFromMap(snap.id, data);
  }

  ChatThread _threadFromMap(String id, Map<String, dynamic> m) {
    return ChatThread(
      id: id,
      familyId: m['familyId'] ?? '',
      nannyId: m['nannyId'] ?? '',
      familyName: m['familyName'] ?? '',
      nannyName: m['nannyName'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (m['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: m['lastMessage'] ?? '',
      unreadCount: UnreadCount(
        family: (m['unreadCount']?['family'] as num?)?.toInt() ?? 0,
        nanny: (m['unreadCount']?['nanny'] as num?)?.toInt() ?? 0,
      ),
      trialId: m['trialId'],
      trialStatus: m['trialStatus'] as String?,
      status: m['status'] == 'archived' ? ChatStatus.archived : ChatStatus.active,
    );
  }

  Query<Map<String, dynamic>> _messagesQuery(String threadId) => _threads
      .doc(threadId)
      .collection('messages')
      .orderBy('createdAt', descending: false)
      .limit(100);

  ChatMessage _messageFromDoc(
      String threadId, QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final rawAtt = m['attachments'];
    final attachments = rawAtt is List
        ? rawAtt
            .whereType<Map>()
            .map(
              (a) => Attachment(
                type: (a['type'] ?? 'image').toString(),
                url: (a['url'] ?? '').toString(),
                name: (a['name'] ?? 'file').toString(),
              ),
            )
            .toList()
        : <Attachment>[];
    return ChatMessage(
      id: d.id,
      threadId: threadId,
      senderId: m['senderId'] ?? '',
      senderType: m['senderType'] ?? 'family',
      content: m['content'] ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values
          .firstWhere((e) => e.name == m['type'], orElse: () => MessageType.text),
      readAt: (m['readAt'] as Timestamp?)?.toDate(),
      trialOfferId: m['trialOfferId'] as String?,
      attachments: attachments,
    );
  }

  @override
  Future<List<ChatMessage>> loadMessages(String threadId) async {
    final snap = await _messagesQuery(threadId).get();
    return snap.docs.map((d) => _messageFromDoc(threadId, d)).toList();
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId) => _messagesQuery(threadId)
      .snapshots()
      .map((s) => s.docs.map((d) => _messageFromDoc(threadId, d)).toList());

  @override
  Future<void> sendMessage(String threadId, ChatMessage message) async {
    final batch = FirebaseFirestore.instance.batch();

    final msgRef = _threads.doc(threadId).collection('messages').doc(message.id);
    final payload = <String, dynamic>{
      'senderId': message.senderId,
      'senderType': message.senderType,
      'content': message.content,
      'type': message.type.name,
      'createdAt': FieldValue.serverTimestamp(),
      if (message.attachments.isNotEmpty)
        'attachments': message.attachments.map((a) => a.toMap()).toList(),
      if (message.trialOfferId != null) 'trialOfferId': message.trialOfferId,
    };
    batch.set(msgRef, payload);

    final threadRef = _threads.doc(threadId);
    batch.update(threadRef, {
      'lastMessage': message.content,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.${message.senderType == 'family' ? 'nanny' : 'family'}': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<ChatThread> findOrCreateThread({
    required String familyId,
    required String nannyId,
    String? nannyName,
    String? familyName,
  }) async {
    final snap = await _threads
        .where('familyId', isEqualTo: familyId)
        .where('nannyId', isEqualTo: nannyId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      return _threadFromDoc(snap.docs.first);
    }

    final doc = _threads.doc();
    final now = FieldValue.serverTimestamp();
    await doc.set({
      'familyId': familyId,
      'nannyId': nannyId,
      'familyName': familyName ?? '',
      'nannyName': nannyName ?? 'Nanny',
      'createdAt': now,
      'lastMessageAt': now,
      'lastMessage': '',
      'unreadCount': {'family': 0, 'nanny': 0},
      'status': 'active',
    });

    final fresh = await doc.get();
    if (!fresh.exists || fresh.data() == null) {
      throw StateError('thread_create_failed');
    }
    return _threadFromSnapshot(fresh);
  }

  @override
  Future<void> linkTrialToThread(String threadId, String trialId,
      {String? lastMessage, String? trialStatus}) async {
    final updates = <String, dynamic>{
      'trialId': trialId,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (lastMessage != null) updates['lastMessage'] = lastMessage;
    if (trialStatus != null) updates['trialStatus'] = trialStatus;
    await _threads.doc(threadId).update(updates);
  }

  @override
  Future<void> markThreadRead(String threadId, String readerRole) async {
    await _threads.doc(threadId).update({
      'unreadCount.$readerRole': 0,
    });
  }
}
