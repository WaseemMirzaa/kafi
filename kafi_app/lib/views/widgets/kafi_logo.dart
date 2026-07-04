import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiLogo extends StatelessWidget {
  const KafiLogo({super.key, this.size = 24, this.purple = false});

  final double size;
  final bool purple;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _FlowerPainter(purple: purple),
        ),
        const SizedBox(width: 6),
        Text(
          AppStrings.appName.tr,
          style: KafiTheme.pacifico(17),
        ),
      ],
    );
  }
}

class _FlowerPainter extends CustomPainter {
  _FlowerPainter({this.purple = false});
  final bool purple;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final petalColor = purple ? const Color(0xFFC8A8F0) : KafiColors.roseL;
    final centerColor = purple ? KafiColors.pur : KafiColors.rose;
    final petal = Paint()..color = petalColor.withValues(alpha: 0.85);
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 1.047);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, -size.height * 0.2), width: size.width * 0.35, height: size.height * 0.55),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(c, size.width * 0.2, Paint()..color = Colors.white);
    canvas.drawCircle(c, size.width * 0.13, Paint()..color = centerColor);
    canvas.drawCircle(c, size.width * 0.06, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
