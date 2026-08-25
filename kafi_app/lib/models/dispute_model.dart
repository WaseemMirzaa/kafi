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

/// Best-effort profile fields captured at report file time for admin context.
class DisputeUserSnapshot {
  const DisputeUserSnapshot({
    this.phone,
    this.city,
    this.nationality,
    this.status,
  });

  final String? phone;
  final String? city;
  final String? nationality;
  final String? status;

  Map<String, dynamic> toMap() => {
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (nationality != null && nationality!.isNotEmpty) 'nationality': nationality,
        if (status != null && status!.isNotEmpty) 'status': status,
      };

  factory DisputeUserSnapshot.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const DisputeUserSnapshot();
    return DisputeUserSnapshot(
      phone: m['phone']?.toString(),
      city: m['city']?.toString(),
      nationality: m['nationality']?.toString(),
      status: m['status']?.toString(),
    );
  }

  bool get isEmpty =>
      (phone == null || phone!.isEmpty) &&
      (city == null || city!.isEmpty) &&
      (nationality == null || nationality!.isEmpty) &&
      (status == null || status!.isEmpty);
}

/// Evidence file attached when filing a report (image or PDF).
class DisputeAttachment {
  const DisputeAttachment({
    required this.id,
    required this.url,
    required this.storagePath,
    required this.name,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  final String id;
  final String url;
  final String storagePath;
  final String name;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;

  bool get isImage => contentType.toLowerCase().startsWith('image/');
  bool get isPdf => contentType.toLowerCase() == 'application/pdf';

  Map<String, dynamic> toMap() => {
        'id': id,
        'url': url,
        'storagePath': storagePath,
        'name': name,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory DisputeAttachment.fromMap(Map<String, dynamic> m) => DisputeAttachment(
        id: m['id']?.toString() ?? '',
        url: m['url']?.toString() ?? '',
        storagePath: m['storagePath']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        contentType: m['contentType']?.toString() ?? '',
        sizeBytes: (m['sizeBytes'] is num) ? (m['sizeBytes'] as num).toInt() : 0,
        uploadedAt: _parseDisputeDate(m['uploadedAt']),
      );
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
  final String? reporterName;
  final String? reporterType;
  final String? reportedName;
  final String? reportedType;
  final DisputeUserSnapshot? reporterSnapshot;
  final DisputeUserSnapshot? reportedSnapshot;
  final List<DisputeAttachment> attachments;

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
    this.reporterName,
    this.reporterType,
    this.reportedName,
    this.reportedType,
    this.reporterSnapshot,
    this.reportedSnapshot,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'category': category.value,
        'description': description,
        'status': status.value,
        if (relatedTrialId != null) 'relatedTrialId': relatedTrialId,
        if (resolution != null) 'resolution': resolution,
        if (reporterName != null) 'reporterName': reporterName,
        if (reporterType != null) 'reporterType': reporterType,
        if (reportedName != null) 'reportedName': reportedName,
        if (reportedType != null) 'reportedType': reportedType,
        if (reporterSnapshot != null && !reporterSnapshot!.isEmpty)
          'reporterSnapshot': reporterSnapshot!.toMap(),
        if (reportedSnapshot != null && !reportedSnapshot!.isEmpty)
          'reportedSnapshot': reportedSnapshot!.toMap(),
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory DisputeModel.fromMap(String id, Map<String, dynamic> m) {
    final rawAtt = m['attachments'];
    final attachments = <DisputeAttachment>[];
    if (rawAtt is List) {
      for (final item in rawAtt) {
        if (item is Map) {
          attachments.add(
            DisputeAttachment.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    Map<String, dynamic>? snapMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

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
      reporterName: m['reporterName']?.toString(),
      reporterType: m['reporterType']?.toString(),
      reportedName: m['reportedName']?.toString(),
      reportedType: m['reportedType']?.toString(),
      reporterSnapshot: DisputeUserSnapshot.fromMap(snapMap(m['reporterSnapshot'])),
      reportedSnapshot: DisputeUserSnapshot.fromMap(snapMap(m['reportedSnapshot'])),
      attachments: attachments,
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
