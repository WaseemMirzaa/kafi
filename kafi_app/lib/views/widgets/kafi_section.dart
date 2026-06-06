import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiSection extends StatelessWidget {
  const KafiSection({
    super.key,
    required this.title,
    required this.children,
    this.accent = KafiSectionAccent.rose,
    this.icon = Icons.person_outline,
  });

  final String title;
  final List<Widget> children;
  final KafiSectionAccent accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = switch (accent) {
      KafiSectionAccent.rose => const [KafiColors.rose, KafiColors.roseD],
      KafiSectionAccent.purple => const [KafiColors.pur, Color(0xFFC084FC)],
      KafiSectionAccent.green => const [KafiColors.grn, KafiColors.grnD],
      KafiSectionAccent.teal => const [KafiColors.teal, Color(0xFF2ABFBB)],
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(bottom: 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFE8F0), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(icon, color: Colors.white, size: 10),
                ),
                const SizedBox(width: 5),
                Text(
                  title.toUpperCase(),
                  style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800).copyWith(letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

enum KafiSectionAccent { rose, purple, green, teal }
