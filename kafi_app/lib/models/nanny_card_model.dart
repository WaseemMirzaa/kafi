import 'package:kafi_app/models/nanny_model.dart';

/// Light-weight card representation used in the browse list.
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

  /// Builds a browse card from a full [NannyModel] (e.g. a shortlisted / trial
  /// nanny resolved by id from Firestore). Mirrors the mapping in
  /// firestore_job_service.browseNannies so cards look identical everywhere.
  /// `matchPercent` is left 0 (no job context here); callers may rank/override.
  factory NannyCardModel.fromNanny(NannyModel n) {
    final name = n.fullName;
    return NannyCardModel(
      id: n.id,
      initials: name.isNotEmpty ? name[0].toUpperCase() : 'N',
      name: name,
      nationality: n.nationality,
      yearsExp: n.experiences.length,
      jobType: switch (n.jobTypePreference) {
        JobTypePreference.liveIn => 'Live-in',
        JobTypePreference.liveOut => 'Live-out',
        JobTypePreference.both => 'Live-in · Live-out',
      },
      city: n.currentArea,
      matchPercent: 0,
      tags: n.languages.take(3).toList(),
      verified: n.isVerified,
      introVideoUrl: n.introVideoUrl,
      averageRating: n.stats.averageRating,
      reviewsCount: n.stats.reviewsCount,
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
      );
}
