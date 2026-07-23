import 'package:get/get.dart';
import 'package:kafi_app/controllers/trial_controller.dart';

/// Minimal, role-agnostic binding for the Trial screen (`Routes.trial`).
///
/// Both the family flow (`FamilyBinding`) and the nanny flow (`NannyBinding`)
/// already register `TrialController` — plus its service dependencies and the
/// global `PermissionController` / `SubscriptionController` — permanently before
/// this screen is reachable, so this only guarantees `TrialController` exists.
///
/// It deliberately does NOT pull in the family-only controllers that
/// `FamilyBinding` did (`FamilyShellController`, `BrowseController`,
/// `FamilyProfileController`, …). Under a nanny account those were `Get.put`
/// permanently the first time she opened a trial, which made
/// `Get.isRegistered<FamilyShellController>()` true — after which
/// `AppNavigation.openChat` took the family-shell branch and the nanny's own
/// chat-entry buttons went dead.
class TrialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TrialController>()) {
      Get.put(TrialController(), permanent: true);
    }
  }
}
