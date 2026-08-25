import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/nanny_shell_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/family/chat_screen.dart';
import 'package:kafi_app/views/family/settings_screen.dart';
import 'package:kafi_app/views/nanny/jobs_home_screen.dart';
import 'package:kafi_app/views/nanny/nanny_dashboard_screen.dart';
import 'package:kafi_app/views/widgets/kafi_bottom_nav.dart';

/// Main nanny app shell — one tab visible at a time (avoids IndexedStack hit-test issues).
class NannyShellScreen extends StatelessWidget {
  const NannyShellScreen({super.key});

  NannyShellController get _shell => Get.find<NannyShellController>();

  Widget _tabBody(int index) {
    switch (index) {
      case 0:
        return NannyDashboardScreen(
          embedInShell: true,
          onSeeAllJobs: () => _shell.goToTab(1),
        );
      case 1:
        return const JobsHomeScreen(embedInShell: true);
      case 2:
        return const ChatScreen(embedInShell: true);
      case 3:
        return const SettingsScreen(embedInShell: true);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final tab = _shell.tabIndex.value;
        var msgBadge = 0;
        if (Get.isRegistered<ChatController>()) {
          final chat = Get.find<ChatController>();
          for (final t in chat.threads) {
            chat.isNanny ? t.unreadCount.nanny : t.unreadCount.family;
          }
          msgBadge = tab == 2 ? 0 : chat.navMessageBadgeCount;
        }
        return Scaffold(
          body: SizedBox.expand(child: _tabBody(tab)),
          bottomNavigationBar: KafiBottomNav(
            activeIndex: tab,
            items: [
              KafiBottomNavItem(
                emoji: '🏠',
                label: AppStrings.navHome.tr,
                onTap: () => _shell.goToTab(0),
              ),
              KafiBottomNavItem(
                emoji: '💼',
                label: AppStrings.navJobs.tr,
                onTap: () => _shell.goToTab(1),
              ),
              KafiBottomNavItem(
                emoji: '💬',
                label: AppStrings.navMessages.tr,
                badgeCount: msgBadge,
                onTap: () => _shell.goToTab(2),
              ),
              KafiBottomNavItem(
                emoji: '👤',
                label: AppStrings.navProfile.tr,
                onTap: () => _shell.goToTab(3),
              ),
            ],
          ),
        );
      },
    );
  }
}
