import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Matches the web `.fhdr` form header: light gradient, dark title, rose
/// progress bar + step dots.
class KafiFormHeader extends StatelessWidget {
  const KafiFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.step,
    this.totalSteps = NannyConstants.totalSteps,
    this.gradient = const [Color(0xFFFFE0EC), Color(0xFFFFCCE0)],
    this.accent = KafiColors.roseD,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final int step;
  final int totalSteps;
  final List<Color> gradient;
  final Color accent;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (step / totalSteps).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack ?? Get.back,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: Icon(Icons.arrow_back, size: 14, color: accent),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w900)),
                    const SizedBox(height: 1),
                    Text(subtitle, style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar (white track + rose gradient fill).
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 4, color: Colors.white.withValues(alpha: 0.55)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [KafiColors.rose, KafiColors.roseD]),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            AppStrings.stepXofY.trParams({'x': '$step', 'y': '$totalSteps'}),
            textAlign: TextAlign.right,
            style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (i) {
              final on = i < step;
              return Container(
                width: on ? 14 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: on ? accent : KafiColors.roseL.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
