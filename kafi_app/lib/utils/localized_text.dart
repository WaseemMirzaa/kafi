import 'package:get/get.dart';

/// Reads a translatable free-text field in the app's current language.
///
/// User-generated content (nanny bio, family "about", job notes, …) is stored
/// as the original string plus a sibling `<field>_i18n` map (`{ en, ar }`) that
/// the `translate*` Cloud Functions keep in sync on every add/edit. Returns the
/// translation for [lang] (defaults to the app's current locale) when present
/// and non-empty, otherwise falls back to the [original] source text — so the
/// UI always shows something, even before the translation function has run.
String localize(String? original, Map<String, String>? i18n, [String? lang]) {
  final code = (lang ?? Get.locale?.languageCode ?? 'en').toLowerCase();
  final translated = i18n?[code];
  if (translated != null && translated.trim().isNotEmpty) return translated;
  return original ?? '';
}

/// Parses a Firestore `<field>_i18n` value into a `{ lang: text }` map.
/// Tolerates nulls / non-map shapes by returning an empty map.
Map<String, String> i18nFromRaw(dynamic raw) {
  if (raw is Map) {
    final out = <String, String>{};
    raw.forEach((key, value) {
      if (value != null) out['$key'] = '$value';
    });
    return out;
  }
  return const {};
}

/// Builds the per-field translation map for a document from its `<field>_i18n`
/// keys, e.g. `{'bio': {'en': …, 'ar': …}}`. Only non-empty fields are kept.
Map<String, Map<String, String>> i18nMapsFrom(
  Map<String, dynamic> doc,
  List<String> fields,
) {
  final out = <String, Map<String, String>>{};
  for (final field in fields) {
    final parsed = i18nFromRaw(doc['${field}_i18n']);
    if (parsed.isNotEmpty) out[field] = parsed;
  }
  return out;
}
