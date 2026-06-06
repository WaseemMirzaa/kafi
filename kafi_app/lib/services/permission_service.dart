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

  Future<bool> checkGallery() async =>
      (await _galleryPermission().status).isGranted;

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
    final status = await _galleryPermission().request();
    if (status.isPermanentlyDenied) {
      await _showSettingsDialog(AppStrings.permissionGalleryDenied.tr);
    }
    return status.isGranted;
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

  /// Android 13+ uses READ_MEDIA_IMAGES; older uses READ_EXTERNAL_STORAGE.
  Permission _galleryPermission() {
    if (Platform.isAndroid) return Permission.photos;
    return Permission.photos; // iOS: PHPhotoLibrary
  }
}
