import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/report_problem_sheet.dart';
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
                      if (t.isActive) _dayProofSection(t),
                      if (_isNanny) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(13, 8, 13, 0),
                          child: _paymentBlock(context, t),
                        ),
                      ],
                      _reportProblemLink(t),
                      const SizedBox(height: 6),
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

  // ── Daily task proof: nanny uploads a photo per trial day; family views ──
  Widget _dayProofSection(TrialModel t) {
    final today = controller.currentTrialDay(t);
    return Container(
      margin: const EdgeInsets.fromLTRB(13, 8, 13, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEFE4), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x0F2E9A58), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_camera_outlined, color: KafiColors.grnD, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.trialProofTitle.tr,
                        style: KafiTheme.fredoka(12.5, color: KafiColors.td, w: FontWeight.w700)),
                    Text(
                      _isNanny
                          ? AppStrings.trialProofNannySub.tr
                          : AppStrings.trialProofFamilySub.tr,
                      style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            // Read the reactive maps so the grid rebuilds after an upload.
            final proofs = controller.dayProofs;
            final uploading = controller.isUploadingProof.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int day = 1; day <= t.durationDays; day++)
                  _dayTile(t, day, today, proofs[day], uploading),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _dayTile(TrialModel t, int day, int today, DayProof? proof, bool uploading) {
    const size = 72.0;
    final label = AppStrings.trialProofDay.trParams({'n': '$day'});

    Widget frame(Widget child, {Color border = const Color(0xFFE3EFE8)}) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF6FBF8),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: border, width: 1.3),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );

    if (proof != null && proof.imageUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => _viewProof(proof.imageUrl),
        child: frame(
          Stack(
            fit: StackFit.expand,
            children: [
              _proofImage(proof.imageUrl),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: KafiTheme.fredoka(8.5, color: Colors.white, w: FontWeight.w700)),
                ),
              ),
            ],
          ),
          border: KafiColors.grn,
        ),
      );
    }

    // No proof yet. The nanny can add for today or any past day; the family (or
    // future days) just see a pending placeholder.
    final canUpload = _isNanny && day <= today;
    return GestureDetector(
      onTap: canUpload && !uploading ? () => _chooseProofSource(t, day) : null,
      child: frame(
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (canUpload && uploading)
              const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: KafiColors.grnD))
            else
              Icon(canUpload ? Icons.add_a_photo_outlined : Icons.hourglass_empty,
                  size: 18, color: canUpload ? KafiColors.grnD : KafiColors.ts.withValues(alpha: 0.5)),
            const SizedBox(height: 3),
            Text(label,
                style: KafiTheme.nunito(8.5, color: KafiColors.ts, w: FontWeight.w700)),
            Text(canUpload ? AppStrings.trialProofAdd.tr : AppStrings.trialProofPending.tr,
                style: KafiTheme.nunito(7.5, color: KafiColors.ts.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _proofImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: KafiColors.ts));
    }
    return Image.file(File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: KafiColors.ts));
  }

  void _viewProof(String url) {
    Get.dialog(
      GestureDetector(
        onTap: Get.back,
        child: Container(
          color: Colors.black.withValues(alpha: 0.85),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _proofImage(url),
          ),
        ),
      ),
    );
  }

  void _chooseProofSource(TrialModel t, int day) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: KafiColors.cardBorder, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            _sourceTile(Icons.photo_camera_outlined, AppStrings.mediaTakePhoto.tr, () {
              Get.back();
              controller.uploadDayProof(t, day, ImageSource.camera);
            }),
            _sourceTile(Icons.photo_library_outlined, AppStrings.mediaChooseGallery.tr, () {
              Get.back();
              controller.uploadDayProof(t, day, ImageSource.gallery);
            }),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: KafiColors.grnD),
      title: Text(label, style: KafiTheme.nunito(12.5, color: KafiColors.td, w: FontWeight.w700)),
    );
  }

  // ── Green header: status badge + timer + parties ──────────────────────────
  Widget _header(TrialModel t) {
    // The "Family" card must identify the FAMILY. When a nanny views the trial,
    // currentUser is her — so use the family name the controller resolved from
    // the trial's familyId; the family viewer still sees its own name.
    final String famName;
    if (_isNanny) {
      final resolved = controller.familyDisplayName.value;
      famName = (resolved != null && resolved.isNotEmpty) ? resolved : 'The family';
    } else {
      final famUser =
          Get.isRegistered<AuthController>() ? Get.find<AuthController>().currentUser.value : null;
      famName = (famUser?.fullName?.isNotEmpty == true) ? famUser!.fullName! : 'Your family';
    }
    final nanny = controller.nannyCardFor(t.nannyId);

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
                    const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
                    showRevealed: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partyCard(String name, String role, List<Color> avColors,
      {bool showRevealed = false}) {
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
          // Only the nanny's contact is ever revealed (family -> nanny), so
          // show "Revealed" on her card only. Showing it on the family card
          // wrongly implied the nanny could call the family, which she can't.
          if (showRevealed) ...[
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
        ],
      ),
    );
  }

  // ── Evaluation checklist ───────────────────────────────────────────────────
  Widget _evalSection(TrialModel t) {
    // (TrialEvaluation field key, label). The family ticks these before
    // recording an outcome; the nanny sees the recorded result read-only.
    final items = <(String, String)>[
      ('childInteractionAndPatience', 'Child interaction & patience'),
      ('punctualityAndReliability', 'Punctuality & reliability'),
      ('followingInstructions', 'Following instructions'),
      ('communicationAndLanguage', 'Communication & language'),
      ('cookingFamilyFood', 'Cooking (family food)'),
      ('honestyAndTrustworthiness', 'Honesty & trustworthiness'),
    ];
    final editable = !_isNanny;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 ${AppStrings.trialEval.tr}',
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
          const SizedBox(height: 4),
          for (final (i, item) in items.indexed)
            Obx(() => _evalItem(
                  item.$2,
                  editable
                      ? (controller.evalDraft[item.$1] ?? false)
                      : _evalValue(t.evaluation, item.$1),
                  i == items.length - 1,
                  onTap: editable ? () => controller.toggleEval(item.$1) : null,
                )),
        ],
      ),
    );
  }

  bool _evalValue(TrialEvaluation? e, String key) {
    if (e == null) return false;
    return switch (key) {
      'childInteractionAndPatience' => e.childInteractionAndPatience,
      'punctualityAndReliability' => e.punctualityAndReliability,
      'followingInstructions' => e.followingInstructions,
      'communicationAndLanguage' => e.communicationAndLanguage,
      'cookingFamilyFood' => e.cookingFamilyFood,
      'honestyAndTrustworthiness' => e.honestyAndTrustworthiness,
      _ => false,
    };
  }

  Widget _evalItem(String label, bool ok, bool last, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
    // The family can only record an outcome (Hire / Not this time) once the
    // trial is actually ACTIVE — not during an accepted-but-not-yet-started
    // trial, and not after it has already been resolved.
    if (!t.isActive) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 10, 13, 13),
        decoration: const BoxDecoration(color: Color(0xFFF0FFF5)),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.setOutcome(TrialStatus.completed,
                    outcomeLabel: 'failed', evaluation: controller.buildEvaluation()),
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
                onTap: () => controller.setOutcome(TrialStatus.completed,
                    outcomeLabel: 'hired', evaluation: controller.buildEvaluation()),
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

  // Always-available "Report a problem" entry (both roles) — files a dispute
  // about the trial counterparty (no-show, abuse, fraud, payment, other). The
  // report then appears under Settings → My reports and in the admin panel.
  Widget _reportProblemLink(TrialModel t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 6, 13, 0),
        child: TextButton.icon(
          onPressed: () => showReportProblemSheet(
            reportedUserId: _isNanny ? t.familyId : t.nannyId,
            relatedTrialId: t.id,
          ),
          style: TextButton.styleFrom(
            foregroundColor: KafiColors.ts,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          icon: const Icon(Icons.flag_outlined, size: 15),
          label: Text(AppStrings.reportProblemTitle.tr,
              style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w700)),
        ),
      ),
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
