import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';

class SettingsController extends GetxController {
  final IUserService _userService = Get.find<IUserService>();
  final AuthController _auth = Get.find<AuthController>();

  final Rx<UserSettings> settings = const UserSettings().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser.value;
      if (user != null) {
        final data = await _userService.getSettings(user.id);
        if (data != null) {
          settings.value = UserSettings.fromMap(data);
          _applyLocale(settings.value.language);
        } else {
          settings.value = user.settings;
          _applyLocale(user.settings.language);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final user = _auth.currentUser.value;
    if (user == null) return;

    if (key == 'pushNotifications' && value == true) {
      await Get.find<PermissionController>().requestNotification();
    }

    settings.value = _applySettingUpdate(key, value);
    await _userService.updateSettings(user.id, {key: value});
  }

  UserSettings _applySettingUpdate(String key, dynamic value) {
    switch (key) {
      case 'pushNotifications':
        return settings.value.copyWith(pushNotifications: value as bool);
      case 'messageNotifications':
        return settings.value.copyWith(messageNotifications: value as bool);
      case 'jobMatchNotifications':
        return settings.value.copyWith(jobMatchNotifications: value as bool);
      case 'trialNotifications':
        return settings.value.copyWith(trialNotifications: value as bool);
      case 'profileViewNotifications':
        return settings.value.copyWith(profileViewNotifications: value as bool);
      case 'marketingNotifications':
        return settings.value.copyWith(marketingNotifications: value as bool);
      case 'emailNotifications':
        return settings.value.copyWith(emailNotifications: value as bool);
      case 'showOnlineStatus':
        return settings.value.copyWith(showOnlineStatus: value as bool);
      case 'language':
        return settings.value.copyWith(language: value as String);
      default:
        return settings.value;
    }
  }

  Future<void> changeLanguage(String langCode) async {
    await updateSetting('language', langCode);
    _applyLocale(langCode);
  }

  void _applyLocale(String langCode) {
    final code = langCode.toLowerCase();
    if (code.startsWith('ar')) {
      Get.updateLocale(const Locale('ar', 'AE'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }
}
