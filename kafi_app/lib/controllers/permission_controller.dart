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

  bool _startupRequested = false;

  @override
  void onInit() {
    super.onInit();
    checkAllPermissions();
  }

  /// One-time upfront permission request, fired right after the user picks a
  /// role on the welcome screen ("Get Started"). Guarded so it runs at most
  /// once per app session; individual features still re-request in context.
  /// Never throws — permission plugin failures are swallowed so they can't
  /// break the login flow that triggers this.
  Future<void> requestStartupPermissions() async {
    if (_startupRequested) return;
    _startupRequested = true;
    try {
      await _permService.requestStartupBatch();
    } catch (_) {
      // Best-effort: features still request their own permissions in context.
    }
    await checkAllPermissions();
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
    if (!cam) return false;
    final mic = await requestMicrophone();
    return mic;
  }

  Future<bool> ensureGallery() async => requestGallery();

  Future<bool> ensureVideoGallery() async {
    final granted = await _permService.requestVideoGallery();
    hasGalleryPermission.value = granted;
    return granted;
  }

  Future<void> openAppSettings() async {
    await _permService.openSettings();
  }
}
