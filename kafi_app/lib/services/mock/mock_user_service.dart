import 'dart:async';

import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/constants/mock_constants.dart';

class MockUserService implements IUserService {
  final Map<String, NannyModel> _nannies = {};
  final Map<String, StreamController<NannyModel?>> _streams = {};
  final Map<String, Timer> _approveTimers = {};
  final Map<String, FamilyModel> _families = {};
  final Map<String, Map<String, dynamic>> _settings = {};
  final Map<String, Set<String>> _viewedNannies = {};

  @override
  Future<FamilyModel?> getFamily(String id) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _families[id];
  }

  @override
  Future<void> saveFamily(FamilyModel family) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _families[family.id] = family;
  }

  @override
  Future<bool> isUserBlocked(String userId, {required bool isNanny}) async => false;

  @override
  Future<NannyModel?> getNanny(String id) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _nannies[id];
  }

  @override
  Future<void> saveNanny(NannyModel nanny) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _nannies[nanny.id] = nanny;
    _streams[nanny.id]?.add(nanny);
    if (AppConfig.useMock && nanny.status == NannyOnboardingStatus.pending) {
      _scheduleMockAutoApprove(id: nanny.id);
    }
  }

  @override
  Future<void> submitNannyForReview(String id) async {
    final n = _nannies[id];
    if (n == null) return;
    final updated = n.copyWith(status: NannyOnboardingStatus.pending);
    _nannies[id] = updated;
    _streams[id]?.add(updated);
    if (AppConfig.useMock) {
      _scheduleMockAutoApprove(id: id);
    }
  }

  void _scheduleMockAutoApprove({required String id}) {
    _approveTimers[id]?.cancel();
    _approveTimers[id] = Timer(MockConstants.nannyAutoApproveDelay, () {
      final n = _nannies[id];
      if (n == null || n.status != NannyOnboardingStatus.pending) return;
      final now = DateTime.now();
      final approved = n.copyWith(
        status: NannyOnboardingStatus.approved,
        isVerified: true,
        stats: const NannyStats(profileViews: 143, shortlists: 12, averageRating: 4.8),
        documents: n.documents
            .map(
              (d) => d.status == DocumentStatus.missing
                  ? d
                  : d.copyWith(
                      status: DocumentStatus.approved,
                      reviewedAt: now,
                      reviewedBy: 'mock-admin',
                    ),
            )
            .toList(),
      );
      _nannies[id] = approved;
      _streams[id]?.add(approved);
      _approveTimers.remove(id);
    });
  }

  @override
  Stream<NannyModel?> watchNanny(String id) {
    _streams.putIfAbsent(
      id,
      () => StreamController<NannyModel?>.broadcast(),
    );
    Future.microtask(() => _streams[id]?.add(_nannies[id]));
    return _streams[id]!.stream;
  }

  @override
  Future<Map<String, dynamic>?> getSettings(String userId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _settings[userId];
  }

  @override
  Future<void> updateSettings(String userId, Map<String, dynamic> settings) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _settings[userId] = {...?_settings[userId], ...settings};
  }

  @override
  Future<void> recordProfileView(String familyId, String nannyId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _viewedNannies.putIfAbsent(familyId, () => {});
    _viewedNannies[familyId]!.add(nannyId);
  }

  @override
  Future<int> getFreeContactsUsed(String familyId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _viewedNannies[familyId]?.length ?? 0;
  }
}
