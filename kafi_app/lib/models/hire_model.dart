import 'package:cloud_firestore/cloud_firestore.dart';

/// Accepts Firestore `Timestamp`, native `DateTime`, ISO `String`, or epoch
/// `int` so the model hydrates cleanly whether the source is a server-side
/// write (`FieldValue.serverTimestamp()`) or a local mock seed.
DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Employment status of a hire. A hire is `active` from the moment a family
/// hires a nanny (after a trial) until either side ends it.
enum HireStatus { active, ended }

/// Why a hire ended. `resigned` = nanny left, `terminated` = family ended,
/// `completed` = mutually finished / contract ran its course.
enum HireEndReason { resigned, terminated, completed }

/// A concrete employment relationship between a family and a nanny — created
/// when a family taps "Hire" at the end of a trial (design: hiring is only
/// reachable after a trial with that nanny). Distinct from the trial: the
/// trial is the evaluation, the hire is the ongoing job.
class HireModel {
  const HireModel({
    required this.id,
    required this.familyId,
    required this.nannyId,
    this.jobPostId,
    this.trialId,
    this.employmentType = 'live-in',
    this.salaryAed = 0,
    this.status = HireStatus.active,
    this.endReason,
    required this.startedAt,
    this.endedAt,
    this.endNote,
    this.nannyName,
    this.familyName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? startedAt;

  final String id;
  final String familyId;

  /// The nanny's **user id** (`nannies/{uid}`), so `getHiresForNanny` resolves
  /// when the nanny signs in.
  final String nannyId;
  final String? jobPostId;
  final String? trialId;

  /// 'live-in' | 'live-out' — carried over from the trial.
  final String employmentType;

  /// Agreed monthly salary in AED. `0` = not yet set (agreed off-app / later).
  final int salaryAed;

  final HireStatus status;
  final HireEndReason? endReason;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Optional free-text reason captured when the hire is ended.
  final String? endNote;

  /// Denormalized display names written at hire time so the family "My hires"
  /// and nanny "My job" lists render without extra lookups.
  final String? nannyName;
  final String? familyName;
  final DateTime createdAt;

  bool get isActive => status == HireStatus.active;

  HireModel copyWith({
    HireStatus? status,
    HireEndReason? endReason,
    DateTime? endedAt,
    String? endNote,
    int? salaryAed,
  }) =>
      HireModel(
        id: id,
        familyId: familyId,
        nannyId: nannyId,
        jobPostId: jobPostId,
        trialId: trialId,
        employmentType: employmentType,
        salaryAed: salaryAed ?? this.salaryAed,
        status: status ?? this.status,
        endReason: endReason ?? this.endReason,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        endNote: endNote ?? this.endNote,
        nannyName: nannyName,
        familyName: familyName,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'nannyId': nannyId,
        'jobPostId': jobPostId,
        'trialId': trialId,
        'employmentType': employmentType,
        'salaryAed': salaryAed,
        'status': status.name,
        'endReason': endReason?.name,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'endNote': endNote,
        'nannyName': nannyName,
        'familyName': familyName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HireModel.fromMap(Map<String, dynamic> m) => HireModel(
        id: (m['id'] ?? '').toString(),
        familyId: (m['familyId'] ?? '').toString(),
        nannyId: (m['nannyId'] ?? '').toString(),
        jobPostId: m['jobPostId']?.toString(),
        trialId: m['trialId']?.toString(),
        employmentType: (m['employmentType'] ?? 'live-in').toString(),
        salaryAed: (m['salaryAed'] as num?)?.toInt() ?? 0,
        status: HireStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => HireStatus.active,
        ),
        endReason: m['endReason'] == null
            ? null
            : HireEndReason.values.firstWhere(
                (e) => e.name == m['endReason'],
                orElse: () => HireEndReason.completed,
              ),
        startedAt: _parseDate(m['startedAt']) ?? DateTime.now(),
        endedAt: _parseDate(m['endedAt']),
        endNote: m['endNote']?.toString(),
        nannyName: m['nannyName']?.toString(),
        familyName: m['familyName']?.toString(),
        createdAt: _parseDate(m['createdAt']),
      );
}
