/// Nanny onboarding constants (System spec §Onboarding).
class NannyConstants {
  static const totalSteps = 6;

  static const minPhotos = 1;
  static const maxPhotos = 5;
  static const maxVideoSeconds = 60;
  static const maxBioChars = 300;

  // §profile score bonuses
  static const scorePoliceClearance = 10;
  static const scoreTrainingCert = 7;
  static const scoreLoginBonus = 5;

  static const nationalities = [
    'Filipino', 'Indonesian', 'Indian', 'Sri Lankan', 'Nepalese',
    'Ethiopian', 'Kenyan', 'Ugandan', 'Ghanaian', 'Nigerian',
    'Bangladeshi', 'Pakistani', 'Malagasy', 'Zimbabwean', 'Other',
  ];

  static const languages = [
    'English', 'Arabic (basic)', 'Hindi', 'Tagalog',
    'Urdu', 'French', 'Swahili', 'Amharic',
  ];

  static const jobTitles = [
    'Live-in Nanny', 'Live-out Nanny', 'Babysitter',
    'Newborn Specialist', 'Housekeeper & Nanny',
  ];

  static const reasonsLeaving = [
    'Family relocated', 'Contract ended', 'Children grew up',
    'Family decision', 'Personal reasons',
  ];

  static const referenceRelations = [
    'Previous employer', 'Agency supervisor', 'Family member of employer',
    'Long-term contact',
  ];
}
