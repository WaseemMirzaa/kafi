import 'package:flutter_test/flutter_test.dart';
import 'package:kafi_app/models/nanny_map_codec.dart';
import 'package:kafi_app/models/nanny_model.dart';

/// Covers the data contract behind the rejected-nanny flow (#11 / Spec §6.1):
/// the admin writes profile-level rejection feedback, the app must read it,
/// must NOT write it back (admin-owned), and must preserve it across copyWith.
void main() {
  group('nannyModelFromMap — admin rejection fields', () {
    test('parses profile rejection + intro-video verdict', () {
      final n = nannyModelFromMap('n1', {
        'status': 'rejected',
        'rejectionReason': 'Passport photo is blurry — please re-upload.',
        'rejectedAt': '2026-06-20T10:00:00.000Z',
        'introVideoStatus': 'rejected',
        'introVideoRejectionReason': 'Re-record in better lighting.',
        'introVideoUrl': 'https://example.com/v.mp4',
      });

      expect(n.status, NannyOnboardingStatus.rejected);
      expect(n.rejectionReason, 'Passport photo is blurry — please re-upload.');
      expect(n.rejectedAt, DateTime.utc(2026, 6, 20, 10));
      expect(n.introVideoStatus, IntroVideoStatus.rejected);
      expect(n.introVideoRejectionReason, 'Re-record in better lighting.');
    });

    test('defaults are null/draft when the fields are absent', () {
      final n = nannyModelFromMap('n2', {'fullName': 'Maria'});
      expect(n.status, NannyOnboardingStatus.draft);
      expect(n.rejectionReason, isNull);
      expect(n.rejectedAt, isNull);
      expect(n.introVideoStatus, isNull);
      expect(n.introVideoRejectionReason, isNull);
    });

    test('parses an approved intro video verdict', () {
      final n = nannyModelFromMap('n3', {'introVideoStatus': 'approved'});
      expect(n.introVideoStatus, IntroVideoStatus.approved);
    });
  });

  group('NannyModel — admin fields are read-only', () {
    test('toMap never serializes admin-owned review feedback', () {
      final n = NannyModel(
        id: 'n1',
        userId: 'n1',
        status: NannyOnboardingStatus.rejected,
        rejectionReason: 'blurry',
        rejectedAt: DateTime(2026, 6, 20),
        introVideoStatus: IntroVideoStatus.rejected,
        introVideoRejectionReason: 'too dark',
      );
      final map = n.toMap();
      // A profile save must not be able to overwrite the admin's decision.
      expect(map.containsKey('rejectionReason'), isFalse);
      expect(map.containsKey('rejectedAt'), isFalse);
      expect(map.containsKey('introVideoStatus'), isFalse);
      expect(map.containsKey('introVideoRejectionReason'), isFalse);
      // ...but status itself round-trips so the app can flip draft→pending.
      expect(map['status'], 'rejected');
    });

    test('copyWith preserves admin review fields', () {
      final n = NannyModel(
        id: 'n1',
        userId: 'n1',
        rejectionReason: 'blurry',
        introVideoStatus: IntroVideoStatus.approved,
      );
      final edited = n.copyWith(fullName: 'Maria', status: NannyOnboardingStatus.pending);
      expect(edited.fullName, 'Maria');
      expect(edited.status, NannyOnboardingStatus.pending);
      expect(edited.rejectionReason, 'blurry');
      expect(edited.introVideoStatus, IntroVideoStatus.approved);
    });
  });
}
