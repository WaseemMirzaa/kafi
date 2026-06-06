import 'package:get/get.dart';
import 'package:kafi_app/services/permission_service.dart';

class PermissionController extends GetxController {
  final PermissionService _permService = Get.find<PermissionService>();

  final RxBool hasNotificationPermission = false.obs;
  final RxBool hasCameraPermission = false.obs;
  final RxBool hasGalleryPermission = false.obs;
  final RxBool hasMicrophonePermission = false.obs;
  final RxBool hasLocationPermission = false.obs;
  final RxBool hasContactsPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    hasNotificationPermission.value = await _permService.checkNotification();
    hasCameraPermission.value = await _permService.checkCamera();
    hasGalleryPermission.value = await _permService.checkGallery();
    hasMicrophonePermission.value = await _permService.checkMicrophone();
    hasLocationPermission.value = await _permService.checkLocation();
    hasContactsPermission.value = await _permService.checkContacts();
  }

  Future<bool> requestNotification() async {
    final granted = await _permService.requestNotification();
    hasNotificationPermission.value = granted;
    return granted;
  }

  Future<bool> requestCamera() async {
    final granted = await _permService.requestCamera();
    hasCameraPermission.value = granted;
    return granted;
  }

  Future<bool> requestGallery() async {
    final granted = await _permService.requestGallery();
    hasGalleryPermission.value = granted;
    return granted;
  }

  Future<bool> requestMicrophone() async {
    final granted = await _permService.requestMicrophone();
    hasMicrophonePermission.value = granted;
    return granted;
  }

  Future<bool> requestLocation() async {
    final granted = await _permService.requestLocation();
    hasLocationPermission.value = granted;
    return granted;
  }

  Future<bool> requestContacts() async {
    final granted = await _permService.requestContacts();
    hasContactsPermission.value = granted;
    return granted;
  }

  Future<bool> ensureCameraAndMic() async {
    final cam = await requestCamera();
    final mic = await requestMicrophone();
    return cam && mic;
  }

  Future<bool> ensureGallery() async => requestGallery();

  Future<void> openAppSettings() async {
    await _permService.openSettings();
  }
}
