import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';

class MockDisputeService implements IDisputeService {
  final _store = <String, DisputeModel>{};
  int _seq = 0;

  @override
  Future<String> fileDispute({
    required String reporterId,
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
  }) async {
    final id = 'dispute_${++_seq}';
    _store[id] = DisputeModel(
      id: id,
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      category: category,
      description: description,
      relatedTrialId: relatedTrialId,
      createdAt: DateTime.now(),
    );
    return id;
  }

  @override
  Future<List<DisputeModel>> getMyDisputes(String userId) async {
    return _store.values.where((d) => d.reporterId == userId).toList();
  }
}
