enum JobType { liveIn, liveOut }

enum VisaSponsorship { full, shared, residenceOnly, none }

/// Per System Spec §3.3
enum SubscriptionStatus { free, active, cancelled, expired, paymentFailed }

/// Backwards compatibility alias — maps legacy enum to [SubscriptionStatus].
enum SubscriptionState { free, trial, active, cancelledInPeriod, expired, paymentGrace }

extension SubscriptionStateCompat on SubscriptionState {
  SubscriptionStatus toStatus() {
    switch (this) {
      case SubscriptionState.free: return SubscriptionStatus.free;
      case SubscriptionState.trial: return SubscriptionStatus.active;
      case SubscriptionState.active: return SubscriptionStatus.active;
      case SubscriptionState.cancelledInPeriod: return SubscriptionStatus.cancelled;
      case SubscriptionState.expired: return SubscriptionStatus.expired;
      case SubscriptionState.paymentGrace: return SubscriptionStatus.paymentFailed;
    }
  }
}

/// Per System Spec §3.3
enum NannyReligionPreference { noPreference, preferMuslim, preferSame, openWithRespect }

/// Per System Spec §3.3
class FamilySubscription {
  const FamilySubscription({
    this.status = SubscriptionStatus.free,
    this.plan,
    this.startDate,
    this.endDate,
    this.autoRenew = false,
    this.revenueCatId,
    this.hasEverSubscribed = false,
    this.expiredAt,
    this.lastRenewalAt,
  });

  final SubscriptionStatus status;
  final String? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final String? revenueCatId;
  final bool hasEverSubscribed;
  final DateTime? expiredAt;
  final DateTime? lastRenewalAt;

  bool get contactsHidden =>
      status == SubscriptionStatus.expired || status == SubscriptionStatus.paymentFailed;

  bool get chatLocked =>
      status == SubscriptionStatus.expired || status == SubscriptionStatus.paymentFailed;

  FamilySubscription copyWith({
    SubscriptionStatus? status,
    String? plan,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    String? revenueCatId,
    bool? hasEverSubscribed,
    DateTime? expiredAt,
    DateTime? lastRenewalAt,
  }) =>
      FamilySubscription(
        status: status ?? this.status,
        plan: plan ?? this.plan,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        autoRenew: autoRenew ?? this.autoRenew,
        revenueCatId: revenueCatId ?? this.revenueCatId,
        hasEverSubscribed: hasEverSubscribed ?? this.hasEverSubscribed,
        expiredAt: expiredAt ?? this.expiredAt,
        lastRenewalAt: lastRenewalAt ?? this.lastRenewalAt,
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'plan': plan,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'autoRenew': autoRenew,
        'revenueCatId': revenueCatId,
        'hasEverSubscribed': hasEverSubscribed,
        'expiredAt': expiredAt?.toIso8601String(),
        'lastRenewalAt': lastRenewalAt?.toIso8601String(),
      };

