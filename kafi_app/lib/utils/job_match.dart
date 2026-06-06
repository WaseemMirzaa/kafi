import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/match_service.dart';

/// Deterministic compatibility score (0–99) between a posted [job] and a
/// browse-card [nanny].
///
/// Thin wrapper over the single source of truth, [MatchService]: it delegates to
/// the card-level scorer (same weights & formulas as the full algorithm, over
/// the subset of dimensions a card carries) and applies the friendly display
/// floor. See /MATCH_ALGORITHM.md.
int jobMatchPercent(JobPostModel job, NannyCardModel nanny) =>
    MatchService().cardMatchPercent(nanny, job);
