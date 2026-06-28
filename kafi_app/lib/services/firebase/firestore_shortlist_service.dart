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
  }) async {
    // Deterministic id makes add idempotent — a re-tap/retry won't create a
    // duplicate doc or double-increment the counter.
    final id = '${familyId}_$nannyId';
    final ref = _shortlists.doc(id);
    final existing = await ref.get();
    if (existing.exists) {
      return ShortlistItem.fromMap(existing.data()!);
    }

    final nannySnap = await _nannies.doc(nannyId).get();
    final nannyData = nannySnap.data();

    final item = ShortlistItem(
      id: id,
      familyId: familyId,
      nannyId: nannyId,
      nannyName: nannyData?['fullName'],
      nannyPhoto: (nannyData?['photoUrls'] as List?)?.firstOrNull?.toString(),
      notes: notes,
      addedAt: DateTime.now(),
    );

    await ref.set(item.toMap());

    // Increment the field the nanny dashboard actually reads (stats.shortlists),
    // not the top-level `shortlists` that nothing reads.
    await _nannies.doc(nannyId).update({
      'stats.shortlists': FieldValue.increment(1),
    });

    return item;
  }

  @override
  Future<void> remove({required String familyId, required String nannyId}) async {
    // Prefer the deterministic id; fall back to a query for legacy docs.
    final detRef = _shortlists.doc('${familyId}_$nannyId');
    if ((await detRef.get()).exists) {
      await detRef.delete();
      await _nannies.doc(nannyId).update({
        'stats.shortlists': FieldValue.increment(-1),
      });
      return;
    }
    final snap = await _shortlists
        .where('familyId', isEqualTo: familyId)
        .where('nannyId', isEqualTo: nannyId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await _shortlists.doc(snap.docs.first.id).delete();
      await _nannies.doc(nannyId).update({
        'stats.shortlists': FieldValue.increment(-1),
      });
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
