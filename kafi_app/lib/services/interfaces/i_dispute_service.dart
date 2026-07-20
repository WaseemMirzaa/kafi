import 'package:kafi_app/models/dispute_model.dart';

abstract class IDisputeService {
  /// File a new dispute. Returns the created dispute doc id.
  Future<String> fileDispute({
    required String reporterId,
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
  });

  Future<List<DisputeModel>> getMyDisputes(String userId);

  /// A single dispute (for the chat header + live status/resolution).
  Future<DisputeModel?> getDispute(String disputeId);

  /// Live message stream for a dispute's support conversation.
  Stream<List<DisputeMessage>> watchMessages(String disputeId);

  /// One-shot message load (bootstrap before the stream resolves).
  Future<List<DisputeMessage>> loadMessages(String disputeId);

  /// Posts a message from the reporter (senderType is pinned to 'user').
  Future<void> sendMessage(String disputeId, DisputeMessage message);
}
