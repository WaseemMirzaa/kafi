import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/utils/constants/auth_constants.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_password_strength.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String _countryCode = '+971';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authPhoneRequired.tr);
      return;
    }
    setState(() => _loading = true);
    try {
      await Get.find<IAuthService>().sendPasswordResetOtp(_phoneCtrl.text, _countryCode);
      setState(() => _step = 1);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length < AuthConstants.otpLength) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authInvalidOtp.tr);
      return;
    }
    setState(() => _loading = true);
    try {
      await Get.find<IAuthService>().verifyPasswordResetOtp(_otpCtrl.text);
      setState(() => _step = 2);
    } catch (_) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.authInvalidOtp.tr);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_passCtrl.text.length < 8) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.pwWeak.tr);
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.pwMismatch.tr);
      return;
    }
    setState(() => _loading = true);
    try {
      await Get.find<IAuthService>().resetPassword(_otpCtrl.text, _passCtrl.text);
      Get.snackbar(AppStrings.pwResetSuccess.tr, AppStrings.pwResetSuccessMessage.tr);
      Get.offAllNamed(Routes.welcome);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.roseP,
      appBar: KafiAppBar(title: AppStrings.pwResetTitle.tr),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step == 0) ..._phoneStep(),
              if (_step == 1) ..._otpStep(),
              if (_step == 2) ..._passwordStep(),
              const Spacer(),
              KafiPrimaryButton(
                label: _step == 0
                    ? AppStrings.pwResetSendOtp.tr
                    : _step == 1
                        ? AppStrings.authVerify.tr
                        : AppStrings.createPwSave.tr,
                loading: _loading,
                onPressed: _loading
                    ? null
                    : _step == 0
                        ? _sendOtp
                        : _step == 1
                            ? _verifyOtp
                            : _resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _phoneStep() {
    return [
      Text(
        AppStrings.pwResetEnterPhone.tr,
        style: KafiTheme.nunito(13, color: KafiColors.tm),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: KafiColors.rose, width: 1.5),
            ),
            child: Text(_countryCode, style: KafiTheme.nunito(14, color: KafiColors.td)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '50 123 4567',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: KafiColors.rose, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: KafiColors.rose, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _otpStep() {
    return [
      Text(
        AppStrings.pwResetOtpSent.trParams({'phone': '$_countryCode${_phoneCtrl.text}'}),
        style: KafiTheme.nunito(13, color: KafiColors.tm),
      ),
      const SizedBox(height: 8),
      Text(
        AppStrings.pwResetEnterOtp.tr,
        style: KafiTheme.nunito(11, color: KafiColors.ts),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: AuthConstants.otpLength,
        textAlign: TextAlign.center,
        style: KafiTheme.fredoka(24, color: KafiColors.td),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: KafiColors.rose, width: 1.5),
          ),
        ),
      ),
    ];
  }

  List<Widget> _passwordStep() {
    return [
      Text(
        AppStrings.pwResetNewPassword.tr,
        style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: _passCtrl,
        obscureText: true,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: '••••••••',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: KafiColors.rose, width: 1.5),
          ),
        ),
      ),
      KafiPasswordStrength(password: _passCtrl.text),
      const SizedBox(height: 16),
      Text(
        AppStrings.pwResetConfirmPassword.tr,
        style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      TextField(
        controller: _confirmCtrl,
        obscureText: true,
        decoration: InputDecoration(
          hintText: '••••••••',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: KafiColors.rose, width: 1.5),
          ),
        ),
      ),
    ];
  }
}
