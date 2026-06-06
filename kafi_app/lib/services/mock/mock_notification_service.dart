import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';

class MockNotificationService implements INotificationService {
  final Map<String, List<AppNotification>> _notifications = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => 'mock-fcm-token-12345';

  @override
  Future<void> saveToken(String userId, String token) async {}

  @override
  Future<void> removeToken(String userId, String token) async {}

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}

  @override
  Future<List<AppNotification>> loadNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _notifications[userId] ?? _seedFor(userId);
  }

  List<AppNotification> _seedFor(String userId) {
    final isNanny = userId.contains('nanny');
    final list = buildMockNotifications(userId, isNanny: isNanny);
    _notifications[userId] = list;
    return list;
  }

  @override
  Future<void> markAsRead(String notifId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final list in _notifications.values) {
      final i = list.indexWhere((n) => n.id == notifId);
      if (i >= 0) {
        list[i] = list[i].copyWith(read: true, readAt: DateTime.now());
        return;
      }
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _notifications[userId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(read: true, readAt: DateTime.now());
    }
  }

  @override
  Future<void> delete(String notifId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final list in _notifications.values) {
      list.removeWhere((n) => n.id == notifId);
    }
  }
}
