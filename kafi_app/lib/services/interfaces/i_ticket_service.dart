import 'package:kafi_app/models/ticket_model.dart';

/// User↔admin support tickets. A user opens a ticket and exchanges messages
/// with admin; status is admin-owned. Realtime message stream mirrors chat.
abstract class ITicketService {
  /// Opens a ticket and returns its id. [firstMessage] seeds the conversation.
  Future<String> openTicket({
    required String openerId,
    required String openerType,
    required String subject,
    required TicketCategory category,
    required String firstMessage,
    String? relatedTrialId,
  });

  /// The user's own tickets, newest first.
  Future<List<TicketModel>> getMyTickets(String userId);

  /// A single ticket (for the detail screen header).
  Future<TicketModel?> getTicket(String ticketId);

  /// Live ticket document (status / lastMessage) so admin resolves show up
  /// without a manual pull-to-refresh.
  Stream<TicketModel?> watchTicket(String ticketId);

  /// Live message stream for a ticket.
  Stream<List<TicketMessage>> watchMessages(String ticketId);

  /// One-shot message load (bootstrap before the stream resolves).
  Future<List<TicketMessage>> loadMessages(String ticketId);

  /// Posts a message and bumps the ticket's lastMessage/lastMessageAt.
  Future<void> sendMessage(String ticketId, TicketMessage message);
}
