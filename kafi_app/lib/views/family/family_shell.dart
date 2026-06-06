import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/views/widgets/kafi_bottom_nav.dart';

/// Legacy wrapper — prefer [FamilyShellScreen] in routes.
@Deprecated('Use FamilyShellScreen')
class FamilyShell extends StatelessWidget {
  const FamilyShell({
    super.key,
    required this.navIndex,
    required this.body,
  });

  final int navIndex;
  final Widget body;

  void _onNavTap(int index) {
    if (index == navIndex) return;
    switch (index) {
      case 0:
        Get.offAllNamed(Routes.browse);
      case 1:
        Get.offAllNamed(Routes.browse);
        Get.snackbar('Shortlist', 'Coming soon');
      case 2:
        Get.offAllNamed(Routes.chat);
      case 3:
        Get.offAllNamed(Routes.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: KafiBottomNav(
        activeIndex: navIndex,
        items: [
          KafiBottomNavItem(
            emoji: '🏠',
            label: 'Browse',
            onTap: () => _onNavTap(0),
          ),
          KafiBottomNavItem(
            emoji: '❤️',
            label: 'Shortlist',
            onTap: () => _onNavTap(1),
          ),
          KafiBottomNavItem(
            emoji: '💬',
            label: 'Chat',
            onTap: () => _onNavTap(2),
          ),
          KafiBottomNavItem(
            emoji: '👤',
            label: 'Profile',
            onTap: () => _onNavTap(3),
          ),
        ],
      ),
    );
  }
}
