import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
  }
}
