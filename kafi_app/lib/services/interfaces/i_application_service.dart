import 'package:kafi_app/models/application_model.dart';

abstract class IApplicationService {
  Future<List<ApplicationModel>> getApplicationsForNanny(String nannyId);
  Future<List<ApplicationModel>> getApplicationsForFamily(String familyId);

  /// Live inbox for the family's Applicants screen.
  Stream<List<ApplicationModel>> watchApplicationsForFamily(String familyId);

  /// Live list for the nanny's My Applications screen.
  Stream<List<ApplicationModel>> watchApplicationsForNanny(String nannyId);

  Future<List<ApplicationModel>> getApplicationsForJob(String jobId);
  Future<ApplicationModel> apply({
    required String nannyId,
    required String jobId,
    String? coverMessage,
  });
  Future<void> withdraw(String appId);
  Future<void> markViewed(String appId);
  Future<void> shortlist(String appId);
  Future<void> decline(String appId);
  Future<void> offerTrial(String appId);

  /// Marks the application as hired — set when a family hires the nanny at the
  /// end of a trial, so the family's Applicants list shows the "Hired" badge.
  Future<void> markHired(String appId);
}
