import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';

/// Shared rule for admin `settings/global.hideInactiveNannies`.
/// When the toggle is on, a nanny is hidden from family discovery unless her
/// `lastActiveAt` is within [NannyConstants.hideInactiveListingDays].
/// Missing `lastActiveAt` counts as inactive (cannot prove recent open).
class NannyListingActivity {
  NannyListingActivity._();

  static bool isActiveForListing(NannyModel n, {DateTime? now}) {
    final at = n.lastActiveAt;
    if (at == null) return false;
    final cutoff = (now ?? DateTime.now())
        .subtract(const Duration(days: NannyConstants.hideInactiveListingDays));
    return !at.isBefore(cutoff);
  }

  /// Returns true when this nanny must be excluded from family browse/search.
  static bool shouldHideFromListing(
    NannyModel n, {
    required bool hideInactiveEnabled,
    DateTime? now,
  }) {
    if (!hideInactiveEnabled) return false;
    return !isActiveForListing(n, now: now);
  }
}
