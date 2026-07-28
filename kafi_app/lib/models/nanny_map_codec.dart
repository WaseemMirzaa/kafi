import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/geo_location.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/localized_text.dart';

/// Parse a nested location map (coords + address + city + country), tolerating
/// Firestore's `Map<Object?, Object?>` shape.
GeoLocation? _geoFromMap(dynamic v) =>
    v is Map ? GeoLocation.fromMap(Map<String, dynamic>.from(v)) : null;

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

T? _enumByName<T extends Enum>(List<T> values, dynamic raw) {
  if (raw == null) return null;
  final name = raw.toString();
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}

WorkExperience _experienceFromMap(Map<String, dynamic> m) => WorkExperience(
      id: m['id']?.toString() ?? '',
      jobTitle: m['jobTitle']?.toString() ?? '',
      employer: m['employer']?.toString() ?? '',
      cityCountry: m['cityCountry']?.toString() ?? '',
      fromDate: _parseDate(m['fromDate']) ?? DateTime(2000),
      toDate: _parseDate(m['toDate']) ?? DateTime.now(),
      children: m['children']?.toString() ?? '',
      duties: m['duties']?.toString() ?? '',
      reasonLeaving: m['reasonLeaving']?.toString() ?? '',
      location: _geoFromMap(m['location']),
    );

ReferenceContact _referenceFromMap(Map<String, dynamic> m) => ReferenceContact(
      id: m['id']?.toString() ?? '',
      relationship: m['relationship']?.toString() ?? '',
      city: m['city']?.toString() ?? '',
      yearsWorked: (m['yearsWorked'] as num?)?.toInt() ?? 0,
      canConfirm: m['canConfirm']?.toString() ?? '',
      location: _geoFromMap(m['location']),
    );

NannyDocument _documentFromMap(Map<String, dynamic> m) => NannyDocument(
      type: _enumByName(DocumentType.values, m['type']) ?? DocumentType.passport,
      status: _enumByName(DocumentStatus.values, m['status']) ?? DocumentStatus.missing,
      url: m['url'] as String?,
      uploadedAt: _parseDate(m['uploadedAt']),
      rejectionReason: m['rejectionReason'] as String?,
      reviewedAt: _parseDate(m['reviewedAt']),
      reviewedBy: m['reviewedBy'] as String?,
    );

NannyStats _statsFromMap(Map<String, dynamic>? m) => NannyStats(
      profileViews: (m?['profileViews'] as num?)?.toInt() ?? 0,
      shortlists: (m?['shortlists'] as num?)?.toInt() ?? 0,
      applicationsCount: (m?['applicationsCount'] as num?)?.toInt() ?? 0,
      trialsCount: (m?['trialsCount'] as num?)?.toInt() ?? 0,
      hiresCount: (m?['hiresCount'] as num?)?.toInt() ?? 0,
      averageRating: (m?['averageRating'] as num?)?.toDouble(),
      reviewsCount: (m?['reviewsCount'] as num?)?.toInt() ?? 0,
    );

