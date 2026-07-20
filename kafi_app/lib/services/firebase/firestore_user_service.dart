import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/nanny_map_codec.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/localized_text.dart';

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
      nannyReligionPreference: NannyReligionPreference.values.firstWhere(
          (e) => e.name == m['nannyReligionPreference'],
          orElse: () => NannyReligionPreference.noPreference),
      houseRules: m['houseRules'] as String?,
      aboutFamily: m['aboutFamily'] as String?,
      profilePhoto: m['profilePhoto'] as String?,
      specialNeedsDetails: m['specialNeedsDetails'] as String?,
      subscription: subMap != null
          ? FamilySubscription.fromMap(subMap)
          : const FamilySubscription(),
      freeContactsUsed: (m['freeContactsUsed'] as num?)?.toInt() ?? 0,
      viewedProfiles: List<String>.from(m['viewedProfiles'] ?? []),
      activeTrialNannyIds: List<String>.from(m['activeTrialNannyIds'] ?? []),
      stats: FamilyStats.fromMap(m['stats'] as Map<String, dynamic>?),
      i18n: i18nMapsFrom(m, const ['aboutFamily', 'houseRules']),
    );
  }

  @override
  Future<void> saveFamily(FamilyModel family) {
    // Strip every server-owned / admin-only field from a family's own profile
    // write. The security rules DENY an update that touches subscription,
    // freeContactsUsed, viewedProfiles, or activeTrialNannyIds — so leaving them
    // in makes the whole merge-write permission-denied for any family that has
    // used a free contact (the controller rebuilds these as 0/[]). `stats` is
    // server-maintained too and would be clobbered to zeros. These are owned by
    // the subscription service / RevenueCat webhook and the profileViews /
    // trial Cloud Functions.
    final data = family.toMap()
      ..remove('subscription')
      ..remove('freeContactsUsed')
      ..remove('viewedProfiles')
      ..remove('activeTrialNannyIds')
      ..remove('stats');
    return _families.doc(family.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<NannyModel?> getNanny(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    return nannyModelFromMap(snap.id, snap.data() ?? {});
  }

  @override
  Future<void> saveNanny(NannyModel nanny) async {
    // Strip server-owned fields from a nanny's own profile write, mirroring
    // saveFamily. `stats` (profileViews/shortlists/hiresCount/averageRating) and
    // `profileScore` are maintained by the stats Cloud Functions, and the client
    // freezes them at launch (the profile watch is cancelled at approval) — so a
    // post-approval edit would otherwise clobber the live server values with a
    // stale snapshot and regress the dashboard counters.
    final data = nanny.toMap()
      ..remove('stats')
      ..remove('profileScore');
    await _col.doc(nanny.id).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> saveNannyDocumentUrls(
      String nannyId, Map<DocumentType, String> urls) async {
    if (urls.isEmpty) return;
    final docs = _col.doc(nannyId).collection('documents');
    // One doc per type (deterministic id = type name). Merge so re-uploading a
    // single document doesn't clobber the others.
    await Future.wait(urls.entries.map((e) => docs.doc(e.key.name).set(
          {'type': e.key.name, 'url': e.value, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        )));
  }

  @override
  Future<void> submitNannyForReview(String id) async {
    // Resubmitting after a rejection must clear the admin's previous verdict so
    // the nanny isn't shown a stale reason once they're back in the queue. The
    // fields are deleted (not nulled) since the app never writes them otherwise.
    await _col.doc(id).update({
      'status': NannyOnboardingStatus.pending.name,
      'submittedAt': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
      'rejectedAt': FieldValue.delete(),
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
  Future<int> getFreeContactsUsed(String familyId) async {
    final snap = await _families.doc(familyId).get();
    if (!snap.exists) return 0;
    final data = snap.data();
    return (data?['freeContactsUsed'] as num?)?.toInt() ??
        (data?['freeViewsUsed'] as num?)?.toInt() ??
        0;
  }

  @override
  Future<String?> revealContact(String familyId, String nannyId) async {
    final ref = FirebaseFirestore.instance
        .collection('contactReveals')
        .doc('${familyId}_$nannyId');
    try {
      final existing = await ref.get();
      if (!existing.exists) {
        await ref.set({
          'familyId': familyId,
          'nannyId': nannyId,
          'requestedAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      // If the reveal doc does not exist yet, the rules deny the initial read.
      // Fall back to a create-only write in that case.
      if (e.code == 'permission-denied') {
        await ref.set({
          'familyId': familyId,
          'nannyId': nannyId,
          'requestedAt': FieldValue.serverTimestamp(),
        });
        return await _awaitRevealResult(ref);
      }
      if (e.code != 'permission-denied') rethrow;
    }
    return _awaitRevealResult(ref);
  }

  Future<String?> _awaitRevealResult(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final snap = await ref
          .snapshots()
          .firstWhere((s) {
            final st = s.data()?['status'];
            return st == 'revealed' || st == 'denied';
          })
          // 15s tolerates a cold-started onContactRevealRequested function.
          .timeout(const Duration(seconds: 15));
      final d = snap.data();
      return d?['status'] == 'revealed' ? (d?['phone'] as String?) : null;
    } catch (_) {
      // The stream timed out or errored. A cold/slow function may have resolved
      // the reveal just after the timeout — do one final direct read before
      // giving up, so a slow function isn't misread as a denial.
      try {
        final d = (await ref.get()).data();
        if (d?['status'] == 'revealed') return d?['phone'] as String?;
      } catch (_) {
        // Give up quietly; the caller shows a generic "unavailable" message.
      }
      return null;
    }
  }

  @override
  Future<bool> isUserBlocked(String userId, {required bool isNanny}) async {
    final snap = await (isNanny ? _col : _families).doc(userId).get();
    return snap.data()?['blocked'] == true;
  }

  @override
  Stream<bool> watchBlocked(String userId, {required bool isNanny}) =>
      (isNanny ? _col : _families)
          .doc(userId)
          .snapshots()
          .map((s) => s.data()?['blocked'] == true);
}
