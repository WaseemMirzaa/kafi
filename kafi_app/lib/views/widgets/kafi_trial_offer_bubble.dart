import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/views/shared/kafi_colors.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';

/// HTML `.trial-offer-bubble` — green (family sent) or purple (nanny received).
class KafiTrialOfferBubble extends StatelessWidget {
  const KafiTrialOfferBubble({
    super.key,
    required this.message,
    required this.isNannyView,
    this.onAccept,
    this.onCounter,
    this.onAcceptCounter,
    this.onDeclineCounter,
  });

  final ChatMessage message;
  final bool isNannyView;
  // Nanny-side actions on the original offer (pending).
  final VoidCallback? onAccept;
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
      return FutureBuilder<TrialModel?>(
        future: Future.value(null),
        builder: (_, __) => _bubbleBody(null),
      );
    }
    final ctrl = Get.find<TrialController>();
    // Reactive: rebuild whenever the trial list updates after accept/decline/counter.
    return Obx(() {
      final trial = ctrl.all.firstWhereOrNull((t) => t.id == message.trialOfferId);
      if (trial == null) {
        // Fall back to one-shot fetch if the controller cache hasn't loaded yet.
        return FutureBuilder<TrialModel?>(
          future: ctrl.getTrial(message.trialOfferId!),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 48,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: KafiColors.grnD),
                ),
              );
            }
            return _bubbleBody(snap.data);
          },
        );
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
    final received = isNannyView && message.type == MessageType.trialOffer;
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

    return Align(
      alignment: received ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
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
              Text(
                AppStrings.trialOfferBubbleDuration.trParams({'days': '${trial.durationDays}'}),
                style: KafiTheme.nunito(9.5, color: rowColor, w: FontWeight.w600),
              ),
              Text(
                AppStrings.trialOfferBubbleRate.trParams({'rate': '${trial.dailyRate}'}),
                style: KafiTheme.nunito(9.5, color: rowColor, w: FontWeight.w600),
              ),
              if (trial.counterOffer != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppStrings.trialCounterOffer.trParams(
                      {'rate': '${trial.counterOffer!.dailyRate}'}),
                  style: KafiTheme.nunito(9.5,
                      color: KafiColors.ambD, w: FontWeight.w800),
                ),
              ],
              if (trial.notes != null && trial.notes!.isNotEmpty)
                Text(
                  trial.notes!,
                  style: KafiTheme.nunito(9, color: rowColor.withValues(alpha: 0.85)),
                ),
              // Status badge for non-pending trials so users see what's happened.
              if (trial.status != TrialStatus.pending) ...[
                const SizedBox(height: 6),
                _statusChip(trial.status),
              ],
            ],
            // Nanny side — Accept / Counter on the original pending offer.
            if (received &&
                message.type == MessageType.trialOffer &&
                (trial == null || trial.status == TrialStatus.pending)) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: KafiPrimaryButton(
                      label: AppStrings.trialOfferAccept.tr,
                      variant: KafiButtonVariant.green,
                      onPressed: onAccept,
                    ),
                  ),
                  const SizedBox(width: 5),
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
                ],
              ),
            ],
            // Family side — Accept / Decline on a nanny's counter offer.
            // The "received" gate is inverted (family is recipient of the counter).
            if (!isNannyView &&
                message.type == MessageType.trialCountered &&
                trial != null &&
                trial.status == TrialStatus.countered) ...[
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: KafiPrimaryButton(
                      label: AppStrings.trialOfferAccept.tr,
                      variant: KafiButtonVariant.green,
                      onPressed: onAcceptCounter,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDeclineCounter,
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
          ],
        ),
      ),
    );
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
