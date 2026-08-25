import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// HTML `.trial-offer-bubble` — green (family sent) or purple (nanny received).
/// Full rows per System Spec §3.7 TrialOfferBubble + HTML chat columns.
class KafiTrialOfferBubble extends StatelessWidget {
  const KafiTrialOfferBubble({
    super.key,
    required this.message,
    required this.isNannyView,
    this.onAccept,
    this.onDecline,
    this.onCounter,
    this.onAcceptCounter,
    this.onDeclineCounter,
  });

  final ChatMessage message;
  final bool isNannyView;
  // Nanny-side actions on the original offer (pending) — Screen 32A.
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCounter;
  // Family-side actions on the counter offer (countered).
  final VoidCallback? onAcceptCounter;
  final VoidCallback? onDeclineCounter;

  @override
  Widget build(BuildContext context) {
    if (message.trialOfferId == null) {
      return _plainFallback();
    }
    if (!Get.isRegistered<TrialController>()) {
      return _bubbleBody(null);
    }
    final ctrl = Get.find<TrialController>();
    // Reactive: rebuild whenever the trial list updates after accept/decline/counter.
    // No per-bubble spinner — conversation detail shows one list-level loader
    // while messages + trials are fetched; missing trial is fetched by id so
    // nannies still see duration / rate / type / location (not title-only).
    return Obx(() {
      final id = message.trialOfferId!;
      final trial = ctrl.all.firstWhereOrNull((t) => t.id == id);
      if (trial == null) {
        // Schedule outside build; Obx rebuilds when [all] gains the trial.
        Future.microtask(() => ctrl.ensureTrialInList(id));
      }
      return _bubbleBody(trial);
    });
  }

