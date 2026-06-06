import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';

/// Tab index for [NannyShellScreen] bottom navigation.
class NannyShellController extends GetxController {
  final RxInt tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.currentRoute == Routes.nannyJobs) {
      tabIndex.value = 1;
    }
  }

  void goToTab(int index) {
    if (index < 0 || index > 3) return;
    tabIndex.value = index;
  }
}
