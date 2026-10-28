import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:kafi_app/utils/nanny_listing_activity.dart';

/// Family browse visibility. Match % only orders the list; a profile leaves it
/// only for the reasons below. Approved + verified is enforced by the query.
void main() {
  bool listed(Map<String, dynamic> r) => NannyListingActivity.isListableRecord(r);

  group('always listed', () {
    test('an ordinary approved nanny', () {
      expect(listed({'status': 'approved'}), isTrue);
    });

    test('a nanny on a live trial (hiddenFromBrowse) stays listed', () {
      expect(listed({'hiddenFromBrowse': true}), isTrue);
    });

    test('a hired nanny who has not changed her availability stays listed', () {
      expect(
        listed({
          'hiddenFromBrowse': true,
          'availability': 'availableNow',
          'hireAvailabilityKey': 'availableNow|',
        }),
        isTrue,
      );
    });
  });

  group('hidden', () {
    test('a blocked nanny', () {
      expect(listed({'blocked': true}), isFalse);
      expect(listed({'blocked': true, 'hiddenFromBrowse': true}), isFalse);
    });

    test('a nanny who paused her own profile, even when hired or on trial', () {
      expect(listed({'profilePaused': true}), isFalse);
      expect(listed({'profilePaused': true, 'hiddenFromBrowse': true}), isFalse);
    });

    test('a hired nanny who changed her availability since the hire', () {
      expect(
        listed({
          'availability': 'availableFrom',
          'availableFrom': '2026-12-01T00:00:00.000',
          'hireAvailabilityKey': 'availableNow|',
        }),
        isFalse,
      );
    });

    test('...and she is visible again once the hire ends (snapshot cleared)', () {
      expect(
        listed({'availability': 'availableFrom', 'availableFrom': '2026-12-01'}),
        isTrue,
      );
    });

    test('un-pausing makes her visible again', () {
      expect(listed({'profilePaused': false}), isTrue);
    });
  });

  // Shared table: the same cases are asserted in functions/test/nanny_visibility.test.js
  // so the app and the Cloud Function always compute the same fingerprint.
  group('availabilityKey (must match the Cloud Function)', () {
    final cases = <(Map<String, dynamic>, String)>[
      ({}, 'availableNow|'),
      ({'availability': 'availableNow'}, 'availableNow|'),
      ({'availability': 'onTrial'}, 'onTrial|'),
      // A stale date is ignored unless the status is availableFrom.
      ({'availability': 'availableNow', 'availableFrom': '2026-01-01'}, 'availableNow|'),
      ({'availability': 'availableFrom', 'availableFrom': '2026-12-01T00:00:00.000'},
          'availableFrom|2026-12-01'),
      ({'availability': 'availableFrom', 'availableFrom': '2026-12-01T23:59:59.000Z'},
          'availableFrom|2026-12-01'),
      ({'availability': 'availableFrom'}, 'availableFrom|'),
    ];
    for (final (record, expected) in cases) {
      test('$record -> $expected', () {
        expect(NannyListingActivity.availabilityKey(record), expected);
      });
    }

    test('a Firestore Timestamp is read as its UTC calendar date', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 12, 1, 8));
      expect(
        NannyListingActivity.availabilityKey(
            {'availability': 'availableFrom', 'availableFrom': ts}),
        'availableFrom|2026-12-01',
      );
    });
  });
}
