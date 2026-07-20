import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/nanny_model.dart';

/// Best-match algorithm — see /MATCH_ALGORITHM.md for the full specification.
///
/// This is the **single source of truth** for all match scoring in the app.
/// Every UI surface (browse cards, profile hero, smart match, applications)
/// must use [calculateJobMatch] so the percentage is identical everywhere.
///
/// All scores are deterministic: identical inputs always yield the same value.
class MatchService {
  /// Dimension weights (sum = 1.0). Mirrors §4 of MATCH_ALGORITHM.md.
  static const _weights = <String, double>{
    'jobType': 0.18,
    'location': 0.14,
    'language': 0.14,
    'experience': 0.12,
    'salary': 0.10,
    'skills': 0.09,
    'religion': 0.07,
    'household': 0.05,
    'householdLoad': 0.03,
    'availability': 0.04,
    'visa': 0.04,
  };

  // ════════════════════════ FULL SCORER (NannyModel) ════════════════════════

  /// Calculate the similarity score between a nanny and a job post (0–100).
  ///
  /// [family] is optional household context; when omitted, the religion,
  /// household-comfort, and household-load dimensions default to neutral (1.0).
  int calculateJobMatch(NannyModel nanny, JobPostModel job, {FamilyModel? family}) {
    double total = 0;
    total += _jobTypeScore(nanny, job) * _weights['jobType']!;
    total += _locationScore(nanny, job) * _weights['location']!;
    total += _languageScore(nanny, job, family) * _weights['language']!;
    total += _experienceScore(nanny, job) * _weights['experience']!;
    total += _salaryScore(nanny, job) * _weights['salary']!;
    total += _skillsScore(nanny, job, family) * _weights['skills']!;
    total += _religionScore(nanny, job, family) * _weights['religion']!;
    total += _householdComfortScore(nanny, family) * _weights['household']!;
    total += _householdLoadScore(nanny, family) * _weights['householdLoad']!;
    total += _availabilityScore(nanny, job) * _weights['availability']!;
    total += _visaScore(nanny, job) * _weights['visa']!;
    return (total * 100).round().clamp(0, 100);
  }

  // ── Dimension scorers (each returns 0.0–1.0) ───────────────────────────────

  double _jobTypeScore(NannyModel nanny, JobPostModel job) {
    if (nanny.jobTypePreference == JobTypePreference.both) return 1.0;
    final jobLiveIn = job.jobType == JobType.liveIn;
    final nannyLiveIn = nanny.jobTypePreference == JobTypePreference.liveIn;
    return (jobLiveIn == nannyLiveIn) ? 1.0 : 0.2;
  }

  double _locationScore(NannyModel nanny, JobPostModel job) {
    if (job.city.isEmpty) return 1.0;
    final emirateMatch = nanny.workEmirates.any(
      (e) => e.name.toLowerCase() == job.city.toLowerCase(),
    );
    if (emirateMatch) return 1.0;
    if (nanny.willingToRelocate) return 0.7;
    return 0.2;
  }

  double _languageScore(NannyModel nanny, JobPostModel job, FamilyModel? family) {
    final nannyLangs = nanny.languages.map((e) => e.toLowerCase()).toSet();

    // Fall back to the family's spoken languages when the posting omits them.
    var required = job.languagesRequired;
    if (required.isEmpty) required = family?.languagesAtHome ?? const [];

    final double base;
    if (required.isEmpty) {
      base = 1.0;
    } else {
      final matched =
          required.map((e) => e.toLowerCase()).where(nannyLangs.contains).length;
      base = matched / required.length;
    }

    // Preferred (nice-to-have) languages add a small bonus, capped at 1.0.
    final preferred = job.languagesPreferred;
    if (preferred.isEmpty) return base;
    final prefMatched =
        preferred.map((e) => e.toLowerCase()).where(nannyLangs.contains).length;
    final bonus = 0.1 * (prefMatched / preferred.length);
    return (base + bonus).clamp(0.0, 1.0);
  }

