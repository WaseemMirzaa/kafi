import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> checkNotification() async =>
      (await Permission.notification.status).isGranted;

  Future<bool> checkCamera() async =>
      (await Permission.camera.status).isGranted;

  Future<bool> checkGallery() async {
    if (Platform.isAndroid) {
      // READ_MEDIA_* on Android 13+, READ_EXTERNAL_STORAGE on Android 12−.
      return _hasPhotoAccess(await Permission.photos.status) ||
          (await Permission.storage.status).isGranted;
    }
    return _hasPhotoAccess(await Permission.photos.status);
  }

  Future<bool> checkVideoGallery() async {
    if (Platform.isAndroid) {
      return _hasPhotoAccess(await Permission.videos.status) ||
          (await Permission.storage.status).isGranted;
    }
    return _hasPhotoAccess(await Permission.photos.status);
  }

  Future<bool> checkMicrophone() async =>
      (await Permission.microphone.status).isGranted;

  Future<bool> checkLocation() async =>
      (await Permission.locationWhenInUse.status).isGranted;

  Future<bool> checkContacts() async =>
      (await Permission.contacts.status).isGranted;

  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionNotificationDenied.tr);
    }
    return status.isGranted;
  }

  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionCameraDenied.tr);
    }
    return status.isGranted;
  }

  Future<bool> requestGallery() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (!_hasPhotoAccess(status)) {
        final legacyStatus = await Permission.storage.request();
        if (legacyStatus.isGranted) return true;
        if (legacyStatus.isPermanentlyDenied) status = legacyStatus;
      }
    } else {
      status = await Permission.photos.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionGalleryDenied.tr);
    }
    // iOS 14+ "Selected Photos" is sufficient for image_picker and must not
    // be treated as a denied permission.
    return _hasPhotoAccess(status);
  }

  Future<bool> requestVideoGallery() async {
    PermissionStatus status;
    if (Platform.isAndroid) {
      status = await Permission.videos.request();
      if (!_hasPhotoAccess(status)) {
        final legacyStatus = await Permission.storage.request();
        if (legacyStatus.isGranted) return true;
        if (legacyStatus.isPermanentlyDenied) status = legacyStatus;
      }
    } else {
      status = await Permission.photos.request();
    }
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionGalleryDenied.tr);
    }
    return _hasPhotoAccess(status);
  }

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionCameraDenied.tr);
    }
    return status.isGranted;
  }

  Future<bool> requestLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionPermanentlyDeniedBody.tr);
    }
    return status.isGranted;
  }

  Future<bool> requestContacts() async {
    final status = await Permission.contacts.request();
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionPermanentlyDeniedBody.tr);
    }
    return status.isGranted;
  }

  Future<void> openSettings() async => openAppSettings();

  Future<void> _showSettingsDialog(String bodyMessage) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(
          AppStrings.permissionPermanentlyDeniedTitle.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(bodyMessage),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: Text(
              AppStrings.permissionOpenSettings.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  bool _hasPhotoAccess(PermissionStatus status) =>
      status.isGranted || status.isLimited;
}
