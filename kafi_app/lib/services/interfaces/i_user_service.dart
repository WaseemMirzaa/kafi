import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/nanny_model.dart';

abstract class IUserService {
  Future<NannyModel?> getNanny(String id);
  Future<void> saveNanny(NannyModel nanny);
  Future<void> submitNannyForReview(String id);
  Stream<NannyModel?> watchNanny(String id);

  Future<FamilyModel?> getFamily(String id);
  Future<void> saveFamily(FamilyModel family);

  Future<Map<String, dynamic>?> getSettings(String userId);
  Future<void> updateSettings(String userId, Map<String, dynamic> settings);
  Future<void> recordProfileView(String familyId, String nannyId);
  Future<int> getFreeContactsUsed(String familyId);

  /// Whether an admin has blocked this user (nanny or family) in Firestore.
  Future<bool> isUserBlocked(String userId, {required bool isNanny});
}
