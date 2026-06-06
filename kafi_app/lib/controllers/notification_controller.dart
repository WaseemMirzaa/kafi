import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class NotificationController extends GetxController {
  final INotificationService _notifService = Get.find<INotificationService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  /// Queued chat deep-link when the user taps a notification before the
  /// family shell (and [ChatController]) has mounted.
  String? pendingChatThreadId;
  String? pendingChatNannyId;

  void clearPendingChatOpen() {
    pendingChatThreadId = null;
    pendingChatNannyId = null;
  }

  @override
  void onInit() {
    super.onInit();
    initFCM();
    // Reload inbox + register token whenever the user changes (login, logout,
    // role switch). Avoids stale empty inboxes for users who weren't logged
    // in at app start.
    ever<dynamic>(_auth.currentUser, (user) async {
      if (user == null) {
        notifications.clear();
        unreadCount.value = 0;
        return;
      }
      await loadNotifications();
      final token = await _notifService.getToken();
      if (token != null) await registerToken(token);
    });
    loadNotifications();
  }

  Future<void> initFCM() async {
    final granted = await _notifService.requestPermission();
    if (!granted) return;
    await _notifService.initialize();
    final token = await _notifService.getToken();
    if (token != null) {
      await registerToken(token);
    }
  }

  /// Persists the current device's FCM token against the signed-in user.
  /// Called on login, token refresh, and after FCM initialisation.
  Future<void> registerToken(String token) async {
    final userId = _auth.currentUser.value?.id;
    if (userId != null) {
      await _notifService.saveToken(userId, token);
    }
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final userId = currentUserId(_auth);
      if (userId == null) return;
      notifications.value = await _notifService.loadNotifications(userId);
      unreadCount.value = notifications.where((n) => !n.read).length;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    await _notifService.markAsRead(id);
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      notifications[idx] = notifications[idx].copyWith(read: true);
      unreadCount.value = notifications.where((n) => !n.read).length;
    }
  }

  Future<void> markAllAsRead() async {
    final userId = currentUserId(_auth);
    if (userId == null) return;
    await _notifService.markAllAsRead(userId);
    notifications.value = notifications.map((n) => n.copyWith(read: true)).toList();
    unreadCount.value = 0;
  }

  Future<void> deleteNotification(String id) async {
    await _notifService.delete(id);
    notifications.removeWhere((n) => n.id == id);
    unreadCount.value = notifications.where((n) => !n.read).length;
  }

  void handleNotificationTap(AppNotification notif) {
    markAsRead(notif.id);
    final route = notif.data['route'] as String?;
    if (route == null) return;

    if (route == Routes.chat) {
      if (_auth.currentUser.value?.isNanny ?? false) {
        AppNavigation.nannyGoToTab(2);
      } else {
        AppNavigation.familyGoToTab(2);
      }
      // If the notification carries a specific thread/nanny, open it.
      final threadId = notif.data['threadId'] as String?;
      final nannyId = notif.data['nannyId'] as String?;
      if (Get.isRegistered<ChatController>()) {
        final chat = Get.find<ChatController>();
        if (threadId != null && threadId.isNotEmpty) {
          chat.openThread(threadId);
        } else if (nannyId != null && nannyId.isNotEmpty) {
          chat.openThreadForNanny(nannyId: nannyId);
        }
      } else {
        pendingChatThreadId = threadId;
        pendingChatNannyId = nannyId;
      }
      return;
    }
    if (route == Routes.nannyHome || route == Routes.nannyJobs) {
      AppNavigation.nannyGoToTab(route == Routes.nannyJobs ? 1 : 0);
      return;
    }
    if (route == Routes.browse || route == Routes.shortlist) {
      AppNavigation.familyGoToTab(route == Routes.shortlist ? 1 : 0);
      return;
    }

    Get.toNamed(route, arguments: notif.data);
  }
}
