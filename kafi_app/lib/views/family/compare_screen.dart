import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/data/mock/mock_nannies.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _cardsById = <String, NannyCardModel>{};
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final all = await Get.find<IJobService>().browseNannies();
      for (final c in all) {
        _cardsById[c.id] = c;
      }
    } catch (_) {
      for (final c in mockNannyCards) {
        _cardsById[c.id] = c;
      }
    }
    if (mounted) setState(() => _loaded = true);
  }

  NannyCardModel _card(String nannyId) =>
      _cardsById[nannyId] ??
      mockNannyCards.firstWhereOrNull((c) => c.id == nannyId) ??
      mockNannyCards.first;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShortlistController>();
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      appBar: KafiAppBar(title: AppStrings.shortlistCompare.tr),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator(color: KafiColors.roseD))
          : Obx(() {
              final items = controller.shortlistedNannies.take(2).toList();
              if (items.length < 2) {
                return Center(
                  child: Text(
                    AppStrings.shortlistEmptySub.tr,
                    style: KafiTheme.nunito(12, color: KafiColors.tm),
                  ),
                );
              }
              final a = _card(items[0].nannyId);
              final b = _card(items[1].nannyId);
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
