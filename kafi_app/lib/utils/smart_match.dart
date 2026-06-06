import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/match_service.dart';

/// Smart-match evaluation for the nanny-side "why this match" screen.
///
/// Thin wrapper over the single source of truth, [MatchService]: the overall
/// [MatchResult.score] is the canonical 0–100 similarity, and the five boolean
/// checks surfaced in the UI are derived from the corresponding canonical
/// dimensions (a dimension "passes" when its score clears the threshold below).
/// See /MATCH_ALGORITHM.md.
class SmartMatch {
  static MatchResult evaluate({JobPostModel? job, NannyModel? nanny, FamilyModel? family}) {
    if (job == null || nanny == null) {
      return const MatchResult(
        score: 60,
        language: false,
        experience: true,
        role: true,
        visa: true,
        salary: false,
      );
    }

    final svc = MatchService();
    final score = svc.calculateJobMatch(nanny, job, family: family);
    final factors = {
      for (final f in svc.getMatchFactors(nanny, job, family: family)) f.name: f.score,
    };
    bool pass(String name, [int threshold = 80]) => (factors[name] ?? 0) >= threshold;

    return MatchResult(
      score: score,
      language: pass('Languages'),
      experience: pass('Experience', 70),
      role: pass('Job Type'),
      visa: pass('Visa'),
      salary: pass('Salary'),
    );
  }
}

class MatchResult {
  const MatchResult({
    required this.score,
    required this.language,
    required this.experience,
    required this.role,
    required this.visa,
    required this.salary,
  });

  final int score;
  final bool language;
  final bool experience;
  final bool role;
  final bool visa;
  final bool salary;
}
