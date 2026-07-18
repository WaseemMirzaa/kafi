import 'package:flutter_test/flutter_test.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';

/// [JobPostModel.fromMap] is the reusable parser behind real match scoring —
/// the apply service reads the stored job doc through it to compute an
/// attribute-based match (Spec §9) instead of a hardcoded placeholder.
void main() {
  group('JobPostModel.fromMap', () {
    test('round-trips the matching-critical fields via toMap', () {
      final job = JobPostModel(
        id: 'j1',
        familyId: 'f1',
        familyName: 'Al Mansoori',
        jobTitle: 'Live-in Nanny',
        jobType: JobType.liveIn,
        city: 'Dubai',
        experienceYears: 3,
        languagesRequired: const ['English', 'Arabic'],
        languagesPreferred: const ['French'],
        skillsRequired: const ['Cooking'],
        duties: const ['School runs'],
        nationalityPreference: const ['Filipino'],
        salaryMin: 2000,
        salaryMax: 3000,
        visaSponsorship: VisaSponsorship.full,
        religionPreference: NannyReligionPreference.preferMuslim,
        trialDurationDays: 7,
        trialDailyRate: 150,
        additionalNotes: 'Must love pets',
      );
      final back = JobPostModel.fromMap('j1', job.toMap());
      expect(back.jobTitle, 'Live-in Nanny');
      expect(back.jobType, JobType.liveIn);
      expect(back.city, 'Dubai');
      expect(back.experienceYears, 3);
      expect(back.languagesRequired, ['English', 'Arabic']);
      expect(back.languagesPreferred, ['French']);
      expect(back.skillsRequired, ['Cooking']);
      expect(back.duties, ['School runs']);
      expect(back.nationalityPreference, ['Filipino']);
      expect(back.salaryMin, 2000);
      expect(back.salaryMax, 3000);
      expect(back.visaSponsorship, VisaSponsorship.full);
      expect(back.religionPreference, NannyReligionPreference.preferMuslim);
      expect(back.trialDurationDays, 7);
      expect(back.additionalNotes, 'Must love pets');
    });

    test('tolerates missing / unknown values with sensible defaults', () {
      final back = JobPostModel.fromMap('j2', const {});
      expect(back.id, 'j2');
      expect(back.familyId, '');
      expect(back.status, JobPostStatus.active);
      expect(back.jobType, JobType.liveIn);
      expect(back.visaSponsorship, VisaSponsorship.full);
      expect(back.salaryMin, 0);
      expect(back.experienceYears, 0);
      expect(back.religionPreference, isNull);
    });

    test('parses ISO date strings', () {
      final back = JobPostModel.fromMap(
          'j3', {'startDate': '2026-08-01T00:00:00.000Z'});
      expect(back.startDate, DateTime.utc(2026, 8, 1));
    });
  });
}
