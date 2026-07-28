import 'package:kafi_app/models/geo_location.dart';
import 'package:kafi_app/utils/localized_text.dart';

enum VisaStatus { visit, residenceSponsored, ownResidence, cancelled, outsideUae }

enum Emirate { dubai, abuDhabi, sharjah, ajman, rak, fujairah, uaq, alAin }

enum MaritalStatus { married, single, divorced, widowed }

enum NannyOnboardingStatus { draft, pending, approved, rejected }

/// Admin's separate review track for the intro video (System Spec §6.1).
/// Written by the admin panel as `introVideoStatus` on the nanny doc.
enum IntroVideoStatus { pending, approved, rejected }

/// Per System Spec §3.2
enum AvailabilityStatus { availableNow, availableFrom, onTrial }

/// Per System Spec §3.2
enum JobTypePreference { liveIn, liveOut, both }

class WorkExperience {
  WorkExperience({
    required this.id,
    required this.jobTitle,
    required this.employer,
    required this.cityCountry,
    required this.fromDate,
    required this.toDate,
    required this.children,
    required this.duties,
    required this.reasonLeaving,
    this.location,
  });

  final String id;
  final String jobTitle;
  final String employer;
  final String cityCountry;
  final DateTime fromDate;
  final DateTime toDate;
  final String children;
  final String duties;
  final String reasonLeaving;

  /// Structured city/country from the map picker (coords + address), when
  /// available. `cityCountry` remains the display string.
  final GeoLocation? location;

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobTitle': jobTitle,
        'employer': employer,
        'cityCountry': cityCountry,
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'children': children,
        'duties': duties,
        'reasonLeaving': reasonLeaving,
        if (location != null) 'location': location!.toMap(),
      };
}

class ReferenceContact {
  ReferenceContact({
    required this.id,
    required this.relationship,
    required this.city,
    required this.yearsWorked,
    required this.canConfirm,
    this.location,
  });

  final String id;
  final String relationship;
  final String city;
  final int yearsWorked;
  final String canConfirm;

  /// Structured city from the map picker (coords + address), when available.
  /// `city` remains the display string.
  final GeoLocation? location;

  Map<String, dynamic> toMap() => {
        'id': id,
        'relationship': relationship,
        'city': city,
        'yearsWorked': yearsWorked,
        'canConfirm': canConfirm,
        if (location != null) 'location': location!.toMap(),
      };
}

enum DocumentType { passport, visa, emiratesId, trainingCert, policeClearance }

enum DocumentStatus { missing, uploaded, reviewing, approved, rejected }

class NannyDocument {
  NannyDocument({
    required this.type,
    required this.status,
    this.url,
    this.uploadedAt,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewedBy,
  });

  final DocumentType type;
  final DocumentStatus status;
  final String? url;
  final DateTime? uploadedAt;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  NannyDocument copyWith({
    DocumentStatus? status,
    String? url,
    DateTime? uploadedAt,
    String? rejectionReason,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) =>
      NannyDocument(
        type: type,
        status: status ?? this.status,
        url: url ?? this.url,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        reviewedBy: reviewedBy ?? this.reviewedBy,
      );

  /// NOTE: `url` is deliberately **omitted** here. This map is embedded in the
  /// `nannies/{id}` doc, which becomes world-readable once the nanny is
  /// approved+verified — and a Storage download URL carries a token that
  /// bypasses Storage rules (C5). The sensitive URL is instead persisted to the
  /// private `nannies/{id}/documents/{type}` subcollection (owner/admin only);
  /// only status/metadata — which the admin list, review flow, and the
  /// onDocumentReviewed function rely on — stays on the parent doc.
  Map<String, dynamic> toMap() => {
        'type': type.name,
        'status': status.name,
        'uploadedAt': uploadedAt?.toIso8601String(),
        'rejectionReason': rejectionReason,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewedBy': reviewedBy,
      };
}

/// Per System Spec §3.2
class NannyStats {
  const NannyStats({
    this.profileViews = 0,
    this.shortlists = 0,
    this.applicationsCount = 0,
    this.trialsCount = 0,
    this.hiresCount = 0,
    this.averageRating,
    this.reviewsCount = 0,
  });

