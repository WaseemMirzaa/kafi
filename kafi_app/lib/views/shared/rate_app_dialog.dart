import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/store_config.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Prompts the user to rate Kafi on the app store. Replaces the old peer
/// (nanny↔family) review dialog — shown after a completed trial or an ended
/// hire. Throttled with `shared_preferences`: never shown again once the user
/// taps "Rate now", and at most once per [_minGap] otherwise.
class RateAppPrompt {
  RateAppPrompt._();

  static const _kRated = 'kafi.rating.rated';
  static const _kLastPromptedAt = 'kafi.rating.lastPromptedAt';
  static const Duration _minGap = Duration(days: 14);

  /// Shows the prompt if the throttle allows. Safe to await from a flow that
  /// has already completed — it never throws into the caller.
  static Future<void> maybeShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kRated) ?? false) return;
      final last = prefs.getInt(_kLastPromptedAt) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (last != 0 && now - last < _minGap.inMilliseconds) return;
      await prefs.setInt(_kLastPromptedAt, now);
    } catch (_) {
      return; // storage unavailable → skip the prompt silently
    }
    await Get.dialog(const _RateAppDialog(), barrierDismissible: true);
  }

  /// Marks the app as rated (so it's never prompted again) and opens the store
  /// listing. Best-effort — a failed launch still leaves the user thanked.
  static Future<void> rate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRated, true);
    } catch (_) {/* best-effort */}
    final url = StoreConfig.storeListingUrl;
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {/* store not reachable → still thank the user */}
  }
}

class _RateAppDialog extends StatefulWidget {
  const _RateAppDialog();

  @override
  State<_RateAppDialog> createState() => _RateAppDialogState();
}

class _RateAppDialogState extends State<_RateAppDialog> {
  int _rating = 5;
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    await RateAppPrompt.rate();
    if (!mounted) return;
    Get.back();
    Get.snackbar(AppStrings.successTitle.tr, AppStrings.rateAppThanks.tr,
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.rateAppTitle.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(AppStrings.rateAppSubtitle.tr,
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
            const SizedBox(height: 16),
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
                      child: Text(AppStrings.rateAppLater.tr,
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(AppStrings.rateAppCta.tr,
                              style: KafiTheme.nunito(12, color: Colors.white, w: FontWeight.w800)),
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
