import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/chat_controller.dart';

/// Tab index for [NannyShellScreen] bottom navigation.
class NannyShellController extends GetxController {
  final RxInt tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.currentRoute == Routes.nannyJobs) {
      tabIndex.value = 1;
    }
    if (Get.currentRoute == Routes.chat) {
      tabIndex.value = 2;
      _clearMessagesNavBadge();
    }
  }

  void goToTab(int index) {
    if (index < 0 || index > 3) return;
    final prev = tabIndex.value;
    tabIndex.value = index;
    if (index == 2 || prev == 2) _clearMessagesNavBadge();
  }

  void _clearMessagesNavBadge() {
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().onMessagesTabOpened();
    }
  }
}
