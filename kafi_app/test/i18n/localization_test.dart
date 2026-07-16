import 'package:flutter_test/flutter_test.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_map_codec.dart';
import 'package:kafi_app/utils/localized_text.dart';

/// Client read-path for translation-aware app data. User free-text is stored as
/// the original plus a `<field>_i18n` map the translate* Cloud Functions keep in
/// sync; the app reads it in the current locale and falls back to the original.
void main() {
  group('localize()', () {
    const i18n = {'en': 'Loves kids', 'ar': 'تحب الأطفال'};

    test('returns the translation for the requested language', () {
      expect(localize('Loves kids', i18n, 'ar'), 'تحب الأطفال');
      expect(localize('Loves kids', i18n, 'en'), 'Loves kids');
    });
    test('is case-insensitive on the language code', () {
      expect(localize('Loves kids', i18n, 'AR'), 'تحب الأطفال');
    });
    test('falls back to the original when the translation is missing/blank', () {
      expect(localize('Loves kids', i18n, 'fr'), 'Loves kids');
      expect(localize('Loves kids', null, 'ar'), 'Loves kids');
      expect(localize('Loves kids', const {'ar': '   '}, 'ar'), 'Loves kids');
    });
    test('defaults to English when no language is given and no locale is set', () {
      expect(localize('Loves kids', i18n), 'Loves kids');
    });
    test('empty original + no translation → empty string', () {
      expect(localize(null, null, 'ar'), '');
    });
  });

  group('i18nFromRaw() / i18nMapsFrom()', () {
    test('parses a translation map', () {
      expect(i18nFromRaw({'en': 'a', 'ar': 'ب'}), {'en': 'a', 'ar': 'ب'});
    });
    test('tolerates null / non-map values', () {
      expect(i18nFromRaw(null), isEmpty);
      expect(i18nFromRaw('not a map'), isEmpty);
    });
    test('builds per-field maps and skips fields with no translations', () {
      final doc = {
        'bio': 'Loves kids',
        'bio_i18n': {'en': 'Loves kids', 'ar': 'تحب الأطفال'},
        'healthConditions': 'None', // no _i18n → skipped
      };
      final maps = i18nMapsFrom(doc, const ['bio', 'healthConditions']);
      expect(maps.keys, ['bio']);
      expect(maps['bio']!['ar'], 'تحب الأطفال');
    });
  });

  group('NannyModel translation-awareness', () {
    test('parses bio_i18n and localizes the bio', () {
      final n = nannyModelFromMap('n1', {
        'bio': 'Loves kids',
        'bio_i18n': {'en': 'Loves kids', 'ar': 'تحب الأطفال'},
      });
      expect(n.localizedBio('ar'), 'تحب الأطفال');
      expect(n.localizedBio('en'), 'Loves kids');
    });
    test('localizedBio falls back to the original when untranslated', () {
      final n = nannyModelFromMap('n1', {'bio': 'Loves kids'});
      expect(n.localizedBio('ar'), 'Loves kids');
    });
    test('toMap never serializes the server-owned translation maps', () {
      final n = nannyModelFromMap('n1', {
        'bio': 'Loves kids',
        'bio_i18n': {'en': 'Loves kids', 'ar': 'تحب الأطفال'},
      });
      final map = n.toMap();
      expect(map.containsKey('bio_i18n'), isFalse);
      expect(map.containsKey('i18n'), isFalse);
      expect(map['bio'], 'Loves kids');
    });
    test('copyWith preserves translations', () {
      final n = nannyModelFromMap('n1', {
        'bio': 'Loves kids',
        'bio_i18n': {'en': 'Loves kids', 'ar': 'تحب الأطفال'},
      });
      final edited = n.copyWith(fullName: 'Maria');
      expect(edited.fullName, 'Maria');
      expect(edited.localizedBio('ar'), 'تحب الأطفال');
    });
  });

  group('FamilyModel translation-awareness', () {
    test('localizes aboutFamily / houseRules, falling back to original', () {
      const f = FamilyModel(
        id: 'f1',
        userId: 'f1',
        aboutFamily: 'We are a warm family',
        houseRules: 'No smoking',
        i18n: {
          'aboutFamily': {'en': 'We are a warm family', 'ar': 'نحن عائلة دافئة'},
        },
      );
      expect(f.localizedAboutFamily('ar'), 'نحن عائلة دافئة');
      expect(f.localizedAboutFamily('en'), 'We are a warm family');
      expect(f.localizedHouseRules('ar'), 'No smoking'); // no ar → original
      expect(f.copyWith(fullName: 'X').localizedAboutFamily('ar'), 'نحن عائلة دافئة');
    });
    test('toMap never serializes the translation maps', () {
      const f = FamilyModel(
        id: 'f1',
        userId: 'f1',
        aboutFamily: 'Hi',
        i18n: {
          'aboutFamily': {'en': 'Hi', 'ar': 'مرحبا'},
        },
      );
      final map = f.toMap();
      expect(map.containsKey('aboutFamily_i18n'), isFalse);
      expect(map.containsKey('i18n'), isFalse);
    });
  });

  group('JobPostModel translation-awareness', () {
    test('localizes jobTitle / schedule / additionalNotes with fallback', () {
      const j = JobPostModel(
        id: 'j1',
        familyId: 'f1',
        jobTitle: 'Live-in Nanny',
        schedule: 'Mon-Fri',
        additionalNotes: 'Must love pets',
        i18n: {
          'jobTitle': {'en': 'Live-in Nanny', 'ar': 'مربية مقيمة'},
        },
      );
      expect(j.localizedJobTitle('ar'), 'مربية مقيمة');
      expect(j.localizedSchedule('ar'), 'Mon-Fri'); // no ar → original
      expect(j.localizedAdditionalNotes('ar'), 'Must love pets');
      expect(j.copyWith(city: 'Dubai').localizedJobTitle('ar'), 'مربية مقيمة');
    });
    test('toMap never serializes the translation maps', () {
      const j = JobPostModel(
        id: 'j1',
        familyId: 'f1',
        jobTitle: 'Nanny',
        i18n: {
          'jobTitle': {'en': 'Nanny', 'ar': 'مربية'},
        },
      );
      final map = j.toMap();
      expect(map.containsKey('jobTitle_i18n'), isFalse);
      expect(map.containsKey('i18n'), isFalse);
    });
  });
}
