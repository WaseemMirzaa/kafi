import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_translations.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/mock/mock_auth_service.dart';
import 'package:kafi_app/utils/constants/mock_constants.dart';
import 'package:kafi_app/views/auth/create_password_screen.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Covers the create-password step wired after OTP (Spec §6.1 / §6.2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SharedPreferences caches a single static instance for the whole file, so
  // clearing it before each test is the only reliable way to start pristine.
  Future<void> resetPrefs() async {
    SharedPreferences.setMockInitialValues({});
    await (await SharedPreferences.getInstance()).clear();
  }

  group('Create-password backend semantics (MockAuthService)', () {
    setUp(resetPrefs);

    test('new user has NO password after OTP finalize, then gains it', () async {
      final svc = MockAuthService();
      await svc.setUserRole(UserType.family);
      await svc.sendOtp('501234567', '+971');
      await svc.verifyOtp(MockConstants.otp);
      await svc.finalizePhoneRegistration();

      final afterOtp = await svc.getCurrentUser();
      expect(afterOtp, isNotNull);
      expect(
        afterOtp!.hasPassword,
        isFalse,
        reason: 'a brand-new user must be routed to /create-password',
      );
      expect(afterOtp.type, UserType.family,
          reason: 'role chosen on the login screen must be persisted');

      await svc.createPassword('Passw0rd!');
      final afterPw = await svc.getCurrentUser();
      expect(afterPw!.hasPassword, isTrue,
          reason: 'setting a password flips hasPassword and unlocks onboarding');
    });

    test('finalize preserves an already-set password (returning via OTP)',
        () async {
      // A user who already completed signup with a password.
      final first = MockAuthService();
      await first.setUserRole(UserType.nanny);
      await first.sendOtp('501234567', '+971');
      await first.verifyOtp(MockConstants.otp);
      await first.createPassword('Passw0rd!');
      expect((await first.getCurrentUser())!.hasPassword, isTrue);

      // A fresh service instance (e.g. app relaunch) re-runs OTP.
      final second = MockAuthService();
      await second.sendOtp('501234567', '+971');
      await second.verifyOtp(MockConstants.otp);
      await second.finalizePhoneRegistration();
      expect(
        (await second.getCurrentUser())!.hasPassword,
        isTrue,
        reason: 'finalize must never wipe an existing password',
      );
    });

    test('verifyOtp rejects the wrong code', () async {
      final svc = MockAuthService();
      await expectLater(svc.verifyOtp('000000'), throwsException);
    });
  });

  group('AuthController password validation', () {
    late AuthController controller;

    setUp(() async {
      await resetPrefs();
      Get.testMode = true;
      Get.put<IAuthService>(MockAuthService());
      controller = AuthController();
    });

    tearDown(Get.reset);

    test('canSavePassword requires 8+ chars AND a matching confirmation', () {
      controller.newPasswordController.text = 'Short1!';
      controller.confirmPasswordController.text = 'Short1!';
      expect(controller.hasMinLength, isFalse);
      expect(controller.canSavePassword, isFalse);

      controller.newPasswordController.text = 'LongEnough1!';
      controller.confirmPasswordController.text = 'LongEnough1!';
      expect(controller.hasMinLength, isTrue);
      expect(controller.passwordsMatch, isTrue);
      expect(controller.canSavePassword, isTrue);
    });

    test('mismatched confirmation blocks save', () {
      controller.newPasswordController.text = 'LongEnough1!';
      controller.confirmPasswordController.text = 'Different1!';
      expect(controller.passwordsMatch, isFalse);
      expect(controller.canSavePassword, isFalse);
    });

    test('strength score rises with complexity', () {
      controller.newPasswordController.text = 'aaaaaaaa';
      controller.confirmPasswordController.text = 'aaaaaaaa';
      controller.updatePasswordStrength();
      final weak = controller.passwordStrength.value;

      controller.newPasswordController.text = 'Aa1!aaaa';
      controller.confirmPasswordController.text = 'Aa1!aaaa';
      controller.updatePasswordStrength();
      final strong = controller.passwordStrength.value;

      expect(strong, greaterThan(weak));
      expect(strong, closeTo(1.0, 0.001));
    });
  });

  group('CreatePasswordScreen widget', () {
    setUp(() async {
      await resetPrefs();
      Get.testMode = true;
      Get.put<IAuthService>(MockAuthService());
      Get.put(AuthController());
    });

    tearDown(Get.reset);

    testWidgets('Save button is disabled until passwords are valid + match',
        (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const CreatePasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final saveButton = find.byType(KafiPrimaryButton);
      expect(saveButton, findsOneWidget);
      expect(
        tester.widget<KafiPrimaryButton>(saveButton).onPressed,
        isNull,
        reason: 'save must be disabled before a valid password is entered',
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'LongEnough1!');
      await tester.enterText(fields.at(1), 'LongEnough1!');
      await tester.pumpAndSettle();

      expect(
        tester.widget<KafiPrimaryButton>(saveButton).onPressed,
        isNotNull,
        reason: 'save enables once both fields are valid and match',
      );
    });
  });
}
