import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/subscription_plan.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class PricingScreen extends GetView<SubscriptionController> {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _includedBox(),
                    const SizedBox(height: 10),
                    Obx(() {
                      final activeId = controller.activePlanId.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final p in controller.plans) _planCard(p, p.id == activeId),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+5% UAE VAT · Nannies always free · Cancel anytime',
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600).copyWith(height: 1.5),
              ),
              const SizedBox(height: 8),
              _trustRow(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero (.sp-hero) ────────────────────────────────────────────────────────
  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 19),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5EEFF), Color(0xFFFFE8F5)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: AppNavigation.back,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.arrow_back, size: 14, color: KafiColors.pur),
                ),
              ),
              const Spacer(),
              Text(AppStrings.appName.tr, style: KafiTheme.pacifico(18)),
              const Spacer(),
              const SizedBox(width: 27),
            ],
          ),
          const SizedBox(height: 11),
          Text.rich(
            TextSpan(
              style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900),
              children: [
                const TextSpan(text: 'Upgrade your '),
                TextSpan(text: 'plan', style: TextStyle(color: KafiColors.roseD)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Unlimited contacts · CVs · Videos · Smart matching\nNannies always 100% free · No hidden fees',
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── "All plans include everything" (.plans-wrap green box) ─────────────────
  Widget _includedBox() {
    const features = [
      'Unlimited contacts', 'All videos', 'Full CVs', 'Smart match %',
      'Trial offers', 'Chat', 'Call & WhatsApp', 'Unlimited posts',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.grnL, Color(0xFFD0F5E0)]),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All plans include everything:',
              style: KafiTheme.nunito(10.5, color: KafiColors.grnD, w: FontWeight.w800)),
          const SizedBox(height: 7),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 7.5,
            mainAxisSpacing: 3,
            crossAxisSpacing: 6,
            children: [
              for (final f in features)
                Row(
                  children: [
                    const Text('✓', style: TextStyle(fontSize: 9, color: Color(0xFF2A7A50), fontWeight: FontWeight.w800)),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(f,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KafiTheme.nunito(9, color: const Color(0xFF2A7A50), w: FontWeight.w700)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('Only difference is how long access lasts',
                style: KafiTheme.nunito(8.5, color: const Color(0xFF4AAA70), w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Plan card (.plan-card) ─────────────────────────────────────────────────
  Widget _planCard(SubscriptionPlan p, bool selected) {
    final monthly = p.popular || p.durationDays == 30;
    final weekly = p.durationDays <= 7;
    final vat = p.priceAed * 0.05;
    final total = p.priceAed + vat;

    // Per-plan palette
    final Color cardBg;
    final Color? borderColor;
    final List<Color>? cardGradient;
    final Color tagBg, tagText, btnBg, btnText, nameColor, descColor, priceColor, periodColor, vatColor;
    final String periodWord;
    if (monthly) {
      cardBg = Colors.transparent;
      cardGradient = const [KafiColors.pur, Color(0xFFC084FC)];
      borderColor = null;
      tagBg = Colors.white.withValues(alpha: 0.25);
      tagText = Colors.white;
      btnBg = Colors.white;
      btnText = const Color(0xFF7C3AED);
      nameColor = Colors.white;
      descColor = Colors.white.withValues(alpha: 0.75);
      priceColor = Colors.white;
      periodColor = Colors.white.withValues(alpha: 0.7);
      vatColor = Colors.white.withValues(alpha: 0.6);
      periodWord = 'month';
    } else if (weekly) {
      cardBg = const Color(0xFFFFF8EE);
      cardGradient = null;
      borderColor = const Color(0xFFFFE0A0);
      tagBg = const Color(0xFFFFE0A0);
      tagText = const Color(0xFFA06010);
      btnBg = const Color(0xFFFFB347);
      btnText = Colors.white;
      nameColor = KafiColors.td;
      descColor = KafiColors.ts;
      priceColor = KafiColors.td;
      periodColor = KafiColors.ts;
      vatColor = KafiColors.ts;
      periodWord = 'week';
    } else {
      cardBg = const Color(0xFFF0FFF8);
      cardGradient = null;
      borderColor = const Color(0xFFB0E8C8);
      tagBg = const Color(0xFFB0E8C8);
      tagText = const Color(0xFF1A6A40);
      btnBg = const Color(0xFF34B87A);
      btnText = Colors.white;
      nameColor = KafiColors.td;
      descColor = KafiColors.ts;
      priceColor = KafiColors.td;
      periodColor = KafiColors.ts;
      vatColor = KafiColors.ts;
      periodWord = '2 months';
    }

    final name = '${p.durationDays} days access';
    final desc = monthly
        ? 'Best for most families'
        : weekly
            ? 'Try it — find your nanny fast'
            : 'Best value · AED ${(p.priceAed / p.durationDays).toStringAsFixed(2)}/day';

    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardGradient == null ? cardBg : null,
        gradient: cardGradient == null ? null : LinearGradient(colors: cardGradient),
        borderRadius: BorderRadius.circular(14),
        border: borderColor == null ? null : Border.all(color: borderColor, width: 2),
        boxShadow: monthly
            ? [BoxShadow(color: KafiColors.pur.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _pill(p.label, tagBg, tagText),
                        if (!monthly && p.savingsLabel != null) ...[
                          const SizedBox(width: 3),
                          _pill(p.savingsLabel!, const Color(0xFF34B87A), Colors.white),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(name, style: KafiTheme.nunito(12, color: nameColor, w: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Text(desc, style: KafiTheme.nunito(9, color: descColor, w: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      style: KafiTheme.nunito(19, color: priceColor, w: FontWeight.w900),
                      children: [
                        TextSpan(text: 'AED ',
                            style: KafiTheme.nunito(9.5, color: priceColor, w: FontWeight.w700)),
                        TextSpan(text: '${p.priceAed}'),
                      ],
                    ),
                  ),
                  Text('valid ${p.durationDays} days',
                      style: KafiTheme.nunito(9, color: periodColor, w: FontWeight.w600)),
                  Text('+AED ${vat.toStringAsFixed(2)} VAT = AED ${total.toStringAsFixed(2)}',
                      style: KafiTheme.nunito(8, color: vatColor, w: FontWeight.w600)),
                ],
              ),
            ],
          ),
          if (!monthly && !weekly) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFD0F5E0), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Text('✓', style: TextStyle(fontSize: 10, color: Color(0xFF1A6A40), fontWeight: FontWeight.w800)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('Job post highlighted at top of search',
                        style: KafiTheme.nunito(9, color: const Color(0xFF1A6A40), w: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          GestureDetector(
            onTap: selected ? null : () => _select(p),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: monthly ? 0.9 : 1) : btnBg,
                borderRadius: BorderRadius.circular(9),
                border: selected ? Border.all(color: KafiColors.grnD, width: 1.5) : null,
              ),
              child: Text(
                selected ? '✓ Current plan' : 'Select · AED ${p.priceAed} / $periodWord',
                style: KafiTheme.fredoka(11.5, color: selected ? KafiColors.grnD : btnText, w: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );

    // Popular ribbon on top of the monthly card.
    if (monthly) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            card,
            Positioned(
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [KafiColors.rose, KafiColors.roseD]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('🌸 ${p.savingsLabel ?? AppStrings.pricingPopular.tr}',
                    style: KafiTheme.fredoka(8, color: Colors.white, w: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }
    return card;
  }

  Widget _pill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: KafiTheme.fredoka(8, color: fg, w: FontWeight.w700)),
    );
  }

  Widget _trustRow() {
    Widget item(String emoji, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 3),
            Text(label, style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w700)),
          ],
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item('🛡️', 'SSL'),
        const SizedBox(width: 12),
        item('❤️', 'UAE trusted'),
        const SizedBox(width: 12),
        item('⭐', '5-star'),
      ],
    );
  }

  Future<void> _select(SubscriptionPlan p) async {
    final ok = await controller.subscribe(p.id);
    if (!ok) return; // the controller already surfaced the error
    Get.snackbar(AppStrings.subscribeNow.tr, 'Subscription active');
    // Return to wherever the paywall was hit from — including the (now
    // unlockable) locked profile — instead of always resetting to browse
    // (DISC-15). Fall back to browse only when there's nothing to pop.
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
    } else {
      Get.offAllNamed(Routes.browse);
    }
  }
}
