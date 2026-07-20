import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/firebase_options.dart';
import 'package:get/get.dart';
import 'package:kafi_app/bindings/initial_binding.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/l10n/app_translations.dart';
import 'package:kafi_app/services/firebase/firebase_messaging_background.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Avoid runtime font downloads on Android; the cache path currently trips a
  // native jni/path_provider crash on this device/build.
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setSystemUIOverlayStyle(KafiTheme.darkStatusBar);
  if (!AppConfig.useMock) {
    try {
      // Live Firebase. If a native google-services.json (via the google-services
      // Gradle plugin) has already auto-initialized the default app, reuse it;
      // otherwise initialize from firebase_options.dart. In CI that file is
      // generated on the runner by scripts/materialize-secrets.sh from the
      // VITE_FIREBASE_* web secrets — Android reuses the web app config. See
      // BUILD_APK.md.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
      initialRoute: Routes.splash,
      getPages: AppRoutes.routes,
    );
  }
}
