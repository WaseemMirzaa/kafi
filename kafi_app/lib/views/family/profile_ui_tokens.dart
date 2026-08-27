import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Shared layout tokens for nanny profile screens (reference design).
abstract class ProfileUi {
  static const hPad = 16.0;
  static const sectionGap = 16.0;
  static const cardRadius = 14.0;
  static const tileRadius = 12.0;
  static const actionRadius = 12.0;
  static const pillRadius = 24.0;
  static const tileBorder = Color(0xFFEDE8EC);
  static const actionBorder = Color(0xFFE6DCE3);

  static TextStyle sectionHeading = KafiTheme.fredoka(13, color: KafiColors.navy, w: FontWeight.w800);
  static TextStyle tileBody = KafiTheme.nunito(10.5, color: KafiColors.td, w: FontWeight.w700);
  static TextStyle tileValue = KafiTheme.nunito(10, color: KafiColors.grnD, w: FontWeight.w800);
  static TextStyle tileValueNegative = KafiTheme.nunito(10, color: KafiColors.tm, w: FontWeight.w800);
  static TextStyle actionLabel = KafiTheme.fredoka(9, color: KafiColors.roseD, w: FontWeight.w700);

  static Widget iconBadge(IconData icon) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: KafiColors.roseP,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: KafiColors.roseD, size: 17),
    );
  }

  static BoxDecoration whiteCard({double radius = tileRadius}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tileBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      );
}

/// Pink → purple arc for the Kafi Match ring.
class ProfileMatchRing extends StatelessWidget {
  const ProfileMatchRing({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: CustomPaint(
        painter: _MatchRingPainter(percent / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percent%',
                  style: KafiTheme.fredoka(13, color: KafiColors.roseD, w: FontWeight.w800)),
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
    final radius = size.width / 2 - 4;
    const stroke = 5.0;
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
