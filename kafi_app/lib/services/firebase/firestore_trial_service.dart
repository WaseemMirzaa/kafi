import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';

class FirestoreTrialService implements ITrialService {
  final _trials = FirebaseFirestore.instance.collection('trials');

  @override
  Future<List<TrialModel>> listTrials(String familyId) async {
    final snap = await _trials
        .where('familyId', isEqualTo: familyId)
        .orderBy('offeredAt', descending: true)
        .get();

    return snap.docs.map((d) => _trialFromMap(d.id, d.data())).toList();
  }

  @override
  Future<List<TrialModel>> listTrialsForNanny(String nannyId) async {
    final snap = await _trials
        .where('nannyId', isEqualTo: nannyId)
        .orderBy('offeredAt', descending: true)
        .get();

    return snap.docs.map((d) => _trialFromMap(d.id, d.data())).toList();
  }

  @override
  Future<TrialModel?> getTrial(String trialId) async {
    final doc = await _trials.doc(trialId).get();
    if (!doc.exists) return null;
    return _trialFromMap(doc.id, doc.data()!);
  }

  @override
  Future<TrialModel?> activeTrial(String familyId) async {
    // Includes awaitingOutcome so TrialController.refreshAll() still resolves
    // this trial (and the mutual-outcome UI stays reachable) once the
    // execution window closes — distinct from activeTrialNannyIds() below,
    // the browse-hide derivation, which deliberately excludes it (plan §1).
    final snap = await _trials
        .where('familyId', isEqualTo: familyId)
        .where('status', whereIn: ['active', 'accepted', 'awaitingOutcome'])
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return _trialFromMap(d.id, d.data());
  }

  @override
  Future<Set<String>> activeTrialNannyIds() async {
    // Single-field `status` filter (auto-indexed). Bounded like the hire
    // equivalent — if ever exceeded, denormalize an "engaged" flag instead.
    final snap = await _trials
        .where('status', whereIn: ['active', 'accepted'])
        .limit(1000)
        .get();
    return snap.docs
        .map((d) => (d.data()['nannyId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  @override
  Future<void> sendOffer(TrialModel trial) async {
    // Persist startDate/endDate as Timestamps so Timestamp range queries can
    // actually match them: the scheduled "trial starts tomorrow" reminder
    // (startDate) and the trial-outcome detector (endDate). toMap() writes
    // both as ISO strings by default, which a `where('endDate', '<=', ...)`
    // query silently never matches.
    final data = trial.toMap();
    data['startDate'] = Timestamp.fromDate(trial.startDate);
    data['endDate'] = Timestamp.fromDate(trial.endDate);
    await _trials.doc(trial.id).set(data);
  }

  @override
  Future<void> updateStatus(String trialId, TrialStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
    };

    if (status == TrialStatus.active) {
      updates['startedAt'] = FieldValue.serverTimestamp();
    } else if (status == TrialStatus.completed) {
      updates['completedAt'] = FieldValue.serverTimestamp();
    } else if (status == TrialStatus.accepted ||
        status == TrialStatus.declined ||
        status == TrialStatus.countered) {
      updates['respondedAt'] = FieldValue.serverTimestamp();
    }

    await _trials.doc(trialId).update(updates);
  }

  @override
  Future<void> respondAccept(String trialId) => updateStatus(trialId, TrialStatus.accepted);

  @override
  Future<void> respondDecline(String trialId) => updateStatus(trialId, TrialStatus.declined);

  @override
  Future<void> respondCounter(String trialId, CounterOffer counter) async {
    await _trials.doc(trialId).update({
      'status': TrialStatus.countered.name,
      'counterOffer': counter.toMap(),
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> cancelTrial(String trialId, {String? reason}) async {
    await _trials.doc(trialId).update({
      'status': TrialStatus.cancelled.name,
      'cancelReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> confirmPaymentReceived(String trialId) async {
    await _trials.doc(trialId).update({
      'nannyConfirmedPayment': true,
      'nannyConfirmedPaymentAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reportPaymentIssue(String trialId, String description) async {
    await _trials.doc(trialId).update({
      'paymentIssueReported': true,
      'paymentIssueDescription': description,
      'paymentIssueReportedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> recordOutcome(
    String trialId,
    TrialStatus outcome, {
    TrialEvaluation? evaluation,
    String? outcomeLabel,
  }) async {
    await _trials.doc(trialId).update({
      'status': outcome.name,
      'outcome': outcomeLabel ?? outcome.name,
      'outcomeAt': FieldValue.serverTimestamp(),
      if (evaluation != null) 'evaluation': evaluation.toMap(),
      if (outcome == TrialStatus.completed) 'completedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setFamilyOutcome(
    String trialId, {
    required String outcome,
    TrialEvaluation? evaluation,
    String? notHiredReason,
  }) =>
      _trials.doc(trialId).update({
        'familyOutcome': outcome,
        'familyOutcomeAt': FieldValue.serverTimestamp(),
        if (evaluation != null) 'evaluation': evaluation.toMap(),
        if (notHiredReason != null) 'notHiredReason': notHiredReason,
      });

  @override
  Future<void> setNannyOutcome(String trialId, {required String outcome}) =>
      _trials.doc(trialId).update({
        'nannyOutcome': outcome,
        'nannyOutcomeAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> applyCounterAndAccept(String trialId, CounterOffer counter) async {
    // CounterOffer only carries `dailyRate` and `startDate` — durationDays
    // comes from the trial itself so a counter that moves the start date
    // also recomputes the end date (previously left stale) and keeps it a
    // Timestamp, matching sendOffer's fix above.
    final doc = await _trials.doc(trialId).get();
    final durationDays = (doc.data()?['durationDays'] as num?)?.toInt() ?? 7;
    final newEndDate = counter.startDate.add(Duration(days: durationDays));
    await _trials.doc(trialId).update({
      'dailyRate': counter.dailyRate,
      'startDate': Timestamp.fromDate(counter.startDate),
      'endDate': Timestamp.fromDate(newEndDate),
      'status': TrialStatus.accepted.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> saveDayProof(
    String trialId,
    int dayIndex, {
    required String imageUrl,
    String? nannyId,
    String? note,
  }) async {
    await _trials.doc(trialId).collection('days').doc('$dayIndex').set({
      'dayIndex': dayIndex,
      'imageUrl': imageUrl,
      'nannyId': nannyId,
      'note': note,
      'uploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<List<DayProof>> listDayProofs(String trialId) async {
    final snap = await _trials.doc(trialId).collection('days').get();
    return snap.docs.map((d) => DayProof.fromMap(d.data())).toList()
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
  }

  TrialModel _trialFromMap(String id, Map<String, dynamic> m) =>
      TrialModel.fromMap({...m, 'id': id});
}
