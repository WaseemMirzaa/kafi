import 'package:kafi_app/models/trial_model.dart';

abstract class ITrialService {
  Future<List<TrialModel>> listTrials(String familyId);
  Future<List<TrialModel>> listTrialsForNanny(String nannyId);
  Future<TrialModel?> getTrial(String trialId);
  Future<TrialModel?> activeTrial(String familyId);
  Future<void> sendOffer(TrialModel trial);
  Future<void> updateStatus(String trialId, TrialStatus status);
  Future<void> respondAccept(String trialId);
  Future<void> respondDecline(String trialId);
  Future<void> respondCounter(String trialId, CounterOffer counter);

  /// Family or admin cancels a pending/accepted trial before it starts.
  Future<void> cancelTrial(String trialId, {String? reason});

  /// Nanny confirms payment received from family.
  Future<void> confirmPaymentReceived(String trialId);

  /// Nanny reports payment issue (no payment, partial, late).
  Future<void> reportPaymentIssue(String trialId, String description);

  /// Record final hire/pass decision plus optional evaluation.
  Future<void> recordOutcome(
    String trialId,
    TrialStatus outcome, {
    TrialEvaluation? evaluation,
    String? outcomeLabel,
  });

  /// Apply a counter offer's accepted terms to the trial record
  /// (daily rate, duration, start date) and mark it `accepted`.
  Future<void> applyCounterAndAccept(String trialId, CounterOffer counter);
}
