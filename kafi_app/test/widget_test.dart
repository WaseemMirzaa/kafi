import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_translations.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/mock/mock_auth_service.dart';
import 'package:kafi_app/views/auth/welcome_screen.dart';

void main() {
  testWidgets('Welcome shows role cards', (tester) async {
    Get.testMode = true;
    Get.put<IAuthService>(MockAuthService());
    Get.put(AuthController());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const WelcomeScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Who are you?'), findsOneWidget);
    expect(find.text('I am a Nanny / Helper'), findsWidgets);
    expect(find.text('I am a Family'), findsWidgets);

    Get.reset();
  });
}
