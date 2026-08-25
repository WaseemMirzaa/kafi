import 'package:get/get.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/browse_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/family_jobs_controller.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/controllers/family_shell_controller.dart';
import 'package:kafi_app/controllers/settings_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/controllers/ticket_controller.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';

class FamilyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SubscriptionController>()) {
      Get.put(SubscriptionController(), permanent: true);
    }
    Get.put(FamilyShellController(), permanent: true);
    Get.put(BrowseController(), permanent: true);
    Get.put(ShortlistController(), permanent: true);
    Get.put(ChatController(), permanent: true);
    Get.put(TrialController(), permanent: true);
    if (!Get.isRegistered<ApplicationController>()) {
      Get.put(ApplicationController(), permanent: true);
    }
    Get.put(FamilyProfileController(), permanent: true);
    Get.put(FamilyJobsController(), permanent: true);
    Get.put(TicketController(), permanent: true);
    if (!Get.isRegistered<DisputeController>()) {
      Get.put(DisputeController(), permanent: true);
    }
    Get.put(SettingsController(), permanent: true);
  }
}
