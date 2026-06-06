/// Per System Spec §3.7
enum MessageType {
  text,
  image,
  trialOffer,
  trialAccepted,
  trialDeclined,
  trialCountered,
  system,
}

/// Per System Spec §3.7
class Attachment {
  const Attachment({
    required this.type,
    required this.url,
    required this.name,
  });

  final String type;
  final String url;
  final String name;

  Map<String, dynamic> toMap() => {
        'type': type,
        'url': url,
        'name': name,
      };
}

/// Per System Spec §3.7
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.createdAt,
    this.type = MessageType.text,
    this.attachments = const [],
    this.trialOfferId,
    this.readAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String senderType;
  final String content;
  final DateTime createdAt;
  final MessageType type;
  final List<Attachment> attachments;
  final String? trialOfferId;
  final DateTime? readAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'threadId': threadId,
        'senderId': senderId,
        'senderType': senderType,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'trialOfferId': trialOfferId,
        'readAt': readAt?.toIso8601String(),
      };
}

/// Per System Spec §3.7
class UnreadCount {
  const UnreadCount({
    this.family = 0,
    this.nanny = 0,
  });

  final int family;
  final int nanny;

  Map<String, dynamic> toMap() => {
        'family': family,
        'nanny': nanny,
      };
}

/// Per System Spec §3.7
enum ChatStatus { active, archived }

/// Per System Spec §3.7
class ChatThread {
  const ChatThread({
    required this.id,
    required this.familyId,
    required this.nannyId,
    this.familyName = '',
    this.nannyName = '',
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage = '',
    this.unreadCount = const UnreadCount(),
    this.trialId,
    this.trialStatus,
    this.status = ChatStatus.active,
  });

  final String id;
  final String familyId;
  final String nannyId;
  final String familyName;
  final String nannyName;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessage;
  final UnreadCount unreadCount;
  final String? trialId;
  /// Cached trial status string (`active`, `pending`, etc.) to avoid loading trial doc.
  final String? trialStatus;
  final ChatStatus status;

  /// Trial bypass per spec §6.6 — allowed when the linked trial is either
  /// accepted (paid, awaiting start) or active (running). pending / declined
  /// / cancelled / completed all do NOT bypass.
  bool get hasActiveTrial =>
      trialId != null && (trialStatus == 'active' || trialStatus == 'accepted');

  bool get hasPendingTrial => trialId != null && trialStatus == 'pending';

  ChatThread copyWith({
    String? familyName,
    String? nannyName,
    DateTime? lastMessageAt,
    String? lastMessage,
    UnreadCount? unreadCount,
    String? trialId,
    String? trialStatus,
    ChatStatus? status,
  }) =>
      ChatThread(
        id: id,
        familyId: familyId,
        nannyId: nannyId,
        familyName: familyName ?? this.familyName,
        nannyName: nannyName ?? this.nannyName,
        createdAt: createdAt,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        trialId: trialId ?? this.trialId,
        trialStatus: trialStatus ?? this.trialStatus,
        status: status ?? this.status,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'nannyId': nannyId,
        'familyName': familyName,
        'nannyName': nannyName,
        'createdAt': createdAt.toIso8601String(),
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'lastMessage': lastMessage,
        'unreadCount': unreadCount.toMap(),
        'trialId': trialId,
        'trialStatus': trialStatus,
        'status': status.name,
      };
}
