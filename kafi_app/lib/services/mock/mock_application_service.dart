import 'package:get/get.dart';
import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:uuid/uuid.dart';

class MockApplicationService implements IApplicationService {
  final _uuid = const Uuid();
  final List<ApplicationModel> _applications = [];

  MockApplicationService() {
    _applications.addAll(buildMockApplications(DateTime.now()));
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForNanny(String nannyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _applications.where((a) => mockNannyIdMatches(nannyId, a.nannyId)).toList();
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForFamily(String familyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _applications.where((a) => a.familyId == familyId).toList();
  }

  @override
  Future<List<ApplicationModel>> getApplicationsForJob(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _applications.where((a) => a.jobPostId == jobId).toList();
  }

  @override
  Future<ApplicationModel> apply({
    required String nannyId,
    required String jobId,
    String? coverMessage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final job = await Get.find<IJobService>().getJob(jobId);
    final familyId = job?.familyId ?? '';
    final app = ApplicationModel(
      id: _uuid.v4(),
      jobPostId: jobId,
      nannyId: nannyId,
      familyId: familyId,
      status: ApplicationStatus.pending,
      matchScore: 85,
      coverMessage: coverMessage,
      createdAt: DateTime.now(),
    );
    _applications.add(app);
    return app;
  }

  @override
  Future<void> withdraw(String appId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.withdrawn,
        withdrawnAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> markViewed(String appId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.viewed,
        viewedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> shortlist(String appId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.shortlisted,
        respondedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> decline(String appId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.declined,
        respondedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> offerTrial(String appId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _applications.indexWhere((a) => a.id == appId);
    if (idx >= 0) {
      _applications[idx] = _applications[idx].copyWith(
        status: ApplicationStatus.trialOffered,
        respondedAt: DateTime.now(),
      );
    }
  }
}
