import 'package:flutter/material.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// A simple pill search box used on listing screens (applicants, shortlist,
/// my-applications). `onChanged`-only — no controller — so it drops into a
/// stateless GetView and writes straight to a controller's query Rx.
class KafiSearchField extends StatelessWidget {
  const KafiSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KafiColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: KafiColors.ts, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: KafiTheme.nunito(11, color: KafiColors.td),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