  double _experienceScore(NannyModel nanny, JobPostModel job) {
    final nannyYears = _nannyYears(nanny);
    if (job.experienceYears == 0) return 1.0;
    if (nannyYears >= job.experienceYears) return 1.0;
    if (nannyYears >= job.experienceYears - 1) return 0.7;
    return 0.3;
  }

  int _nannyYears(NannyModel nanny) => nanny.experiences.fold<int>(0, (sum, exp) {
        final years = exp.toDate.year - exp.fromDate.year;
        return sum + years.clamp(0, 20);
      });

  double _salaryScore(NannyModel nanny, JobPostModel job) {
    if (nanny.expectedSalaryMin == 0 && nanny.expectedSalaryMax == 0) return 1.0;
    if (job.salaryMax == 0) return 1.0;

    final overlap = !(nanny.expectedSalaryMin > job.salaryMax ||
        nanny.expectedSalaryMax < job.salaryMin);
    if (overlap) return 1.0;

    final diff = nanny.expectedSalaryMin - job.salaryMax;
    if (diff < 500) return 0.7;
    if (diff < 1000) return 0.4;
    return 0.1;
  }

  double _skillsScore(NannyModel nanny, JobPostModel job, FamilyModel? family) {
    // Combine explicit skill requirements with the daily duties on the posting,
    // plus a special-needs requirement when the household has one.
    final requirements = <String>{...job.skillsRequired, ...job.duties};
    if (family?.hasSpecialNeedsChild == true) requirements.add('special needs');
    if (requirements.isEmpty) return 1.0;
    final familyHasInfant = family?.childrenAges.any((a) {
          final n = int.tryParse(a.trim());
          return n != null && n <= 1;
        }) ??
        false;
    var score = 0;
    for (final raw in requirements) {
      final req = raw.toLowerCase();
      if (req.contains('cook') || req.contains('meal')) {
        if (nanny.canCook) score++;
      } else if (req.contains('newborn') || req.contains('infant')) {
        final hasNewborn = familyHasInfant ||
            nanny.experiences.any((e) =>
                e.jobTitle.toLowerCase().contains('newborn') ||
                e.children.toLowerCase().contains('newborn'));
        if (hasNewborn) score++;
      } else if (req.contains('night')) {
        if (nanny.canDoNightShifts) score++;
      } else if (req.contains('pet')) {
        if (nanny.comfortableWithPets) score++;
      } else if (req.contains('special')) {
        if (nanny.experiences
            .any((e) => e.jobTitle.toLowerCase().contains('special'))) {
          score++;
        }
      } else {
        // Unknown duty — no negative signal.
        score++;
      }
    }
    return score / requirements.length;
  }

  double _religionScore(NannyModel nanny, JobPostModel job, FamilyModel? family) {
    final pref = job.religionPreference ??
        family?.nannyReligionPreference ??
        NannyReligionPreference.noPreference;
    final nannyReligion = nanny.religion.toLowerCase();
    final nannyIsMuslim =
        nannyReligion.contains('muslim') || nannyReligion.contains('islam');
    switch (pref) {
      case NannyReligionPreference.noPreference:
        return 1.0;
      case NannyReligionPreference.preferMuslim:
        return nannyIsMuslim ? 1.0 : 0.3;
      case NannyReligionPreference.preferSame:
        final famReligion = (family?.religion ?? '').toLowerCase();
        if (famReligion.isEmpty || nannyReligion.isEmpty) return 0.6;
        return nannyReligion == famReligion ? 1.0 : 0.3;
      case NannyReligionPreference.openWithRespect:
        return nanny.comfortableWithDifferentFaith ? 1.0 : 0.5;
    }
  }

