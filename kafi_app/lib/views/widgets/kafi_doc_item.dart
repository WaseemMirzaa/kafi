import 'package:flutter/material.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:get/get.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

enum KafiDocVariant { rose, purple, green, amber }

class KafiDocItem extends StatelessWidget {
  const KafiDocItem({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.required,
    required this.status,
    required this.onTap,
    this.variant = KafiDocVariant.rose,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool required;
  final DocumentStatus status;
  final VoidCallback onTap;
  final KafiDocVariant variant;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusBg, statusFg) = switch (status) {
      DocumentStatus.uploaded || DocumentStatus.approved => (AppStrings.docUploaded.tr, KafiColors.grnL, KafiColors.grnD),
      DocumentStatus.reviewing => (AppStrings.docReviewing.tr, KafiColors.ambL, const Color(0xFFA06010)),
      DocumentStatus.missing => (required ? AppStrings.docMissing.tr : AppStrings.docOptional.tr, KafiColors.ambL, const Color(0xFFA06010)),
      DocumentStatus.rejected => (AppStrings.docRejected.tr, KafiColors.roseP, KafiColors.roseD),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: KafiColors.cardBorder, width: 1.5),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: switch (variant) {
                  KafiDocVariant.rose => KafiColors.roseP,
                  KafiDocVariant.purple => KafiColors.purL,
                  KafiDocVariant.green => KafiColors.grnL,
                  KafiDocVariant.amber => const Color(0xFFFFF4E0),
                },
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon,
                color: switch (variant) {
                  KafiDocVariant.rose => KafiColors.roseD,
                  KafiDocVariant.purple => KafiColors.pur,
                  KafiDocVariant.green => KafiColors.grnD,
                  KafiDocVariant.amber => const Color(0xFFA06010),
                },
                size: 18),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
                  Text(subtitle, style: KafiTheme.nunito(9, color: KafiColors.ts)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(statusLabel, style: KafiTheme.fredoka(9, color: statusFg)),
                ),
                // Optional, not-yet-uploaded docs show an explicit Upload button.
                if (!required && status == DocumentStatus.missing) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: variant == KafiDocVariant.green ? KafiColors.grnL : KafiColors.purL,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(AppStrings.docUploadBtn.tr,
                        style: KafiTheme.fredoka(8.5,
                            color: variant == KafiDocVariant.green ? KafiColors.grnD : KafiColors.pur,
                            w: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
