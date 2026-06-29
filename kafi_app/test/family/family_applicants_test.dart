import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/mock/mock_application_service.dart';
import 'package:kafi_app/services/mock/mock_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the family Applicants view (#5): the controller's optimistic status
/// updates that the screen renders when a family reviews an application.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApplicationController controller;

  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put<IAuthService>(MockAuthService());
    Get.put(AuthController());
    Get.put<IApplicationService>(MockApplicationService());
    // Construct directly (not via Get.put) so onInit's auto-load doesn't run.
    controller = ApplicationController();
    controller.receivedApplications.value = [
      ApplicationModel(
        id: 'a1',
        jobPostId: 'j1',
        nannyId: 'n1',
        familyId: 'f1',
        status: ApplicationStatus.pending,
        createdAt: DateTime(2026, 6, 20),
        nannyName: 'Maria Santos',
        jobTitle: 'Live-in Nanny',
      ),
    ];
  });

  tearDown(Get.reset);

  test('markAsViewed flips a pending application to viewed', () async {
    await controller.markAsViewed('a1');
    expect(controller.receivedApplications.first.status, ApplicationStatus.viewed);
  });

  test('shortlist flips the application to shortlisted', () async {
    await controller.shortlist('a1');
    expect(controller.receivedApplications.first.status,
        ApplicationStatus.shortlisted);
  });

  test('decline flips the application to declined', () async {
    await controller.decline('a1');
    expect(controller.receivedApplications.first.status,
        ApplicationStatus.declined);
  });

  test('the denormalized nanny/job names survive a status update', () async {
    await controller.shortlist('a1');
    final updated = controller.receivedApplications.first;
    expect(updated.nannyName, 'Maria Santos');
    expect(updated.jobTitle, 'Live-in Nanny');
  });
}
