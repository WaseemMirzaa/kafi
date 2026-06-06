import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiTextField extends StatelessWidget {
  const KafiTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.purple = false,
    this.onChanged,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final bool purple;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final border = purple ? KafiColors.purB : KafiColors.cardBorder;
    final bg = purple ? KafiColors.inputBgP : KafiColors.inputBg;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KafiTheme.nunito(9, color: KafiColors.tm, w: FontWeight.w800)),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: KafiTheme.nunito(11, color: KafiColors.td),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: border, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: purple ? KafiColors.pur : KafiColors.roseD,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
