import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';

/// Centralised form validators for auth + onboarding.
///
/// Each method returns an **l10n key** (from [AppStrings]) describing the error,
/// or `null` when the value is valid. Callers resolve the message with `.tr`,
/// e.g. `final err = Validators.phone(x); if (err != null) show(err.tr);`
///
/// Messages map to the System Specification error catalogue (§14.1 auth, §14.4
/// profile validation).
class Validators {
  Validators._();

  /// Normalises a raw phone entry to its national significant number: strips
  /// spaces, dashes, parentheses and any other non-digit, then drops a single
  /// leading trunk `0` (e.g. UAE users type `050…` for `+9715…`). Used both by
  /// the validators below and by the auth service before it builds the E.164
  /// number for Firebase, so the two never diverge.
  static String sanitizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.startsWith('0') ? digits.substring(1) : digits;
  }

  /// Phone national-number validation (country code is selected separately).
  /// Accepts spaces/dashes; strips a leading 0; expects 6–12 digits. (§14.1 A1)
  static String? phone(String raw) {
    if (raw.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) return AppStrings.phoneRequired;
    final national = sanitizePhone(raw);
    if (national.length < 6 || national.length > 12) {
      return AppStrings.authPhoneInvalid;
    }
    return null;
  }

  /// Generic required text field. (§14.4 V1)
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.valRequired;
    return null;
  }

  /// Date of birth: present, not in the future, age ≥ 18. (§14.4 V2, V3)
  static String? dateOfBirth(DateTime? dob) {
    if (dob == null) return AppStrings.valRequired;
    final now = DateTime.now();
    if (dob.isAfter(now)) return AppStrings.valDobInvalid;
    if (_age(dob, now) < 18) return AppStrings.valAgeMin18;
    return null;
  }

  /// Emergency / secondary phone — same rule as [phone] but reuses the
  /// generic "valid phone" message. (§14.4 V4)
  static String? contactPhone(String raw) {
    if (raw.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) return AppStrings.valRequired;
    final national = sanitizePhone(raw);
    if (national.length < 6 || national.length > 12) {
      return AppStrings.valPhoneInvalid;
    }
    return null;
  }

  /// Upper sanity ceiling for a monthly salary (AED). Guards against typos like
  /// an extra trailing zero without rejecting genuine high-end offers.
  static const int maxMonthlySalary = 100000;

  /// Salary range: both positive, min ≤ max, and within a sane ceiling.
  /// (§14.4 V8)
  static String? salaryRange(int min, int max) {
    if (min <= 0 || max <= 0) return AppStrings.valRequired;
    if (min > max) return AppStrings.valSalaryOrder;
    if (max > maxMonthlySalary) return AppStrings.valSalaryTooHigh;
    return null;
  }

  /// Trial offer daily rate: must be set (V13) and within TX1/TX2 bounds.
  static String? trialDailyRate(int rate) {
    if (rate <= 0) return AppStrings.trialOfferRateRequired;
    if (rate < FamilyConstants.minTrialDailyRateAed) {
      return AppStrings.trialOfferRateTooLow;
    }
    if (rate > FamilyConstants.maxTrialDailyRateAed) {
      return AppStrings.trialOfferRateTooHigh;
    }
    return null;
  }

  /// Trial start calendar day must not be before today (V15; TX3 allows today).
  static String? trialStartDate(DateTime? start) {
    if (start == null) return AppStrings.trialOfferStartRequired;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start.year, start.month, start.day);
    if (day.isBefore(today)) return AppStrings.trialOfferStartPast;
    return null;
  }

  /// Work-experience date range: `from` must be on or before `to`. (§14.4)
  static String? experienceDates(DateTime from, DateTime to) {
    if (from.isAfter(to)) return AppStrings.valExpDatesInvalid;
    return null;
  }

  /// At least one item selected (languages, emirates, duties, …). (§14.4 V6/V7)
  static String? nonEmptyList(List<Object?> items, String emptyKey) {
    if (items.isEmpty) return emptyKey;
    return null;
  }

  static int _age(DateTime dob, DateTime now) {
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }
}
