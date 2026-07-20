import 'package:cloud_firestore/cloud_firestore.dart';

/// What a support ticket is about. `trial`/`hiring` let a user raise an issue
/// during a trial or an active hire (the two contexts the product cares about).
enum TicketCategory { account, payment, trial, hiring, technical, other }

/// Lifecycle of a ticket. `open` → `investigating` (admin engaged) → `resolved`
/// → `closed`.
enum TicketStatus { open, investigating, resolved, closed }

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// A support ticket a user (family or nanny) opens with admin. The conversation
/// lives in a `tickets/{id}/messages` subcollection. Distinct from disputes,
/// which are conduct/payment reports about another user.
class TicketModel {
  const TicketModel({
    required this.id,
    required this.openerId,
    required this.openerType,
    required this.subject,
    this.category = TicketCategory.other,
    this.status = TicketStatus.open,
    this.relatedTrialId,
    this.lastMessage,
    required this.createdAt,
    this.lastMessageAt,
  });

  final String id;

  /// The user id of whoever opened the ticket.
  final String openerId;

  /// 'family' | 'nanny' — denormalized so the admin queue renders without a lookup.
  final String openerType;
  final String subject;
  final TicketCategory category;
  final TicketStatus status;

  /// Optional context when the ticket is raised during a trial/hire.
  final String? relatedTrialId;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  bool get isClosed => status == TicketStatus.resolved || status == TicketStatus.closed;

  TicketModel copyWith({
    TicketStatus? status,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) =>
      TicketModel(
        id: id,
        openerId: openerId,
        openerType: openerType,
        subject: subject,
        category: category,
        status: status ?? this.status,
        relatedTrialId: relatedTrialId,
        lastMessage: lastMessage ?? this.lastMessage,
        createdAt: createdAt,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      );

  Map<String, dynamic> toMap() => {
        'openerId': openerId,
        'openerType': openerType,
        'subject': subject,
        'category': category.name,
        'status': status.name,
        if (relatedTrialId != null) 'relatedTrialId': relatedTrialId,
        if (lastMessage != null) 'lastMessage': lastMessage,
        'createdAt': createdAt.toIso8601String(),
        if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
      };

  factory TicketModel.fromMap(String id, Map<String, dynamic> m) => TicketModel(
        id: id,
        openerId: (m['openerId'] ?? '').toString(),
        openerType: (m['openerType'] ?? 'family').toString(),
        subject: (m['subject'] ?? '').toString(),
        category: TicketCategory.values.firstWhere(
          (e) => e.name == m['category'],
          orElse: () => TicketCategory.other,
        ),
        status: TicketStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => TicketStatus.open,
        ),
        relatedTrialId: m['relatedTrialId']?.toString(),
        lastMessage: m['lastMessage']?.toString(),
        createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
        lastMessageAt: _parseDate(m['lastMessageAt']),
      );
}

/// A single message in a ticket conversation. `senderType` is 'user' or
/// 'admin' (the rules pin a non-admin to 'user').
class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String senderId;
  final String senderType;
  final String content;
  final DateTime createdAt;

  bool get isAdmin => senderType == 'admin';

  Map<String, dynamic> toMap() => {
        'ticketId': ticketId,
        'senderId': senderId,
        'senderType': senderType,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TicketMessage.fromMap(String id, Map<String, dynamic> m) => TicketMessage(
        id: id,
        ticketId: (m['ticketId'] ?? '').toString(),
        senderId: (m['senderId'] ?? '').toString(),
        senderType: (m['senderType'] ?? 'user').toString(),
        content: (m['content'] ?? '').toString(),
        createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
      );
}
