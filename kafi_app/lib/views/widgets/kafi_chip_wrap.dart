import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiChip extends StatelessWidget {
  const KafiChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.purple = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool purple;

  @override
  Widget build(BuildContext context) {
    final colorOn = purple ? KafiColors.pur : KafiColors.roseD;
    final bgOff = purple ? KafiColors.inputBgP : KafiColors.inputBg;
    final bgOn = purple ? KafiColors.purL : KafiColors.roseP;
    final borderOff = purple ? KafiColors.purB : KafiColors.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? bgOn : bgOff,
          border: Border.all(color: selected ? colorOn : borderOff, width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: KafiTheme.fredoka(
            10,
            color: selected ? colorOn : (purple ? const Color(0xFF7A50B0) : KafiColors.tm),
          ),
        ),
      ),
    );
  }
}

class KafiToggleTile extends StatelessWidget {
  const KafiToggleTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.purple = false,
    this.subtitle,
    this.compact = false,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool purple;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorOn = purple ? KafiColors.pur : KafiColors.roseD;
    final bgOn = purple ? KafiColors.purL : KafiColors.roseP;
    final bgOff = purple ? KafiColors.inputBgP : KafiColors.inputBg;
    final borderOff = purple ? KafiColors.purB : KafiColors.cardBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 7 : 9),
        decoration: BoxDecoration(
          color: selected ? bgOn : bgOff,
          border: Border.all(color: selected ? colorOn : borderOff, width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colorOn : Colors.transparent,
                border: Border.all(
                  color: selected ? colorOn : KafiColors.roseL,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 8)
                  : null,
            ),
            const SizedBox(width: 8),
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? colorOn : KafiColors.tm),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: KafiTheme.nunito(
                      10.5,
                      color: selected ? colorOn : KafiColors.td,
                      w: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: KafiTheme.nunito(8.5, color: KafiColors.ts),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
