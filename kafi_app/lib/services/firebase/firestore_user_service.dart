import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/nanny_map_codec.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';

/// Firestore implementation — collection structure per Technical Architecture §6.1.
class FirestoreUserService implements IUserService {
  final _col = FirebaseFirestore.instance.collection('nannies');
  final _families = FirebaseFirestore.instance.collection('families');
  final _users = FirebaseFirestore.instance.collection('users');

  @override
  Future<FamilyModel?> getFamily(String id) async {
    final s = await _families.doc(id).get();
    if (!s.exists) return null;
    final m = s.data()!;
    final subMap = m['subscription'] as Map<String, dynamic>?;
    return FamilyModel(
      id: s.id,
      userId: (m['userId'] as String?) ?? s.id,
      fullName: (m['fullName'] as String?) ?? '',
      city: (m['city'] as String?) ?? '',
      nationality: (m['nationality'] as String?) ?? '',
      childrenCount: (m['childrenCount'] as num?)?.toInt() ?? 0,
      childrenAges: List<String>.from(m['childrenAges'] ?? []),
      hasSpecialNeedsChild: m['hasSpecialNeedsChild'] ?? false,
      languagesAtHome: List<String>.from(m['languagesAtHome'] ?? []),
      hasCameras: m['hasCameras'] ?? false,
      hasPets: m['hasPets'] ?? false,
      petTypes: List<String>.from(m['petTypes'] ?? []),
      religion: (m['religion'] as String?) ?? '',
      houseRules: m['houseRules'] as String?,
      aboutFamily: m['aboutFamily'] as String?,
      subscription: subMap != null
          ? FamilySubscription.fromMap(subMap)
          : const FamilySubscription(),
      freeContactsUsed: (m['freeContactsUsed'] as num?)?.toInt() ?? 0,
      viewedProfiles: List<String>.from(m['viewedProfiles'] ?? []),
    );
  }

  @override
  Future<void> saveFamily(FamilyModel family) =>
      _families.doc(family.id).set(family.toMap(), SetOptions(merge: true));

  @override
  Future<NannyModel?> getNanny(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return nannyModelFromMap(snap.id, snap.data() ?? {});
  }

  @override
  Future<void> saveNanny(NannyModel nanny) async {
    await _col.doc(nanny.id).set(nanny.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> submitNannyForReview(String id) async {
    await _col.doc(id).update({
      'status': NannyOnboardingStatus.pending.name,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<NannyModel?> watchNanny(String id) =>
      _col.doc(id).snapshots().map((s) => s.exists ? nannyModelFromMap(s.id, s.data()!) : null);

  @override
  Future<Map<String, dynamic>?> getSettings(String userId) async {
    final snap = await _users.doc(userId).get();
    if (!snap.exists) return null;
    return snap.data()?['settings'] as Map<String, dynamic>?;
  }

  @override
  Future<void> updateSettings(String userId, Map<String, dynamic> settings) async {
    final flattened = <String, dynamic>{
      for (final entry in settings.entries) 'settings.${entry.key}': entry.value,
    };
    if (flattened.isEmpty) return;
    await _users.doc(userId).set(flattened, SetOptions(merge: true));
  }

  @override
  Future<void> recordProfileView(String familyId, String nannyId) async {
    // Use a transaction to ensure freeContactsUsed only increments
    // when the nannyId is genuinely new — prevents duplicate burns.
    final ref = _families.doc(familyId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final viewed = List<String>.from(
        (snap.data()?['viewedProfiles'] as List?) ?? const [],
      );
      if (viewed.contains(nannyId)) return;
      viewed.add(nannyId);
      tx.update(ref, {
        'viewedProfiles': viewed,
        'freeContactsUsed': FieldValue.increment(1),
      });
    });
  }

  @override
  Future<int> getFreeContactsUsed(String familyId) async {
    final snap = await _families.doc(familyId).get();
    if (!snap.exists) return 0;
    final data = snap.data();
    return (data?['freeContactsUsed'] as num?)?.toInt() ??
        (data?['freeViewsUsed'] as num?)?.toInt() ??
        0;
  }

  @override
  Future<bool> isUserBlocked(String userId, {required bool isNanny}) async {
    final snap = await (isNanny ? _col : _families).doc(userId).get();
    return snap.data()?['blocked'] == true;
  }
}
