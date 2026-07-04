import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiBottomNavItem {
  const KafiBottomNavItem({
    this.icon,
    this.emoji,
    required this.label,
    required this.onTap,
  }) : assert(icon != null || emoji != null, 'Provide an icon or an emoji');

  /// Material icon (used when [emoji] is null).
  final IconData? icon;

  /// Emoji glyph; takes precedence over [icon] when provided.
  final String? emoji;
  final String label;
  final VoidCallback onTap;
}

class KafiBottomNav extends StatelessWidget {
  const KafiBottomNav({
    super.key,
    required this.items,
    required this.activeIndex,
  });

  final List<KafiBottomNavItem> items;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFFFE8EF), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == activeIndex;
              final color = active ? KafiColors.roseD : KafiColors.ts;
              return Expanded(
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: active
                        ? BoxDecoration(
                            color: KafiColors.roseP,
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.emoji != null)
                          Opacity(
                            opacity: active ? 1 : 0.55,
                            child: Text(item.emoji!, style: const TextStyle(fontSize: 19)),
                          )
                        else
                          Icon(item.icon, color: color, size: 22),
                        const SizedBox(height: 2),
                        Text(item.label, style: KafiTheme.fredoka(9, color: color)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
