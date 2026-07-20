import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';

class MockDisputeService implements IDisputeService {
  final _store = <String, DisputeModel>{};
  final _messages = <String, List<DisputeMessage>>{};
  int _seq = 0;
  int _msgSeq = 0;

  @override
  Future<String> fileDispute({
    required String reporterId,
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
  }) async {
    final id = 'dispute_${++_seq}';
    _store[id] = DisputeModel(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      category: category,
      description: description,
      relatedTrialId: relatedTrialId,
      createdAt: DateTime.now(),
    );
    return id;
  }

  @override
  Future<List<DisputeModel>> getMyDisputes(String userId) async {
    return _store.values.where((d) => d.reporterId == userId).toList();
  }

  @override
  Future<DisputeModel?> getDispute(String disputeId) async => _store[disputeId];

  @override
  Stream<List<DisputeMessage>> watchMessages(String disputeId) =>
      Stream.value(List.of(_messages[disputeId] ?? const []));

  @override
  Future<List<DisputeMessage>> loadMessages(String disputeId) async =>
      List.of(_messages[disputeId] ?? const []);

  @override
  Future<void> sendMessage(String disputeId, DisputeMessage message) async {
    _messages.putIfAbsent(disputeId, () => []).add(
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
  }
}
