import 'package:kafi_app/models/application_model.dart';

abstract class IApplicationService {
  Future<List<ApplicationModel>> getApplicationsForNanny(String nannyId);
  Future<List<ApplicationModel>> getApplicationsForFamily(String familyId);
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
}
