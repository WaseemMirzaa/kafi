import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';

class FcmNotificationService implements INotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _notifications = FirebaseFirestore.instance.collection('notifications');
  final _users = FirebaseFirestore.instance.collection('users');

  @override
  Future<void> initialize() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

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

  void _handleOpenedFromBackground(RemoteMessage message) {
    if (!Get.isRegistered<NotificationController>()) return;
    final ctrl = Get.find<NotificationController>();
    final data = message.data;
    final notif = AppNotification.fromMap({
      'id': data['notificationId']?.toString() ?? message.messageId ?? '',
      'userId': data['userId']?.toString() ?? '',
      'title': message.notification?.title ?? data['title']?.toString() ?? '',
      'body': message.notification?.body ?? data['body']?.toString() ?? '',
      'type': data['type']?.toString() ?? 'systemAnnouncement',
      'createdAt': DateTime.now().toIso8601String(),
      'data': data.map((k, v) => MapEntry(k.toString(), v)),
    });
    ctrl.handleNotificationTap(notif);
    ctrl.loadNotifications();
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  @override
  Future<String?> getToken() async {
    return await _messaging.getToken();
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
