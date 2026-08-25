import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';
import 'package:kafi_app/utils/constants/notification_constants.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:permission_handler/permission_handler.dart';

class FcmNotificationService implements INotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _notifications = FirebaseFirestore.instance.collection('notifications');
  final _users = FirebaseFirestore.instance.collection('users');
  final _localNotifications = FlutterLocalNotificationsPlugin();
  var _androidNotificationsReady = false;

  @override
  Future<void> initialize() async {
    await _setupAndroidNotifications();

    // On web, FCM needs a service worker (web/firebase-messaging-sw.js) and a
    // VAPID key to obtain a token; neither is configured, so token retrieval
    // is intentionally skipped there. The listeners below are still safe to
    // register. Any platform quirk must not crash startup — hence the guard.
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('FCM setForegroundNotificationPresentationOptions skipped: $e');
    }

    // Foreground messages — refresh inbox so badge/list updates without a
    // restart, and surface deep-link data into NotificationController.
    FirebaseMessaging.onMessage.listen((message) {
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().loadNotifications();
      }
      final title = message.notification?.title ?? message.data['title'] ?? '';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      if (title.isEmpty && body.isEmpty) return;
      final notif = AppNotification.fromMap({
        'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': '',
        'title': title,
        'body': body,
        'data': message.data,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (defaultTargetPlatform == TargetPlatform.android) {
        _showAndroidForegroundNotification(message, notif);
        return;
      }

      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: KafiColors.grnL,
        colorText: KafiColors.grnD,
        onTap: (_) {
          if (Get.isRegistered<NotificationController>()) {
            Get.find<NotificationController>().handleNotificationTap(notif);
          }
        },
      );
    });

    // User tapped a notification while the app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleOpenedFromBackground(message);
    });

    // App was launched cold from a notification tap.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleOpenedFromBackground(initial);
    }

    // Keep token fresh if Firebase rotates it.
    _messaging.onTokenRefresh.listen((token) async {
      if (Get.isRegistered<NotificationController>()) {
        await Get.find<NotificationController>().registerToken(token);
      }
    });
  }

  Future<void> _setupAndroidNotifications() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (_androidNotificationsReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        if (!Get.isRegistered<NotificationController>()) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          final notif = AppNotification.fromMap({
            'id': data['notificationId']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['userId']?.toString() ?? '',
            'title': data['title']?.toString() ?? '',
            'body': data['body']?.toString() ?? '',
            'type': data['type']?.toString() ?? 'systemAnnouncement',
            'createdAt': DateTime.now().toIso8601String(),
            'data': data,
          });
          Get.find<NotificationController>().handleNotificationTap(notif);
        } catch (e) {
          debugPrint('FCM local notification tap parse failed: $e');
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationConstants.fcmChannelId,
            NotificationConstants.fcmChannelName,
            description: NotificationConstants.fcmChannelDescription,
            importance: Importance.high,
          ),
        );

    _androidNotificationsReady = true;
  }

  Future<void> _showAndroidForegroundNotification(
    RemoteMessage message,
    AppNotification notif,
  ) async {
    await _setupAndroidNotifications();

    final title = notif.title;
    final body = notif.body;
    if (title.isEmpty && body.isEmpty) return;

    final payload = jsonEncode({
      ...notif.data,
      'title': title,
      'body': body,
      'notificationId': notif.id,
    });

    await _localNotifications.show(
      notif.id.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationConstants.fcmChannelId,
          NotificationConstants.fcmChannelName,
          channelDescription: NotificationConstants.fcmChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  void _handleOpenedFromBackground(RemoteMessage message) {
    if (!Get.isRegistered<NotificationController>()) return;
    final ctrl = Get.find<NotificationController>();
    final data = message.data;
    // Prefer the inbox enum name when present; otherwise map snake_case push
    // `data.type` so tap routing still hits the right NotificationType branch.
    final rawType = data['inboxType']?.toString() ??
        data['notificationType']?.toString() ??
        data['type']?.toString() ??
        'systemAnnouncement';
    final normalizedType = switch (rawType) {
      'new_message' => 'newMessage',
      'new_application' => 'newApplication',
      'application_viewed' => 'applicationViewed',
      'application_declined' => 'applicationDeclined',
      'trial_offer_received' => 'trialOfferReceived',
      'trial_accepted' || 'trial_counter_accepted' => 'trialAccepted',
      'trial_declined' || 'trial_counter_declined' => 'trialDeclined',
      'trial_countered' => 'trialCountered',
      'trial_starting_soon' => 'trialStartingSoon',
      'trial_ending_soon' => 'trialEndingSoon',
      'trial_completed' => 'trialCompleted',
      'documents_approved' || 'intro_video_approved' => 'documentsApproved',
      'documents_rejected' || 'intro_video_rejected' || 'profile_rejected' =>
        'documentsRejected',
      'profile_approved' => 'profileVerified',
      'hire_ended' => 'systemAnnouncement',
      _ => rawType,
    };
    final notif = AppNotification.fromMap({
      'id': data['notificationId']?.toString() ?? message.messageId ?? '',
      'userId': data['userId']?.toString() ?? '',
      'title': message.notification?.title ?? data['title']?.toString() ?? '',
      'body': message.notification?.body ?? data['body']?.toString() ?? '',
      'type': normalizedType,
      'createdAt': DateTime.now().toIso8601String(),
      'data': data.map((k, v) => MapEntry(k.toString(), v)),
    });
    ctrl.handleNotificationTap(notif);
    ctrl.loadNotifications();
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _setupAndroidNotifications();
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();

        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }

        // Android can still obtain an FCM token even if notifications are denied.
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
        return true;
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FCM requestPermission failed (non-fatal): $e');
      return defaultTargetPlatform == TargetPlatform.android;
    }
  }

  /// iOS FCM tokens depend on APNS. `getToken()` throws
  /// `firebase_messaging/apns-token-not-set` if called before the device token
  /// arrives, so poll briefly after permission + remote-notification registration.
  Future<void> _ensureApnsTokenReady() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    for (var attempt = 0;
        attempt < NotificationConstants.iosApnsMaxAttempts;
        attempt++) {
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) return;
      await Future<void>.delayed(Duration(milliseconds: 250 + attempt * 200));
    }
    debugPrint('FCM APNS token still unavailable after retries');
  }

  @override
  Future<String?> getToken() async {
    // Web token retrieval requires a VAPID key + service worker that this app
    // does not ship; calling getToken() there throws. Skip on web and fail
    // soft everywhere else so a missing/rotated token never crashes the app.
    if (kIsWeb) return null;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _ensureApnsTokenReady();
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _setupAndroidNotifications();
      }

      final maxAttempts = defaultTargetPlatform == TargetPlatform.android
          ? NotificationConstants.androidTokenMaxAttempts
          : 3;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final token = await _messaging.getToken();
        if (token != null) return token;
        await Future<void>.delayed(Duration(milliseconds: 200 + attempt * 150));
      }
      return null;
    } catch (e) {
      debugPrint('FCM getToken failed (non-fatal): $e');
      return null;
    }
  }

  @override
  Future<void> saveToken(String userId, String token) async {
    await _users.doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeToken(String userId, String token) async {
    await _users.doc(userId).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  @override
  Future<List<AppNotification>> loadNotifications(String userId) async {
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    return snap.docs
        .map((d) => AppNotification.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> markAsRead(String notifId) async {
    await _notifications.doc(notifId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snap = await _notifications
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> delete(String notifId) async {
    await _notifications.doc(notifId).delete();
  }
}
