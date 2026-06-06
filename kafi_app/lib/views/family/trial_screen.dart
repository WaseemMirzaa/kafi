import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/nanny_card_resolver.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

class TrialScreen extends GetView<TrialController> {
  const TrialScreen({super.key});

  bool get _isNanny =>
      Get.isRegistered<AuthController>() && Get.find<AuthController>().currentUser.value?.isNanny == true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF5),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(() {
          final t = controller.displayed;
          if (t == null) return _emptyState();
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(t),
                      const SizedBox(height: 4),
                      _evalSection(t),
                      if (_isNanny) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
                          child: _paymentBlock(context, t),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _outcomeBar(context, t),
            ],
          );
        }),
      ),
    );
  }

  // ── Green header: status badge + timer + parties ──────────────────────────
  Widget _header(TrialModel t) {
    final famUser = Get.isRegistered<AuthController>() ? Get.find<AuthController>().currentUser.value : null;
    final famName = (famUser?.fullName?.isNotEmpty == true) ? famUser!.fullName! : 'Your family';
    final nanny = resolveNannyCard(t.nannyId);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F8EE), Color(0xFFF0FFF5)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: Get.back,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.arrow_back, color: KafiColors.grnD, size: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(color: KafiColors.grn, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 11),
                    const SizedBox(width: 4),
                    Text(AppStrings.trialActive.tr,
                        style: KafiTheme.fredoka(10, color: Colors.white, w: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Timer card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFD0F0DC), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.schedule, color: KafiColors.grnD, size: 11),
                    const SizedBox(width: 4),
                    Text(AppStrings.trialRemaining.tr,
                        style: KafiTheme.nunito(9.5, color: KafiColors.grnD, w: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 5),
                Text(_remainingLabel(t),
                    style: KafiTheme.nunito(26, color: KafiColors.td, w: FontWeight.w900).copyWith(height: 1)),
                const SizedBox(height: 3),
                Text(
                  '${t.durationDays}-day paid trial · AED ${t.dailyRate}/day · Ends ${_fmtEnd(t.endDate)}',
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Parties
          Row(
            children: [
              Expanded(
                child: _partyCard(famName, 'Family · ${t.location.isNotEmpty ? t.location : 'UAE'}',
                    const [KafiColors.pur, Color(0xFFC084FC)]),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('↔', style: TextStyle(fontSize: 16, color: KafiColors.grn, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: _partyCard(nanny.name, 'Nanny · ${nanny.nationality}',
                    const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partyCard(String name, String role, List<Color> avColors) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE0F5E8), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: avColors),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(initial, style: KafiTheme.fredoka(13, color: Colors.white, w: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 5),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w800)),
          Text(role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KafiTheme.nunito(8.5, color: KafiColors.ts, w: FontWeight.w600)),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.call, color: KafiColors.grnD, size: 9),
              const SizedBox(width: 2),
              Text('Revealed', style: KafiTheme.nunito(9.5, color: KafiColors.grnD, w: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Evaluation checklist ───────────────────────────────────────────────────
  Widget _evalSection(TrialModel t) {
    final eval = t.evaluation;
    final items = <(String, bool)>[
      ('Child interaction & patience', eval?.childInteractionAndPatience ?? false),
      ('Punctuality & reliability', eval?.punctualityAndReliability ?? false),
      ('Following instructions', eval?.followingInstructions ?? false),
      ('Communication & language', eval?.communicationAndLanguage ?? false),
      ('Cooking (family food)', eval?.cookingFamilyFood ?? false),
      ('Honesty & trustworthiness', eval?.honestyAndTrustworthiness ?? false),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 ${AppStrings.trialEval.tr}',
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
          const SizedBox(height: 4),
          for (var i = 0; i < items.length; i++) _evalItem(items[i].$1, items[i].$2, i == items.length - 1),
        ],
      ),
    );
  }

  Widget _evalItem(String label, bool ok, bool last) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: ok ? KafiColors.grn : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: ok ? null : Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: ok ? const Icon(Icons.check, color: Colors.white, size: 11) : null,
          ),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: KafiTheme.nunito(10, color: KafiColors.td, w: FontWeight.w700))),
        ],
      ),
    );
  }

  // ── Outcome bar (family: Hire / Not this time) ─────────────────────────────
  Widget _outcomeBar(BuildContext context, TrialModel t) {
    if (_isNanny) {
      // Nanny side: cancel option only (payment block is in the scroll body).
      if (t.status != TrialStatus.pending && t.status != TrialStatus.accepted) {
        return const SizedBox.shrink();
      }
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 6, 13, 10),
          child: TextButton.icon(
            onPressed: () => _confirmCancel(context, t),
            icon: const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFCC3344)),
            label: const Text('Cancel trial', style: TextStyle(color: Color(0xFFCC3344))),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
        decoration: const BoxDecoration(color: Color(0xFFF0FFF5)),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setOutcome(TrialStatus.completed, outcomeLabel: 'failed'),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: KafiColors.cardBorder, width: 2),
                  ),
                  child: Text(AppStrings.trialNotThisTime.tr,
                      style: KafiTheme.fredoka(12, color: KafiColors.roseD, w: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setOutcome(TrialStatus.completed, outcomeLabel: 'hired'),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [KafiColors.grn, KafiColors.grnD]),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(color: KafiColors.grnD.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(AppStrings.trialHire.tr,
                          style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KafiColors.grnL,
                shape: BoxShape.circle,
                border: Border.all(color: KafiColors.grnD.withValues(alpha: 0.3), width: 2),
              ),
              child: const Icon(Icons.handshake_outlined, color: KafiColors.grnD, size: 30),
            ),
            const SizedBox(height: 14),
            Text('No active trial yet',
                style: KafiTheme.nunito(14, color: KafiColors.grnD, w: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('Send a trial offer to a nanny you like',
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
            const SizedBox(height: 20),
            KafiPrimaryButton(
              label: AppStrings.sendTrialOffer.tr,
              variant: KafiButtonVariant.green,
              onPressed: Get.back,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => AppNavigation.familyGoToTab(0),
              child: Text('Browse nannies',
                  style: KafiTheme.nunito(11, color: KafiColors.grnD, w: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nanny-only payment block (preserved) ───────────────────────────────────
  Widget _paymentBlock(BuildContext context, TrialModel t) {
    if (t.nannyConfirmedPayment) {
      return _banner(KafiColors.grnL, KafiColors.grnD, Icons.check_circle, 'Payment confirmed');
    }
    if (t.paymentIssueReported) {
      return _banner(KafiColors.ambL, KafiColors.ambD, Icons.warning_amber, 'Issue reported — admin will follow up');
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _reportIssueDialog(context, t),
            style: OutlinedButton.styleFrom(foregroundColor: KafiColors.amb),
            child: const Text('Report issue'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: KafiPrimaryButton(
            label: 'Confirm payment',
            variant: KafiButtonVariant.green,
            onPressed: () => controller.confirmPaymentReceived(t.id),
          ),
        ),
      ],
    );
  }

  Widget _banner(Color bg, Color fg, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: KafiTheme.nunito(11, color: fg, w: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, TrialModel t) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel trial?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Both parties will be notified.'),
            const SizedBox(height: 8),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'Reason (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Keep')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Cancel trial')),
        ],
      ),
    );
    if (ok == true) {
      await controller.cancelTrial(t.id, reason: reasonCtrl.text.trim());
    }
  }

  Future<void> _reportIssueDialog(BuildContext context, TrialModel t) async {
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report payment issue'),
        content: TextField(
          controller: descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe the issue…'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Send report')),
        ],
      ),
    );
    if (ok == true && descCtrl.text.trim().isNotEmpty) {
      await controller.reportPaymentIssue(t.id, descCtrl.text.trim());
    }
  }

  String _remainingLabel(TrialModel t) {
    final d = t.remaining;
    if (d.isNegative) return '0d 0h 0m';
    return '${d.inDays}d ${d.inHours.remainder(24)}h ${d.inMinutes.remainder(60)}m';
  }

  String _fmtEnd(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}
