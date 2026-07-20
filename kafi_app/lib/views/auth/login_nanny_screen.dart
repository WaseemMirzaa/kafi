import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/auth_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class LoginNannyScreen extends StatefulWidget {
  const LoginNannyScreen({super.key});

  @override
  State<LoginNannyScreen> createState() => _LoginNannyScreenState();
}

class _LoginNannyScreenState extends State<LoginNannyScreen> {
  late final AuthController controller;

  // Sourced from the shared constant so the list lives in one place.
  static const _countryOptions = AuthConstants.nannyCountryOptions;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    controller.prepareNannyLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.roseP,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: Get.back,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new, size: 14, color: KafiColors.roseD),
                      Text(AppStrings.back.tr,
                          style: KafiTheme.nunito(12, color: KafiColors.roseD)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(child: KafiLogo(size: 28)),
              const SizedBox(height: 16),
              _banner(),
              const SizedBox(height: 22),
              Text(
                AppStrings.authEnterPhone.tr,
                style: KafiTheme.nunito(22, color: KafiColors.td, w: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.authEnterPhoneSub.tr,
                style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.authPhoneLabel.tr,
                style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Obx(() => _phoneInput()),
              Obx(
                () => controller.phoneError.value.isEmpty
                    ? const SizedBox(height: 16)
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          controller.phoneError.value,
                          style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w700),
                        ),
                      ),
              ),
              _otpNotice(),
              const SizedBox(height: 20),
              Obx(
                () => KafiPrimaryButton(
                  label: AppStrings.authSendOtp.tr,
                  icon: Icons.phone,
                  loading: controller.isLoading.value,
                  onPressed: controller.sendOtpAndNavigate,
                ),
              ),
              const SizedBox(height: 24),
              _divider(AppStrings.authAlreadyAccount.tr),
              const SizedBox(height: 14),
              _returningInfo(),
              const SizedBox(height: 20),
              _termsRow(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FAB), Color(0xFFFF4D82)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x44FF4D82), blurRadius: 16, spreadRadius: 0, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x22FF4D82), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.nannySignUpBanner.tr,
                  style: KafiTheme.nunito(13, color: Colors.white, w: FontWeight.w900),
                ),
                const SizedBox(height: 1),
                Text(
                  AppStrings.nannySignUpSub.tr,
                  style: KafiTheme.nunito(10, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneInput() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: KafiColors.cardBorder, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _countryOptions.firstWhere(
                (o) => o.contains(controller.countryCode.value),
                orElse: () => _countryOptions.first,
              ),
              isDense: true,
              style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w700),
              items: _countryOptions
                  .map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(o, style: KafiTheme.nunito(13, color: KafiColors.td)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final code = RegExp(r'\+\d+').stringMatch(v) ?? controller.countryCode.value;
                controller.countryCode.value = code;
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: KafiColors.cardBorder, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              style: KafiTheme.nunito(17, color: KafiColors.td, w: FontWeight.w700),
              decoration: InputDecoration(
                hintText: '50 234 5678',
                hintStyle: KafiTheme.nunito(17, color: KafiColors.cardBorder, w: FontWeight.w500),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _otpNotice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📱', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppStrings.authOtpNotice.tr,
            style: KafiTheme.nunito(11, color: KafiColors.tm, w: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _divider(String text) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFFFD8E8))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text, style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w700)),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFFFD8E8))),
      ],
    );
  }

  /// Returning users sign in the same way — enter the number above and verify
  /// the OTP. Firebase phone auth signs them back into the same account, so no
  /// password is needed.
  Widget _returningInfo() {
    return Center(
      child: Text(
        AppStrings.authSigninHint.tr,
        textAlign: TextAlign.center,
        style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w500),
      ),
    );
  }

  Widget _termsRow() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w500),
          children: [
            TextSpan(text: AppStrings.authAgreePrefix.tr),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.terms),
                child: Text(AppStrings.terms.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w700)),
              ),
            ),
            TextSpan(text: AppStrings.authAgreeAnd.tr),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => Get.toNamed(Routes.privacy),
                child: Text(AppStrings.privacy.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
