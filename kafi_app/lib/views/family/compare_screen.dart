import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_app_bar.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  // Which two shortlisted entries are being compared. A family with more than
  // two shortlisted nannies picks any pair (previously it was always the two
  // oldest, `take(2)`, so no other pair could be compared).
  int _aIndex = 0;
  int _bIndex = 1;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ShortlistController>();
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      appBar: KafiAppBar(title: AppStrings.shortlistCompare.tr),
      body: Obx(() {
        final items = controller.shortlistedNannies.toList();
        if (items.length < 2) {
          return Center(
            child: Text(
              AppStrings.shortlistEmptySub.tr,
              style: KafiTheme.nunito(12, color: KafiColors.tm),
            ),
          );
        }
        // Keep the selected indices valid as the shortlist changes underneath.
        final len = items.length;
        var aIdx = _aIndex >= len ? 0 : _aIndex;
        var bIdx = _bIndex >= len ? len - 1 : _bIndex;
        if (aIdx == bIdx) bIdx = (aIdx + 1) % len;

        final a = controller.cardFor(items[aIdx]);
        final b = controller.cardFor(items[bIdx]);
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            if (len > 2) ...[
              _pickerCard(items, controller, aIdx, bIdx, len),
              const SizedBox(height: 12),
            ],
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

  /// Two dropdowns (left/right) to choose which shortlisted nannies to compare.
  /// Picking a nanny already selected on the other side nudges that side to a
  /// different entry so the two columns are never the same person.
  Widget _pickerCard(
    List<ShortlistItem> items,
    ShortlistController controller,
    int aIdx,
    int bIdx,
    int len,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KafiColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _pick(items, controller, aIdx, (i) {
              setState(() {
                _aIndex = i;
                if (_bIndex == i) _bIndex = (i + 1) % len;
              });
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('vs',
                style: KafiTheme.fredoka(9, color: KafiColors.tm)),
          ),
          Expanded(
            child: _pick(items, controller, bIdx, (i) {
              setState(() {
                _bIndex = i;
                if (_aIndex == i) _aIndex = (i + 1) % len;
              });
            }),
          ),
        ],
      ),
    );
  }

  Widget _pick(
    List<ShortlistItem> items,
    ShortlistController controller,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return DropdownButton<int>(
      value: value,
      isExpanded: true,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        for (var i = 0; i < items.length; i++)
          DropdownMenuItem(
            value: i,
            child: Text(
              controller.cardFor(items[i]).name,
              overflow: TextOverflow.ellipsis,
              style: KafiTheme.nunito(10),
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
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
          _row(
              'Match',
              a.matchPercent > 0 ? '${a.matchPercent}%' : '—',
              b.matchPercent > 0 ? '${b.matchPercent}%' : '—'),
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
