import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Shared layout tokens for nanny profile screens (Maria Santos reference).
abstract class ProfileUi {
  static const hPad = 16.0;
  static const sectionGap = 14.0;
  static const cardRadius = 14.0;
  static const tileRadius = 12.0;
  static const actionRadius = 10.0;
  static const pillRadius = 24.0;
  static const roseBorder = Color(0xFFFFD8E8);
  static const tileBorder = roseBorder;
  static const actionBorder = Color(0xFFFFC8DC);
  static const galleryThumbSize = 72.0;
  static const experienceTileHeight = 94.0;
  static const experienceTileRadius = 14.0;
  static const experienceBorder = Color(0xFFEAE6EC);
  static const actionHeight = 40.0;
  static const gridIconSize = 26.0;
  static const matchRingSize = 64.0;

  static TextStyle sectionHeading =
      KafiTheme.fredoka(14, color: KafiColors.navy, w: FontWeight.w800);
  static TextStyle tileBody =
      KafiTheme.nunito(9.5, color: KafiColors.td, w: FontWeight.w700).copyWith(height: 1.3);
  static TextStyle tileSub =
      KafiTheme.nunito(9, color: KafiColors.td, w: FontWeight.w600).copyWith(height: 1.25);
  static TextStyle tileLabel =
      KafiTheme.nunito(9, color: KafiColors.td, w: FontWeight.w700);
  static TextStyle listRowTitle =
      KafiTheme.nunito(11, color: KafiColors.navy, w: FontWeight.w800);
  static TextStyle listRowValue =
      KafiTheme.nunito(10.5, color: KafiColors.grnD, w: FontWeight.w700).copyWith(height: 1.35);
  static TextStyle listRowValueMuted =
      KafiTheme.nunito(10.5, color: KafiColors.tm, w: FontWeight.w700).copyWith(height: 1.35);
  static TextStyle tileValue =
      KafiTheme.nunito(9.5, color: KafiColors.grnD, w: FontWeight.w800);
  static TextStyle tileValueNegative =
      KafiTheme.nunito(9.5, color: KafiColors.tm, w: FontWeight.w800);
  static TextStyle actionLabel =
      KafiTheme.fredoka(10, color: KafiColors.roseD, w: FontWeight.w700);

  static Widget experienceIcon(IconData icon) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: KafiColors.roseP,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: KafiColors.roseD, size: 15),
    );
  }

  static BoxDecoration experienceCard() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(experienceTileRadius),
        border: Border.all(color: experienceBorder, width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      );

  static BoxDecoration whiteCard({double radius = tileRadius}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tileBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      );

  static BoxDecoration actionButton({bool highlighted = false}) => BoxDecoration(
        color: highlighted ? KafiColors.roseP : Colors.white,
        borderRadius: BorderRadius.circular(actionRadius),
        border: Border.all(
          color: highlighted ? KafiColors.rose.withValues(alpha: 0.55) : roseBorder,
          width: highlighted ? 1.5 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      );
}

/// Pink → purple arc for the Kafi Match ring.
class ProfileMatchRing extends StatelessWidget {
  const ProfileMatchRing({
    super.key,
    required this.percent,
    this.matchLabel,
  });

  final int percent;
  final String? matchLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProfileUi.matchRingSize,
      height: ProfileUi.matchRingSize,
      child: CustomPaint(
        painter: _MatchRingPainter(percent / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (matchLabel != null)
                Text(matchLabel!,
                    style: KafiTheme.nunito(7, color: KafiColors.ts, w: FontWeight.w700)),
              Text('$percent%',
                  style: KafiTheme.fredoka(14, color: KafiColors.roseD, w: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRingPainter extends CustomPainter {
  _MatchRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    const stroke = 4.5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = KafiColors.roseP
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -1.5708,
      colors: const [KafiColors.rose, KafiColors.pur],
    );
    canvas.drawArc(
      rect,
      -1.5708,
      progress * 6.28318,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MatchRingPainter old) => old.progress != progress;
}
