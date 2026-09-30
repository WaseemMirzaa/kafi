/// Family job-post constants (per docs §Family — Post Job).
class FamilyConstants {
  static const homeLanguages = ['English', 'Arabic', 'Hindi', 'Filipino', 'Urdu', 'French'];

  static const roles = [
    'Nanny', 'Maid', 'Caregiver', 'Cook', 'Babysitter', 'Helper', 'Pet Caretaker',
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

  /// Screen 31 notes field max length (App doc).
  static const maxTrialNotesLength = 300;

  /// Soft-bound daily rates for trial offers (System Spec TX1 / TX2).
  static const minTrialDailyRateAed = 50;
  static const maxTrialDailyRateAed = 1000;

  /// Weekday labels for the working-schedule multi-select (Mon → Sun).
  static const workDays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
}
