import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/browse_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_nanny_card.dart';
import 'package:kafi_app/views/widgets/kafi_search_field.dart';

class ShortlistScreen extends GetView<ShortlistController> {
  const ShortlistScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            KafiSearchField(
              hint: AppStrings.searchHint.tr,
              onChanged: (v) => controller.query.value = v,
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: KafiColors.roseD));
                }
                if (controller.shortlistedNannies.isEmpty) {
                  return _emptyState();
                }
                final items = controller.filteredShortlist;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            final card = controller.cardFor(item);
            // Identical card to the home feed; swipe left to remove.
            return Dismissible(
              key: ValueKey(item.nannyId),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => controller.removeFromShortlist(item.nannyId),
              background: Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline, color: KafiColors.roseD),
              ),
              child: KafiNannyCard(
                card: card,
                jobLabel: Get.isRegistered<BrowseController>()
                    ? Get.find<BrowseController>().matchJobTitle
                    : null,
                onTap: () => AppNavigation.openNannyProfile(card),
              ),
                  );
                },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEE0FF), Color(0xFFF0D8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!embedInShell)
                GestureDetector(
                  onTap: Get.back,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
                  ),
                ),
              Expanded(
                  child: Text(AppStrings.navShortlist.tr,
                      style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090)))),
            ],
          ),
          const SizedBox(height: 2),
          Obx(() {
            final n = controller.shortlistedNannies.length;
            return Text('$n ${n == 1 ? 'nanny' : 'nannies'} saved',
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600));
          }),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_outlined, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.shortlistEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(AppStrings.shortlistEmptySub.tr,
              style: KafiTheme.nunito(10, color: KafiColors.ts)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => AppNavigation.familyGoToTab(0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: KafiColors.roseD,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(AppStrings.browse.tr,
                  style: KafiTheme.nunito(12, color: Colors.white, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

}