  final int profileViews;
  final int shortlists;
  final int applicationsCount;
  final int trialsCount;
  final int hiresCount;
  final double? averageRating;
  final int reviewsCount;

  Map<String, dynamic> toMap() => {
        'profileViews': profileViews,
        'shortlists': shortlists,
        'applicationsCount': applicationsCount,
        'trialsCount': trialsCount,
        'hiresCount': hiresCount,
        'averageRating': averageRating,
        'reviewsCount': reviewsCount,
      };
}

/// Complete Nanny model per System Spec §3.2
class NannyModel {
  NannyModel({
    required this.id,
    required this.userId,
    this.fullName = '',
    this.dateOfBirth,
    this.nationality = '',
    this.languages = const [],
    this.visaStatus,
    this.hasEmiratesId = false,
    this.eidNumber,
    this.willingToTransferVisa,
    this.workEmirates = const [],
    this.willingToRelocate = false,
    this.currentArea = '',
    this.currentLocation,
    this.jobTypePreference = JobTypePreference.both,
    this.expectedSalaryMin = 0,
    this.expectedSalaryMax = 0,
    this.availability = AvailabilityStatus.availableNow,
    this.availableFrom,
    this.maritalStatus,
    this.hasChildren = false,
    this.childrenCount = 0,
    this.childrenAges,
    this.hasHealthConditions = false,
    this.healthConditions = '',
    this.takesMedication = false,
    this.medications = '',
    this.hasAllergies = false,
    this.allergies = '',
    this.comfortableWithCameras = true,
    this.cameraNote,
    this.comfortableWithPets = true,
    this.petTypes = const [],
    this.canCook = true,
    this.cuisines = const [],
    this.canDoNightShifts = false,
    this.religion = '',
    this.religiousNotes = '',
    this.comfortableWithDifferentFaith = true,
    this.emergencyName = '',
    this.emergencyRelationship = '',
    this.emergencyCountryCode = '+971',
    this.emergencyPhone = '',
    this.bio = '',
    this.photoUrls = const [],
    this.introVideoUrl,
    this.experiences = const [],
    this.experienceCompleted = false,
    this.hasReferences = false,
    this.commitsToShare = false,
    this.numberOfReferences = 0,
    this.references = const [],
    this.referencesCompleted = false,
    this.documents = const [],
    this.status = NannyOnboardingStatus.draft,
    this.rejectionReason,
    this.rejectedAt,
    this.introVideoStatus,
    this.introVideoRejectionReason,
    this.isVerified = false,
    this.verifiedAt,
    this.profileScore = 0,
    this.stats = const NannyStats(),
    this.i18n = const {},
    this.lastActiveAt,
  });

  final String id;
  final String userId;
  final String fullName;
  final DateTime? dateOfBirth;
  final String nationality;
  final List<String> languages;
  final VisaStatus? visaStatus;
  final bool hasEmiratesId;
  final String? eidNumber;
  final bool? willingToTransferVisa;
  final List<Emirate> workEmirates;
  final bool willingToRelocate;
  final String currentArea;

  /// Structured current area / neighbourhood from the map picker (coords +
  /// address + city + country). `currentArea` remains the display string.
  final GeoLocation? currentLocation;
  final JobTypePreference jobTypePreference;
  final int expectedSalaryMin;
  final int expectedSalaryMax;
  final AvailabilityStatus availability;
  final DateTime? availableFrom;
  final MaritalStatus? maritalStatus;
  final bool hasChildren;
  final int childrenCount;
  final String? childrenAges;
  final bool hasHealthConditions;
  final String healthConditions;
  final bool takesMedication;
  final String medications;
  final bool hasAllergies;
  final String allergies;
  final bool comfortableWithCameras;
  final String? cameraNote;
  final bool comfortableWithPets;
  final List<String> petTypes;
  final bool canCook;
  final List<String> cuisines;
  final bool canDoNightShifts;
  final String religion;
  final String religiousNotes;
  final bool comfortableWithDifferentFaith;
  final String emergencyName;
  final String emergencyRelationship;
  final String emergencyCountryCode;
  final String emergencyPhone;
  final String bio;
  final List<String> photoUrls;
  final String? introVideoUrl;
  final List<WorkExperience> experiences;

