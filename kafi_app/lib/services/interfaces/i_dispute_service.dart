import 'package:kafi_app/models/dispute_model.dart';

abstract class IDisputeService {
  /// File a new dispute. Returns the created dispute doc id.
  Future<String> fileDispute({
    required String reporterId,
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
  });

  Future<List<DisputeModel>> getMyDisputes(String userId);
}
