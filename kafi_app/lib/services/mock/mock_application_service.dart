import 'dart:async';

import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';

class MockApplicationService implements IApplicationService {
  final List<ApplicationModel> _applications = [];
  final _changed = StreamController<void>.broadcast();

  MockApplicationService() {
    _applications.addAll(buildMockApplications(DateTime.now()));
  }

  void _notify() {
    if (!_changed.isClosed) _changed.add(null);
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForNanny(String nannyId) async {
    await Future.delayed(AppConfig.mockDelay);
    return _forNanny(nannyId);
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForFamily(String familyId) async {
    await Future.delayed(AppConfig.mockDelay);
    return _forFamily(familyId);
  }

  @override
  Stream<List<ApplicationModel>> watchApplicationsForNanny(String nannyId) async* {
    yield _forNanny(nannyId);
    await for (final _ in _changed.stream) {
      yield _forNanny(nannyId);
    }
  }

  @override
  Stream<List<ApplicationModel>> watchApplicationsForFamily(String familyId) async* {
    yield _forFamily(familyId);
    await for (final _ in _changed.stream) {
      yield _forFamily(familyId);
    }
  }

  List<ApplicationModel> _forNanny(String nannyId) =>
      _applications.where((a) => mockNannyIdMatches(nannyId, a.nannyId)).toList();

  List<ApplicationModel> _forFamily(String familyId) =>
      _applications.where((a) => a.familyId == familyId).toList();

  @override
  Future<List<ApplicationModel>> getApplicationsForJob(String jobId) async {
    await Future.delayed(AppConfig.mockDelay);
    return _applications.where((a) => a.jobPostId == jobId).toList();
  }

  @override
  Future<ApplicationModel> apply({
    required String nannyId,
    required String jobId,
    String? coverMessage,
  }) async {
    await Future.delayed(AppConfig.mockDelay);
    final already = _applications.any((a) =>
        a.jobPostId == jobId &&
        mockNannyIdMatches(nannyId, a.nannyId) &&
        a.status != ApplicationStatus.withdrawn);
    if (already) throw Exception('already_applied');
    final job = await Get.find<IJobService>().getJob(jobId);
    final familyId = job?.familyId.trim() ?? '';
    if (familyId.isEmpty) throw Exception('job_missing_family');
    final app = ApplicationModel(
      id: '${jobId}_$nannyId',
      jobPostId: jobId,
      nannyId: nannyId,
      familyId: familyId,
      status: ApplicationStatus.pending,
      matchScore: 85,
      coverMessage: coverMessage,
      createdAt: DateTime.now(),
      jobTitle: job?.jobTitle,
      familyName: job?.familyName,
    );
    _applications.removeWhere((a) => a.id == app.id);
    _applications.add(app);
    _notify();
    return app;
  }

  @override
  Future<void> withdraw(String appId) async {
    await Future.delayed(AppConfig.mockDelay);
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.withdrawn,
        withdrawnAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> markViewed(String appId) async {
    await Future.delayed(AppConfig.mockDelay);
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.viewed,
        viewedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> shortlist(String appId) async {
    await Future.delayed(AppConfig.mockDelay);
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.shortlisted,
        respondedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> decline(String appId) async {
    await Future.delayed(AppConfig.mockDelay);
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.declined,
        respondedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> offerTrial(String appId) async {
    await Future.delayed(AppConfig.mockDelay);
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.trialOffered,
        respondedAt: DateTime.now(),
      );
      _notify();
    }
  }

  @override
  Future<void> markHired(String appId) async {
    await Future.delayed(AppConfig.mockDelay);
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.hired,
        respondedAt: DateTime.now(),
      );
      _notify();
    }
  }
}
