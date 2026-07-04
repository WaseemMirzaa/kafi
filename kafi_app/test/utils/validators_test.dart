import 'package:flutter_test/flutter_test.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/validators.dart';

/// Unit tests for [Validators] — the centralised auth/onboarding form rules
/// (Spec §14.1 auth, §14.4 profile validation). Pure functions: they return an
/// l10n key on error or `null` when valid, so no Firebase/mocks are needed.
void main() {
  group('Validators.phone (§14.1 A1)', () {
    test('accepts a normal national number', () {
      expect(Validators.phone('501234567'), isNull);
    });

    test('accepts spaces and dashes', () {
      expect(Validators.phone('50 123 4567'), isNull);
      expect(Validators.phone('50-123-4567'), isNull);
    });

    test('strips a single leading zero before length check', () {
      expect(Validators.phone('0501234567'), isNull); // 9 national digits
    });

    test('empty → phoneRequired', () {
      expect(Validators.phone(''), AppStrings.phoneRequired);
      expect(Validators.phone('   '), AppStrings.phoneRequired);
    });

    test('too short (<6 national digits) → invalid', () {
      expect(Validators.phone('12345'), AppStrings.authPhoneInvalid);
    });

    test('too long (>12 national digits) → invalid', () {
      expect(Validators.phone('1234567890123'), AppStrings.authPhoneInvalid);
    });
  });

  group('Validators.dateOfBirth (§14.4 V2/V3)', () {
    final now = DateTime.now();

    test('null → required', () {
      expect(Validators.dateOfBirth(null), AppStrings.valRequired);
    });

    test('future date → invalid', () {
      expect(
        Validators.dateOfBirth(now.add(const Duration(days: 1))),
        AppStrings.valDobInvalid,
      );
    });

    test('under 18 → ageMin18', () {
      final tenYearsOld = DateTime(now.year - 10, now.month, now.day);
      expect(Validators.dateOfBirth(tenYearsOld), AppStrings.valAgeMin18);
    });

    test('just under 18 (17y 364d) → ageMin18', () {
      final almost18 = now.subtract(const Duration(days: 365 * 18 - 2));
      expect(Validators.dateOfBirth(almost18), AppStrings.valAgeMin18);
    });

    test('18 or older → valid', () {
      final twenty = DateTime(now.year - 20, now.month, now.day);
      expect(Validators.dateOfBirth(twenty), isNull);
    });
  });

  group('Validators.salaryRange (§14.4 V8)', () {
    test('min ≤ max and both positive → valid', () {
      expect(Validators.salaryRange(1500, 2500), isNull);
      expect(Validators.salaryRange(2000, 2000), isNull);
    });

    test('min > max → order error', () {
      expect(Validators.salaryRange(3000, 2000), AppStrings.valSalaryOrder);
    });

    test('zero or negative → required', () {
      expect(Validators.salaryRange(0, 2000), AppStrings.valRequired);
      expect(Validators.salaryRange(1500, 0), AppStrings.valRequired);
      expect(Validators.salaryRange(-100, 2000), AppStrings.valRequired);
    });
  });

  group('Validators.nonEmptyList (§14.4 V6/V7)', () {
    test('empty list → the provided empty key', () {
      expect(
        Validators.nonEmptyList(const [], 'languages_required'),
        'languages_required',
      );
    });

    test('non-empty list → valid', () {
      expect(Validators.nonEmptyList(const ['Arabic'], 'x'), isNull);
    });
  });

  group('Validators.required (§14.4 V1)', () {
    test('null/blank → required, non-blank → valid', () {
      expect(Validators.required(null), AppStrings.valRequired);
      expect(Validators.required('  '), AppStrings.valRequired);
      expect(Validators.required('Sarah'), isNull);
    });
  });
}
