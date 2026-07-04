import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

enum KafiButtonVariant { rose, purple, green, dark, red }

class KafiPrimaryButton extends StatelessWidget {
  const KafiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KafiButtonVariant.rose,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KafiButtonVariant variant;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final (colors, shadow) = switch (variant) {
      KafiButtonVariant.rose => (
          [KafiColors.rose, KafiColors.roseD],
          const Color(0x66FF5C8A)
        ),
      KafiButtonVariant.purple => (
          [KafiColors.pur, const Color(0xFFC084FC)],
          const Color(0x669B6EDB)
        ),
      KafiButtonVariant.green => (
          [KafiColors.grn, KafiColors.grnD],
          const Color(0x403DAA65)
        ),
      KafiButtonVariant.dark => (
          [KafiColors.td, KafiColors.tm],
          const Color(0x403D1A26)
        ),
      KafiButtonVariant.red => (
          [const Color(0xFFEF5350), KafiColors.redD],
          const Color(0x66E53935)
        ),
    };

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: shadow, blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 7)),
                BoxShadow(color: shadow.withValues(alpha: shadow.a * 0.45), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: KafiTheme.fredoka(13, color: Colors.white)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
