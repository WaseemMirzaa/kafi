import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openNanny() {
    Get.find<AuthController>().prepareNannyLogin();
    Get.toNamed(Routes.loginNanny);
  }

  void _openFamily() {
    Get.find<AuthController>().prepareFamilyLogin();
    Get.toNamed(Routes.loginFamily);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4EF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE4EF), Color(0xFFFFF4EE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
              child: Column(
                children: [
                  const KafiLogo(size: 26),
                  const SizedBox(height: 12),
                  Text(
                    '${AppStrings.welcomeTagline.tr} 🌸',
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    AppStrings.welcomeWhoAreYou.tr,
                    style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppStrings.welcomeRoleHint.tr,
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 18),
                  _RoleCard(
                    title: AppStrings.roleNannyTitle.tr,
                    subtitle: AppStrings.roleNannySubtitle.tr,
                    badges: [
                      AppStrings.badgeFreeForever.tr,
                      AppStrings.badgeUploadProfile.tr,
                      AppStrings.badgeGetFound.tr,
                    ],
                    gradient: const [KafiColors.rose, KafiColors.roseD],
                    icon: Icons.person_outline,
                    onTap: _openNanny,
                  ),
                  const SizedBox(height: 11),
                  _RoleCard(
                    title: AppStrings.roleFamilyTitle.tr,
                    subtitle: AppStrings.roleFamilySubtitle.tr,
                    badges: [
                      AppStrings.badgeBrowseNannies.tr,
                      AppStrings.badgeSmartMatch.tr,
                      AppStrings.badgeFromPrice.tr,
                    ],
                    gradient: const [KafiColors.pur, Color(0xFFC084FC)],
                    icon: Icons.home_outlined,
                    onTap: _openFamily,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppStrings.welcomeHaveAccount.tr,
                    textAlign: TextAlign.center,
                    style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Get.find<AuthController>().prepareNannyLogin();
                          Get.find<AuthController>().isReturning.value = true;
                          Get.toNamed(Routes.loginNanny);
                        },
                        child: Text(
                          AppStrings.roleNannyTitle.tr,
                          style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w700),
                        ),
                      ),
                      Text('·', style: KafiTheme.nunito(10, color: KafiColors.ts)),
                      TextButton(
                        onPressed: () {
                          Get.find<AuthController>().prepareFamilyLogin();
                          Get.find<AuthController>().isReturning.value = true;
                          Get.toNamed(Routes.loginFamily);
                        },
                        child: Text(
                          AppStrings.roleFamilyTitle.tr,
                          style: KafiTheme.nunito(10, color: KafiColors.pur, w: FontWeight.w700),
                        ),
                      ),
                    ],
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> badges;
  final List<Color> gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 3,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.15),
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset.zero,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: KafiTheme.fredoka(15, color: Colors.white, w: FontWeight.w900),
                          ),
                          Text(
                            subtitle,
                            style: KafiTheme.nunito(9.5, color: Colors.white.withValues(alpha: 0.85), w: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: badges
                      .map((b) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              b,
                              style: KafiTheme.fredoka(9, color: Colors.white, w: FontWeight.w700),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
