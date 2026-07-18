import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Shared profile pieces used by both the locked and unlocked nanny-profile
/// screens, matching the web `.srow`/`.sbox`, `.sk-wrap`/`.sk`, and the
/// trial-active banner.
class ProfileSections {
  const ProfileSections._();

  // ── Stats row (Years exp · Rating · Reviews) ──────────────────────────────
  static Widget statsRow(NannyCardModel card) {
    final hasReviews = card.reviewsCount > 0 && card.averageRating != null;
    return Row(
      children: [
        Expanded(child: _statBox('${card.yearsExp}', AppStrings.yearsExp.tr)),
        const SizedBox(width: 6),
        Expanded(
            child: _statBox(hasReviews ? '${card.averageRating!.toStringAsFixed(1)}★' : '—',
                AppStrings.rating.tr)),
        const SizedBox(width: 6),
        Expanded(child: _statBox('${card.reviewsCount}', AppStrings.reviews.tr)),
      ],
    );
  }

  static Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: KafiColors.purL,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: KafiTheme.nunito(14, color: KafiColors.pur, w: FontWeight.w900)),
          const SizedBox(height: 1),
          Text(label,
              textAlign: TextAlign.center,
              style: KafiTheme.nunito(8, color: KafiColors.ts, w: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Skills & specialties ──────────────────────────────────────────────────
  static Widget skills(NannyCardModel card) {
    final chips = <Widget>[];
    if (card.verified) {
      chips.add(_skill('✓ Verified ID', green: true));
    }
    for (final t in card.tags) {
      final isGreen = t.trimLeft().startsWith('✓');
      chips.add(_skill(t, green: isGreen));
    }
    return Wrap(spacing: 4, runSpacing: 4, children: chips);
  }

  static Widget _skill(String label, {bool green = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: green ? KafiColors.grnL : KafiColors.purL,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: KafiTheme.fredoka(9, color: green ? KafiColors.grnD : KafiColors.pur, w: FontWeight.w700)),
    );
  }

  // ── Trial-active banner (shown when contacts are unlocked via a trial) ─────
  static Widget trialBypassBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.grnL, Color(0xFFE8F8EE)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.grnD.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_open, color: KafiColors.grnD, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trial active — full access',
                    style: KafiTheme.nunito(11, color: KafiColors.grnD, w: FontWeight.w900)),
                Text('Contacts unlocked for the duration of your trial.',
                    style: KafiTheme.nunito(9.5, color: KafiColors.grnD, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
