import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

enum KafiChipVariant { rose, purple }

/// HTML `.chip` `.cr` / `.cp` with `.on`
class KafiChip extends StatelessWidget {
  const KafiChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.variant = KafiChipVariant.rose,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final KafiChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final isRose = variant == KafiChipVariant.rose;
    final bg = selected
        ? (isRose ? KafiColors.rosePale : KafiColors.purpleLight)
        : (isRose ? const Color(0xFFFFF7FA) : const Color(0xFFFAF5FF));
    final border = selected
        ? (isRose ? KafiColors.roseDark : KafiColors.purple)
        : (isRose ? KafiColors.cardBorder : const Color(0xFFE0C8F0));
    final textColor = selected
        ? (isRose ? KafiColors.roseDark : KafiColors.purple)
        : (isRose ? KafiColors.textMid : const Color(0xFF7A50B0));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
