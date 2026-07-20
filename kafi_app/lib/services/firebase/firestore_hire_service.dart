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
  Future<void> endHire(
    String hireId, {
    required HireEndReason reason,
    String? note,
  }) async {
    await _hires.doc(hireId).update({
      'status': HireStatus.ended.name,
      'endReason': reason.name,
      'endNote': note,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  List<HireModel> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => HireModel.fromMap(d.data())).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }
}
