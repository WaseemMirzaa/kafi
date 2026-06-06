import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_logo.dart';
import 'package:flutter/services.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class OtpVerifyScreen extends GetView<AuthController> {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.roseP,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: Get.back,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new,
                          size: 14, color: KafiColors.roseD),
                      Text(AppStrings.back.tr,
                          style: KafiTheme.nunito(12, color: KafiColors.roseD)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const KafiLogo(size: 26),
              const SizedBox(height: 22),
              Text(
                AppStrings.otpEnterTitle.tr,
                style: KafiTheme.nunito(22, color: KafiColors.td, w: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Obx(
                () => RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600),
                    children: [
                      TextSpan(text: '${AppStrings.otpEnterSub.tr.split(controller.formattedPhone).first}'),
                      TextSpan(
                        text: controller.formattedPhone,
                        style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _BigOtpBoxes(onChanged: (v) => controller.otpCode.value = v),
              const SizedBox(height: 14),
              Obx(
                () {
                  final label = controller.otpTimerLabel;
                  return RichText(
                    text: TextSpan(
                      style: KafiTheme.nunito(10.5, color: KafiColors.ts),
                      children: [
                        TextSpan(text: '${AppStrings.otpExpires.tr.split(label).first}'),
                        TextSpan(
                          text: label,
                          style: KafiTheme.nunito(10.5, color: KafiColors.roseD, w: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Obx(
                () {
                  final expired = controller.otpSecondsLeft.value <= 0;
                  final loading = controller.isLoading.value;
                  return KafiPrimaryButton(
                    label: expired
                        ? AppStrings.otpExpiredMessage.tr
                        : '${AppStrings.authVerifyOtp.tr}  →',
                    loading: loading,
                    onPressed: (!loading && !expired)
                        ? controller.verifyOtpAndNavigate
                        : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              Obx(
                () => Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text("Didn't receive it? ", style: KafiTheme.nunito(10, color: KafiColors.ts)),
                    GestureDetector(
                      onTap: controller.canResendOtp ? controller.resendOtp : null,
                      child: Text(
                        AppStrings.otpResend.tr,
                        style: KafiTheme.nunito(
                          10,
                          color: controller.canResendOtp ? KafiColors.roseD : KafiColors.ts,
                          w: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(' · ', style: KafiTheme.nunito(10, color: KafiColors.ts)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        AppStrings.otpChangeNumber.tr,
                        style: KafiTheme.nunito(10, color: KafiColors.roseD, w: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.otpSecurityNotice.tr,
                      style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigOtpBoxes extends StatefulWidget {
  const _BigOtpBoxes({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  State<_BigOtpBoxes> createState() => _BigOtpBoxesState();
}

class _BigOtpBoxesState extends State<_BigOtpBoxes> {
  static const _len = 6;
  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _focusNodes = List.generate(_len, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _notify() => widget.onChanged(_controllers.map((c) => c.text).join());

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_len, (i) {
        return Container(
          width: 42,
          height: 52,
          margin: EdgeInsets.only(right: i < _len - 1 ? 6 : 0),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: KafiTheme.nunito(22, color: KafiColors.td, w: FontWeight.w900),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.roseL, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.roseD, width: 2.5),
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && i < _len - 1) _focusNodes[i + 1].requestFocus();
              _notify();
            },
          ),
        );
      }),
    );
  }
}
