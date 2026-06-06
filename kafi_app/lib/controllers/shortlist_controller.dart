import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/services/interfaces/i_shortlist_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class ShortlistController extends GetxController {
  final IShortlistService _shortlistService = Get.find<IShortlistService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<ShortlistItem> shortlistedNannies = <ShortlistItem>[].obs;
  final RxSet<String> shortlistedIds = <String>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadShortlist();
  }

  Future<void> loadShortlist() async {
    isLoading.value = true;
    try {
      final familyId = currentFamilyId(_auth);
      if (familyId == null) return;
      shortlistedNannies.value = await _shortlistService.getShortlist(familyId);
      shortlistedIds.assignAll(shortlistedNannies.map((s) => s.nannyId).toSet());
    } finally {
      isLoading.value = false;
    }
  }

  bool isShortlisted(String nannyId) => shortlistedIds.contains(nannyId);

  Future<void> toggleShortlist(String nannyId) async {
    if (isShortlisted(nannyId)) {
      await removeFromShortlist(nannyId);
    } else {
      await addToShortlist(nannyId);
    }
  }

  Future<void> addToShortlist(String nannyId, {String? notes}) async {
    final familyId = currentFamilyId(_auth);
    if (familyId == null) return;
    final item = await _shortlistService.add(familyId: familyId, nannyId: nannyId, notes: notes);
    shortlistedNannies.add(item);
    shortlistedIds.add(nannyId);
  }

  Future<void> removeFromShortlist(String nannyId) async {
    final familyId = currentFamilyId(_auth);
    if (familyId == null) return;
    await _shortlistService.remove(familyId: familyId, nannyId: nannyId);
    shortlistedNannies.removeWhere((s) => s.nannyId == nannyId);
    shortlistedIds.remove(nannyId);
  }

  Future<void> updateNotes(String nannyId, String notes) async {
    final familyId = currentFamilyId(_auth);
    if (familyId == null) return;
    await _shortlistService.updateNotes(familyId: familyId, nannyId: nannyId, notes: notes);
    final idx = shortlistedNannies.indexWhere((s) => s.nannyId == nannyId);
    if (idx >= 0) {
      shortlistedNannies[idx] = shortlistedNannies[idx].copyWith(notes: notes);
    }
  }
}
