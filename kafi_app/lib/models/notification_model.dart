enum NotificationType {
  newMessage,
  newApplication,
  applicationViewed,
  applicationDeclined,
  trialOfferReceived,
  trialAccepted,
  trialDeclined,
  trialCountered,
  trialStartingSoon,
  trialEndingSoon,
  trialCompleted,
  hired,
  profileViewed,
  documentsApproved,
  documentsRejected,
  profileVerified,
  subscriptionExpiring,
  subscriptionRenewed,
  subscriptionExpired,
  freeContactsLow,
  systemAnnouncement,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.read = false,
    required this.createdAt,
    this.readAt,
  });

  AppNotification copyWith({
    bool? read,
    DateTime? readAt,
  }) =>
      AppNotification(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        read: read ?? this.read,
        createdAt: createdAt,
        readAt: readAt ?? this.readAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: (m['id'] ?? '').toString(),
        userId: (m['userId'] ?? '').toString(),
        type: NotificationType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => NotificationType.systemAnnouncement,
        ),
        title: (m['title'] ?? '').toString(),
        body: (m['body'] ?? '').toString(),
        data: m['data'] is Map ? Map<String, dynamic>.from(m['data'] as Map) : const {},
        read: m['read'] as bool? ?? false,
        createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
        readAt: _parseDate(m['readAt']),
      );

  /// Tolerates Firestore Timestamps, ISO strings, ints (epoch ms), and DateTimes.
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    // Avoid hard dep on cloud_firestore here — duck-type with a runtime check.
    try {
      // Firestore Timestamp has `.toDate()`.
      final maybeTs = (v as dynamic).toDate;
      if (maybeTs is Function) return v.toDate() as DateTime;
    } catch (_) {}
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
