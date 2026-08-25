import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/services/interfaces/i_shortlist_service.dart';

class FirestoreShortlistService implements IShortlistService {
  final _shortlists = FirebaseFirestore.instance.collection('shortlists');
  final _nannies = FirebaseFirestore.instance.collection('nannies');

  @override
  Future<List<ShortlistItem>> getShortlist(String familyId) async {
    final snap = await _shortlists
        .where('familyId', isEqualTo: familyId)
        .orderBy('addedAt', descending: true)
        .get();

    return snap.docs.map((d) => ShortlistItem.fromMap(d.data())).toList();
  }

  @override
  Future<ShortlistItem> add({
    required String familyId,
    required String nannyId,
    String? notes,
    String? nannyName,
    String? nannyPhoto,
  }) async {
    // Deterministic id makes add idempotent — a re-tap/retry won't create a
    // duplicate doc or double-increment the counter.
    final id = '${familyId}_$nannyId';
    final ref = _shortlists.doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      return ShortlistItem.fromMap(existing.data()!);
    }

    // Prefer caller-supplied denormalized fields (from the browse card). Reading
    // `nannies/{id}` can permission-deny for some profiles and must not block add.
    String? name = nannyName;
    String? photo = nannyPhoto;
    if (name == null || photo == null) {
      try {
        final nannySnap = await _nannies.doc(nannyId).get();
        final nannyData = nannySnap.data();
        name ??= nannyData?['fullName'] as String?;
        photo ??= (nannyData?['photoUrls'] as List?)?.firstOrNull?.toString();
      } catch (_) {
        // Non-fatal — shortlist still saves with the ids we have.
      }
    }

    final item = ShortlistItem(
      id: id,
      familyId: familyId,
      nannyId: nannyId,
      nannyName: name,
      nannyPhoto: photo,
      notes: notes,
      addedAt: DateTime.now(),
    );

    await ref.set(item.toMap());

    // The nanny dashboard's `stats.shortlists` is maintained server-side by the
    // onShortlistCreated Cloud Function — the security rules (correctly) forbid
    // a family from writing another user's nanny doc, so it cannot be done here.
    return item;
  }

  @override
  Future<void> remove({required String familyId, required String nannyId}) async {
    // Deleting the shortlist doc is enough — the onShortlistDeleted Cloud
    // Function decrements the nanny's server-owned stats.shortlists.
    // Prefer the deterministic id; fall back to a query for legacy docs.
    final detRef = _shortlists.doc('${familyId}_$nannyId');
    if ((await detRef.get()).exists) {
      await detRef.delete();
      return;
    }
    final snap = await _shortlists
        .where('familyId', isEqualTo: familyId)
        .where('nannyId', isEqualTo: nannyId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await _shortlists.doc(snap.docs.first.id).delete();
    }
  }

  @override
  Future<void> updateNotes({
    required String familyId,
    required String nannyId,
    required String notes,
  }) async {
    final snap = await _shortlists
        .where('familyId', isEqualTo: familyId)
        .where('nannyId', isEqualTo: nannyId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await _shortlists.doc(snap.docs.first.id).update({'notes': notes});
    }
  }
}
