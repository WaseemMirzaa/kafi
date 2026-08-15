import 'package:flutter_test/flutter_test.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/match_service.dart';

/// Unit tests for [MatchService] — the single source of truth for match scoring
/// across both flows (Spec §9 / MATCH_ALGORITHM.md). Every method is a pure,
/// deterministic function of its inputs, so we can build fixtures with plain
/// constructors and assert the exact integer score by hand — no Firebase, no
/// mocks. The builders below default to a *perfect* nanny/job pair (every
/// dimension scores 1.0 → 100), and each test overrides just the one field
/// under test, so the arithmetic behind each assertion stays obvious.
void main() {
  final svc = MatchService();

  // ── Fixture builders (default = perfect match) ─────────────────────────────

  NannyModel makeNanny({
    JobTypePreference jobType = JobTypePreference.both,
    List<Emirate> emirates = const [Emirate.dubai],
    bool relocate = false,
    List<String> languages = const ['English'],
    List<WorkExperience> experiences = const [],
    int salaryMin = 2000,
    int salaryMax = 3000,
    AvailabilityStatus availability = AvailabilityStatus.availableNow,
    DateTime? availableFrom,
    String religion = '',
    bool differentFaith = true,
    bool cameras = true,
    bool pets = true,
    bool cook = true,
    bool nightShifts = false,
    bool hasChildren = false,
    bool hasEid = false,
    bool? transferVisa,
  }) =>
      NannyModel(
        id: 'n',
        userId: 'n',
        jobTypePreference: jobType,
        workEmirates: emirates,
        willingToRelocate: relocate,
        languages: languages,
        experiences: experiences,
        expectedSalaryMin: salaryMin,
        expectedSalaryMax: salaryMax,
        availability: availability,
        availableFrom: availableFrom,
        religion: religion,
        comfortableWithDifferentFaith: differentFaith,
        comfortableWithCameras: cameras,
        comfortableWithPets: pets,
        canCook: cook,
        canDoNightShifts: nightShifts,
        hasChildren: hasChildren,
        hasEmiratesId: hasEid,
        willingToTransferVisa: transferVisa,
      );

  JobPostModel makeJob({
    JobType type = JobType.liveIn,
    String city = 'Dubai',
    List<String> required = const ['English'],
    List<String> preferred = const [],
    int experienceYears = 0,
    int salaryMin = 2000,
    int salaryMax = 3000,
    List<String> skills = const [],
    List<String> duties = const [],
    NannyReligionPreference? religionPref,
    DateTime? startDate,
    VisaSponsorship visa = VisaSponsorship.full,
  }) =>
      JobPostModel(
        id: 'j',
        familyId: 'f',
        jobType: type,
        city: city,
        languagesRequired: required,
        languagesPreferred: preferred,
        experienceYears: experienceYears,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        skillsRequired: skills,
        duties: duties,
        religionPreference: religionPref,
        startDate: startDate,
        visaSponsorship: visa,
      );

  FamilyModel makeFamily({
    bool cameras = false,
    bool pets = false,
    int childrenCount = 0,
    NannyReligionPreference religionPref = NannyReligionPreference.noPreference,
    String religion = '',
  }) =>
      FamilyModel(
        id: 'f',
        userId: 'f',
        hasCameras: cameras,
        hasPets: pets,
        childrenCount: childrenCount,
        nannyReligionPreference: religionPref,
        religion: religion,
      );

  // A WorkExperience spanning exactly [years] calendar years.
  WorkExperience exp(int years) => WorkExperience(
        id: 'e',
        jobTitle: 'Nanny',
        employer: 'X',
        country: 'UAE',
        city: 'Dubai',
        fromDate: DateTime(2020, 1, 1),
        toDate: DateTime(2020 + years, 1, 1),
        children: '2',
        duties: 'childcare',
        reasonLeaving: 'contract ended',
      );

  // Pull one dimension's 0–100 sub-score out of the factor breakdown.
  int dim(NannyModel n, JobPostModel j, String name, {FamilyModel? family}) =>
      svc
          .getMatchFactors(n, j, family: family)
          .firstWhere((f) => f.name == name)
          .score;

  // ════════════════════════ Composite scorer ════════════════════════════════

  group('calculateJobMatch — composite', () {
    test('a fully-aligned nanny + job scores 100', () {
      expect(svc.calculateJobMatch(makeNanny(), makeJob()), 100);
    });

    test('breaking one dimension lowers the score by its exact weight', () {
      // Job type is live-in; nanny only wants live-out → jobType 0.2 not 1.0.
      // Loss = (1 - 0.2) * 0.18 = 0.144 → 1.0 - 0.144 = 0.856 → 86.
      final n = makeNanny(jobType: JobTypePreference.liveOut);
      final j = makeJob(type: JobType.liveIn);
      expect(svc.calculateJobMatch(n, j), 86);
    });

    test('household context (family) feeds the score', () {
      // Family has cameras but the nanny is not camera-comfortable → household
      // (0 + 1)/2 = 0.5. Loss = 0.5 * 0.05 = 0.025 → 0.975 → 98.
      final n = makeNanny(cameras: false);
      final f = makeFamily(cameras: true);
      expect(svc.calculateJobMatch(n, makeJob(), family: f), 98);
    });

    test('a nanny mismatched everywhere never drops below 0', () {
      final n = makeNanny(
        jobType: JobTypePreference.liveOut,
        emirates: const [Emirate.sharjah],
        relocate: false,
        languages: const ['Tagalog'],
        salaryMin: 9000,
        salaryMax: 9000,
        availability: AvailabilityStatus.onTrial,
        transferVisa: false,
      );
      final j = makeJob(
        type: JobType.liveIn,
        city: 'Dubai',
        required: const ['English', 'Arabic'],
        experienceYears: 5,
        salaryMin: 1000,
        salaryMax: 1500,
        duties: const ['Cooking'],
        visa: VisaSponsorship.residenceOnly,
      );
      final score = svc.calculateJobMatch(n, j);
      expect(score, inInclusiveRange(0, 100));
      expect(score, lessThan(50));
    });
  });

  // ════════════════════════ Per-dimension scorers ═══════════════════════════
  //
  // Each dimension is asserted through getMatchFactors, which exposes the raw
  // 0–100 sub-score for that dimension — so we test one scorer at a time.

  group('dimension: Job Type', () {
    test('"both" always fits', () {
      expect(dim(makeNanny(jobType: JobTypePreference.both),
          makeJob(type: JobType.liveIn), 'Job Type'), 100);
    });
    test('exact live-in/live-out match', () {
      expect(dim(makeNanny(jobType: JobTypePreference.liveOut),
          makeJob(type: JobType.liveOut), 'Job Type'), 100);
    });
    test('mismatch scores 20', () {
      expect(dim(makeNanny(jobType: JobTypePreference.liveOut),
          makeJob(type: JobType.liveIn), 'Job Type'), 20);
    });
  });

  group('dimension: Location', () {
    test('emirate match → 100', () {
      expect(dim(makeNanny(emirates: const [Emirate.dubai]),
          makeJob(city: 'Dubai'), 'Location'), 100);
    });
    test('no match but willing to relocate → 70', () {
      expect(
          dim(makeNanny(emirates: const [Emirate.sharjah], relocate: true),
              makeJob(city: 'Dubai'), 'Location'),
          70);
    });
    test('no match and unwilling to relocate → 20', () {
      expect(
          dim(makeNanny(emirates: const [Emirate.sharjah], relocate: false),
              makeJob(city: 'Dubai'), 'Location'),
          20);
    });
    test('job with no city is unconstrained → 100', () {
      expect(dim(makeNanny(emirates: const [Emirate.sharjah]),
          makeJob(city: ''), 'Location'), 100);
    });
  });

  group('dimension: Languages', () {
    test('all required languages spoken → 100', () {
      expect(dim(makeNanny(languages: const ['English', 'Arabic']),
          makeJob(required: const ['English', 'Arabic']), 'Languages'), 100);
    });
    test('half of the required languages → 50', () {
      expect(dim(makeNanny(languages: const ['English']),
          makeJob(required: const ['English', 'Arabic']), 'Languages'), 50);
    });
    test('preferred languages add a capped bonus', () {
      // base 0.5 (1 of 2 required) + 0.1 bonus (1 of 1 preferred) = 0.6 → 60.
      expect(
          dim(
              makeNanny(languages: const ['English', 'French']),
              makeJob(
                  required: const ['English', 'Arabic'],
                  preferred: const ['French']),
              'Languages'),
          60);
    });
  });

  group('dimension: Experience', () {
    test('job requiring no experience → 100', () {
      expect(dim(makeNanny(), makeJob(experienceYears: 0), 'Experience'), 100);
    });
    test('meets or exceeds the requirement → 100', () {
      expect(dim(makeNanny(experiences: [exp(3)]),
          makeJob(experienceYears: 3), 'Experience'), 100);
    });
    test('one year short → 70', () {
      expect(dim(makeNanny(experiences: [exp(2)]),
          makeJob(experienceYears: 3), 'Experience'), 70);
    });
    test('well short → 30', () {
      expect(dim(makeNanny(experiences: [exp(1)]),
          makeJob(experienceYears: 3), 'Experience'), 30);
    });
  });

  group('dimension: Salary', () {
    test('overlapping ranges → 100', () {
      expect(dim(makeNanny(salaryMin: 2000, salaryMax: 3000),
          makeJob(salaryMin: 2500, salaryMax: 3500), 'Salary'), 100);
    });
    test('small gap (<500) → 70', () {
      expect(dim(makeNanny(salaryMin: 3400, salaryMax: 4000),
          makeJob(salaryMin: 2000, salaryMax: 3000), 'Salary'), 70);
    });
    test('medium gap (<1000) → 40', () {
      expect(dim(makeNanny(salaryMin: 3700, salaryMax: 4000),
          makeJob(salaryMin: 2000, salaryMax: 3000), 'Salary'), 40);
    });
    test('large gap (>=1000) → 10', () {
      expect(dim(makeNanny(salaryMin: 4200, salaryMax: 5000),
          makeJob(salaryMin: 2000, salaryMax: 3000), 'Salary'), 10);
    });
    test('nanny with no salary expectation is flexible → 100', () {
      expect(dim(makeNanny(salaryMin: 0, salaryMax: 0),
          makeJob(salaryMin: 2000, salaryMax: 3000), 'Salary'), 100);
    });
  });

  group('dimension: Skills', () {
    test('no required skills or duties → 100', () {
      expect(dim(makeNanny(), makeJob(duties: const []), 'Skills'), 100);
    });
    test('cooking duty met by a nanny who cooks → 100', () {
      expect(dim(makeNanny(cook: true), makeJob(duties: const ['Cooking']),
          'Skills'), 100);
    });
    test('cooking duty unmet by a nanny who does not cook → 0', () {
      expect(dim(makeNanny(cook: false), makeJob(duties: const ['Cooking']),
          'Skills'), 0);
    });
    test('half the duties met → 50', () {
      // cooks (met) but no night shifts (unmet) → 1 of 2.
      expect(
          dim(makeNanny(cook: true, nightShifts: false),
              makeJob(duties: const ['Cooking', 'Night shift']), 'Skills'),
          50);
    });
    test('an unrecognised duty is not a negative signal → 100', () {
      expect(dim(makeNanny(), makeJob(duties: const ['Laundry']), 'Skills'),
          100);
    });
  });

  group('dimension: Religion', () {
    test('no preference → 100', () {
      expect(dim(makeNanny(religion: 'Christian'),
          makeJob(religionPref: null), 'Religion'), 100);
    });
    test('prefer Muslim, nanny is Muslim → 100', () {
      expect(
          dim(makeNanny(religion: 'Muslim'),
              makeJob(religionPref: NannyReligionPreference.preferMuslim),
              'Religion'),
          100);
    });
    test('prefer Muslim, nanny is not → 30', () {
      expect(
          dim(makeNanny(religion: 'Christian'),
              makeJob(religionPref: NannyReligionPreference.preferMuslim),
              'Religion'),
          30);
    });
    test('open-with-respect rewards faith-flexible nannies', () {
      expect(
          dim(makeNanny(differentFaith: true),
              makeJob(religionPref: NannyReligionPreference.openWithRespect),
              'Religion'),
          100);
      expect(
          dim(makeNanny(differentFaith: false),
              makeJob(religionPref: NannyReligionPreference.openWithRespect),
              'Religion'),
          50);
    });
  });

  group('dimension: Availability', () {
    test('available now → 100', () {
      expect(dim(makeNanny(availability: AvailabilityStatus.availableNow),
          makeJob(), 'Availability'), 100);
    });
    test('currently on another trial → 30', () {
      expect(dim(makeNanny(availability: AvailabilityStatus.onTrial),
          makeJob(), 'Availability'), 30);
    });
    test('available exactly on the start date → 100', () {
      expect(
          dim(
              makeNanny(
                  availability: AvailabilityStatus.availableFrom,
                  availableFrom: DateTime(2026, 1, 1)),
              makeJob(startDate: DateTime(2026, 1, 1)),
              'Availability'),
          100);
    });
    test('available ~10 days after the start date → 60', () {
      expect(
          dim(
              makeNanny(
                  availability: AvailabilityStatus.availableFrom,
                  availableFrom: DateTime(2026, 1, 11)),
              makeJob(startDate: DateTime(2026, 1, 1)),
              'Availability'),
          60);
    });
  });

  group('dimension: Visa', () {
    test('full sponsorship fits anyone → 100', () {
      expect(dim(makeNanny(hasEid: false),
          makeJob(visa: VisaSponsorship.full), 'Visa'), 100);
    });
    test('residence-only requires an Emirates ID', () {
      expect(dim(makeNanny(hasEid: true),
          makeJob(visa: VisaSponsorship.residenceOnly), 'Visa'), 100);
      expect(dim(makeNanny(hasEid: false),
          makeJob(visa: VisaSponsorship.residenceOnly), 'Visa'), 0);
    });
    test('no sponsorship needs transfer-willing or an EID', () {
      expect(dim(makeNanny(transferVisa: true, hasEid: false),
          makeJob(visa: VisaSponsorship.none), 'Visa'), 100);
      expect(dim(makeNanny(transferVisa: false, hasEid: false),
          makeJob(visa: VisaSponsorship.none), 'Visa'), 30);
    });
  });

  group('dimension: Household (needs family context)', () {
    test('no family context is neutral → 100', () {
      expect(dim(makeNanny(cameras: false), makeJob(), 'Household'), 100);
    });
    test('cameras present but nanny uncomfortable → 50', () {
      expect(
          dim(makeNanny(cameras: false), makeJob(),
              family: makeFamily(cameras: true), 'Household'),
          50);
    });
    test('cameras and pets both a problem → 0', () {
      expect(
          dim(makeNanny(cameras: false, pets: false), makeJob(),
              family: makeFamily(cameras: true, pets: true), 'Household'),
          0);
    });
  });

  group('dimension: Household Load (needs family context)', () {
    test('small household imposes no constraint → 100', () {
      expect(
          dim(makeNanny(), makeJob(),
              family: makeFamily(childrenCount: 2), 'Household Load'),
          100);
    });
    test('large household + inexperienced/childless nanny → 60', () {
      expect(
          dim(makeNanny(hasChildren: false), makeJob(),
              family: makeFamily(childrenCount: 3), 'Household Load'),
          60);
    });
    test('large household + a nanny with her own children → 100', () {
      expect(
          dim(makeNanny(hasChildren: true), makeJob(),
              family: makeFamily(childrenCount: 3), 'Household Load'),
          100);
    });
  });

  // ════════════════════════ Factor breakdown & label ════════════════════════

  group('getMatchFactors — metadata', () {
    test('returns all 11 weighted dimensions', () {
      final factors = svc.getMatchFactors(makeNanny(), makeJob());
      expect(factors, hasLength(11));
    });
    test('the weights sum to 100', () {
      final total = svc
          .getMatchFactors(makeNanny(), makeJob())
          .fold<int>(0, (sum, f) => sum + f.weight);
      expect(total, 100);
    });
    test('MatchFactor.isStrong / isWeak thresholds', () {
      expect(const MatchFactor(name: 'x', score: 80, weight: 1).isStrong, isTrue);
      expect(const MatchFactor(name: 'x', score: 79, weight: 1).isStrong, isFalse);
      expect(const MatchFactor(name: 'x', score: 49, weight: 1).isWeak, isTrue);
      expect(const MatchFactor(name: 'x', score: 50, weight: 1).isWeak, isFalse);
    });
  });

  group('getMatchLabel', () {
    test('bucket boundaries', () {
      expect(svc.getMatchLabel(100), 'Great Match! 🌸');
      expect(svc.getMatchLabel(80), 'Great Match! 🌸');
      expect(svc.getMatchLabel(79), 'Good Match');
      expect(svc.getMatchLabel(60), 'Good Match');
      expect(svc.getMatchLabel(59), 'Fair Match');
      expect(svc.getMatchLabel(40), 'Fair Match');
      expect(svc.getMatchLabel(39), 'Low Match');
      expect(svc.getMatchLabel(0), 'Low Match');
    });
  });

  // ════════════════════════ Card scorer & ranking ═══════════════════════════

  NannyCardModel makeCard({
    String id = 'c',
    String nationality = 'Filipino',
    int yearsExp = 5,
    String jobType = 'Live-out',
    String city = 'Dubai',
    List<String> tags = const ['English'],
    bool availableNow = true,
  }) =>
      NannyCardModel(
        id: id,
        initials: 'AB',
        name: 'A B',
        nationality: nationality,
        yearsExp: yearsExp,
        jobType: jobType,
        city: city,
        matchPercent: 0,
        tags: tags,
        availableNow: availableNow,
      );

  JobPostModel makeCardJob({
    JobType type = JobType.liveOut,
    String city = 'Dubai',
    List<String> required = const ['English'],
    int experienceYears = 0,
    List<String> nationalityPref = const [],
  }) =>
      JobPostModel(
        id: 'j',
        familyId: 'f',
        jobType: type,
        city: city,
        languagesRequired: required,
        experienceYears: experienceYears,
        nationalityPreference: nationalityPref,
      );

  group('calculateCardMatch (mock fallback)', () {
    test('a fully-aligned card scores 100', () {
      expect(svc.calculateCardMatch(makeCard(), makeCardJob()), 100);
    });
    test('a poorly-aligned card scores below 35 without display clamping', () {
      final card = makeCard(
          jobType: 'Live-in',
          city: 'Sharjah',
          tags: const [],
          yearsExp: 0,
          availableNow: false);
      final job = makeCardJob(required: const ['English', 'Arabic'], experienceYears: 5);
      expect(svc.calculateCardMatch(card, job), lessThan(35));
    });
  });

  group('rankNannies', () {
    test('uses the canonical full scorer for browse cards', () {
      final job = makeJob();
      final nanny = makeNanny();
      final ranked = svc.rankNannies([nanny], job);
      expect(ranked.single.matchPercent, 100);
    });
  });

  group('rankCards', () {
    test('sorts strictly best-first by score', () {
      final job = makeCardJob();
      final a = makeCard(id: 'A'); // perfect
      final b = makeCard(id: 'B', city: 'Sharjah'); // location miss
      final c = makeCard(
          id: 'C', jobType: 'Live-in', city: 'Sharjah', tags: const [], availableNow: false);
      final ranked = svc.rankCards([c, a, b], job);
      expect(ranked.map((e) => e.id).toList(), ['A', 'B', 'C']);
      expect(ranked.first.matchPercent, 100);
    });

    test('nationality preference only breaks near-ties', () {
      // Two otherwise identical, equally-scoring cards: the one whose
      // nationality the family prefers wins the tie.
      final job = makeCardJob(nationalityPref: const ['Filipino']);
      final indian = makeCard(id: 'X', nationality: 'Indian');
      final filipino = makeCard(id: 'Y', nationality: 'Filipino');
      final ranked = svc.rankCards([indian, filipino], job);
      expect(ranked.first.id, 'Y');
    });

    test('nationality preference never overrides a clearly higher score', () {
      // X (preferred-nationality? no) is a perfect match; Y matches the
      // preferred nationality but scores far lower → X still ranks first.
      final job = makeCardJob(nationalityPref: const ['Filipino']);
      final x = makeCard(id: 'X', nationality: 'Indian'); // 100 on card fallback
      final y = makeCard(id: 'Y', nationality: 'Filipino', city: 'Sharjah'); // lower
      final ranked = svc.rankCards([y, x], job);
      expect(ranked.first.id, 'X');
    });
  });
}
