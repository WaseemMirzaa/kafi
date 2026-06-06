import 'package:cloud_firestore/cloud_firestore.dart';

/// Per System Spec §3.6
enum TrialStatus { pending, countered, accepted, declined, active, completed, cancelled }

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// Per System Spec §3.6
class CounterOffer {
  const CounterOffer({
    required this.dailyRate,
    required this.startDate,
    this.message,
    this.createdAt,
    this.status = 'pending',
  });

  final int dailyRate;
  final DateTime startDate;
  final String? message;
  final DateTime? createdAt;
  final String status;

  Map<String, dynamic> toMap() => {
        'dailyRate': dailyRate,
        'startDate': startDate.toIso8601String(),
        'message': message,
        'createdAt': createdAt?.toIso8601String(),
        'status': status,
      };
}

/// Per System Spec §3.6
class TrialEvaluation {
  const TrialEvaluation({
    this.childInteractionAndPatience = false,
    this.punctualityAndReliability = false,
    this.followingInstructions = false,
    this.communicationAndLanguage = false,
    this.cookingFamilyFood = false,
    this.honestyAndTrustworthiness = false,
    this.additionalNotes,
  });

  final bool childInteractionAndPatience;
  final bool punctualityAndReliability;
  final bool followingInstructions;
  final bool communicationAndLanguage;
  final bool cookingFamilyFood;
  final bool honestyAndTrustworthiness;
  final String? additionalNotes;

  Map<String, dynamic> toMap() => {
        'childInteractionAndPatience': childInteractionAndPatience,
        'punctualityAndReliability': punctualityAndReliability,
        'followingInstructions': followingInstructions,
        'communicationAndLanguage': communicationAndLanguage,
        'cookingFamilyFood': cookingFamilyFood,
        'honestyAndTrustworthiness': honestyAndTrustworthiness,
        'additionalNotes': additionalNotes,
      };
}

/// Complete Trial model per System Spec §3.6
class TrialModel {
  TrialModel({
    required this.id,
    required this.familyId,
    required this.nannyId,
    this.jobPostId,
    required this.durationDays,
    required this.dailyRate,
    required this.startDate,
    this.startTime = '',
    DateTime? endDate,
    this.trialType = 'live-in',
    this.location = '',
    this.notes,
    this.status = TrialStatus.pending,
    DateTime? offeredAt,
    this.respondedAt,
    this.startedAt,
    this.completedAt,
    this.counterOffer,
    this.evaluation,
    this.outcome,
    this.outcomeAt,
    this.nannyConfirmedPayment = false,
    this.paymentIssueReported = false,
  })  : endDate = endDate ?? startDate.add(Duration(days: durationDays)),
        offeredAt = offeredAt ?? DateTime.now();

  final String id;
  final String familyId;
  final String nannyId;
  final String? jobPostId;
  final int durationDays;
  final int dailyRate;
  final DateTime startDate;
  final String startTime;
  final DateTime endDate;
  final String trialType;
  final String location;
  final String? notes;
  final TrialStatus status;
  final DateTime offeredAt;
  final DateTime? respondedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final CounterOffer? counterOffer;
  final TrialEvaluation? evaluation;
  final String? outcome;
  final DateTime? outcomeAt;
  final bool nannyConfirmedPayment;
  final bool paymentIssueReported;

  /// Only TRUE when trial is in execution phase (after start date reached, before end).
  bool get isActive => status == TrialStatus.active;

  /// Accepted but not yet started — used for pre-start UI.
  bool get isAccepted => status == TrialStatus.accepted;

  /// Counts both accepted (pre-start) and active (running) — used to lock new trial offers.
  bool get isAcceptedOrActive => status == TrialStatus.accepted || status == TrialStatus.active;

  Duration get remaining => endDate.difference(DateTime.now());

  int get totalAmount => dailyRate * durationDays;