  Widget _plainFallback() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F8EE), Color(0xFFD0F5E0)]),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFA0E0C0), width: 1.5),
      ),
      child: Text(message.content, style: KafiTheme.nunito(10, color: KafiColors.grnD, w: FontWeight.w800)),
    );
  }

  Widget _bubbleBody(TrialModel? trial) {
    // Nanny receives the original offer; family receives the counter message.
    final received = (isNannyView && message.type == MessageType.trialOffer) ||
        (!isNannyView && message.type == MessageType.trialCountered);
    final gradient = received
        ? const [KafiColors.purL, Color(0xFFEDE4FF)]
        : const [Color(0xFFE8F8EE), Color(0xFFD0F5E0)];
    final border = received ? KafiColors.purB : const Color(0xFFA0E0C0);
    final titleColor = received ? KafiColors.pur : KafiColors.grnD;
    final rowColor = received ? const Color(0xFF4A2080) : const Color(0xFF1A5A38);

    final title = switch (message.type) {
      MessageType.trialOffer =>
        received ? AppStrings.trialOfferBubbleReceived.tr : AppStrings.trialOfferBubbleSent.tr,
      MessageType.trialAccepted => AppStrings.trialAcceptedMessage.tr,
      MessageType.trialDeclined => AppStrings.trialDeclinedMessage.tr,
      MessageType.trialCountered => message.content,
      _ => message.content,
    };

    final showFamilyCounterActions = _showFamilyCounterActions(trial);
    final rowStyle = KafiTheme.nunito(9.5, color: rowColor, w: FontWeight.w600);

    return Align(
      alignment: received ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        // Slightly wider so full Screen 31 fields (start date, notes) fit.
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: KafiTheme.nunito(10, color: titleColor, w: FontWeight.w800)),
            if (trial != null) ...[
              const SizedBox(height: 4),
              // Complete offer fields — Screen 31 form / §3.7 (both parties).
              Text(
                AppStrings.trialOfferBubbleDuration.trParams({'days': '${trial.durationDays}'}),
                style: rowStyle,
              ),
              Text(
                AppStrings.trialOfferBubbleRate.trParams({'rate': '${trial.dailyRate}'}),
                style: rowStyle,
              ),
              Text(
                AppStrings.trialOfferBubbleTotal.trParams({'total': '${trial.totalAmount}'}),
                style: rowStyle,
              ),
              Text(
                AppStrings.trialOfferBubbleStartFrom.trParams({'date': _formatStartDate(trial)}),
                style: rowStyle,
              ),
              Text(_typeRow(trial.trialType), style: rowStyle),
              if (trial.location.trim().isNotEmpty)
                Text(
                  AppStrings.trialOfferBubbleLocationOnly
                      .trParams({'location': trial.location.trim()}),
                  style: rowStyle,
                ),
              if (trial.notes != null && trial.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.trialOfferBubbleNotes.trParams({'notes': trial.notes!.trim()}),
                  style: KafiTheme.nunito(9, color: rowColor.withValues(alpha: 0.85)),
                ),
              ],
              if (trial.counterOffer != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.trialCounterOffer.trParams(
                      {'rate': '${trial.counterOffer!.dailyRate}'}),
                  style: KafiTheme.nunito(9.5,
                      color: KafiColors.ambD, w: FontWeight.w800),
                ),
              ],
              // Status badge for non-pending trials so users see what's happened.
              if (trial.status != TrialStatus.pending) ...[
                const SizedBox(height: 6),
                _statusChip(trial.status),
              ],
            ],
            // Nanny side — Accept / Counter / Decline on the original pending
            // offer (Screen 32A: [Decline] [Counter] [Accept]).
            if (received &&
                message.type == MessageType.trialOffer &&
                (trial == null || trial.status == TrialStatus.pending)) ...[
              const SizedBox(height: 7),
              KafiPrimaryButton(
                label: AppStrings.trialOfferAccept.tr,
                variant: KafiButtonVariant.green,
                onPressed: onAccept,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCounter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KafiColors.pur,
                        side: const BorderSide(color: KafiColors.purB, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        AppStrings.trialOfferCounter.tr,
                        style: KafiTheme.fredoka(9, color: KafiColors.pur, w: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: KafiColors.redD,
                        side: const BorderSide(color: KafiColors.redD, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        AppStrings.trialOfferDecline.tr,
                        style: KafiTheme.fredoka(9, color: KafiColors.redD, w: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // Family side — Accept / Decline on a nanny counter (Screen 17 / §6.5).
            // Shown on the counter message AND on the original offer once status
            // is countered (CX9), including when TrialController.all is briefly stale.
            if (showFamilyCounterActions) ...[
              const SizedBox(height: 7),
              KafiPrimaryButton(
                label: AppStrings.trialOfferAccept.tr,
                variant: KafiButtonVariant.green,
                onPressed: onAcceptCounter,
              ),
              const SizedBox(height: 5),
              OutlinedButton(
                onPressed: onDeclineCounter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KafiColors.redD,
                  side: const BorderSide(color: KafiColors.redD, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: const Size(double.infinity, 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  AppStrings.trialOfferDecline.tr,
                  style: KafiTheme.fredoka(9, color: KafiColors.redD, w: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeRow(String trialType) {
    if (trialType == 'live-out') {
      return AppStrings.trialOfferBubbleTypeLiveOut.tr;
    }
    return AppStrings.trialOfferBubbleTypeLiveIn.tr;
  }

  String _formatStartDate(TrialModel trial) {
    final date = DateFormat('MMM d, yyyy').format(trial.startDate);
    final time = trial.startTime.trim();
    if (time.isEmpty) return date;
    return '$date · $time';
  }

  /// Family may act while the trial is countered, or when the chat message is
  /// already a counter (even if the local trial list hasn't refreshed yet).
  bool _showFamilyCounterActions(TrialModel? trial) {
    if (isNannyView) return false;
    if (onAcceptCounter == null && onDeclineCounter == null) return false;
    const terminal = {
      TrialStatus.accepted,
      TrialStatus.active,
      TrialStatus.declined,
      TrialStatus.completed,
      TrialStatus.cancelled,
    };
    if (trial != null && terminal.contains(trial.status)) return false;
    if (trial?.status == TrialStatus.countered) return true;
    return message.type == MessageType.trialCountered;
  }

  Widget _statusChip(TrialStatus s) {
    final (label, color) = switch (s) {
      TrialStatus.accepted => (AppStrings.trialStatusAccepted.tr, KafiColors.grnD),
      TrialStatus.active => (AppStrings.trialStatusActive.tr, KafiColors.grnD),
      TrialStatus.declined => (AppStrings.trialStatusDeclined.tr, KafiColors.redD),
      TrialStatus.countered => (AppStrings.trialStatusCountered.tr, KafiColors.ambD),
      TrialStatus.completed => (AppStrings.trialStatusCompleted.tr, KafiColors.navy),
      TrialStatus.cancelled => (AppStrings.trialStatusCancelled.tr, KafiColors.grey),
      _ => (s.name, KafiColors.tm),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: KafiTheme.nunito(9, color: color, w: FontWeight.w800)),
    );
  }
}
