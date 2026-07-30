import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/hire_model.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';

class FirestoreHireService implements IHireService {
  final _hires = FirebaseFirestore.instance.collection('hires');

  @override
  Future<HireModel> createHire(HireModel hire) async {
    // Deterministic id = one hire per trial. Idempotent against a double tap
    // of the "Hire" button, and lets `hire_{trialId}` be looked up directly.
    final id = hire.trialId != null && hire.trialId!.isNotEmpty
        ? 'hire_${hire.trialId}'
        : hire.id;
    final data = {...hire.toMap(), 'id': id};
    await _hires.doc(id).set(data);
    return HireModel.fromMap(data);
  }

  @override
  Future<List<HireModel>> getHiresForFamily(String familyId) async {
    // Filter on familyId only (no composite index needed); sort client-side.
    final snap = await _hires.where('familyId', isEqualTo: familyId).get();
    return _sorted(snap);
  }

  @override
  Future<List<HireModel>> getHiresForNanny(String nannyId) async {
    final snap = await _hires.where('nannyId', isEqualTo: nannyId).get();
    return _sorted(snap);
  }

  @override
  Future<HireModel?> activeHireForNanny(String nannyId) async {
    final all = await getHiresForNanny(nannyId);
    return all.where((h) => h.isActive).cast<HireModel?>().firstWhere(
          (h) => h != null,
          orElse: () => null,
        );
  }

  @override
  Future<Set<String>> activeHiredNannyIds() async {
    // Single-field `status` filter (auto-indexed, no composite index). Bounded
    // so a large platform never reads unboundedly on every browse; if this cap
    // is ever hit, move to a denormalized "engaged" flag on the nanny doc.
    final snap = await _hires
        .where('status', isEqualTo: HireStatus.active.name)
        .limit(1000)
        .get();
    return snap.docs
        .map((d) => (d.data()['nannyId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  @override
  Future<void> endHire(
    String hireId, {
    required HireEndReason reason,
    String? note,
  }) async {
    final ref = _hires.doc(hireId);
    // First-end-wins: both parties can end a hire, so read-then-write in a
    // transaction and no-op if it is already ended. Without this, a family
    // terminating a moment after the nanny resigned would overwrite the reason
    // (and re-fire the counterparty notification) — the earlier end must stand.
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final status =
          (snap.data()?['status'] as String?) ?? HireStatus.active.name;
      if (status == HireStatus.ended.name) return;
      tx.update(ref, {
        'status': HireStatus.ended.name,
        'endReason': reason.name,
        'endNote': note,
        'endedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  List<HireModel> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => HireModel.fromMap(d.data())).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }
}
