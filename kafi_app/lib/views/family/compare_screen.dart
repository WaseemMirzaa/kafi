import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShortlistController>();
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      appBar: KafiAppBar(title: AppStrings.shortlistCompare.tr),
      body: Obx(() {
              final items = controller.shortlistedNannies.take(2).toList();
              if (items.length < 2) {
                return Center(
                  child: Text(
                    AppStrings.shortlistEmptySub.tr,
                    style: KafiTheme.nunito(12, color: KafiColors.tm),
                  ),
                );
              }
              // Real cards from the shortlist controller (loaded from Firestore),
              // not seed data.
              final a = controller.cardFor(items[0]);
              final b = controller.cardFor(items[1]);
              return ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  _compareRow(a, b),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => AppNavigation.openNannyProfile(a),
                          child: Text(a.name, style: KafiTheme.fredoka(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => AppNavigation.openNannyProfile(b),
                          child: Text(b.name, style: KafiTheme.fredoka(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
    );
  }

  Widget _compareRow(NannyCardModel a, NannyCardModel b) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.cardBorder),
      ),
      child: Column(
        children: [
          _row('Match', '${a.matchPercent}%', '${b.matchPercent}%'),
          _row('Type', a.jobType, b.jobType),
          _row('Exp', '${a.yearsExp}y', '${b.yearsExp}y'),
          _row('City', a.city, b.city),
        ],
      ),
    );
  }

  Widget _row(String label, String va, String vb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(va, style: KafiTheme.nunito(10))),
          SizedBox(
            width: 60,
            child: Text(label,
                textAlign: TextAlign.center,
                style: KafiTheme.fredoka(9, color: KafiColors.tm)),
          ),
          Expanded(
            child: Text(vb,
                textAlign: TextAlign.right, style: KafiTheme.nunito(10)),
          ),
        ],
      ),
    );
  }
}
