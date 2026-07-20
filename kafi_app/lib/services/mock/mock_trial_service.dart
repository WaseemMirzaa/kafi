import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';

class MockTrialService implements ITrialService {
  final Map<String, TrialModel> _trials = {};
  final Map<String, Map<int, DayProof>> _dayProofs = {};

  MockTrialService() {
    _trials.addAll(buildMockTrials(DateTime.now()));
  }

  @override
  Future<List<TrialModel>> listTrials(String familyId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _trials.values.where((t) => t.familyId == familyId).toList()
      ..sort((a, b) => b.offeredAt.compareTo(a.offeredAt));
  }

  @override
  Future<List<TrialModel>> listTrialsForNanny(String nannyId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _trials.values.where((t) => mockNannyIdMatches(nannyId, t.nannyId)).toList()
      ..sort((a, b) => b.offeredAt.compareTo(a.offeredAt));
  }

  @override
  Future<TrialModel?> getTrial(String trialId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _trials[trialId];
  }

  @override
  Future<TrialModel?> activeTrial(String familyId) async {
    final list = await listTrials(familyId);
    try {
      return list.firstWhere((t) => t.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> sendOffer(TrialModel trial) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _trials[trial.id] = trial;
  }

  @override
  Future<void> updateStatus(String trialId, TrialStatus status) async {
    final t = _trials[trialId];
    if (t == null) return;
    _trials[trialId] = t.copyWith(
      status: status,
      respondedAt: status == TrialStatus.accepted ||
              status == TrialStatus.declined ||
              status == TrialStatus.countered
          ? DateTime.now()
          : t.respondedAt,
      startedAt: status == TrialStatus.active ? DateTime.now() : t.startedAt,
      completedAt: status == TrialStatus.completed ? DateTime.now() : t.completedAt,
    );
  }

  @override
  Future<void> respondAccept(String trialId) async {
    await updateStatus(trialId, TrialStatus.accepted);
  }

  @override
  Future<void> respondDecline(String trialId) async {
    await updateStatus(trialId, TrialStatus.declined);
  }

  @override
  Future<void> respondCounter(String trialId, CounterOffer counter) async {
    final t = _trials[trialId];
    if (t == null) return;
    _trials[trialId] = t.copyWith(
      status: TrialStatus.countered,
      counterOffer: counter,
      respondedAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelTrial(String trialId, {String? reason}) async {
    final t = _trials[trialId];
    if (t == null) return;
    _trials[trialId] = t.copyWith(status: TrialStatus.cancelled, respondedAt: DateTime.now());
  }

  @override
  Future<void> confirmPaymentReceived(String trialId) async {
    final t = _trials[trialId];
    if (t == null) return;
    _trials[trialId] = t.copyWith(nannyConfirmedPayment: true);
  }

  @override
  Future<void> reportPaymentIssue(String trialId, String description) async {
    final t = _trials[trialId];
    if (t == null) return;
    _trials[trialId] = t.copyWith(paymentIssueReported: true);
  }

  @override
  Future<void> recordOutcome(
    String trialId,
    TrialStatus outcome, {
    TrialEvaluation? evaluation,
    String? outcomeLabel,
  }) async {
    final t = _trials[trialId];
    if (t == null) return;
    _trials[trialId] = t.copyWith(
      status: outcome,
      outcome: outcomeLabel ?? outcome.name,
      outcomeAt: DateTime.now(),
      evaluation: evaluation ?? t.evaluation,
      completedAt: outcome == TrialStatus.completed ? DateTime.now() : t.completedAt,
    );
  }

  @override
  Future<void> applyCounterAndAccept(String trialId, CounterOffer counter) async {
    final t = _trials[trialId];
    if (t == null) return;
    // CounterOffer only carries `dailyRate` and `startDate`. Build a fresh
    // TrialModel so we can change the immutable rate/start-date fields too.
    _trials[trialId] = TrialModel(
      id: t.id,
      familyId: t.familyId,
      nannyId: t.nannyId,
      jobPostId: t.jobPostId,
      durationDays: t.durationDays,
      dailyRate: counter.dailyRate,
      startDate: counter.startDate,
      startTime: t.startTime,
      trialType: t.trialType,
      location: t.location,
      notes: t.notes,
      status: TrialStatus.accepted,
      offeredAt: t.offeredAt,
      respondedAt: DateTime.now(),
      counterOffer: counter,
      evaluation: t.evaluation,
      outcome: t.outcome,
      outcomeAt: t.outcomeAt,
    );
  }

  @override
  Future<void> saveDayProof(
    String trialId,
    int dayIndex, {
    required String imageUrl,
    String? nannyId,
    String? note,
  }) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final map = _dayProofs.putIfAbsent(trialId, () => {});
    map[dayIndex] = DayProof(
      dayIndex: dayIndex,
      imageUrl: imageUrl,
      nannyId: nannyId ?? '',
      note: note,
      uploadedAt: DateTime.now(),
    );
  }

  @override
  Future<List<DayProof>> listDayProofs(String trialId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final map = _dayProofs[trialId] ?? const {};
    return map.values.toList()..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
  }
}
