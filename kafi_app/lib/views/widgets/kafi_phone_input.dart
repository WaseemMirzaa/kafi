import 'package:flutter/material.dart';
import 'package:kafi_app/utils/kafi_text_context_menu.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class KafiPhoneInput extends StatelessWidget {
  const KafiPhoneInput({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    this.purple = false,
    this.countryOptions = const ['🇦🇪 +971', '🇵🇭 +63', '🇮🇳 +91'],
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryChanged;
  final bool purple;
  final List<String> countryOptions;

  @override
  Widget build(BuildContext context) {
    final borderColor = purple ? KafiColors.purB : KafiColors.cardBorder;
    final bg = purple ? KafiColors.inputBgP : KafiColors.inputBg;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: countryOptions.firstWhere(
                (o) => o.contains(countryCode),
                orElse: () => countryOptions.first,
              ),
              isDense: true,
              style: KafiTheme.nunito(11, color: KafiColors.td),
              items: countryOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 11))))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                final code = RegExp(r'\+\d+').stringMatch(v) ?? countryCode;
                onCountryChanged(code);
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            contextMenuBuilder: kafiEditableTextContextMenu,
            style: KafiTheme.nunito(11, color: KafiColors.td),
            decoration: InputDecoration(
              hintText: '50 123 4567',
              filled: true,
              fillColor: bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor, width: 1.5),
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
        ),
      ],
    );
  }
}
