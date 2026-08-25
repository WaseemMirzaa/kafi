/// Nanny onboarding constants (System spec §Onboarding).
class NannyConstants {
  static const totalSteps = 6;

  static const minPhotos = 3;
  static const maxPhotos = 5;
  static const maxVideoSeconds = 60;
  static const maxBioChars = 300;

  // Profile quality score (§3.2 ProfileQualityScore) — factors sum to 100.
  static const scoreProfileComplete = 20;
  static const scoreVerified = 20;
  static const scoreVideo = 15;
  static const scoreMultiplePhotos = 10;
  static const scorePoliceClearance = 10;
  static const scoreTrainingCert = 7;
  static const scoreLoginBonus = 5; // recentlyActive: login within 7 days
  static const scoreReferences = 8;
  static const scoreWorkExperience = 5;
  static const recentlyActiveDays = 7;

  /// Admin `hideInactiveNannies`: family Browse hides nannies whose
  /// `lastActiveAt` is older than this many days (or missing).
  static const hideInactiveListingDays = 14;

  /// Comprehensive world nationalities (demonyms), alphabetical so the
  /// searchable picker finds any entry. 'Other' stays last as a catch-all.
  static const nationalities = [
    'Afghan', 'Albanian', 'Algerian', 'American', 'Andorran', 'Angolan',
    'Antiguan', 'Argentine', 'Armenian', 'Australian', 'Austrian',
    'Azerbaijani', 'Bahamian', 'Bahraini', 'Bangladeshi', 'Barbadian',
    'Belarusian', 'Belgian', 'Belizean', 'Beninese', 'Bhutanese', 'Bolivian',
    'Bosnian', 'Botswanan', 'Brazilian', 'British', 'Bruneian', 'Bulgarian',
    'Burkinabe', 'Burmese', 'Burundian', 'Cambodian', 'Cameroonian',
    'Canadian', 'Cape Verdean', 'Central African', 'Chadian', 'Chilean',
    'Chinese', 'Colombian', 'Comoran', 'Congolese', 'Costa Rican', 'Croatian',
    'Cuban', 'Cypriot', 'Czech', 'Danish', 'Djiboutian', 'Dominican', 'Dutch',
    'East Timorese', 'Ecuadorian', 'Egyptian', 'Emirati', 'Equatorial Guinean',
    'Eritrean', 'Estonian', 'Ethiopian', 'Fijian', 'Filipino', 'Finnish',
    'French', 'Gabonese', 'Gambian', 'Georgian', 'German', 'Ghanaian', 'Greek',
    'Grenadian', 'Guatemalan', 'Guinean', 'Guyanese', 'Haitian', 'Honduran',
    'Hungarian', 'Icelandic', 'Indian', 'Indonesian', 'Iranian', 'Iraqi',
    'Irish', 'Israeli', 'Italian', 'Ivorian', 'Jamaican', 'Japanese',
    'Jordanian', 'Kazakh', 'Kenyan', 'Kuwaiti', 'Kyrgyz', 'Laotian', 'Latvian',
    'Lebanese', 'Liberian', 'Libyan', 'Lithuanian', 'Luxembourger',
    'Macedonian', 'Malagasy', 'Malawian', 'Malaysian', 'Maldivian', 'Malian',
    'Maltese', 'Mauritanian', 'Mauritian', 'Mexican', 'Moldovan', 'Mongolian',
    'Montenegrin', 'Moroccan', 'Mozambican', 'Namibian', 'Nepalese',
    'New Zealander', 'Nicaraguan', 'Nigerian', 'Nigerien', 'North Korean',
    'Norwegian', 'Omani', 'Pakistani', 'Palestinian', 'Panamanian',
    'Papua New Guinean', 'Paraguayan', 'Peruvian', 'Polish', 'Portuguese',
    'Qatari', 'Romanian', 'Russian', 'Rwandan', 'Salvadoran', 'Samoan',
    'Saudi', 'Senegalese', 'Serbian', 'Seychellois', 'Sierra Leonean',
    'Singaporean', 'Slovak', 'Slovenian', 'Somali', 'South African',
    'South Korean', 'South Sudanese', 'Spanish', 'Sri Lankan', 'Sudanese',
    'Surinamese', 'Swazi', 'Swedish', 'Swiss', 'Syrian', 'Taiwanese', 'Tajik',
    'Tanzanian', 'Thai', 'Togolese', 'Tongan', 'Trinidadian', 'Tunisian',
    'Turkish', 'Turkmen', 'Ugandan', 'Ukrainian', 'Uruguayan', 'Uzbek',
    'Venezuelan', 'Vietnamese', 'Yemeni', 'Zambian', 'Zimbabwean', 'Other',
  ];

  static const languages = [
    'English', 'Arabic', 'Filipino/Tagalog', 'Bahasa Indonesia', 'Hindi', 'Urdu',
    'Bengali', 'Amharic', 'Oromo', 'Swahili', 'Punjabi', 'Malayalam', 'Other',
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
