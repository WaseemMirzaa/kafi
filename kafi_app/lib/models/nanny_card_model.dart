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
      );
}