  /// The nanny finished (tapped Next on) the Experience step. A distinct signal
  /// from `experiences.isEmpty`, because a first-job nanny legitimately has no
  /// entries — so resume routing must not treat an empty list as "not done".
  final bool experienceCompleted;
  final bool hasReferences;

  /// The nanny has explicitly agreed to share her reference contacts with
  /// families during the trial/hire process. Captured on the references step.
  final bool commitsToShare;
  final int numberOfReferences;
  final List<ReferenceContact> references;

  /// The nanny finished (tapped Next on) the References step. Distinct from
  /// `hasReferences`, which records her yes/no answer, not step completion.
  final bool referencesCompleted;
  final List<NannyDocument> documents;
  final NannyOnboardingStatus status;

  /// Admin-owned review feedback (read-only on the app side; written by the
  /// admin panel via `NannyService.reject`). Deliberately NOT serialized by
  /// [toMap] so a profile save can never overwrite the admin's decision —
  /// it is cleared server-side by `submitNannyForReview` on resubmit.
  final String? rejectionReason;
  final DateTime? rejectedAt;

  /// Admin's separate intro-video review verdict + reason (admin-owned).
  final IntroVideoStatus? introVideoStatus;
  final String? introVideoRejectionReason;

  final bool isVerified;
  final DateTime? verifiedAt;
  final int profileScore;
  final NannyStats stats;

  /// Per-field translations for free-text fields, e.g.
  /// `{'bio': {'en': …, 'ar': …}}`. Populated from the `<field>_i18n` keys by
  /// the `translate*` Cloud Functions; server-owned, so [toMap] never writes it.
  final Map<String, Map<String, String>> i18n;