  double _householdComfortScore(NannyModel nanny, FamilyModel? family) {
    if (family == null) return 1.0;
    final cameraScore =
        family.hasCameras ? (nanny.comfortableWithCameras ? 1.0 : 0.0) : 1.0;
    final petScore =
        family.hasPets ? (nanny.comfortableWithPets ? 1.0 : 0.0) : 1.0;
    return (cameraScore + petScore) / 2;
  }

  /// Heavier households (3+ children) favour nannies with proven depth —
  /// substantial experience or their own parenting background. Smaller
  /// households impose no constraint (neutral 1.0).
  double _householdLoadScore(NannyModel nanny, FamilyModel? family) {
    if (family == null || family.childrenCount <= 2) return 1.0;
    final hasDepth = nanny.hasChildren || _nannyYears(nanny) >= 3;
    return hasDepth ? 1.0 : 0.6;
  }

  double _availabilityScore(NannyModel nanny, JobPostModel job) {
    if (nanny.availability == AvailabilityStatus.onTrial) return 0.3;
    if (nanny.availability == AvailabilityStatus.availableNow) return 1.0;
    if (nanny.availableFrom != null && job.startDate != null) {
      final diff = nanny.availableFrom!.difference(job.startDate!).inDays;
      if (diff <= 0) return 1.0;
      if (diff <= 7) return 0.8;
      if (diff <= 14) return 0.6;
      return 0.3;
    }
    return 0.7;
  }

  double _visaScore(NannyModel nanny, JobPostModel job) {
    switch (job.visaSponsorship) {
      case VisaSponsorship.full:
        return 1.0;
      case VisaSponsorship.residenceOnly:
        return nanny.hasEmiratesId ? 1.0 : 0.0;
      case VisaSponsorship.shared:
      case VisaSponsorship.none:
        return (nanny.willingToTransferVisa == true || nanny.hasEmiratesId)
            ? 1.0
            : 0.3;
    }
  }

  /// Get match quality label based on score.
  String getMatchLabel(int score) {
    if (score >= 80) return 'Great Match! 🌸';
    if (score >= 60) return 'Good Match';
    if (score >= 40) return 'Fair Match';
    return 'Low Match';
  }

  /// Per-dimension breakdown for the "why this match" UI.
  List<MatchFactor> getMatchFactors(NannyModel nanny, JobPostModel job, {FamilyModel? family}) {
    return [
      MatchFactor(name: 'Job Type', score: (_jobTypeScore(nanny, job) * 100).round(), weight: 18),
      MatchFactor(name: 'Location', score: (_locationScore(nanny, job) * 100).round(), weight: 14),
      MatchFactor(name: 'Languages', score: (_languageScore(nanny, job, family) * 100).round(), weight: 14),
      MatchFactor(name: 'Experience', score: (_experienceScore(nanny, job) * 100).round(), weight: 12),
      MatchFactor(name: 'Salary', score: (_salaryScore(nanny, job) * 100).round(), weight: 10),
      MatchFactor(name: 'Skills', score: (_skillsScore(nanny, job, family) * 100).round(), weight: 9),
      MatchFactor(name: 'Religion', score: (_religionScore(nanny, job, family) * 100).round(), weight: 7),
      MatchFactor(name: 'Household', score: (_householdComfortScore(nanny, family) * 100).round(), weight: 5),
      MatchFactor(name: 'Household Load', score: (_householdLoadScore(nanny, family) * 100).round(), weight: 3),
      MatchFactor(name: 'Availability', score: (_availabilityScore(nanny, job) * 100).round(), weight: 4),
      MatchFactor(name: 'Visa', score: (_visaScore(nanny, job) * 100).round(), weight: 4),
    ];
  }

  /// Build a browse card stamped with the canonical job match %.
  NannyCardModel cardWithJobMatch(
    NannyModel nanny,
    JobPostModel job, {
    FamilyModel? family,
  }) =>
      NannyCardModel.fromNanny(nanny).copyWith(
        matchPercent: calculateJobMatch(nanny, job, family: family),
      );

