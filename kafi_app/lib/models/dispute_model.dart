import 'package:cloud_firestore/cloud_firestore.dart';

enum DisputeCategory { fraud, abuse, noShow, payment, other }

enum DisputeStatus { open, investigating, resolved, dismissed }

extension DisputeCategoryX on DisputeCategory {
  String get value => switch (this) {
        DisputeCategory.fraud => 'fraud',
        DisputeCategory.abuse => 'abuse',
        DisputeCategory.noShow => 'no_show',
        DisputeCategory.payment => 'payment',
        DisputeCategory.other => 'other',
      };

  static DisputeCategory fromString(String v) => switch (v) {
        'fraud' => DisputeCategory.fraud,
        'abuse' => DisputeCategory.abuse,
        'no_show' => DisputeCategory.noShow,
        'payment' => DisputeCategory.payment,
        _ => DisputeCategory.other,
      };
}

extension DisputeStatusX on DisputeStatus {
  String get value => switch (this) {
        DisputeStatus.open => 'open',
        DisputeStatus.investigating => 'investigating',
        DisputeStatus.resolved => 'resolved',
        DisputeStatus.dismissed => 'dismissed',
      };

  static DisputeStatus fromString(String v) => switch (v) {
        'investigating' => DisputeStatus.investigating,
        'resolved' => DisputeStatus.resolved,
        'dismissed' => DisputeStatus.dismissed,
        _ => DisputeStatus.open,
      };
}

class DisputeModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final DisputeCategory category;
  final String description;
  final DisputeStatus status;
  final String? relatedTrialId;
  final String? resolution;
  final DateTime createdAt;

  const DisputeModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.category,
    required this.description,
    this.status = DisputeStatus.open,
    this.relatedTrialId,
    this.resolution,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'category': category.value,
        'description': description,
        'status': status.value,
        if (relatedTrialId != null) 'relatedTrialId': relatedTrialId,
        if (resolution != null) 'resolution': resolution,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory DisputeModel.fromMap(String id, Map<String, dynamic> m) {
    return DisputeModel(
      id: id,
      reporterId: m['reporterId']?.toString() ?? '',
      reportedUserId: m['reportedUserId']?.toString() ?? '',
      category: DisputeCategoryX.fromString(m['category']?.toString() ?? ''),
      description: m['description']?.toString() ?? '',
      status: DisputeStatusX.fromString(m['status']?.toString() ?? ''),
      relatedTrialId: m['relatedTrialId']?.toString(),
      resolution: m['resolution']?.toString(),
      createdAt: _parseDisputeDate(m['createdAt']),
    );
  }
}

DateTime _parseDisputeDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}

/// A single message in a dispute's support conversation (reporter ↔ admin),
/// living in the `disputes/{id}/messages` subcollection. `senderType` is
/// 'user' or 'admin' — the security rules pin a non-admin to 'user'.
class DisputeMessage {
  const DisputeMessage({
    required this.id,
    required this.disputeId,
    required this.senderId,
    required this.senderType,
    this.senderName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String disputeId;
  final String senderId;
  final String senderType;
  final String? senderName;
  final String content;
  final DateTime createdAt;

  bool get isAdmin => senderType == 'admin';

  Map<String, dynamic> toMap() => {
        'disputeId': disputeId,
        'senderId': senderId,
        'senderType': senderType,
        if (senderName != null) 'senderName': senderName,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DisputeMessage.fromMap(String id, Map<String, dynamic> m) => DisputeMessage(
        id: id,
        disputeId: (m['disputeId'] ?? '').toString(),
        senderId: (m['senderId'] ?? '').toString(),
        senderType: (m['senderType'] ?? 'user').toString(),
        senderName: m['senderName']?.toString(),
        content: (m['content'] ?? '').toString(),
        createdAt: _parseDisputeDate(m['createdAt']),
      );
}
