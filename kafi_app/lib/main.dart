import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kafi_app/firebase_options.dart';
import 'package:get/get.dart';
import 'package:kafi_app/bindings/initial_binding.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/l10n/app_translations.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(KafiTheme.darkStatusBar);
  if (!AppConfig.useMock) {
    try {
      // On Android the native google-services.json (git-ignored; see
      // FIREBASE_SETUP.md / BUILD_APK.md) is the source of truth, so initialize
      // without explicit options — keeps real credentials out of tracked source.
      // Other platforms use the generated firebase_options.dart.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await Firebase.initializeApp();
      } else {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    } catch (e, st) {
      debugPrint('Firebase init failed (add firebase_options / google-services): $e\n$st');
    }
  } else if (AppConfig.enableLogs) {
    debugPrint('Kafi running in MOCK mode');
  }
  runApp(const KafiApp());
}

class KafiApp extends StatelessWidget {
  const KafiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName.tr,
      debugShowCheckedModeBanner: false,
      theme: KafiTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'AE'),
      ],
      initialBinding: InitialBinding(),
      initialRoute: Routes.welcome,
      getPages: AppRoutes.routes,
    );
  }
}
