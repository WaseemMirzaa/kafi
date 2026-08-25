import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/relative_time.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class NotificationsScreen extends GetView<NotificationController> {
  const NotificationsScreen({super.key});

  bool get _isNanny => Get.find<AuthController>().currentUser.value?.isNanny ?? false;

  // Role colour schemes — family purple, nanny rose.
  List<Color> get _heroColors =>
      _isNanny ? const [Color(0xFFFFE0EC), Color(0xFFFFF4EE)] : const [Color(0xFFEEE0FF), Color(0xFFF0D8FF)];
  Color get _accent => _isNanny ? KafiColors.roseD : KafiColors.pur;
  Color get _titleColor => _isNanny ? KafiColors.roseD : const Color(0xFF5A2090);
  Color get _unreadBg => _isNanny ? const Color(0xFFFFF0F8) : const Color(0xFFF5EEFF);
  Color get _unreadBorder => _isNanny ? KafiColors.roseL : KafiColors.purB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: CircularProgressIndicator(color: _accent));
                }
                if (controller.loadError.value != null &&
                    controller.notifications.isEmpty) {
                  return _errorState();
                }
                if (controller.notifications.isEmpty) {
                  return _emptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  itemCount: controller.notifications.length,
                  itemBuilder: (_, i) => _notificationCard(controller.notifications[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _heroColors,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: AppNavigation.back,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: _accent, size: 20),
            ),
          ),
          Expanded(
            child: Text(AppStrings.notificationsTitle.tr,
                style: KafiTheme.pacifico(17, color: _titleColor)),
          ),
          Obx(() => controller.unreadCount.value > 0
              ? GestureDetector(
                  onTap: controller.markAllAsRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(AppStrings.notificationsMarkAll.tr,
                        style: KafiTheme.fredoka(10, color: _accent, w: FontWeight.w700)),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 52, color: _accent.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.notificationsEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 52, color: _accent.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.loadErrorTitle.tr,
              style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(AppStrings.loadErrorSub.tr,
              textAlign: TextAlign.center,
              style: KafiTheme.nunito(11, color: KafiColors.ts)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: controller.loadNotifications,
            child: Text(AppStrings.retry.tr,
                style: KafiTheme.fredoka(12, color: _accent, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(AppNotification notif) {
    final icon = _getIcon(notif.type);
    final color = _getColor(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.deleteNotification(notif.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: KafiColors.redD,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
      child: GestureDetector(
        onTap: () => controller.handleNotificationTap(notif),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: notif.read ? Colors.white : _unreadBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: notif.read ? const Color(0xFFEFEAF6) : _unreadBorder,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.title,
                        style: KafiTheme.nunito(11,
                            color: KafiColors.td,
                            w: notif.read ? FontWeight.w700 : FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(notif.body,
                        style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(_formatDate(notif.createdAt),
                        style: KafiTheme.nunito(9, color: KafiColors.ts)),
                  ],
                ),
              ),
              if (!notif.read)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newMessage:
        return Icons.chat_bubble;
      case NotificationType.profileViewed:
        return Icons.visibility;
      case NotificationType.trialOfferReceived:
      case NotificationType.trialAccepted:
        return Icons.handshake;
      case NotificationType.hired:
        return Icons.celebration;
      case NotificationType.documentsApproved:
      case NotificationType.profileVerified:
        return Icons.verified;
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionExpired:
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.hired:
      case NotificationType.trialAccepted:
      case NotificationType.documentsApproved:
        return KafiColors.grnD;
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionExpired:
        return KafiColors.ambD;
      case NotificationType.trialDeclined:
      case NotificationType.applicationDeclined:
        return KafiColors.redD;
      default:
        return _accent;
    }
  }

  String _formatDate(DateTime dt) => RelativeTime.ago(dt);
}
