import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/services/interfaces/i_shortlist_service.dart';
import 'package:uuid/uuid.dart';

class FirestoreShortlistService implements IShortlistService {
  final _shortlists = FirebaseFirestore.instance.collection('shortlists');
  final _nannies = FirebaseFirestore.instance.collection('nannies');
  final _uuid = const Uuid();

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
    final nannySnap = await _nannies.doc(nannyId).get();
    final nannyData = nannySnap.data();

    final item = ShortlistItem(
      id: _uuid.v4(),
      familyId: familyId,
      nannyId: nannyId,
      nannyName: nannyData?['fullName'],
      nannyPhoto: (nannyData?['photoUrls'] as List?)?.firstOrNull?.toString(),
      notes: notes,
      addedAt: DateTime.now(),
    );

    await _shortlists.doc(item.id).set(item.toMap());

    await _nannies.doc(nannyId).update({
      'shortlists': FieldValue.increment(1),
    });

    return item;
  }

  @override
  Future<void> remove({required String familyId, required String nannyId}) async {
    final snap = await _shortlists
        .where('familyId', isEqualTo: familyId)
        .where('nannyId', isEqualTo: nannyId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await _shortlists.doc(snap.docs.first.id).delete();

      await _nannies.doc(nannyId).update({
        'shortlists': FieldValue.increment(-1),
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
