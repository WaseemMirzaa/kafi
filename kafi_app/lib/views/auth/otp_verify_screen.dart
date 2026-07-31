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
              Obx(() {
                // Split on the "@phone" token in the template (not on the phone
                // value) so the literal placeholder never leaks when the value
                // isn't present verbatim in the string.
                final parts = AppStrings.otpEnterSub.tr.split('@phone');
                return RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600),
                    children: [
                      TextSpan(text: parts.first),
                      TextSpan(
                        text: controller.formattedPhone,
                        style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w800),
                      ),
                      if (parts.length > 1) TextSpan(text: parts.sublist(1).join('@phone')),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),
              _BigOtpBoxes(onChanged: (v) => controller.otpCode.value = v),
              Obx(
                () => controller.otpError.value.isEmpty
                    ? const SizedBox(height: 14)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          controller.otpError.value,
                          textAlign: TextAlign.center,
                          style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w700),
                        ),
                      ),
              ),
              Obx(
                () {
                  final label = controller.otpTimerLabel;
                  // Split on the "@time" token so the placeholder can't leak.
                  final parts = AppStrings.otpExpires.tr.split('@time');
                  return RichText(
                    text: TextSpan(
                      style: KafiTheme.nunito(10.5, color: KafiColors.ts),
                      children: [
                        TextSpan(text: parts.first),
                        TextSpan(
                          text: label,
                          style: KafiTheme.nunito(10.5, color: KafiColors.roseD, w: FontWeight.w800),
                        ),
                        if (parts.length > 1) TextSpan(text: parts.sublist(1).join('@time')),
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
                    Text(AppStrings.authDidntReceive.tr, style: KafiTheme.nunito(10, color: KafiColors.ts)),
                    GestureDetector(
                      onTap: controller.canResendOtp ? controller.resendOtp : null,
                      child: Text(
                        controller.otpResendLabel,
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
  // One real (visually hidden) field backs the six boxes. This lets paste,
  // SMS / one-time-code autofill and backspace-across-boxes all work natively,
  // instead of the six single-char controllers that fought each of those
  // (maxLength:1 truncated a pasted/autofilled code, and an empty box swallowed
  // backspace) — NAN-6.
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Worker? _clearWorker;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncFromField);
    _focusNode.addListener(_repaint);
    // Clear when the controller resets the code (e.g. on Resend, which sets
    // otpCode to '') so stale digits don't linger while the model is empty.
    _clearWorker = ever<String>(Get.find<AuthController>().otpCode, (code) {
      if (code.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear(); // fires _syncFromField → repaints + notifies
      }
    });
  }

  void _syncFromField() {
    widget.onChanged(_controller.text);
    setState(() {});
  }

  void _repaint() => setState(() {});

  @override
  void dispose() {
    _clearWorker?.dispose();
    _controller.removeListener(_syncFromField);
    _focusNode.removeListener(_repaint);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final focused = _focusNode.hasFocus;
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_len, (i) {
            // Highlight the box being filled next while the field is focused,
            // mirroring the old per-field focus ring.
            final active = focused && i == text.length;
            return Container(
              width: 42,
              height: 52,
              margin: EdgeInsets.only(right: i < _len - 1 ? 6 : 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? KafiColors.roseD : KafiColors.roseL,
                  width: active ? 2.5 : 2,
                ),
              ),
              child: Text(
                i < text.length ? text[i] : '',
                style: KafiTheme.nunito(22, color: KafiColors.td, w: FontWeight.w900),
              ),
            );
          }),
        ),
        // Transparent full-bleed field that actually captures input. Its text
        // and cursor are transparent (not Opacity/Visibility, which can drop
        // interactivity), so a tap anywhere on the boxes focuses it and the
        // digits render in the boxes above.
        //
        // Explicitly clear EVERY border/fill variant — the app's
        // InputDecorationTheme otherwise paints enabled/focused OutlineBorders
        // on top of the digit boxes (visible pink overlay).
        Positioned.fill(
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
            child: AutofillGroup(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: _len,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                showCursor: false,
                cursorColor: Colors.transparent,
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 1,
                  height: 0.01,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  isCollapsed: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
