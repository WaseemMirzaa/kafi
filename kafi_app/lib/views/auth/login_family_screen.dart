import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';
import 'package:kafi_app/views/widgets/kafi_phone_input.dart';
import 'package:kafi_app/views/widgets/auth_returning_section.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class LoginFamilyScreen extends StatefulWidget {
  const LoginFamilyScreen({super.key});

  @override
  State<LoginFamilyScreen> createState() => _LoginFamilyScreenState();
}

class _LoginFamilyScreenState extends State<LoginFamilyScreen> {
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    controller.prepareFamilyLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE0FF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEEE0FF), Color(0xFFF5F0FF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 28),
                const KafiLogo(size: 24, purple: true),
                const SizedBox(height: 14),
                _banner(),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.authEnterPhone.tr,
                        style: KafiTheme.nunito(17, color: const Color(0xFF3A1060), w: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.authQuickSafeEasy.tr,
                        style: KafiTheme.nunito(10, color: const Color(0xFF7A50B0), w: FontWeight.w600),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        AppStrings.familyPhoneLabel.tr,
                        style: KafiTheme.nunito(9, color: const Color(0xFF5A2090), w: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Obx(
                        () => KafiPhoneInput(
                          purple: true,
                          controller: controller.phoneController,
                          countryCode: controller.countryCode.value,
                          onCountryChanged: (c) => controller.countryCode.value = c,
                          // Family country codes per System Spec §1.5.
                          countryOptions: const [
                            '🇦🇪 +971', '🇸🇦 +966', '🇰🇼 +965', '🇶🇦 +974', '🇧🇭 +973',
                            '🇴🇲 +968', '🇪🇬 +20', '🇱🇧 +961', '🇯🇴 +962', '🇲🇦 +212',
                            '🇬🇧 +44', '🇮🇪 +353', '🇫🇷 +33', '🇩🇪 +49', '🇮🇹 +39',
                            '🇪🇸 +34', '🇳🇱 +31', '🇨🇭 +41', '🇺🇸 +1', '🇨🇦 +1',
                            '🇮🇳 +91', '🇵🇰 +92', '🇸🇬 +65', '🇦🇺 +61', '🇳🇿 +64',
                          ],
                        ),
                      ),
                      Obx(
                        () => controller.phoneError.value.isEmpty
                            ? const SizedBox(height: 14)
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  controller.phoneError.value,
                                  style: KafiTheme.nunito(10, color: KafiColors.pur, w: FontWeight.w700),
                                ),
                              ),
                      ),
                      _otpNotice(),
                      const SizedBox(height: 14),
                      Obx(
                        () => KafiPrimaryButton(
                          label: AppStrings.authSendOtp.tr,
                          variant: KafiButtonVariant.purple,
                          icon: Icons.phone,
                          loading: controller.isLoading.value,
                          onPressed: controller.sendOtpAndNavigate,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _divider(AppStrings.authAlreadyAccount.tr),
                      const SizedBox(height: 10),
                      const AuthReturningSection(buttonVariant: KafiButtonVariant.purple),
                      const SizedBox(height: 14),
                      _termsRow(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.pur, Color(0xFFC084FC)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x449B6EDB), blurRadius: 16, spreadRadius: 0, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x229B6EDB), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.familyRegBanner.tr,
                  style: KafiTheme.fredoka(11, color: Colors.white, w: FontWeight.w800),
                ),
                Text(
                  AppStrings.familyRegSub.tr,
                  style: KafiTheme.nunito(9, color: Colors.white.withValues(alpha: 0.85), w: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpNotice() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        border: Border.all(color: KafiColors.purB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📱'),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              AppStrings.familyOtpNotice.tr,
              style: KafiTheme.nunito(9, color: const Color(0xFF5A2090), w: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(String text) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: KafiColors.purB)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: KafiTheme.nunito(10, color: const Color(0xFF9B6EDB), w: FontWeight.w700),
          ),
        ),
        Expanded(child: Container(height: 1, color: KafiColors.purB)),
      ],
    );
  }

  Widget _termsRow() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: KafiTheme.nunito(9, color: const Color(0xFF9B6EDB), w: FontWeight.w600),
          children: [
            TextSpan(text: AppStrings.authAgreePrefix.tr),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.terms),
                child: Text(
                  AppStrings.terms.tr,
                  style: KafiTheme.nunito(9, color: KafiColors.pur, w: FontWeight.w700),
                ),
              ),
            ),
            TextSpan(text: AppStrings.authAgreeAnd.tr),
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.privacy),
                child: Text(
                  AppStrings.privacy.tr,
                  style: KafiTheme.nunito(9, color: KafiColors.pur, w: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
