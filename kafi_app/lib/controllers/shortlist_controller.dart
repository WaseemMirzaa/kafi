import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/browse_controller.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/services/interfaces/i_shortlist_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class ShortlistController extends GetxController {
  final IShortlistService _shortlistService = Get.find<IShortlistService>();
  final IUserService _userService = Get.find<IUserService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<ShortlistItem> shortlistedNannies = <ShortlistItem>[].obs;
  final RxSet<String> shortlistedIds = <String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();
  Worker? _authWorker;

  /// Real browse cards for the shortlisted nannies, keyed by nannyId — loaded
  /// from Firestore so the shortlist shows the actual nanny (not seed data).
  final RxMap<String, NannyCardModel> cards = <String, NannyCardModel>{}.obs;

  /// The real card for a shortlisted item; falls back to the item's own
  /// denormalized name (still real) while the full card is loading.
  NannyCardModel cardFor(ShortlistItem item) =>
      cards[item.nannyId] ??
      NannyCardModel(
        id: item.nannyId,
        initials: (item.nannyName != null && item.nannyName!.isNotEmpty)
            ? item.nannyName![0].toUpperCase()
            : 'N',
        name: item.nannyName ?? '',
        nationality: '',
        yearsExp: 0,
        jobType: 'Live-in',
        city: '',
        matchPercent: 0,
        tags: const [],
      );

  @override
  void onInit() {
    super.onInit();
    _authWorker = ever<dynamic>(_auth.currentUser, (_) => loadShortlist());
    loadShortlist();
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> loadShortlist() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      final familyId = currentFamilyId(_auth);
      if (familyId == null) {
        shortlistedNannies.clear();
        shortlistedIds.clear();
        cards.clear();
        return;
      }
      shortlistedNannies.value = await _shortlistService.getShortlist(familyId);
      shortlistedIds.assignAll(shortlistedNannies.map((s) => s.nannyId).toSet());
      await _loadCards();
    } catch (e) {
      loadError.value = e.toString();
      shortlistedNannies.clear();
      shortlistedIds.clear();
      cards.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetches the real nanny doc for each shortlisted id and builds a card.
  Future<void> _loadCards() async {
    final loaded = <String, NannyCardModel>{};
    final matchJob =
        Get.isRegistered<BrowseController>() ? Get.find<BrowseController>().matchJob : null;
    final family =
        Get.isRegistered<BrowseController>() ? Get.find<BrowseController>().familyContext : null;
    final matcher = Get.isRegistered<MatchService>() ? Get.find<MatchService>() : MatchService();
    await Future.wait(shortlistedNannies.map((s) async {
      // Guard per-nanny: a shortlisted nanny we can't currently read (e.g. she's
      // not approved/verified → rules deny the read) must NOT reject the whole
      // Future.wait and wipe the list. Her card just falls back to the item's
      // denormalized name (see cardFor).
      try {
        final n = await _userService.getNanny(s.nannyId);
        if (n == null) return;
        loaded[s.nannyId] = matchJob != null
            ? matcher.cardWithJobMatch(n, matchJob, family: family)
            : NannyCardModel.fromNanny(n);
      } catch (_) {
        // Skip enrichment for this one; the shortlist item still shows.
      }
    }));
    cards.assignAll(loaded);
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
    if (familyId == null || shortlistedIds.contains(nannyId)) return;
    final item = await _shortlistService.add(familyId: familyId, nannyId: nannyId, notes: notes);
    shortlistedNannies.add(item);
    shortlistedIds.add(nannyId);
    await _loadCards();
  }

  Future<void> removeFromShortlist(String nannyId) async {
    final familyId = currentFamilyId(_auth);
    if (familyId == null) return;
    await _shortlistService.remove(familyId: familyId, nannyId: nannyId);
    shortlistedNannies.removeWhere((s) => s.nannyId == nannyId);
    shortlistedIds.remove(nannyId);
    cards.remove(nannyId);
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
