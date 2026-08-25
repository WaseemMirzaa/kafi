import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';
import 'package:kafi_app/services/interfaces/i_ticket_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/auth_scope.dart';

class NotificationController extends GetxController {
  final INotificationService _notifService = Get.find<INotificationService>();
  final AuthController _auth = Get.find<AuthController>();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();

  /// Queued chat deep-link when the user taps a notification before the
  /// family shell (and [ChatController]) has mounted.
  String? pendingChatThreadId;
  String? pendingChatNannyId;
  String? pendingChatFamilyId;

  void clearPendingChatOpen() {
    pendingChatThreadId = null;
    pendingChatNannyId = null;
    pendingChatFamilyId = null;
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
    loadError.value = null;
    try {
      final userId = currentUserId(_auth);
      if (userId == null) return;
      notifications.value = await _notifService.loadNotifications(userId);
      unreadCount.value = notifications.where((n) => !n.read).length;
    } catch (e) {
      // A failed read must surface as an error+retry, not masquerade as an empty
      // inbox — the screen previously had only loading + empty states.
      Get.log('notifications load failed: $e', isError: true);
      loadError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _notifService.markAsRead(id);
      final idx = notifications.indexWhere((n) => n.id == id);
      if (idx >= 0) {
        notifications[idx] = notifications[idx].copyWith(read: true);
        unreadCount.value = notifications.where((n) => !n.read).length;
      }
    } catch (e) {
      // Incidental (tapping an item) — log, don't disrupt navigation.
      Get.log('markAsRead failed: $e', isError: true);
    }
  }

