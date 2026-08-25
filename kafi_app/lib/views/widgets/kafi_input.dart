import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/utils/kafi_text_context_menu.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

enum KafiInputVariant { rose, purple }

/// HTML `.inp` / `.inp-p`
class KafiInput extends StatelessWidget {
  const KafiInput({
    super.key,
    this.label,
    required this.controller,
    this.hint,
    this.variant = KafiInputVariant.rose,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  final String? label;
  final TextEditingController controller;
  final String? hint;
  final KafiInputVariant variant;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isPurple = variant == KafiInputVariant.purple;
    final bg = isPurple ? const Color(0xFFFAF5FF) : const Color(0xFFFFF7FA);
    final border = isPurple ? const Color(0xFFE0C8F0) : KafiColors.cardBorder;
    final focusBorder = isPurple ? KafiColors.purple : KafiColors.roseDark;
    final labelColor = isPurple ? const Color(0xFF5A2090) : KafiColors.textMid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 3),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          contextMenuBuilder: kafiEditableTextContextMenu,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: KafiColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isPurple ? const Color(0xFFB090D0) : KafiColors.textSoft,
            ),
            filled: true,
            fillColor: bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: focusBorder, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
