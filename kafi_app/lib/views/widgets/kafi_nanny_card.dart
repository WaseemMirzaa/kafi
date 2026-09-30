import 'package:flutter/material.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:get/get.dart';
import 'package:kafi_app/utils/job_type_label.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_avatar.dart';

class KafiNannyCard extends StatelessWidget {
  const KafiNannyCard({super.key, required this.card, required this.onTap, this.jobLabel});

  final NannyCardModel card;
  final VoidCallback onTap;

  /// Optional posted-job title this nanny is matched against.
  final String? jobLabel;

  // Avatar gradient palette (matches the .av1–.av4 cycle in the web design).
  static const List<List<Color>> _avatarGradients = [
    [Color(0xFFFF8FAB), Color(0xFFFF5C8A)], // pink
    [Color(0xFFFFB347), Color(0xFFFF8042)], // orange
    [Color(0xFF6DBF8A), Color(0xFF3DAA65)], // green
    [Color(0xFF9B6EDB), Color(0xFFC084FC)], // purple
  ];

  @override
  Widget build(BuildContext context) {
    final good = card.matchPercent >= 80;
    final matchColor = good ? const Color(0xFF2A8A50) : const Color(0xFFC07A10);
    final matchBg = good ? const Color(0xFFE8F8EE) : KafiColors.ambL;
    final gradient = _avatarGradients[
        card.initials.isEmpty ? 0 : card.initials.codeUnitAt(0) % _avatarGradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: card.featured
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFFF5F8)],
                )
              : null,
          color: card.featured ? null : Colors.white,
          border: Border.all(
              color: card.featured ? KafiColors.roseL : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x14FF5F96), blurRadius: 9, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KafiAvatar(
              photoUrl: card.photoUrls.isNotEmpty ? card.photoUrls.first : null,
              fallbackText: card.initials.isNotEmpty ? card.initials : card.name,
              size: 57,
              gradient: gradient,
              fontSize: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(card.name,
                            style: KafiTheme.nunito(14.5, color: KafiColors.td, w: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (card.verified) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: KafiColors.grnL,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(AppStrings.verifiedBadge.tr,
                              style: KafiTheme.fredoka(10, color: KafiColors.grnD, w: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${card.nationality} · ${AppStrings.yearsAbbrevN.trParams({'n': '${card.yearsExp}'})} · ${localizeJobTypeLabel(card.jobType)} · ${card.city}${card.availableNow ? ' · ${AppStrings.availableNow.tr}' : ''}',
                    style: KafiTheme.nunito(11.5, color: KafiColors.ts, w: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Only show a match chip when the card was scored against a
                      // real job (matchPercent > 0); browsing with no job posted
                      // leaves it 0 → no fake percentage.
                      if (card.matchPercent > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: matchBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${good ? '⭐ ' : ''}${card.matchPercent}${AppStrings.matchSuffix.tr}',
                            style: KafiTheme.fredoka(11.5, color: matchColor, w: FontWeight.w700),
                          ),
                        ),
                      if (jobLabel != null && jobLabel!.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 195),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: KafiColors.purL,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text('🏡 $jobLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KafiTheme.fredoka(11, color: KafiColors.pur, w: FontWeight.w700)),
                        ),
                    ],
                  ),
                  if (card.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: card.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: KafiColors.roseP,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(t,
                                  style: KafiTheme.fredoka(11.5, color: KafiColors.roseD, w: FontWeight.w700)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
