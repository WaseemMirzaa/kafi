import 'package:cloud_firestore/cloud_firestore.dart';

/// Accepts Firestore `Timestamp`, native `DateTime`, ISO `String`, or epoch
/// `int` so models hydrate cleanly whether the source is a server-side write
/// (`FieldValue.serverTimestamp()`) or a local mock seed.
DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

enum ApplicationStatus {
  pending,
  viewed,
  shortlisted,
  trialOffered,
  declined,
  withdrawn,
  hired,
}

class ApplicationModel {
  final String id;
  final String jobPostId;
  final String nannyId;
  final String familyId;
  final ApplicationStatus status;
  final int matchScore;
  final String? coverMessage;
  final DateTime createdAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final DateTime? withdrawnAt;

  const ApplicationModel({
    required this.id,
    required this.jobPostId,
    required this.nannyId,
    required this.familyId,
    required this.status,
    this.matchScore = 0,
    this.coverMessage,
    required this.createdAt,
    this.viewedAt,
    this.respondedAt,
    this.withdrawnAt,
  });

  ApplicationModel copyWith({
    ApplicationStatus? status,
    DateTime? viewedAt,
    DateTime? respondedAt,
    DateTime? withdrawnAt,
  }) =>
      ApplicationModel(
        id: id,
        jobPostId: jobPostId,
        nannyId: nannyId,
        familyId: familyId,
        status: status ?? this.status,
        matchScore: matchScore,
        coverMessage: coverMessage,
        createdAt: createdAt,
        viewedAt: viewedAt ?? this.viewedAt,
        respondedAt: respondedAt ?? this.respondedAt,
        withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobPostId': jobPostId,
        'nannyId': nannyId,
        'familyId': familyId,
        'status': status.name,
        'matchScore': matchScore,
        'coverMessage': coverMessage,
        'createdAt': createdAt.toIso8601String(),
        'viewedAt': viewedAt?.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'withdrawnAt': withdrawnAt?.toIso8601String(),
      };

  factory ApplicationModel.fromMap(Map<String, dynamic> m) => ApplicationModel(
        id: (m['id'] ?? '').toString(),
        jobPostId: (m['jobPostId'] ?? '').toString(),
        nannyId: (m['nannyId'] ?? '').toString(),
        familyId: (m['familyId'] ?? '').toString(),
        status: ApplicationStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => ApplicationStatus.pending,
        ),
        matchScore: (m['matchScore'] as num?)?.toInt() ?? 0,
        coverMessage: m['coverMessage']?.toString(),
        createdAt: _parseDate(m['createdAt']) ?? DateTime.now(),
        viewedAt: _parseDate(m['viewedAt']),
        respondedAt: _parseDate(m['respondedAt']),
        withdrawnAt: _parseDate(m['withdrawnAt']),
      );
}
