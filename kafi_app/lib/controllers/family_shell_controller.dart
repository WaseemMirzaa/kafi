import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';

/// Tab index for [FamilyShellScreen] bottom navigation.
class FamilyShellController extends GetxController {
  final RxInt tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final route = Get.currentRoute;
    if (route == Routes.shortlist) tabIndex.value = 1;
    if (route == Routes.chat) tabIndex.value = 2;
    if (route == Routes.settings) tabIndex.value = 3;
  }

  void goToTab(int index) {
    if (index < 0 || index > 3) return;
    tabIndex.value = index;
  }
}
