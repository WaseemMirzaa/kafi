import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';

/// Shared rule for admin `settings/global.hideInactiveNannies`.
/// When the toggle is on, a nanny is hidden from family discovery unless her
/// `lastActiveAt` is within [NannyConstants.hideInactiveListingDays].
/// Missing `lastActiveAt` counts as inactive (cannot prove recent open).
class NannyListingActivity {
  NannyListingActivity._();

  /// Fingerprint of a nanny's availability setting. Must match
  /// `availabilityKey` in functions/src/utils/nannyBrowseVisibility.ts. The
  /// `availableFrom` date only counts when the status is availableFrom, and only
  /// its calendar date (UTC).
  static String availabilityKey(Map<String, dynamic> record) {
    final raw = record['availability'];
    final status = raw is String && raw.isNotEmpty ? raw : 'availableNow';
    if (status != 'availableFrom') return '$status|';
    final from = record['availableFrom'];
    var date = '';
    if (from is String) {
      date = from.length >= 10 ? from.substring(0, 10) : from;
    } else if (from is Timestamp) {
      date = from.toDate().toUtc().toIso8601String().substring(0, 10);
    }
    return '$status|$date';
  }

  /// Record-level visibility in family browse, decided before the profile is
  /// even parsed. Approved + verified is enforced by the query itself. Hidden
  /// here:
  ///  - a blocked nanny;
  ///  - a nanny who paused her own profile (`profilePaused`);
  ///  - a HIRED nanny who has changed her availability since she was hired
  ///    (the server snapshots it as `hireAvailabilityKey` for the length of the
  ///    hire; the snapshot is gone once the hire ends).
  ///
  /// A nanny on a live trial, and a hired nanny who hasn't touched her
  /// availability, stay listed — `hiddenFromBrowse` is deliberately NOT
  /// consulted. Match % only orders the list, it never removes anyone.
  static bool isListableRecord(Map<String, dynamic> record) {
    if (record['blocked'] == true) return false;
    if (record['profilePaused'] == true) return false;
    final hiredAs = record['hireAvailabilityKey'];
    if (hiredAs is String && hiredAs.isNotEmpty && hiredAs != availabilityKey(record)) {
      return false;
    }
    return true;
  }

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
