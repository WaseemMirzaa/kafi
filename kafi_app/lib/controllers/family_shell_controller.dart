import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/chat_controller.dart';

/// Tab index for [FamilyShellScreen] bottom navigation.
class FamilyShellController extends GetxController {
  final RxInt tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final route = Get.currentRoute;
    if (route == Routes.shortlist) tabIndex.value = 1;
    if (route == Routes.chat) {
      tabIndex.value = 2;
      _clearMessagesNavBadge();
    }
    if (route == Routes.settings) tabIndex.value = 3;
  }

  void goToTab(int index) {
    if (index < 0 || index > 3) return;
    final prev = tabIndex.value;
    tabIndex.value = index;
    // Entering or leaving Messages: acknowledge current unread so the nav
    // badge clears on open and does not reappear for mail already seen on the list.
    if (index == 2 || prev == 2) _clearMessagesNavBadge();
  }

  void _clearMessagesNavBadge() {
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().onMessagesTabOpened();
    }
  }
}
