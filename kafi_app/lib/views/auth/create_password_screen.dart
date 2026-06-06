import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class CreatePasswordScreen extends GetView<AuthController> {
  const CreatePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8EE),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F8EE), Color(0xFFFFF4EE)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: KafiLogo(size: 24)),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: KafiColors.successGradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.otpVerified.tr,
                              style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w800),
                            ),
                            Text(
                              AppStrings.otpVerifiedSub.tr,
                              style: KafiTheme.nunito(9, color: Colors.white.withValues(alpha: 0.9), w: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.createPwTitle.tr,
                  style: KafiTheme.nunito(17, color: KafiColors.td, w: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.createPwSub.tr,
                  style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.createPwLabel.tr,
                  style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: controller.newPasswordController,
                  obscureText: true,
                  onChanged: (_) => controller.updatePasswordStrength(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    filled: true,
                    fillColor: const Color(0xFFFFF7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFFFD8E8), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFFFD8E8), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: KafiColors.roseD, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  final s = controller.passwordStrength.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s,
                          minHeight: 4,
                          backgroundColor: KafiColors.roseP,
                          color: KafiColors.grn,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.passwordStrengthLabel,
                        style: KafiTheme.nunito(9, color: KafiColors.grnD, w: FontWeight.w700),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  AppStrings.createPwConfirm.tr,
                  style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: controller.confirmPasswordController,
                  obscureText: true,
                  onChanged: (_) => controller.updatePasswordStrength(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    filled: true,
                    fillColor: const Color(0xFFFFF7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFFFD8E8), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: Color(0xFFFFD8E8), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(color: KafiColors.roseD, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () {
                    // Subscribe to strength updates so the button enables when passwords match.
                    final _ = controller.passwordStrength.value;
                    final loading = controller.isLoading.value;
                    final canSave = controller.canSavePassword;
                    return KafiPrimaryButton(
                      label: AppStrings.createPwSave.tr,
                      variant: KafiButtonVariant.green,
                      loading: loading,
                      onPressed: !loading && canSave ? controller.savePasswordAndNavigate : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
