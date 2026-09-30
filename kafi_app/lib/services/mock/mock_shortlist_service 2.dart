import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/services/interfaces/i_shortlist_service.dart';
import 'package:uuid/uuid.dart';

class MockShortlistService implements IShortlistService {
  final _uuid = const Uuid();
  final List<ShortlistItem> _items = buildMockShortlist();

  @override
  Future<List<ShortlistItem>> getShortlist(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _items.where((s) => s.familyId == familyId).toList();
  }

  @override
  Future<ShortlistItem> add({
    required String familyId,
    required String nannyId,
    String? notes,
    String? nannyName,
    String? nannyPhoto,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final item = ShortlistItem(
      id: _uuid.v4(),
      familyId: familyId,
      nannyId: nannyId,
      nannyName: nannyName,
      nannyPhoto: nannyPhoto,
      notes: notes,
      addedAt: DateTime.now(),
    );
    _items.add(item);
    return item;
  }

  @override
  Future<void> remove({required String familyId, required String nannyId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _items.removeWhere((s) => s.familyId == familyId && s.nannyId == nannyId);
  }

  @override
  Future<void> updateNotes({
    required String familyId,
    required String nannyId,
    required String notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _items.indexWhere((s) => s.familyId == familyId && s.nannyId == nannyId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(notes: notes);
    }
  }
}
