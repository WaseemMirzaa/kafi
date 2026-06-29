import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/mock/mock_application_service.dart';
import 'package:kafi_app/services/mock/mock_job_service.dart';

/// Covers the application-integrity feature (#13 / Spec §14 J3): one
/// application per (job, nanny), and denormalized names on the application doc.
void main() {
  group('ApplicationModel denormalized names', () {
    test('toMap/fromMap round-trips nannyName, jobTitle, familyName', () {
      final app = ApplicationModel(
        id: 'job1_n1',
        jobPostId: 'job1',
        nannyId: 'n1',
        familyId: 'f1',
        status: ApplicationStatus.pending,
        createdAt: DateTime(2026, 6, 20),
        nannyName: 'Maria Santos',
        jobTitle: 'Live-in Nanny',
        familyName: 'Al Mansoori',
      );
      final back = ApplicationModel.fromMap(app.toMap());
      expect(back.nannyName, 'Maria Santos');
      expect(back.jobTitle, 'Live-in Nanny');
      expect(back.familyName, 'Al Mansoori');
    });

    test('copyWith carries the denormalized names forward', () {
      final app = ApplicationModel(
        id: 'a',
        jobPostId: 'j',
        nannyId: 'n',
        familyId: 'f',
        status: ApplicationStatus.pending,
        createdAt: DateTime(2026),
        nannyName: 'Maria',
        jobTitle: 'Nanny',
        familyName: 'Smith',
      );
      final viewed = app.copyWith(status: ApplicationStatus.viewed);
      expect(viewed.status, ApplicationStatus.viewed);
      expect(viewed.nannyName, 'Maria');
      expect(viewed.jobTitle, 'Nanny');
      expect(viewed.familyName, 'Smith');
    });
  });

  group('MockApplicationService one-application-per-job guard', () {
    setUp(() {
      Get.testMode = true;
      Get.put<IJobService>(MockJobService());
    });
    tearDown(Get.reset);

    test('first apply denormalizes job/family names', () async {
      final svc = MockApplicationService();
      final app = await svc.apply(nannyId: 'test_unique_nanny', jobId: 'job_1');
      expect(app.jobTitle, 'Live-in Nanny');
      expect(app.familyName, 'Al Mansoori');
      expect(app.status, ApplicationStatus.pending);
    });

    test('a second apply to the same job is rejected', () async {
      final svc = MockApplicationService();
      await svc.apply(nannyId: 'test_unique_nanny', jobId: 'job_1');
      await expectLater(
        svc.apply(nannyId: 'test_unique_nanny', jobId: 'job_1'),
        throwsA(predicate((e) => e.toString().contains('already_applied'))),
      );
    });

    test('re-apply is allowed once the prior application is withdrawn', () async {
      final svc = MockApplicationService();
      const nanny = 'test_unique_nanny_2';
      final first = await svc.apply(nannyId: nanny, jobId: 'job_1');
      await svc.withdraw(first.id);
      final second = await svc.apply(nannyId: nanny, jobId: 'job_1');
      expect(second.status, ApplicationStatus.pending);
    });
  });
}
