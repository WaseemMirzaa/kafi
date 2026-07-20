import 'package:kafi_app/models/hire_model.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';

class MockHireService implements IHireService {
  final List<HireModel> _hires = [];

  @override
  Future<HireModel> createHire(HireModel hire) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final id = hire.trialId != null && hire.trialId!.isNotEmpty
        ? 'hire_${hire.trialId}'
        : hire.id;
    // One hire per trial — a duplicate "Hire" tap replaces the same doc.
    _hires.removeWhere((h) => h.id == id);
    final stored = HireModel.fromMap({...hire.toMap(), 'id': id});
    _hires.add(stored);
    return stored;
  }

  @override
  Future<List<HireModel>> getHiresForFamily(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sorted(_hires.where((h) => h.familyId == familyId));
  }

  @override
  Future<List<HireModel>> getHiresForNanny(String nannyId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _sorted(_hires.where((h) => h.nannyId == nannyId));
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
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _hires.indexWhere((h) => h.id == hireId);
    if (idx >= 0) {
      _hires[idx] = _hires[idx].copyWith(
        status: HireStatus.ended,
        endReason: reason,
        endNote: note,
        endedAt: DateTime.now(),
      );
    }
  }

  List<HireModel> _sorted(Iterable<HireModel> items) =>
      items.toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
}
