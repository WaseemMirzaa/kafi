import 'package:kafi_app/models/notification_model.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<String?> getToken();
  Future<void> saveToken(String userId, String token);
  Future<void> removeToken(String userId, String token);
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Future<List<AppNotification>> loadNotifications(String userId);
  Future<void> markAsRead(String notifId);
  Future<void> markAllAsRead(String userId);
  Future<void> delete(String notifId);
}
