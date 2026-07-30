import 'package:kafi_app/models/hire_model.dart';

/// Family↔nanny employment records. A hire is created when a family hires a
/// nanny at the end of a trial. The nanny's `stats.hiresCount` aggregate is
/// maintained server-side by the `onHireCreated` Cloud Function (the rules
/// forbid a family from writing the nanny's doc).
abstract class IHireService {
  /// Creates a hire. Deterministic id (`hire_{trialId}`) keeps it to one hire
  /// per trial — a duplicate "Hire" tap lands on the same doc.
  Future<HireModel> createHire(HireModel hire);

  /// Hires for a family, newest first.
  Future<List<HireModel>> getHiresForFamily(String familyId);

  /// Hires for a nanny (by nanny **user id**), newest first.
  Future<List<HireModel>> getHiresForNanny(String nannyId);

  /// The nanny's current active hire, if any.
  Future<HireModel?> activeHireForNanny(String nannyId);

  /// User ids of all nannies who currently have an ACTIVE hire. Used to hide
  /// employed nannies from family browse/search (M5).
  Future<Set<String>> activeHiredNannyIds();

  /// Ends a hire with a reason (resigned / terminated / completed).
  Future<void> endHire(
    String hireId, {
    required HireEndReason reason,
    String? note,
  });
}