  Future<void> markAllAsRead() async {
    final userId = currentUserId(_auth);
    if (userId == null) return;
    try {
      await _notifService.markAllAsRead(userId);
      notifications.value = notifications.map((n) => n.copyWith(read: true)).toList();
      unreadCount.value = 0;
    } catch (e) {
      Get.log('markAllAsRead failed: $e', isError: true);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _notifService.delete(id);
      notifications.removeWhere((n) => n.id == id);
      unreadCount.value = notifications.where((n) => !n.read).length;
    } catch (e) {
      // Keep the item (the delete didn't take) rather than silently dropping it.
      Get.log('deleteNotification failed: $e', isError: true);
    }
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

  String? _dataString(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  void handleNotificationTap(AppNotification notif) {
    markAsRead(notif.id);

    final data = notif.data;
    final dataType = _dataString(data, 'type');

    // Support tickets and disputes are written by Cloud Functions with the
    // generic `systemAnnouncement` type (no NotificationType enum value exists
    // for them); the real kind + target id ride in `data`. Route these to the
    // relevant thread so the tap isn't a dead end on the no-op default branch.
    if (dataType == 'support_reply' ||
        dataType == 'support_resolved' ||
        dataType == 'support_closed') {
      _openTicketThread(_dataString(data, 'ticketId'));
      return;
    }
    if (dataType == 'dispute_reply' ||
        dataType == 'dispute_resolved' ||
        dataType == 'dispute_dismissed') {
      _openDisputeThread(_dataString(data, 'disputeId'));
      return;
    }

    final isNanny = _auth.currentUser.value?.isNanny ?? false;
    final threadId = _dataString(data, 'threadId');
    final nannyId = _dataString(data, 'nannyId');
    final familyId = _dataString(data, 'familyId');
    final jobPostId = _dataString(data, 'jobPostId');
    final trialId = _dataString(data, 'trialId');
    final route = _dataString(data, 'route');

    // Prefer concrete counterpart deep-links over generic list routes.
    switch (notif.type) {
      case NotificationType.newMessage:
        _openChatDetail(
          threadId: threadId,
          nannyId: nannyId,
          familyId: familyId,
          isNannyViewer: isNanny,
        );
        return;
      case NotificationType.newApplication:
        // Family: open the applying nanny's profile detail.
        if (!isNanny && nannyId != null) {
          _openNannyDetail(nannyId);
          return;
        }
        Get.toNamed(Routes.familyApplicants);
        return;
      case NotificationType.applicationViewed:
      case NotificationType.applicationDeclined:
        // Nanny: open the family's job detail when we have a job id.
        if (isNanny && jobPostId != null) {
          _openJobDetail(jobPostId);
          return;
        }
        if (isNanny) {
          Get.toNamed(Routes.nannyApplications);
        } else {
          Get.toNamed(Routes.familyApplicants);
        }
        return;
      case NotificationType.trialOfferReceived:
      case NotificationType.trialAccepted:
      case NotificationType.trialDeclined:
      case NotificationType.trialCountered:
      case NotificationType.trialStartingSoon:
      case NotificationType.trialEndingSoon:
      case NotificationType.trialCompleted:
      case NotificationType.trialOutcomePending:
        _openTrialDetail(trialId);
        return;
      case NotificationType.hired:
        _openChatDetail(
          threadId: threadId,
          nannyId: nannyId,
          familyId: familyId,
          isNannyViewer: isNanny,
        );
        return;
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionRenewed:
      case NotificationType.subscriptionExpired:
      case NotificationType.freeContactsLow:
        if (!isNanny) Get.toNamed(Routes.pricing);
        return;
      case NotificationType.documentsApproved:
      case NotificationType.documentsRejected:
      case NotificationType.profileVerified:
        if (isNanny) AppNavigation.nannyGoToTab(0);
        return;
      case NotificationType.profileViewed:
        if (isNanny) AppNavigation.nannyGoToTab(0);
        return;
      case NotificationType.systemAnnouncement:
        break;
    }

    // FCM / legacy payloads often put the semantic type only in `data.type`
    // (snake_case) while the inbox enum falls back to systemAnnouncement.
    if (dataType == 'new_message' || dataType == 'hired' || dataType == 'hire_ended') {
      _openChatDetail(
        threadId: threadId,
        nannyId: nannyId,
        familyId: familyId,
        isNannyViewer: isNanny,
      );
      return;
    }
    if (dataType == 'new_application' && !isNanny && nannyId != null) {
      _openNannyDetail(nannyId);
      return;
    }
    if ((dataType == 'application_viewed' || dataType == 'application_declined') &&
        isNanny &&
        jobPostId != null) {
      _openJobDetail(jobPostId);
      return;
    }
    if (dataType != null && dataType.startsWith('trial') && trialId != null) {
      _openTrialDetail(trialId);
      return;
    }

    if (route != null) {
      if (route == Routes.chat || route == '/chat') {
        _openChatDetail(
          threadId: threadId,
          nannyId: nannyId,
          familyId: familyId,
          isNannyViewer: isNanny,
        );
        return;
      }
      if (route == Routes.trial || route == '/trial') {
        _openTrialDetail(trialId);
        return;
      }
      _openRouteForRole(route);
      return;
    }
  }

  void _openChatDetail({
    String? threadId,
    String? nannyId,
    String? familyId,
    required bool isNannyViewer,
  }) {
    if (isNannyViewer) {
      final fam = familyId;
      if (fam != null && fam.isNotEmpty) {
        AppNavigation.openChatWithFamily(familyId: fam);
        if (threadId != null &&
            threadId.isNotEmpty &&
            Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().openThread(threadId);
        }
        return;
      }
    } else {
      final nan = nannyId;
      if (nan != null && nan.isNotEmpty) {
        AppNavigation.openChat(nannyId: nan);
        if (threadId != null &&
            threadId.isNotEmpty &&
            Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().openThread(threadId);
        }
        return;
      }
    }

    _openRouteForRole(Routes.chat);
    if (Get.isRegistered<ChatController>()) {
      final chat = Get.find<ChatController>();
      if (threadId != null && threadId.isNotEmpty) {
        chat.openThread(threadId);
      } else if (!isNannyViewer && nannyId != null && nannyId.isNotEmpty) {
        chat.openThreadForNanny(nannyId: nannyId);
      } else if (isNannyViewer && familyId != null && familyId.isNotEmpty) {
        chat.openThreadForFamily(familyId: familyId);
      }
    } else {
      pendingChatThreadId = threadId;
      pendingChatNannyId = nannyId;
      pendingChatFamilyId = familyId;
    }
  }

  Future<void> _openNannyDetail(String nannyId) async {
    try {
      final nanny = await Get.find<IUserService>().getNanny(nannyId);
      if (nanny != null) {
        AppNavigation.openNannyProfile(NannyCardModel.fromNanny(nanny));
        return;
      }
    } catch (e) {
      Get.log('open nanny from notification failed: $e', isError: true);
    }
    Get.toNamed(Routes.familyApplicants);
  }

  Future<void> _openJobDetail(String jobPostId) async {
    try {
      final job = await Get.find<IJobService>().getJob(jobPostId);
      if (job != null) {
        Get.toNamed(Routes.nannyJobDetail, arguments: job);
        return;
      }
    } catch (e) {
      Get.log('open job from notification failed: $e', isError: true);
    }
    Get.toNamed(Routes.nannyApplications);
  }

  void _openTrialDetail(String? trialId) {
    Get.toNamed(
      Routes.trial,
      arguments: trialId != null && trialId.isNotEmpty
          ? <String, dynamic>{'trialId': trialId}
          : null,
    );
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
