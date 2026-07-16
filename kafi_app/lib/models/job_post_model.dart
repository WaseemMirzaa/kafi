import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/utils/localized_text.dart';

/// Per System Spec §3.4
enum JobPostStatus { active, paused, closed, expired }

/// Per System Spec §3.4
enum JobDuration { permanent, contract }

/// Full-time vs part-time. A family may keep one active job of each at a time.
enum JobEmploymentType { fullTime, partTime }

/// Complete JobPost model per System Spec §3.4
class JobPostModel {
  const JobPostModel({
    required this.id,
    required this.familyId,
    this.familyName = '',
    this.status = JobPostStatus.active,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.jobTitle = '',
    this.rolesNeeded = const [],
    this.jobType = JobType.liveIn,
    this.schedule = '',
    this.startDate,
    this.startImmediate = true,
    this.duration = JobDuration.permanent,
    this.employmentType = JobEmploymentType.fullTime,
    this.contractMonths,
    this.experienceYears = 0,
    this.languagesRequired = const [],
    this.languagesPreferred = const [],
    this.skillsRequired = const [],
    this.nationalityPreference = const [],
    this.religionPreference,
    this.duties = const [],
    this.salaryMin = 0,
    this.salaryMax = 0,
    this.currency = 'AED',
    this.benefits = const [],
    this.visaSponsorship = VisaSponsorship.full,
    this.trialDurationDays = 0,
    this.trialDailyRate = 0,
    this.additionalNotes,
    this.viewsCount = 0,
    this.applicationsCount = 0,
    this.city = '',
    this.commitmentAgreed = false,
    this.i18n = const {},
  });

  final String id;
  final String familyId;
  final String familyName;
  final JobPostStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final String jobTitle;
  final List<String> rolesNeeded;
  final JobType jobType;
  final String schedule;
  final DateTime? startDate;
  final bool startImmediate;
  final JobDuration duration;
  final JobEmploymentType employmentType;
  final int? contractMonths;
  final int experienceYears;
  final List<String> languagesRequired;
  final List<String> languagesPreferred;
  final List<String> skillsRequired;
  final List<String> nationalityPreference;
  final NannyReligionPreference? religionPreference;
  final List<String> duties;
  final int salaryMin;
  final int salaryMax;
  final String currency;
  final List<String> benefits;
  final VisaSponsorship visaSponsorship;
  final int trialDurationDays;
  final int trialDailyRate;
  final String? additionalNotes;
  final int viewsCount;
  final int applicationsCount;
  final String city;
  final bool commitmentAgreed;

  /// Per-field translations for free-text fields (server-owned; see
  /// docs/TRANSLATIONS.md). Never written by [toMap].
  final Map<String, Map<String, String>> i18n;

  /// Job title in the app's current language (falls back to original).
  String localizedJobTitle([String? lang]) =>
      localize(jobTitle, i18n['jobTitle'], lang);

  /// Schedule in the app's current language (falls back to original).
  String localizedSchedule([String? lang]) =>
      localize(schedule, i18n['schedule'], lang);

  /// Additional notes in the app's current language (falls back to original).
  String localizedAdditionalNotes([String? lang]) =>
      localize(additionalNotes, i18n['additionalNotes'], lang);

  JobPostModel copyWith({
    String? familyName,
    JobPostStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? jobTitle,
    List<String>? rolesNeeded,
    JobType? jobType,
    String? schedule,
    DateTime? startDate,
    bool? startImmediate,
    JobDuration? duration,
    JobEmploymentType? employmentType,
    int? contractMonths,
    int? experienceYears,
    List<String>? languagesRequired,
    List<String>? languagesPreferred,
    List<String>? skillsRequired,
    List<String>? nationalityPreference,
    NannyReligionPreference? religionPreference,
    List<String>? duties,
    int? salaryMin,
    int? salaryMax,
    String? currency,
    List<String>? benefits,
    VisaSponsorship? visaSponsorship,
    int? trialDurationDays,
    int? trialDailyRate,
    String? additionalNotes,
    int? viewsCount,
    int? applicationsCount,
    String? city,
    bool? commitmentAgreed,
    Map<String, Map<String, String>>? i18n,
  }) =>
      JobPostModel(
        id: id,
        familyId: familyId,
        familyName: familyName ?? this.familyName,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        jobTitle: jobTitle ?? this.jobTitle,
        rolesNeeded: rolesNeeded ?? this.rolesNeeded,
        jobType: jobType ?? this.jobType,
        schedule: schedule ?? this.schedule,
        startDate: startDate ?? this.startDate,
        startImmediate: startImmediate ?? this.startImmediate,
        duration: duration ?? this.duration,
        employmentType: employmentType ?? this.employmentType,
        contractMonths: contractMonths ?? this.contractMonths,
        experienceYears: experienceYears ?? this.experienceYears,
        languagesRequired: languagesRequired ?? this.languagesRequired,
        languagesPreferred: languagesPreferred ?? this.languagesPreferred,
        skillsRequired: skillsRequired ?? this.skillsRequired,
        nationalityPreference: nationalityPreference ?? this.nationalityPreference,
        religionPreference: religionPreference ?? this.religionPreference,
        duties: duties ?? this.duties,
        salaryMin: salaryMin ?? this.salaryMin,
        salaryMax: salaryMax ?? this.salaryMax,
        currency: currency ?? this.currency,
        benefits: benefits ?? this.benefits,
        visaSponsorship: visaSponsorship ?? this.visaSponsorship,
        trialDurationDays: trialDurationDays ?? this.trialDurationDays,
        trialDailyRate: trialDailyRate ?? this.trialDailyRate,
        additionalNotes: additionalNotes ?? this.additionalNotes,
        viewsCount: viewsCount ?? this.viewsCount,
        applicationsCount: applicationsCount ?? this.applicationsCount,
        city: city ?? this.city,
        commitmentAgreed: commitmentAgreed ?? this.commitmentAgreed,
        i18n: i18n ?? this.i18n,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'familyId': familyId,
        'familyName': familyName,
        'status': status.name,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'jobTitle': jobTitle,
        'rolesNeeded': rolesNeeded,
        'jobType': jobType.name,
        'schedule': schedule,
        'startDate': startDate?.toIso8601String(),
        'startImmediate': startImmediate,
        'duration': duration.name,
        'employmentType': employmentType.name,
        'contractMonths': contractMonths,
        'experienceYears': experienceYears,
        'languagesRequired': languagesRequired,
        'languagesPreferred': languagesPreferred,
        'skillsRequired': skillsRequired,
        'nationalityPreference': nationalityPreference,
        'religionPreference': religionPreference?.name,
        'duties': duties,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'currency': currency,
        'benefits': benefits,
        'visaSponsorship': visaSponsorship.name,
        'trialDurationDays': trialDurationDays,
        'trialDailyRate': trialDailyRate,
        'additionalNotes': additionalNotes,
        'viewsCount': viewsCount,
        'applicationsCount': applicationsCount,
        'city': city,
        'commitmentAgreed': commitmentAgreed,
      };
}
