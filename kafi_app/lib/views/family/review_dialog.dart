import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/review_model.dart';
import 'package:kafi_app/services/interfaces/i_review_service.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Prompts the signed-in family to rate [nannyId] (e.g. after a completed
/// trial). No-ops silently if they've already reviewed this nanny.
Future<void> showReviewDialog({
  required String nannyId,
  String? nannyName,
  String? trialId,
}) async {
  final reviews = Get.find<IReviewService>();
  final me = Get.find<AuthController>().currentUser.value;
  if (me == null) return;
  if (await reviews.hasReviewed(me.id, nannyId)) return;

  await Get.dialog(
    _ReviewDialog(nannyId: nannyId, nannyName: nannyName, trialId: trialId),
    barrierDismissible: true,
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.nannyId, this.nannyName, this.trialId});

  final String nannyId;
  final String? nannyName;
  final String? trialId;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = Get.find<AuthController>().currentUser.value;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      await Get.find<IReviewService>().submitReview(
        ReviewModel(
          id: '', // service assigns a deterministic reviewerId_revieweeId id
          reviewerId: me.id,
          reviewerType: 'family',
          revieweeId: widget.nannyId,
          revieweeType: 'nanny',
          trialId: widget.trialId,
          rating: _rating,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      Get.back();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.reviewThanks.tr,
          snackPosition: SnackPosition.BOTTOM);
    } catch (_) {
      setState(() => _busy = false);
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.reviewFailed.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.nannyName?.trim().isNotEmpty ?? false)
        ? widget.nannyName!.trim()
        : AppStrings.reviewYourNanny.tr;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.reviewTitle.trParams({'name': name}),
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(AppStrings.reviewSubtitle.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: _busy ? null : () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 34,
                        color: filled ? const Color(0xFFFFB800) : KafiColors.roseL),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _comment,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              maxLength: 400,
              style: KafiTheme.nunito(12, color: KafiColors.td),
              decoration: InputDecoration(
                hintText: AppStrings.reviewCommentHint.tr,
                hintStyle: KafiTheme.nunito(11, color: KafiColors.ts),
                filled: true,
                fillColor: const Color(0xFFF7F8FC),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _busy ? null : Get.back,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: KafiColors.roseL, width: 1.5),
                      ),
                      child: Text(AppStrings.reviewSkip.tr,
                          style: KafiTheme.nunito(12, color: KafiColors.roseD, w: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _busy ? null : _submit,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF8FAB), Color(0xFFFF5C8A)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(AppStrings.reviewSubmit.tr,
                              style: KafiTheme.nunito(12,
                                  color: Colors.white, w: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
