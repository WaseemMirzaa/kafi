import 'package:get/get.dart';
import 'package:kafi_app/controllers/application_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/job_post_controller.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/controllers/nanny_shell_controller.dart';
import 'package:kafi_app/controllers/settings_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';

class NannyBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SubscriptionController>()) {
      Get.put(SubscriptionController(), permanent: true);
    }
    Get.put(NannyShellController(), permanent: true);
    Get.put(NannyProfileController(), permanent: true);
    Get.put(JobPostController(), permanent: true);
    Get.put(ApplicationController(), permanent: true);
    Get.put(ChatController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(TrialController(), permanent: true);
  }
}