/// Firestore / mock JSON → [NannyModel].
NannyModel nannyModelFromMap(String id, Map<String, dynamic> m) => NannyModel(
      id: id,
      userId: (m['userId'] as String?) ?? id,
      fullName: (m['fullName'] as String?) ?? '',
      dateOfBirth: _parseDate(m['dateOfBirth']),
      nationality: (m['nationality'] as String?) ?? '',
      languages: List<String>.from(m['languages'] ?? const []),
      visaStatus: _enumByName(VisaStatus.values, m['visaStatus']),
      hasEmiratesId: m['hasEmiratesId'] == true,
      eidNumber: m['eidNumber'] as String?,
      willingToTransferVisa: m['willingToTransferVisa'] as bool?,
      workEmirates: (m['workEmirates'] as List?)
              ?.map((e) => _enumByName(Emirate.values, e))
              .whereType<Emirate>()
              .toList() ??
          const [],
      willingToRelocate: m['willingToRelocate'] == true,
      currentArea: (m['currentArea'] as String?) ?? '',
      currentLocation: _geoFromMap(m['currentLocation']),
      jobTypePreference: _enumByName(JobTypePreference.values, m['jobTypePreference']) ??
          JobTypePreference.both,
      expectedSalaryMin: (m['expectedSalaryMin'] as num?)?.toInt() ?? 0,
      expectedSalaryMax: (m['expectedSalaryMax'] as num?)?.toInt() ?? 0,
      availability: _enumByName(AvailabilityStatus.values, m['availability']) ??
          AvailabilityStatus.availableNow,
      availableFrom: _parseDate(m['availableFrom']),
      maritalStatus: _enumByName(MaritalStatus.values, m['maritalStatus']),
      hasChildren: m['hasChildren'] == true,
      childrenCount: (m['childrenCount'] as num?)?.toInt() ?? 0,
      childrenAges: m['childrenAges'] as String?,
      hasHealthConditions: m['hasHealthConditions'] == true,
      healthConditions: (m['healthConditions'] as String?) ?? '',
      takesMedication: m['takesMedication'] == true,
      medications: (m['medications'] as String?) ?? '',
      hasAllergies: m['hasAllergies'] == true,
      allergies: (m['allergies'] as String?) ?? '',
      comfortableWithCameras: m['comfortableWithCameras'] != false,
      cameraNote: m['cameraNote'] as String?,
      comfortableWithPets: m['comfortableWithPets'] != false,
      petTypes: List<String>.from(m['petTypes'] ?? const []),
      canCook: m['canCook'] != false,
      cuisines: List<String>.from(m['cuisines'] ?? const []),
      canDoNightShifts: m['canDoNightShifts'] == true,
      religion: (m['religion'] as String?) ?? '',
      religiousNotes: (m['religiousNotes'] as String?) ?? '',
      comfortableWithDifferentFaith: m['comfortableWithDifferentFaith'] != false,
      emergencyName: (m['emergencyName'] as String?) ?? '',
      emergencyRelationship: (m['emergencyRelationship'] as String?) ?? '',
      emergencyCountryCode: (m['emergencyCountryCode'] as String?) ?? '+971',
      emergencyPhone: (m['emergencyPhone'] as String?) ?? '',
      bio: (m['bio'] as String?) ?? '',
      photoUrls: List<String>.from(m['photoUrls'] ?? const []),
      introVideoUrl: m['introVideoUrl'] as String?,
      experiences: (m['experiences'] as List?)
              ?.map((e) => _experienceFromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      experienceCompleted: m['experienceCompleted'] == true,
      hasReferences: m['hasReferences'] == true,
      commitsToShare: m['commitsToShare'] == true,
      numberOfReferences: (m['numberOfReferences'] as num?)?.toInt() ?? 0,
      references: (m['references'] as List?)
              ?.map((e) => _referenceFromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      referencesCompleted: m['referencesCompleted'] == true,
      documents: (m['documents'] as List?)
              ?.map((e) => _documentFromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      status: _enumByName(NannyOnboardingStatus.values, m['status']) ??
          NannyOnboardingStatus.draft,
      rejectionReason: m['rejectionReason'] as String?,
      rejectedAt: _parseDate(m['rejectedAt']),
      introVideoStatus: _enumByName(IntroVideoStatus.values, m['introVideoStatus']),
      introVideoRejectionReason: m['introVideoRejectionReason'] as String?,
      isVerified: m['isVerified'] == true,
      verifiedAt: _parseDate(m['verifiedAt']),
      profileScore: (m['profileScore'] as num?)?.toInt() ?? 0,
      stats: _statsFromMap(m['stats'] as Map<String, dynamic>?),
      i18n: i18nMapsFrom(m, const ['bio', 'healthConditions', 'religiousNotes']),
      lastActiveAt: _parseDate(m['lastActiveAt']),
    );
