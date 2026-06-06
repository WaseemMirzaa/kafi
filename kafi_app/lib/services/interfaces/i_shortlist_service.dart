import 'package:kafi_app/models/shortlist_model.dart';

abstract class IShortlistService {
  Future<List<ShortlistItem>> getShortlist(String familyId);
  Future<ShortlistItem> add({
    required String familyId,
    required String nannyId,
    String? notes,
  });
  Future<void> remove({required String familyId, required String nannyId});
  Future<void> updateNotes({
    required String familyId,
    required String nannyId,
    required String notes,
  });
}
