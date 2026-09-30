import 'package:kafi_app/models/dispute_model.dart';

abstract class IDisputeService {
  /// File a new dispute. Returns the created dispute doc id.
  /// When [disputeId] is provided, the doc is written at that id (used when
  /// attachments were uploaded to `disputes/{id}/attachments/` first).
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
  });

  Future<List<DisputeModel>> getMyDisputes(String userId);

  /// A single dispute (for the chat header + live status/resolution).
  Future<DisputeModel?> getDispute(String disputeId);

  /// Live dispute document so admin resolve/dismiss (and resolution text)
  /// appear without leaving the screen — mirrors [ITicketService.watchTicket].
  Stream<DisputeModel?> watchDispute(String disputeId);

  /// Live message stream for a dispute's support conversation.
  Stream<List<DisputeMessage>> watchMessages(String disputeId);

  /// One-shot message load (bootstrap before the stream resolves).
  Future<List<DisputeMessage>> loadMessages(String disputeId);

  /// Posts a message from the reporter (senderType is pinned to 'user').
  Future<void> sendMessage(String disputeId, DisputeMessage message);

  /// Reporter patches attachment metadata after Storage uploads complete.
  Future<void> updateAttachments(
    String disputeId,
    List<DisputeAttachment> attachments,
  );
}
