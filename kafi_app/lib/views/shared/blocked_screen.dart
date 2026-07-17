import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Shown when an admin has blocked the signed-in account. The account can no
/// longer be used — the only action is to log out. Reached from startup routing
/// and from the live block watcher (AuthController), so it also blocks a user
/// who gets blocked mid-session.
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  Future<void> _logout() async {
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().signOut();
    }
    Get.offAllNamed(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    // No AppBar / back button — the user must not be able to navigate back into
    // the app while blocked. PopScope prevents the system back gesture too.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF1F3),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: KafiColors.roseP,
                      shape: BoxShape.circle,
                      border: Border.all(color: KafiColors.roseL, width: 2),
                    ),
                    child: const Icon(Icons.block_rounded,
                        color: KafiColors.roseD, size: 44),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    AppStrings.blockedTitle.tr,
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(20, color: KafiColors.td, w: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppStrings.blockedBody.tr,
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(13, color: KafiColors.tm, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KafiColors.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.support_agent_rounded,
                            color: KafiColors.roseD, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppStrings.blockedContact.tr,
                            style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  KafiPrimaryButton(
                    label: AppStrings.blockedLogout.tr,
                    icon: Icons.logout_rounded,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