  TrialModel copyWith({
    TrialStatus? status,
    DateTime? respondedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    CounterOffer? counterOffer,
    TrialEvaluation? evaluation,
    String? outcome,
    DateTime? outcomeAt,
    bool? nannyConfirmedPayment,
    bool? paymentIssueReported,
  }) =>
      TrialModel(
        id: id,
        familyId: familyId,
        nannyId: nannyId,
        jobPostId: jobPostId,
        durationDays: durationDays,
        dailyRate: dailyRate,
        startDate: startDate,
        startTime: startTime,
        endDate: endDate,
        trialType: trialType,
        location: location,
        notes: notes,
        status: status ?? this.status,
        offeredAt: offeredAt,
        respondedAt: respondedAt ?? this.respondedAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        counterOffer: counterOffer ?? this.counterOffer,
        evaluation: evaluation ?? this.evaluation,
        outcome: outcome ?? this.outcome,
        outcomeAt: outcomeAt ?? this.outcomeAt,
        nannyConfirmedPayment: nannyConfirmedPayment ?? this.nannyConfirmedPayment,
        paymentIssueReported: paymentIssueReported ?? this.paymentIssueReported,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'nannyId': nannyId,
        'jobPostId': jobPostId,
        'durationDays': durationDays,
        'dailyRate': dailyRate,
        'startDate': startDate.toIso8601String(),
        'startTime': startTime,
        'endDate': endDate.toIso8601String(),
        'trialType': trialType,
        'location': location,
        'notes': notes,
        'status': status.name,
        'offeredAt': offeredAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'counterOffer': counterOffer?.toMap(),
        'evaluation': evaluation?.toMap(),
        'outcome': outcome,
        'outcomeAt': outcomeAt?.toIso8601String(),
        'nannyConfirmedPayment': nannyConfirmedPayment,
        'paymentIssueReported': paymentIssueReported,
      };

  /// Tolerates Firestore Timestamps and partial payloads. Use everywhere a
  /// `TrialModel` is loaded from Firestore / mock seeds.
  factory TrialModel.fromMap(Map<String, dynamic> m) {
    CounterOffer? co;
    final cm = m['counterOffer'];
    if (cm is Map) {
      co = CounterOffer(
        dailyRate: (cm['dailyRate'] as num?)?.toInt() ?? 0,
        startDate: _parseDate(cm['startDate']) ?? DateTime.now(),
        message: cm['message']?.toString(),
        createdAt: _parseDate(cm['createdAt']),
        status: (cm['status'] ?? 'pending').toString(),
      );
    }
    TrialEvaluation? ev;
    final em = m['evaluation'];
    if (em is Map) {
      ev = TrialEvaluation(
        childInteractionAndPatience: em['childInteractionAndPatience'] == true,
        punctualityAndReliability: em['punctualityAndReliability'] == true,
        followingInstructions: em['followingInstructions'] == true,
        communicationAndLanguage: em['communicationAndLanguage'] == true,
        cookingFamilyFood: em['cookingFamilyFood'] == true,
        honestyAndTrustworthiness: em['honestyAndTrustworthiness'] == true,
        additionalNotes: em['additionalNotes']?.toString(),
      );
    }
    return TrialModel(
      id: (m['id'] ?? '').toString(),
      familyId: (m['familyId'] ?? '').toString(),
      nannyId: (m['nannyId'] ?? '').toString(),
      jobPostId: m['jobPostId']?.toString(),
      durationDays: (m['durationDays'] as num?)?.toInt() ?? 7,
      dailyRate: (m['dailyRate'] as num?)?.toInt() ?? 0,
      startDate: _parseDate(m['startDate']) ?? DateTime.now(),
      startTime: (m['startTime'] ?? '').toString(),
      endDate: _parseDate(m['endDate']),
      trialType: (m['trialType'] ?? 'live-in').toString(),
      location: (m['location'] ?? '').toString(),
      notes: m['notes']?.toString(),
      status: TrialStatus.values.firstWhere(
        (e) => e.name == m['status'],
        orElse: () => TrialStatus.pending,
      ),
      offeredAt: _parseDate(m['offeredAt']),
      respondedAt: _parseDate(m['respondedAt']),
      startedAt: _parseDate(m['startedAt']),
      completedAt: _parseDate(m['completedAt']),
      counterOffer: co,
      evaluation: ev,
      outcome: m['outcome']?.toString(),
      outcomeAt: _parseDate(m['outcomeAt']),
      nannyConfirmedPayment: m['nannyConfirmedPayment'] == true,
      paymentIssueReported: m['paymentIssueReported'] == true,
    );
  }
}
