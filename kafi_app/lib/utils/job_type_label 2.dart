import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';

/// Localize a nanny-card / seed `jobType` display string ("Live-in", "Live-out",
/// "Live-in · Live-out") while leaving the stored canonical English intact for
/// filters and match scoring.
String localizeJobTypeLabel(String jobType) {
  final lower = jobType.toLowerCase();
  final hasIn = lower.contains('live-in') || lower.contains('livein');
  final hasOut = lower.contains('live-out') || lower.contains('liveout') || lower.contains('out');
  if (hasIn && hasOut) {
    return '${AppStrings.jobLiveIn.tr} · ${AppStrings.jobLiveOut.tr}';
  }
  if (hasOut && !hasIn) return AppStrings.jobLiveOut.tr;
  return AppStrings.jobLiveIn.tr;
}
