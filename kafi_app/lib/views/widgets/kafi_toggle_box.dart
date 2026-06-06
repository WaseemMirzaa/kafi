import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

enum KafiToggleVariant { rose, purple }

/// HTML `.tbox` `.tb-r` / `.tb-p`
class KafiToggleBox extends StatelessWidget {
  const KafiToggleBox({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.variant = KafiToggleVariant.rose,
  });

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final KafiToggleVariant variant;

  @override
  Widget build(BuildContext context) {
    final isRose = variant == KafiToggleVariant.rose;
    final bg = selected
        ? (isRose ? KafiColors.rosePale : KafiColors.purpleLight)
        : (isRose ? const Color(0xFFFFF7FA) : const Color(0xFFFAF5FF));
    final border = selected
        ? (isRose ? KafiColors.roseDark : KafiColors.purple)
        : (isRose ? KafiColors.cardBorder : const Color(0xFFE0C8F0));
    final labelColor = selected
        ? (isRose ? KafiColors.roseDark : KafiColors.purple)
        : KafiColors.textMid;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
