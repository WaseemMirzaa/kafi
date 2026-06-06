import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/family_shell_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/views/family/browse_screen.dart';
import 'package:kafi_app/views/family/chat_screen.dart';
import 'package:kafi_app/views/family/settings_screen.dart';
import 'package:kafi_app/views/family/shortlist_screen.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_bottom_nav.dart';

/// Main family app shell — one tab visible at a time.
class FamilyShellScreen extends StatelessWidget {
  const FamilyShellScreen({super.key});

  FamilyShellController get _shell => Get.find<FamilyShellController>();

  Widget _tabBody(int index) {
    switch (index) {
      case 0:
        return const BrowseScreen(embedInShell: true);
      case 1:
        return const ShortlistScreen(embedInShell: true);
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
    final subs = Get.find<SubscriptionController>();
    return Obx(
      () {
        final tab = _shell.tabIndex.value;
        final inGrace = subs.state.value == SubscriptionState.paymentGrace;
        // Browse tab (0) already renders its own grace banner with full
        // styling, so we only show the shell-level slim banner on other tabs.
        final showShellGrace = inGrace && tab != 0;
        return Scaffold(
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                if (showShellGrace) _shellGraceBanner(),
                Expanded(child: _tabBody(tab)),
              ],
            ),
          ),
          bottomNavigationBar: KafiBottomNav(
            activeIndex: tab,
            items: [
              KafiBottomNavItem(
                emoji: '🏠',
                label: AppStrings.navHome.tr,
                onTap: () => _shell.goToTab(0),
              ),
              KafiBottomNavItem(
                emoji: '❤️',
                label: AppStrings.navShortlist.tr,
                onTap: () => _shell.goToTab(1),
              ),
              KafiBottomNavItem(
                emoji: '💬',
                label: AppStrings.navMessages.tr,
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

  Widget _shellGraceBanner() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.pricing),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: KafiColors.ambL,
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: KafiColors.ambD, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                AppStrings.subGraceBanner.tr,
                style: KafiTheme.nunito(11,
                    color: const Color(0xFF7A4A00), w: FontWeight.w700),
              ),
            ),
            Text(AppStrings.subFixNow.tr,
                style: KafiTheme.nunito(11,
                    color: KafiColors.roseD, w: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
