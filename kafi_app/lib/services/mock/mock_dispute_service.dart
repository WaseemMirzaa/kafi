import 'dart:async';

import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';

class MockDisputeService implements IDisputeService {
  final _store = <String, DisputeModel>{};
  final _messages = <String, List<DisputeMessage>>{};
  final _msgControllers = <String, StreamController<List<DisputeMessage>>>{};
  final _disputeControllers = <String, StreamController<DisputeModel?>>{};
  int _seq = 0;
  int _msgSeq = 0;

  StreamController<List<DisputeMessage>> _msgCtrl(String disputeId) =>
      _msgControllers.putIfAbsent(disputeId, () => StreamController.broadcast());

  StreamController<DisputeModel?> _disputeCtrl(String disputeId) =>
      _disputeControllers.putIfAbsent(disputeId, () => StreamController.broadcast());

  void _emitDispute(String disputeId) {
    final c = _disputeControllers[disputeId];
    if (c != null && !c.isClosed) c.add(_store[disputeId]);
  }

  @override
  Future<String> fileDispute({
    required String reporterId,
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
    String? disputeId,
    String? reporterName,
    String? reporterType,
    String? reportedName,
    String? reportedType,
    DisputeUserSnapshot? reporterSnapshot,
    DisputeUserSnapshot? reportedSnapshot,
    List<DisputeAttachment> attachments = const [],
  }) async {
    final id = (disputeId != null && disputeId.isNotEmpty) ? disputeId : 'dispute_${++_seq}';
    _store[id] = DisputeModel(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      category: category,
      description: description,
      relatedTrialId: relatedTrialId,
      createdAt: DateTime.now(),
      reporterName: reporterName,
      reporterType: reporterType,
      reportedName: reportedName,
      reportedType: reportedType,
      reporterSnapshot: reporterSnapshot,
      reportedSnapshot: reportedSnapshot,
      attachments: attachments,
    );
    _emitDispute(id);
    return id;
  }

  @override
  Future<List<DisputeModel>> getMyDisputes(String userId) async {
    return _store.values.where((d) => d.reporterId == userId).toList();
  }

  @override
  Future<DisputeModel?> getDispute(String disputeId) async => _store[disputeId];

  @override
  Stream<DisputeModel?> watchDispute(String disputeId) {
    final c = _disputeCtrl(disputeId);
    scheduleMicrotask(() => c.add(_store[disputeId]));
    return c.stream;
  }

  @override
  Stream<List<DisputeMessage>> watchMessages(String disputeId) {
    final c = _msgCtrl(disputeId);
    scheduleMicrotask(() => c.add(List.of(_messages[disputeId] ?? const [])));
    return c.stream;
  }

  @override
  Future<List<DisputeMessage>> loadMessages(String disputeId) async =>
      List.of(_messages[disputeId] ?? const []);

  @override
  Future<void> sendMessage(String disputeId, DisputeMessage message) async {
    final list = _messages.putIfAbsent(disputeId, () => []);
    list.add(
      DisputeMessage(
        id: 'dmsg_${++_msgSeq}',
        disputeId: disputeId,
        senderId: message.senderId,
        senderType: 'user',
        senderName: message.senderName,
        content: message.content,
        createdAt: DateTime.now(),
      ),
    );
    _msgCtrl(disputeId).add(List.of(list));
  }

  @override
  Future<void> updateAttachments(
    String disputeId,
    List<DisputeAttachment> attachments,
  ) async {
    final existing = _store[disputeId];
    if (existing == null) return;
    _store[disputeId] = DisputeModel(
      id: existing.id,
      reporterId: existing.reporterId,
      reportedUserId: existing.reportedUserId,
      category: existing.category,
      description: existing.description,
      status: existing.status,
      relatedTrialId: existing.relatedTrialId,
      resolution: existing.resolution,
      createdAt: existing.createdAt,
      reporterName: existing.reporterName,
      reporterType: existing.reporterType,
      reportedName: existing.reportedName,
      reportedType: existing.reportedType,
      reporterSnapshot: existing.reporterSnapshot,
      reportedSnapshot: existing.reportedSnapshot,
      attachments: attachments,
    );
    _emitDispute(disputeId);
  }
}