  factory FamilySubscription.fromMap(Map<String, dynamic> m) => FamilySubscription(
        status: SubscriptionStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => SubscriptionStatus.free),
        plan: m['plan'],
        startDate: _date(m['startDate']),
        endDate: _date(m['endDate']),
        autoRenew: m['autoRenew'] ?? false,
        revenueCatId: m['revenueCatId'],
        hasEverSubscribed: m['hasEverSubscribed'] ?? false,
        expiredAt: _date(m['expiredAt']),
        lastRenewalAt: _date(m['lastRenewalAt']),
      );

  /// Accepts ISO strings, `DateTime`, or a Firestore `Timestamp` (duck-typed
  /// `.toDate()`). Subscription dates are written as Timestamps by the
  /// subscription service / webhook / admin, but as ISO strings by `toMap()`.
  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    try {
      return (v as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}

/// Per System Spec §3.3
class FamilyStats {
  const FamilyStats({
    this.jobPostsCount = 0,
    this.activeJobPosts = 0,
    this.totalApplicationsReceived = 0,
    this.trialsCount = 0,
    this.hiresCount = 0,
  });

  final int jobPostsCount;
  final int activeJobPosts;
  final int totalApplicationsReceived;
  final int trialsCount;
  final int hiresCount;

  Map<String, dynamic> toMap() => {
        'jobPostsCount': jobPostsCount,
        'activeJobPosts': activeJobPosts,
        'totalApplicationsReceived': totalApplicationsReceived,
        'trialsCount': trialsCount,
        'hiresCount': hiresCount,
      };

  factory FamilyStats.fromMap(Map<String, dynamic>? m) => FamilyStats(
        jobPostsCount: (m?['jobPostsCount'] as num?)?.toInt() ?? 0,
        activeJobPosts: (m?['activeJobPosts'] as num?)?.toInt() ?? 0,
        totalApplicationsReceived: (m?['totalApplicationsReceived'] as num?)?.toInt() ?? 0,
        trialsCount: (m?['trialsCount'] as num?)?.toInt() ?? 0,
        hiresCount: (m?['hiresCount'] as num?)?.toInt() ?? 0,
      );
}

/// Complete Family model per System Spec §3.3
class FamilyModel {
  const FamilyModel({
    required this.id,
    required this.userId,
    this.fullName = '',
    this.nationality = '',
    this.city = '',
    this.profilePhoto,
    this.childrenCount = 0,
    this.childrenAges = const [],
    this.hasSpecialNeedsChild = false,
    this.specialNeedsDetails,
    this.languagesAtHome = const [],
    this.hasCameras = false,
    this.hasPets = false,
    this.petTypes = const [],
    this.religion = '',
    this.nannyReligionPreference = NannyReligionPreference.noPreference,
    this.houseRules,
    this.aboutFamily,
    this.subscription = const FamilySubscription(),
    this.freeContactsUsed = 0,
    this.viewedProfiles = const [],
    this.activeTrialNannyIds = const [],
    this.stats = const FamilyStats(),
  });

  final String id;
  final String userId;
  final String fullName;
  final String nationality;
  final String city;
  final String? profilePhoto;
  final int childrenCount;
  final List<String> childrenAges;
  final bool hasSpecialNeedsChild;
  final String? specialNeedsDetails;
  final List<String> languagesAtHome;
  final bool hasCameras;
  final bool hasPets;
  final List<String> petTypes;
  final String religion;
  final NannyReligionPreference nannyReligionPreference;
  final String? houseRules;

  /// Free-text introduction the family writes about themselves (multiline).
  final String? aboutFamily;
  final FamilySubscription subscription;
  final int freeContactsUsed;
  final List<String> viewedProfiles;
  final List<String> activeTrialNannyIds;
  final FamilyStats stats;

  bool get isSubscribed =>
      subscription.status == SubscriptionStatus.active ||
      subscription.status == SubscriptionStatus.cancelled;

  bool get isLockedOut =>
      subscription.status == SubscriptionStatus.expired ||
      subscription.status == SubscriptionStatus.paymentFailed;

  bool hasActiveTrialWith(String nannyId) => activeTrialNannyIds.contains(nannyId);

  FamilyModel copyWith({
    String? fullName,
    String? nationality,
    String? city,
    String? profilePhoto,
    int? childrenCount,
    List<String>? childrenAges,
    bool? hasSpecialNeedsChild,
    String? specialNeedsDetails,
    List<String>? languagesAtHome,
    bool? hasCameras,
    bool? hasPets,
    List<String>? petTypes,
    String? religion,
    NannyReligionPreference? nannyReligionPreference,
    String? houseRules,
    String? aboutFamily,
    FamilySubscription? subscription,
    int? freeContactsUsed,
    List<String>? viewedProfiles,
    List<String>? activeTrialNannyIds,
    FamilyStats? stats,
  }) =>
      FamilyModel(
        id: id,
        userId: userId,
        fullName: fullName ?? this.fullName,
        nationality: nationality ?? this.nationality,
        city: city ?? this.city,
        profilePhoto: profilePhoto ?? this.profilePhoto,
        childrenCount: childrenCount ?? this.childrenCount,
        childrenAges: childrenAges ?? this.childrenAges,
        hasSpecialNeedsChild: hasSpecialNeedsChild ?? this.hasSpecialNeedsChild,
        specialNeedsDetails: specialNeedsDetails ?? this.specialNeedsDetails,
        languagesAtHome: languagesAtHome ?? this.languagesAtHome,
        hasCameras: hasCameras ?? this.hasCameras,
        hasPets: hasPets ?? this.hasPets,
        petTypes: petTypes ?? this.petTypes,
        religion: religion ?? this.religion,
        nannyReligionPreference: nannyReligionPreference ?? this.nannyReligionPreference,
        houseRules: houseRules ?? this.houseRules,
        aboutFamily: aboutFamily ?? this.aboutFamily,
        subscription: subscription ?? this.subscription,
        freeContactsUsed: freeContactsUsed ?? this.freeContactsUsed,
        viewedProfiles: viewedProfiles ?? this.viewedProfiles,
        activeTrialNannyIds: activeTrialNannyIds ?? this.activeTrialNannyIds,
        stats: stats ?? this.stats,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'fullName': fullName,
        'nationality': nationality,
        'city': city,
        'profilePhoto': profilePhoto,
        'childrenCount': childrenCount,
        'childrenAges': childrenAges,
        'hasSpecialNeedsChild': hasSpecialNeedsChild,
        'specialNeedsDetails': specialNeedsDetails,
        'languagesAtHome': languagesAtHome,
        'hasCameras': hasCameras,
        'hasPets': hasPets,
        'petTypes': petTypes,
        'religion': religion,
        'nannyReligionPreference': nannyReligionPreference.name,
        'houseRules': houseRules,
        'aboutFamily': aboutFamily,
        'subscription': subscription.toMap(),
        'freeContactsUsed': freeContactsUsed,
        'viewedProfiles': viewedProfiles,
        'activeTrialNannyIds': activeTrialNannyIds,
        'stats': stats.toMap(),
      };
}
