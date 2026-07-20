import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';
import 'package:kafi_app/services/interfaces/i_ticket_service.dart';
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
    // FCM setup is best-effort: on web (no service worker / VAPID key) or when
    // the user denies permission it must degrade gracefully, never throw an
    // uncaught error that surfaces in the console or blocks the app.
    try {
      await _notifService.requestPermission();
      await _notifService.initialize();
      final token = await _notifService.getToken();
      if (token != null) {
        await registerToken(token);
      }
    } catch (e) {
      Get.log('initFCM failed (non-fatal): $e');
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

  void _openRouteForRole(String route) {
    if (route == Routes.chat) {
      if (_auth.currentUser.value?.isNanny ?? false) {
        AppNavigation.nannyGoToTab(2);
      } else {
        AppNavigation.familyGoToTab(2);
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
    if (route == Routes.settings) {
      AppNavigation.familyGoToTab(3);
      return;
    }
    Get.toNamed(route);
  }

  void handleNotificationTap(AppNotification notif) {
    markAsRead(notif.id);

    // Support tickets and disputes are written by Cloud Functions with the
    // generic `systemAnnouncement` type (no NotificationType enum value exists
    // for them); the real kind + target id ride in `data`. Route these to the
    // relevant thread so the tap isn't a dead end on the no-op default branch.
    final dataType = notif.data['type'] as String?;
    if (dataType == 'support_reply') {
      _openTicketThread(notif.data['ticketId'] as String?);
      return;
    }
    if (dataType == 'dispute_reply' ||
        dataType == 'dispute_resolved' ||
        dataType == 'dispute_dismissed') {
      _openDisputeThread(notif.data['disputeId'] as String?);
      return;
    }

    final route = notif.data['route'] as String?;
    final isNanny = _auth.currentUser.value?.isNanny ?? false;

    if (route != null) {
      _openRouteForRole(route);

      if (route == Routes.chat) {
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
      }
      return;
    }

    // Legacy / server-generated notifications often omit `route`.
    switch (notif.type) {
      case NotificationType.newApplication:
        if (!isNanny) {
          Get.toNamed(Routes.familyApplicants);
        }
        return;
      case NotificationType.applicationViewed:
      case NotificationType.applicationDeclined:
        if (isNanny) {
          Get.toNamed(Routes.nannyApplications);
        } else {
          Get.toNamed(Routes.familyApplicants);
        }
        return;
      case NotificationType.newMessage:
      case NotificationType.trialOfferReceived:
      case NotificationType.trialAccepted:
      case NotificationType.trialDeclined:
      case NotificationType.trialCountered:
      case NotificationType.trialStartingSoon:
      case NotificationType.trialEndingSoon:
      case NotificationType.trialCompleted:
        _openRouteForRole(Routes.chat);
        return;
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionRenewed:
      case NotificationType.subscriptionExpired:
      case NotificationType.freeContactsLow:
        if (!isNanny) {
          Get.toNamed(Routes.pricing);
        }
        return;
      case NotificationType.profileViewed:
      case NotificationType.documentsApproved:
      case NotificationType.documentsRejected:
      case NotificationType.profileVerified:
      case NotificationType.hired:
      case NotificationType.systemAnnouncement:
        return;
    }
  }

  /// Opens a support ticket from a notification tap. The detail screen needs the
  /// [TicketModel] as its route argument, so load it first; fall back to the
  /// ticket list if the id is missing or the load fails.
  Future<void> _openTicketThread(String? ticketId) async {
    if (ticketId == null || ticketId.isEmpty) {
      Get.toNamed(Routes.support);
      return;
    }
    try {
      final ticket = await Get.find<ITicketService>().getTicket(ticketId);
      if (ticket != null) {
        Get.toNamed(Routes.supportTicket, arguments: ticket);
      } else {
        Get.toNamed(Routes.support);
      }
    } catch (e) {
      Get.log('open ticket from notification failed: $e', isError: true);
      Get.toNamed(Routes.support);
    }
  }

  /// Opens a dispute report thread from a notification tap. Same load-then-route
  /// pattern as tickets — the dispute chat screen needs the [DisputeModel] as
  /// its argument; fall back to the reports list if it can't be loaded.
  Future<void> _openDisputeThread(String? disputeId) async {
    if (disputeId == null || disputeId.isEmpty) {
      Get.toNamed(Routes.disputes);
      return;
    }
    try {
      final dispute = await Get.find<IDisputeService>().getDispute(disputeId);
      if (dispute != null) {
        Get.toNamed(Routes.disputeChat, arguments: dispute);
      } else {
        Get.toNamed(Routes.disputes);
      }
    } catch (e) {
      Get.log('open dispute from notification failed: $e', isError: true);
      Get.toNamed(Routes.disputes);
    }
  }
}