  /// Last time the nanny was active in the app (server-owned, written by a
  /// throttled presence heartbeat). Drives the admin "hide nannies inactive for
  /// 2 weeks" filter. Never written by [toMap] — set only by the presence write.
  final DateTime? lastActiveAt;

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    var a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      a--;
    }
    return a;
  }

  // ── Onboarding completeness (used for startup routing) ────────────────────
  // These mirror the required fields validated on each onboarding step so a
  // returning nanny is resumed at the first step she has not finished.

  /// Step 1 — personal info: the identity + work basics are filled in.
  bool get hasPersonalInfo =>
      fullName.trim().isNotEmpty &&
      dateOfBirth != null &&
      visaStatus != null &&
      workEmirates.isNotEmpty &&
      currentArea.trim().isNotEmpty &&
      bio.trim().isNotEmpty;

  /// Step 2 — media: at least 3 photos and an intro video (System Spec §3.2).
  bool get hasMedia =>
      photoUrls.length >= 3 && (introVideoUrl?.isNotEmpty ?? false);

  /// Step 5 — required documents: passport + visa have been uploaded.
  bool get hasRequiredDocuments {
    bool present(DocumentType t) => documents.any(
        (d) => d.type == t && d.status != DocumentStatus.missing);
    return present(DocumentType.passport) && present(DocumentType.visa);
  }

  /// True once every required onboarding step is finished (ready to submit).
  bool get onboardingComplete =>
      hasPersonalInfo && hasMedia && hasRequiredDocuments;

  /// Bio in the app's current language (falls back to the original text).
  String localizedBio([String? lang]) => localize(bio, i18n['bio'], lang);

  /// Health conditions in the app's current language (falls back to original).
  String localizedHealthConditions([String? lang]) =>
      localize(healthConditions, i18n['healthConditions'], lang);

  /// Religious notes in the app's current language (falls back to original).
  String localizedReligiousNotes([String? lang]) =>
      localize(religiousNotes, i18n['religiousNotes'], lang);

  /// Total years of experience summed across all work-experience entries (each
  /// entry clamped 0–20). The single source of truth for "years of experience"
  /// — used by both the match scorer and the profile cards so they never
  /// diverge (a card must not show job *count* where the scorer sums durations).
  int get totalExperienceYears => experiences.fold<int>(0, (sum, e) {
        // Use actual elapsed months, not the calendar-year delta: the old
        // `toDate.year - fromDate.year` counted a 2-month Dec→Feb job as a full
        // year while an 11-month same-year job counted as zero.
        final months = (e.toDate.year - e.fromDate.year) * 12 +
            (e.toDate.month - e.fromDate.month);
        return sum + (months ~/ 12).clamp(0, 20);
      });

  NannyModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? nationality,
    List<String>? languages,
    VisaStatus? visaStatus,
    bool? hasEmiratesId,
    String? eidNumber,
    bool? willingToTransferVisa,
    List<Emirate>? workEmirates,
    bool? willingToRelocate,
    String? currentArea,
    GeoLocation? currentLocation,
    JobTypePreference? jobTypePreference,
    int? expectedSalaryMin,
    int? expectedSalaryMax,
    AvailabilityStatus? availability,
    DateTime? availableFrom,
    MaritalStatus? maritalStatus,
    bool? hasChildren,
    int? childrenCount,
    String? childrenAges,
    bool? hasHealthConditions,
    String? healthConditions,
    bool? takesMedication,
    String? medications,
    bool? hasAllergies,
    String? allergies,
    bool? comfortableWithCameras,
    String? cameraNote,
    bool? comfortableWithPets,
    List<String>? petTypes,
    bool? canCook,
    List<String>? cuisines,
    bool? canDoNightShifts,
    String? religion,
    String? religiousNotes,
    bool? comfortableWithDifferentFaith,
    String? emergencyName,
    String? emergencyRelationship,
    String? emergencyCountryCode,
    String? emergencyPhone,
    String? bio,
    List<String>? photoUrls,
    String? introVideoUrl,
    List<WorkExperience>? experiences,
    bool? experienceCompleted,
    bool? hasReferences,
    bool? commitsToShare,
    int? numberOfReferences,
    List<ReferenceContact>? references,
    bool? referencesCompleted,
    List<NannyDocument>? documents,
    NannyOnboardingStatus? status,
    String? rejectionReason,
    DateTime? rejectedAt,
    IntroVideoStatus? introVideoStatus,
    String? introVideoRejectionReason,
    bool? isVerified,
    DateTime? verifiedAt,
    int? profileScore,
    NannyStats? stats,
    Map<String, Map<String, String>>? i18n,
    DateTime? lastActiveAt,
  }) =>
      NannyModel(
        id: id,
        userId: userId,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        nationality: nationality ?? this.nationality,
        languages: languages ?? this.languages,
        visaStatus: visaStatus ?? this.visaStatus,
        hasEmiratesId: hasEmiratesId ?? this.hasEmiratesId,
        eidNumber: eidNumber ?? this.eidNumber,
        willingToTransferVisa: willingToTransferVisa ?? this.willingToTransferVisa,
        workEmirates: workEmirates ?? this.workEmirates,
        willingToRelocate: willingToRelocate ?? this.willingToRelocate,
        currentArea: currentArea ?? this.currentArea,
        currentLocation: currentLocation ?? this.currentLocation,
        jobTypePreference: jobTypePreference ?? this.jobTypePreference,
        expectedSalaryMin: expectedSalaryMin ?? this.expectedSalaryMin,
        expectedSalaryMax: expectedSalaryMax ?? this.expectedSalaryMax,
        availability: availability ?? this.availability,
        availableFrom: availableFrom ?? this.availableFrom,
        maritalStatus: maritalStatus ?? this.maritalStatus,
        hasChildren: hasChildren ?? this.hasChildren,
        childrenCount: childrenCount ?? this.childrenCount,
        childrenAges: childrenAges ?? this.childrenAges,
        hasHealthConditions: hasHealthConditions ?? this.hasHealthConditions,
        healthConditions: healthConditions ?? this.healthConditions,
        takesMedication: takesMedication ?? this.takesMedication,
        medications: medications ?? this.medications,
        hasAllergies: hasAllergies ?? this.hasAllergies,
        allergies: allergies ?? this.allergies,
        comfortableWithCameras: comfortableWithCameras ?? this.comfortableWithCameras,
        cameraNote: cameraNote ?? this.cameraNote,
        comfortableWithPets: comfortableWithPets ?? this.comfortableWithPets,
        petTypes: petTypes ?? this.petTypes,
        canCook: canCook ?? this.canCook,
        cuisines: cuisines ?? this.cuisines,
        canDoNightShifts: canDoNightShifts ?? this.canDoNightShifts,
        religion: religion ?? this.religion,
        religiousNotes: religiousNotes ?? this.religiousNotes,
        comfortableWithDifferentFaith: comfortableWithDifferentFaith ?? this.comfortableWithDifferentFaith,
        emergencyName: emergencyName ?? this.emergencyName,
        emergencyRelationship: emergencyRelationship ?? this.emergencyRelationship,
        emergencyCountryCode: emergencyCountryCode ?? this.emergencyCountryCode,
        emergencyPhone: emergencyPhone ?? this.emergencyPhone,
        bio: bio ?? this.bio,
        photoUrls: photoUrls ?? this.photoUrls,
        introVideoUrl: introVideoUrl ?? this.introVideoUrl,
        experiences: experiences ?? this.experiences,
        experienceCompleted: experienceCompleted ?? this.experienceCompleted,
        hasReferences: hasReferences ?? this.hasReferences,
        commitsToShare: commitsToShare ?? this.commitsToShare,
        numberOfReferences: numberOfReferences ?? this.numberOfReferences,
        references: references ?? this.references,
        referencesCompleted: referencesCompleted ?? this.referencesCompleted,
        documents: documents ?? this.documents,
        status: status ?? this.status,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        rejectedAt: rejectedAt ?? this.rejectedAt,
        introVideoStatus: introVideoStatus ?? this.introVideoStatus,
        introVideoRejectionReason:
            introVideoRejectionReason ?? this.introVideoRejectionReason,
        isVerified: isVerified ?? this.isVerified,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        profileScore: profileScore ?? this.profileScore,
        stats: stats ?? this.stats,
        i18n: i18n ?? this.i18n,
        lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'nationality': nationality,
        'languages': languages,
        'visaStatus': visaStatus?.name,
        'hasEmiratesId': hasEmiratesId,
        'eidNumber': eidNumber,
        'willingToTransferVisa': willingToTransferVisa,
        'workEmirates': workEmirates.map((e) => e.name).toList(),
        'willingToRelocate': willingToRelocate,
        'currentArea': currentArea,
        if (currentLocation != null) 'currentLocation': currentLocation!.toMap(),
        'jobTypePreference': jobTypePreference.name,
        'expectedSalaryMin': expectedSalaryMin,
        'expectedSalaryMax': expectedSalaryMax,
        'availability': availability.name,
        'availableFrom': availableFrom?.toIso8601String(),
        'maritalStatus': maritalStatus?.name,
        'hasChildren': hasChildren,
        'childrenCount': childrenCount,
        'childrenAges': childrenAges,
        'hasHealthConditions': hasHealthConditions,
        'healthConditions': healthConditions,
        'takesMedication': takesMedication,
        'medications': medications,
        'hasAllergies': hasAllergies,
        'allergies': allergies,
        'comfortableWithCameras': comfortableWithCameras,
        'cameraNote': cameraNote,
        'comfortableWithPets': comfortableWithPets,
        'petTypes': petTypes,
        'canCook': canCook,
        'cuisines': cuisines,
        'canDoNightShifts': canDoNightShifts,
        'religion': religion,
        'religiousNotes': religiousNotes,
        'comfortableWithDifferentFaith': comfortableWithDifferentFaith,
        'emergencyName': emergencyName,
        'emergencyRelationship': emergencyRelationship,
        'emergencyCountryCode': emergencyCountryCode,
        'emergencyPhone': emergencyPhone,
        'bio': bio,
        'photoUrls': photoUrls,
        'introVideoUrl': introVideoUrl,
        'experiences': experiences.map((e) => e.toMap()).toList(),
        'experienceCompleted': experienceCompleted,
        'hasReferences': hasReferences,
        'commitsToShare': commitsToShare,
        'numberOfReferences': numberOfReferences,
        'references': references.map((r) => r.toMap()).toList(),
        'referencesCompleted': referencesCompleted,
        'documents': documents.map((d) => d.toMap()).toList(),
        'status': status.name,
        'isVerified': isVerified,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'profileScore': profileScore,
        'stats': stats.toMap(),
      };
}
