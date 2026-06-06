import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

enum KafiSectionIconVariant { rose, purple, green }

/// HTML `.fsec-hd` + `.fsec-ic`
class KafiSectionHeader extends StatelessWidget {
  const KafiSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.variant = KafiSectionIconVariant.rose,
  });

  final String title;
  final IconData? icon;
  final KafiSectionIconVariant variant;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (variant) {
      KafiSectionIconVariant.rose => [KafiColors.rose, KafiColors.roseDark],
      KafiSectionIconVariant.purple => [KafiColors.purple, const Color(0xFFC084FC)],
      KafiSectionIconVariant.green => [KafiColors.green, KafiColors.greenDark],
    };

    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFFFE8F0), width: 1.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
            child: Icon(icon ?? Icons.person_outline, size: 9, color: Colors.white),
          ),
          const SizedBox(width: 5),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: KafiColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
