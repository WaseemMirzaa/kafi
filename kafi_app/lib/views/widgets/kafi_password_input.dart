import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// HTML `.pw-wrap` + `.pw-inp` + `.pw-eye`
class KafiPasswordInput extends StatefulWidget {
  const KafiPasswordInput({
    super.key,
    this.label,
    required this.controller,
    this.hint,
    this.onChanged,
    this.variant = KafiPasswordVariant.rose,
  });

  final String? label;
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final KafiPasswordVariant variant;

  @override
  State<KafiPasswordInput> createState() => _KafiPasswordInputState();
}

enum KafiPasswordVariant { rose, purple }

class _KafiPasswordInputState extends State<KafiPasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isPurple = widget.variant == KafiPasswordVariant.purple;
    final bg = isPurple ? const Color(0xFFFAF5FF) : const Color(0xFFFFF7FA);
    final border = isPurple ? const Color(0xFFE0C8F0) : const Color(0xFFFFD8E8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.nunito(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: KafiColors.textMid,
            ),
          ),
          const SizedBox(height: 5),
        ],
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: widget.controller,
              obscureText: _obscure,
              onChanged: widget.onChanged,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KafiColors.textDark,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: KafiColors.textSoft,
                  letterSpacing: 0,
                ),
                filled: true,
                fillColor: bg,
                contentPadding: const EdgeInsets.fromLTRB(12, 11, 40, 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(color: border, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: KafiColors.roseDark, width: 2),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 14,
                color: KafiColors.textSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
