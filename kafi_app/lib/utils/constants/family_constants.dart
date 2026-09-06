/// Family job-post constants (per docs §Family — Post Job).
class FamilyConstants {
  static const homeLanguages = [
    'Arabic', 'English', 'Hindi', 'Urdu', 'Tagalog', 'French', 'Russian', 'Other',
  ];

  static const roles = [
    'Maid & Nanny', 'Nanny', 'Maid', 'Babysitter', "Mother's Helper",
    'Child Caregiver', 'Elderly Caregiver', 'Cook', 'Household Helper',
    'Pet Caregiver', 'Other',
  ];

  static const duties = [
    'Newborn', 'Childcare', 'Cook family', 'Light cleaning',
    'Laundry', 'Pet care', 'Driving', 'Tutoring', 'First Aid',
  ];

  static const benefits = [
    'Meals provided', 'Private room', 'Yearly flight',
    'Health insurance', 'Phone provided', 'Days off weekly',
  ];

  static const trialDurations = [3, 5, 7, 10, 14];

  static const daysOffOptions = ['1 day off', '2 days off', 'Other'];

  /// Screen 31 notes field max length (App doc).
  static const maxTrialNotesLength = 300;

  /// Soft-bound daily rates for trial offers (System Spec TX1 / TX2).
  static const minTrialDailyRateAed = 50;
  static const maxTrialDailyRateAed = 1000;

  /// Bundled portraits a family can pick as their profile photo instead of
  /// uploading their own (Edit family profile — KAFI-EDITS #1/#2).
  static const defaultPhotoAssets = [
    'assets/images/family_defaults/family_1.jpg',
    'assets/images/family_defaults/family_2.jpg',
    'assets/images/family_defaults/family_3.jpg',
    'assets/images/family_defaults/family_4.jpg',
    'assets/images/family_defaults/family_5.jpg',
    'assets/images/family_defaults/family_6.jpg',
  ];

  /// Stable default portrait for a family id/name when no photo was uploaded.
  /// Used on nanny job lists and chat so empty `familyPhotoUrl` still shows a
  /// bundled portrait instead of a blank/initials-only tile.
  static String defaultPhotoFor(String seed) {
    if (defaultPhotoAssets.isEmpty) return '';
    if (seed.isEmpty) return defaultPhotoAssets.first;
    final hash = seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return defaultPhotoAssets[hash % defaultPhotoAssets.length];
  }

  /// Prefer [photoUrl] when set; otherwise [defaultPhotoFor].
  static String resolvedPhotoUrl(String? photoUrl, String seed) {
    final trimmed = photoUrl?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
    return defaultPhotoFor(seed);
  }
}
