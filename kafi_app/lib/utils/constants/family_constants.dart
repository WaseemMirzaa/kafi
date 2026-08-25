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
}
