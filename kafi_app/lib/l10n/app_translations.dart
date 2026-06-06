import 'package:get/get.dart';
import 'package:kafi_app/l10n/locales/ar_ae.dart';
import 'package:kafi_app/l10n/locales/en_us.dart';

class AppTranslations extends Translations {
  static const localeEn = 'en_US';
  static const localeAr = 'ar_AE';

  static const fallbackLocale = localeEn;

  @override
  Map<String, Map<String, String>> get keys => {
        localeEn: enUs,
        localeAr: arAe,
      };
}
