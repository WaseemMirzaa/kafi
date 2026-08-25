import 'package:kafi_app/models/nanny_model.dart';

/// Light-weight card representation used in the browse list. Also backs the
/// full nanny-profile-detail screen (ProfileHero + the profile screens), so
/// it additionally carries the display-only fields that screen needs
/// (photos, bio, salary range, preferences) — all sourced from [NannyModel]
/// via [fromNanny], never fetched separately.
class NannyCardModel {
  const NannyCardModel({
    required this.id,
    required this.initials,
    required this.name,
    required this.nationality,
    required this.yearsExp,
    required this.jobType,
    required this.city,
    required this.matchPercent,
    required this.tags,
    this.verified = true,
    this.availableNow = false,
    this.featured = false,
    this.introVideoUrl,
    this.averageRating,
    this.reviewsCount = 0,
    this.age,
    this.photoUrls = const [],
    this.bio = '',
    this.expectedSalaryMin = 0,
    this.expectedSalaryMax = 0,
    this.comfortableWithCameras = false,
    this.comfortableWithPets = false,
    this.hasHealthConditions = false,
    this.handledChildrenNote,
    this.workEmirateLabels = const [],
    this.hasReferences = false,
  });

  final String id;
  final String initials;
  final String name;
  final String nationality;
  final int yearsExp;
  final String jobType;
  final String city;
  final int matchPercent;
  final List<String> tags;
  final bool verified;
  final bool availableNow;
  final bool featured;
  final String? introVideoUrl;

  /// Reviewee rating aggregate (from the nanny's server-owned stats). Null/0
  /// until the nanny has received reviews.
  final double? averageRating;
  final int reviewsCount;

  /// Age in years, derived from the nanny's date of birth. Null if unset.
  final int? age;

  /// Profile photo gallery (Photos & Videos section on the detail screen).
  final List<String> photoUrls;

  /// Free-text "About Me" bio, already localized to the app's current language.
  final String bio;

  final int expectedSalaryMin;
  final int expectedSalaryMax;

  final bool comfortableWithCameras;
  final bool comfortableWithPets;
  final bool hasHealthConditions;

  /// Ages/count of children handled, taken from the nanny's most recent
  /// work-experience entry (e.g. "2 kids, ages 1 & 4"). Null when she has no
  /// experience entries with that field filled in.
  final String? handledChildrenNote;

  /// Emirates the nanny is willing to work in, as display labels.
  final List<String> workEmirateLabels;

  /// Whether the nanny has provided reference contacts (References Verified
  /// checklist item on the detail screen).
  final bool hasReferences;

  /// Builds a browse card from a full [NannyModel] (e.g. a shortlisted / trial
  /// nanny resolved by id from Firestore). Mirrors the mapping in
  /// firestore_job_service.browseNannies so cards look identical everywhere.
  /// `matchPercent` is left 0 (no job context here); callers may rank/override.
  factory NannyCardModel.fromNanny(NannyModel n) {
    final name = n.fullName;
    final childrenNote = n.experiences
        .map((e) => e.children.trim())
        .firstWhere((c) => c.isNotEmpty, orElse: () => '');
    return NannyCardModel(
      id: n.id,
      initials: name.isNotEmpty ? name[0].toUpperCase() : 'N',
      name: name,
      nationality: n.nationality,
      yearsExp: n.totalExperienceYears,
      jobType: switch (n.jobTypePreference) {
        JobTypePreference.liveIn => 'Live-in',
        JobTypePreference.liveOut => 'Live-out',
        JobTypePreference.both => 'Live-in · Live-out',
      },
      city: n.currentArea,
      matchPercent: 0,
      tags: n.languages.take(3).toList(),
      verified: n.isVerified,
      availableNow: n.availability == AvailabilityStatus.availableNow,
      introVideoUrl: n.introVideoUrl,
      averageRating: n.stats.averageRating,
      reviewsCount: n.stats.reviewsCount,
      age: n.age,
      photoUrls: n.photoUrls,
      bio: n.localizedBio(),
      expectedSalaryMin: n.expectedSalaryMin,
      expectedSalaryMax: n.expectedSalaryMax,
      comfortableWithCameras: n.comfortableWithCameras,
      comfortableWithPets: n.comfortableWithPets,
      hasHealthConditions: n.hasHealthConditions,
      handledChildrenNote: childrenNote.isEmpty ? null : childrenNote,
      workEmirateLabels: n.workEmirates.map((e) => e.label).toList(),
      hasReferences: n.hasReferences,
    );
  }

  NannyCardModel copyWith({int? matchPercent, bool? featured}) => NannyCardModel(
        id: id,
        initials: initials,
        name: name,
        nationality: nationality,
        yearsExp: yearsExp,
        jobType: jobType,
        city: city,
        matchPercent: matchPercent ?? this.matchPercent,
        tags: tags,
        verified: verified,
        availableNow: availableNow,
        featured: featured ?? this.featured,
        introVideoUrl: introVideoUrl,
        averageRating: averageRating,
        reviewsCount: reviewsCount,
        age: age,
        photoUrls: photoUrls,
        bio: bio,
        expectedSalaryMin: expectedSalaryMin,
        expectedSalaryMax: expectedSalaryMax,
        comfortableWithCameras: comfortableWithCameras,
        comfortableWithPets: comfortableWithPets,
        hasHealthConditions: hasHealthConditions,
        handledChildrenNote: handledChildrenNote,
        workEmirateLabels: workEmirateLabels,
        hasReferences: hasReferences,
      );
}
