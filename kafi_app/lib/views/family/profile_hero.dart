import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/report_user_sheet.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.card});

  final NannyCardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEE0FF), Color(0xFFF0D8FF)],
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Back + favourite buttons
          Positioned(
            top: 11,
            left: 13,
            child: _circleBtn(Icons.arrow_back, Get.back),
          ),
          Positioned(
            top: 11,
            right: 12,
            child: _circleBtn(Icons.favorite, () => AppNavigation.toggleShortlist(card),
                filled: true),
          ),
          // Report this nanny — files a support ticket to the admin team.
          Positioned(
            top: 11,
            right: 45,
            child: _circleBtn(
              Icons.flag_outlined,
              () => showReportUserSheet(reportedUserId: card.id, reportedUserName: card.name),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 34, 15, 13),
            child: Column(
              children: [
                // Avatar 68 rounded-square + verified badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF9B6EDB), Color(0xFFC084FC)],
                        ),
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF9B6EDB).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Center(
                        child: Text(card.initials,
                            style: KafiTheme.fredoka(24, color: Colors.white, w: FontWeight.w900)),
                      ),
                    ),
                    if (card.verified)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: KafiColors.grn,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(card.name,
                    style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w900)),
                const SizedBox(height: 1),
                Text('${card.jobType} · ${card.city} · ${card.nationality}',
                    style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
                // Shown only when the nanny was scored against the family's job
                // (matchPercent > 0); otherwise there's no "your job" to match.
                if (card.matchPercent > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9B6EDB), Color(0xFFC084FC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 11),
                        const SizedBox(width: 4),
                        Text('${card.matchPercent}% match with your job',
                            style: KafiTheme.fredoka(11.5, color: Colors.white, w: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: KafiColors.pur, size: 13),
      ),
    );
  }
}
