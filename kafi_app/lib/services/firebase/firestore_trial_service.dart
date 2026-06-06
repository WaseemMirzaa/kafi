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
    final snap = await _trials
        .where('familyId', isEqualTo: familyId)
        .where('status', whereIn: ['active', 'accepted'])
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return _trialFromMap(d.id, d.data());
  }

  @override
  Future<void> sendOffer(TrialModel trial) async {
    await _trials.doc(trial.id).set(trial.toMap());
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
  Future<void> applyCounterAndAccept(String trialId, CounterOffer counter) async {
    // CounterOffer only carries `dailyRate` and `startDate`.
    await _trials.doc(trialId).update({
      'dailyRate': counter.dailyRate,
      'startDate': Timestamp.fromDate(counter.startDate),
      'status': TrialStatus.accepted.name,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  TrialModel _trialFromMap(String id, Map<String, dynamic> m) =>
      TrialModel.fromMap({...m, 'id': id});
}
