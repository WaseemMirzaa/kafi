import 'package:kafi_app/models/trial_model.dart';

abstract class ITrialService {
  Future<List<TrialModel>> listTrials(String familyId);
  Future<List<TrialModel>> listTrialsForNanny(String nannyId);
  Future<TrialModel?> getTrial(String trialId);

  /// The trial currently in play for this family — active, accepted, or
  /// awaitingOutcome (execution window closed, outcome not yet resolved).
  /// Drives `TrialController.active`/the trial screen. Distinct from
  /// [activeTrialNannyIds], the browse-hide derivation below, which
  /// deliberately excludes awaitingOutcome (plan §1).
  Future<TrialModel?> activeTrial(String familyId);

  /// Nanny ids currently on an accepted or active trial (with any family). Used
  /// to hide nannies mid-trial from family browse/search (M5).
  Future<Set<String>> activeTrialNannyIds();
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

  /// Family's mutual-outcome response once the trial reaches
  /// `awaitingOutcome`. Writes only the family's own side — resolution
  /// (creating the `hires` doc, flipping the trial to `completed`) happens
  /// server-side once both parties have responded (see
  /// `onTrialOutcomeResolved`), never on the client.
  Future<void> setFamilyOutcome(
    String trialId, {
    required String outcome,
    TrialEvaluation? evaluation,
    String? notHiredReason,
  });

  /// Nanny's mutual-outcome response once the trial reaches
  /// `awaitingOutcome`. Writes only the nanny's own side — see
  /// [setFamilyOutcome].
  Future<void> setNannyOutcome(String trialId, {required String outcome});

  /// Apply a counter offer's accepted terms to the trial record
  /// (daily rate, duration, start date) and mark it `accepted`.
  Future<void> applyCounterAndAccept(String trialId, CounterOffer counter);

  /// Saves the nanny's proof-of-work photo for [dayIndex] of the trial
  /// (upsert — re-uploading a day replaces it).
  Future<void> saveDayProof(
    String trialId,
    int dayIndex, {
    required String imageUrl,
    String? nannyId,
    String? note,
  });

  /// All uploaded day proofs for a trial, ascending by day.
  Future<List<DayProof>> listDayProofs(String trialId);

  /// Persist the family's in-progress evaluation checklist (during the trial,
  /// not only at hire/pass). Both parties read it from the trial doc.
  Future<void> saveEvaluation(String trialId, TrialEvaluation evaluation);

  /// Live updates for a single trial (evaluation ticks, status, payment flags).
  Stream<TrialModel?> watchTrial(String trialId);
}