  /// Score + sort nannies against a job using the canonical 11-dimension algorithm.
  List<NannyCardModel> rankNannies(
    List<NannyModel> nannies,
    JobPostModel job, {
    FamilyModel? family,
  }) {
    final scored = nannies
        .map((n) => cardWithJobMatch(n, job, family: family))
        .toList();
    return _sortByMatchPercent(scored, job);
  }

  /// Legacy card-only ranking for mock seeds that lack full [NannyModel] data.
  /// Prefer [rankNannies] whenever the full profile is available.
  List<NannyCardModel> rankCards(List<NannyCardModel> cards, JobPostModel job) {
    final scored = cards
        .map((c) => c.copyWith(matchPercent: calculateCardMatch(c, job)))
        .toList();
    return _sortByMatchPercent(scored, job);
  }

  List<NannyCardModel> _sortByMatchPercent(List<NannyCardModel> scored, JobPostModel job) {
    final prefs = job.nationalityPreference.map((e) => e.toLowerCase()).toSet();
    scored.sort((a, b) {
      final byScore = b.matchPercent.compareTo(a.matchPercent);
      if ((a.matchPercent - b.matchPercent).abs() > 2) return byScore;
      final aPref = prefs.contains(a.nationality.toLowerCase()) ? 1 : 0;
      final bPref = prefs.contains(b.nationality.toLowerCase()) ? 1 : 0;
      if (aPref != bPref) return bPref.compareTo(aPref);
      return byScore;
    });
    return scored;
  }

  // ═══════════════════════ CARD SCORER (mock fallback only) ═════════════════

  static const _cardDims = ['jobType', 'location', 'language', 'experience', 'availability'];

  /// True 0–100 score for a browse card against a job (no display floor).
  int calculateCardMatch(NannyCardModel card, JobPostModel job) {
    final scores = <String, double>{
      'jobType': _cardJobType(card, job),
      'location': _cardLocation(card, job),
      'language': _cardLanguage(card, job),
      'experience': _cardExperience(card, job),
      'availability': card.availableNow ? 1.0 : 0.7,
    };
    double weighted = 0;
    double weightSum = 0;
    for (final d in _cardDims) {
      weighted += scores[d]! * _weights[d]!;
      weightSum += _weights[d]!;
    }
    return (weighted / weightSum * 100).round().clamp(0, 100);
  }

  double _cardJobType(NannyCardModel card, JobPostModel job) {
    final cardLiveOut = card.jobType.toLowerCase().contains('out');
    final jobLiveOut = job.jobType == JobType.liveOut;
    return cardLiveOut == jobLiveOut ? 1.0 : 0.2;
  }

  double _cardLocation(NannyCardModel card, JobPostModel job) {
    if (job.city.isEmpty) return 1.0;
    return card.city.toLowerCase() == job.city.toLowerCase() ? 1.0 : 0.4;
  }

  double _cardLanguage(NannyCardModel card, JobPostModel job) {
    final required = job.languagesRequired.map((e) => e.toLowerCase()).toList();
    if (required.isEmpty) return 1.0;
    final tags = card.tags.map((t) => t.toLowerCase()).toList();
    final matched = required
        .where((l) => tags.any((t) => t.contains(l) || l.contains(t)))
        .length;
    return matched / required.length;
  }

  double _cardExperience(NannyCardModel card, JobPostModel job) {
    if (job.experienceYears <= 0) return 1.0;
    if (card.yearsExp >= job.experienceYears) return 1.0;
    if (card.yearsExp >= job.experienceYears - 1) return 0.7;
    return 0.3;
  }
}

class MatchFactor {
  const MatchFactor({
    required this.name,
    required this.score,
    required this.weight,
  });

  final String name;
  final int score;
  final int weight;

  bool get isStrong => score >= 80;
  bool get isWeak => score < 50;
}
