import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// Password sign-in block for returning users on login screens.
class AuthReturningSection extends GetView<AuthController> {
  const AuthReturningSection({super.key, this.buttonVariant = KafiButtonVariant.rose});

  final KafiButtonVariant buttonVariant;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isReturning.value) {
        return TextButton(
          onPressed: () => controller.isReturning.value = true,
          child: Text(
            AppStrings.authSignInPassword.tr,
            style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w700),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.authSignInTitle.tr,
            style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(AppStrings.authSignInSub.tr, style: KafiTheme.nunito(10, color: KafiColors.ts)),
          const SizedBox(height: 12),
          Text(
            AppStrings.authPasswordLabel.tr,
            style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller.passwordController,
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => KafiPrimaryButton(
              label: AppStrings.authSignInPassword.tr,
              variant: buttonVariant,
              loading: controller.isLoading.value,
              onPressed: controller.loginWithPassword,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.toNamed(Routes.passwordReset),
              child: Text(AppStrings.authForgotPassword.tr, style: KafiTheme.nunito(10, color: KafiColors.roseD)),
            ),
          ),
          TextButton(
            onPressed: () => controller.isReturning.value = false,
            child: Text('Use OTP instead', style: KafiTheme.nunito(10, color: KafiColors.ts)),
          ),
        ],
      );
    });
  }
}
