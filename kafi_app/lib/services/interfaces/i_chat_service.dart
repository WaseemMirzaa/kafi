import 'package:kafi_app/models/chat_models.dart';

abstract class IChatService {
  /// [userId] — family or nanny account id (threads matched on either side).
  Future<List<ChatThread>> listThreads(String userId);

  /// Live stream of [userId]'s threads, newest-activity first. Emits on every
  /// change (new message, unread count, trial link) so the list stays current.
  Stream<List<ChatThread>> watchThreads(String userId);

  Future<List<ChatMessage>> loadMessages(String threadId);

  /// Live stream of the messages in [threadId], oldest→newest. Firestore's
  /// latency compensation echoes the sender's own messages instantly.
  Stream<List<ChatMessage>> watchMessages(String threadId);

  Future<void> sendMessage(String threadId, ChatMessage message);

  /// Creates or returns existing thread between family and nanny.
  Future<ChatThread> findOrCreateThread({
    required String familyId,
    required String nannyId,
    String? nannyName,
    String? familyName,
  });

  /// Links a pending/active trial to the chat thread (for lockdown exception).
  /// [trialStatus] should reflect the trial's current status (e.g. `pending`, `active`).
  Future<void> linkTrialToThread(String threadId, String trialId,
      {String? lastMessage, String? trialStatus});

  /// Resets unread count for [threadId] from the perspective of [readerRole].
  Future<void> markThreadRead(String threadId, String readerRole);
}
