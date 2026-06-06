import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// HTML `.sbar` — gradient strip with time and signal (no fake phone bezel).
class KafiStatusBar extends StatelessWidget {
  const KafiStatusBar({
    super.key,
    this.gradientColors = const [Color(0xFFFFE4EF), Color(0xFFFFF4EE)],
    this.textColor,
  });

  final List<Color> gradientColors;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? KafiColors.textMid;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 9,
        left: 18,
        right: 18,
        bottom: 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            '●●● 100%',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
