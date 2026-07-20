import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/match_service.dart';

/// Canonical compatibility score (0–100) between a posted [job] and [nanny].
///
/// Thin wrapper over [MatchService.calculateJobMatch] — the only score families
/// and nannies should see. See /MATCH_ALGORITHM.md.
int jobMatchPercent(
  JobPostModel job,
  NannyModel nanny, {
  FamilyModel? family,
}) =>
    MatchService().calculateJobMatch(nanny, job, family: family);
