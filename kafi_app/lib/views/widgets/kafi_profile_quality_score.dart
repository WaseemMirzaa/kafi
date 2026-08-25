import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiProfileQualityScore extends StatelessWidget {
  const KafiProfileQualityScore({
    super.key,
    required this.score,
    this.onImprove,
  });

  final int score;
  final VoidCallback? onImprove;

  Color get _color {
    if (score >= 80) return KafiColors.grnD;
    if (score >= 60) return KafiColors.grnL;
    if (score >= 40) return Colors.orange;
    return KafiColors.redD;
  }

  String get _label {
    if (score >= 80) return AppStrings.qualityExcellent.tr;
    if (score >= 60) return AppStrings.qualityGood.tr;
    if (score >= 40) return AppStrings.qualityFair.tr;
    return AppStrings.qualityNeedsWork.tr;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: KafiColors.rose.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: KafiColors.roseP,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
                Text('$score%', style: KafiTheme.fredoka(14, color: _color)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.qualityProfileStrength.tr,
                    style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_label, style: KafiTheme.fredoka(14, color: _color)),
                if (score < 80) ...[
                  const SizedBox(height: 6),
                  _tips(),
                ],
              ],
            ),
          ),
          if (onImprove != null && score < 100)
            IconButton(
              onPressed: onImprove,
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: KafiColors.roseD),
            ),
        ],
      ),
    );
  }

  Widget _tips() {
    final tips = <String>[];
    if (score < 40) tips.add(AppStrings.qualityTipPhoto.tr);
    if (score < 60) tips.add(AppStrings.qualityTipVideo.tr);
    if (score < 80) tips.add(AppStrings.qualityTipReferences.tr);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips.take(2).map((t) => Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 12, color: KafiColors.ts),
          const SizedBox(width: 4),
          Text(t, style: KafiTheme.nunito(10, color: KafiColors.ts)),
        ],
      )).toList(),
    );
  }
}
