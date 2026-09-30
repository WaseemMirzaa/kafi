import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/family_shell_controller.dart';
import 'package:kafi_app/controllers/nanny_shell_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Shared navigation helpers for consistent flows across screens.
class AppNavigation {
  AppNavigation._();

  /// Safe "back" for header back buttons. Pops the current route when there is
  /// one to pop; otherwise (e.g. the screen was reached via [Get.offAllNamed],
  /// so the stack is empty) it falls back to the role-appropriate home instead
  /// of silently doing nothing. Behaves exactly like [Get.back] in the common
  /// case where a previous route exists.
  ///
  /// Families still gated on their first job post cannot leave Screen 13 via
  /// this helper — Browse / home is blocked until a job exists.
  static void back() {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    // First-job onboarding gate: back must not open Browse/home at all.
    if (auth?.familyMustPostFirstJob.value == true) {
      if (Get.currentRoute != Routes.familyForm) {
        Get.offAllNamed(Routes.familyForm);
      }
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    final user = auth?.currentUser.value;
    if (user == null) {
      Get.offAllNamed(Routes.welcome);
    } else if (user.isNanny) {
      Get.offAllNamed(Routes.nannyHome);
    } else {
      Get.offAllNamed(Routes.browse);
    }
  }

  /// True when a family must finish Screen 13 before any home/shell route.
  static bool get _familyFirstJobGated =>
      Get.isRegistered<AuthController>() &&
      Get.find<AuthController>().familyMustPostFirstJob.value;

  static void openNotifications() => Get.toNamed(Routes.notifications);

  /// A nanny's general profile (photos, nationality, experience, skills,
  /// languages, salary, visa status, etc.) is always free to browse for every
  /// family, regardless of subscription state — so there's a single profile
  /// route. Video / contact / chat are gated inline on that screen via
  /// SubscriptionController.isNannyLocked.
  static void openNannyProfile(NannyCardModel card) {
    Get.toNamed(Routes.profileUnlocked, arguments: card);
  }

  /// Opens pricing, optionally remembering which nanny profile to unlock
  /// after a successful subscribe (Screen 38 / System Spec §6.8).
  static void openPricing({NannyCardModel? unlockNanny, String? reason}) {
    Get.toNamed(
      Routes.pricing,
      arguments: <String, dynamic>{
        if (reason != null) 'reason': reason,
        if (unlockNanny != null) 'unlockNanny': unlockNanny,
      },
    );
  }

  /// After subscribe succeeds: close the paywall. The profile screen (if
  /// that's where the paywall was opened from) reactively unlocks itself via
  /// SubscriptionController's Obx state, so simply popping back to it is
  /// enough — no route replacement needed.
  static void afterSubscribeSuccess() {
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
      return;
    }
    final args = Get.arguments;
    final card =
        args is Map && args['unlockNanny'] is NannyCardModel ? args['unlockNanny'] as NannyCardModel : null;
    if (card != null && card.id.isNotEmpty) {
      Get.offNamed(Routes.profileUnlocked, arguments: card);
      return;
    }
    Get.offAllNamed(Routes.browse);
  }

  static void openChat({String? nannyId, String? nannyName}) {
    if (_familyFirstJobGated) {
      Get.offAllNamed(Routes.familyForm);
      return;
    }
    // Queue the conversation so the Messages tab opens straight into the
    // thread (rather than the inbox) once it builds / reacts.
    if (nannyId != null && Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().setPendingOpen(nannyId: nannyId, nannyName: nannyName);
    }
    // Return to the shell (closing any pushed profile/detail routes) and
    // switch to the Messages tab so the embedded ChatScreen takes over.
    if (Get.isRegistered<FamilyShellController>()) {
      Get.until((route) => route.isFirst);
      Get.find<FamilyShellController>().goToTab(2);
    } else if (Get.isRegistered<NannyShellController>()) {
      Get.until((route) => route.isFirst);
      Get.find<NannyShellController>().goToTab(2);
    } else {
      Get.toNamed(Routes.chat, arguments: nannyId != null
          ? <String, dynamic>{'nannyId': nannyId, 'nannyName': nannyName}
          : null);
    }
    // ChatScreen may already be mounted (shell tab kept / rebuild without
    // initState). Open the thread explicitly on the next frame.
    if (nannyId != null && Get.isRegistered<ChatController>()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().consumePendingOpen();
        }
      });
    }
  }

  /// Nanny-side chat entry: opens (or creates) the thread with the counterparty
  /// **family**. Mirrors [openChat] but is keyed on the family id, so a nanny
  /// engaged with several families never lands in the wrong conversation.
  static void openChatWithFamily({required String familyId, String? familyName}) {
    if (familyId.isNotEmpty && Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().setPendingOpen(familyId: familyId, familyName: familyName);
    }
    if (Get.isRegistered<NannyShellController>()) {
      Get.until((route) => route.isFirst);
      Get.find<NannyShellController>().goToTab(2);
    } else if (Get.isRegistered<FamilyShellController>()) {
      Get.until((route) => route.isFirst);
      Get.find<FamilyShellController>().goToTab(2);
    } else {
      Get.toNamed(Routes.chat);
    }
    if (familyId.isNotEmpty && Get.isRegistered<ChatController>()) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<ChatController>()) {
          Get.find<ChatController>().consumePendingOpen();
        }
      });
    }
  }

  static Future<void> toggleShortlist(NannyCardModel card) async {
    if (!Get.isRegistered<ShortlistController>()) {
      Get.put(ShortlistController());
    }
    final sl = Get.find<ShortlistController>();
    final wasShortlisted = sl.isShortlisted(card.id);
    // Only confirm once the write succeeds; the controller surfaces any error.
    final ok = wasShortlisted
        ? await sl.removeFromShortlist(card.id)
        : await sl.addToShortlist(
            card.id,
            nannyName: card.name,
          );
    if (!ok) {
      if (!wasShortlisted && sl.isShortlisted(card.id)) {
        // Already shortlisted in memory — treat as success feedback.
        Get.snackbar(
          AppStrings.shortlistTitle.tr,
          AppStrings.shortlistAlreadyAdded.tr,
        );
      }
      return;
    }
    Get.snackbar(
      AppStrings.shortlistTitle.tr,
      wasShortlisted
          ? AppStrings.shortlistRemoved.tr
          : AppStrings.shortlistAdded.tr,
    );
  }

  static void openTrialOffer({required String nannyId, required String nannyName, String? threadId}) {
    Get.toNamed(
      Routes.trialOffer,
      arguments: {
        'nannyId': nannyId,
        'nannyName': nannyName,
        if (threadId != null) 'threadId': threadId,
      },
    );
  }

  /// Opens the full-screen intro video player for a nanny (Screen 16 perk).
  /// No-ops when [introVideoUrl] is missing.
  static void openIntroVideo({
    required String? introVideoUrl,
    String? nannyName,
  }) {
    final url = (introVideoUrl ?? '').trim();
    if (url.isEmpty) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        AppStrings.videoUnavailable.tr,
      );
      return;
    }
    Get.toNamed(
      Routes.videoPlayer,
      arguments: <String, dynamic>{
        'videoUrl': url,
        if (nannyName != null && nannyName.isNotEmpty) 'nannyName': nannyName,
      },
    );
  }

  /// Opens the full-size, pinch-to-zoom photo viewer for a nanny's profile
  /// gallery, starting at [initialIndex] (the thumbnail that was tapped).
  static void openNannyPhotoViewer({
    required List<String> photoUrls,
    int initialIndex = 0,
    String? nannyName,
  }) {
    if (photoUrls.isEmpty) return;
    Get.toNamed(
      Routes.nannyPhotoViewer,
      arguments: <String, dynamic>{
        'photoUrls': photoUrls,
        'initialIndex': initialIndex,
        if (nannyName != null && nannyName.isNotEmpty) 'nannyName': nannyName,
      },
    );
  }

  static void familyGoToTab(int index) {
    // Notifications / deep links must not open Browse while the first job is due.
    if (_familyFirstJobGated) {
      Get.offAllNamed(Routes.familyForm);
      return;
    }
    if (Get.isRegistered<FamilyShellController>()) {
      Get.find<FamilyShellController>().goToTab(index);
      return;
    }
    Get.offAllNamed(Routes.browse);
    if (Get.isRegistered<FamilyShellController>()) {
      Get.find<FamilyShellController>().goToTab(index);
    }
  }

  static void nannyGoToTab(int index) {
    if (Get.isRegistered<NannyShellController>()) {
      Get.find<NannyShellController>().goToTab(index);
      return;
    }
    Get.offAllNamed(Routes.nannyHome);
    if (Get.isRegistered<NannyShellController>()) {
      Get.find<NannyShellController>().goToTab(index);
    }
  }

  /// Confirm then clear the session and return to Welcome. Used from nanny
  /// onboarding / pending headers so a stuck draft profile isn't locked in.
  static Future<void> confirmSignOut() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppStrings.settingsLogoutConfirm.tr,
            style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900)),
        content: Text(AppStrings.settingsLogoutConfirmSub.tr,
            style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(AppStrings.cancel.tr,
                style: KafiTheme.nunito(12, color: KafiColors.ts, w: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.settingsLogout.tr,
                style: KafiTheme.nunito(12, color: KafiColors.redD, w: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().signOut();
    }
    Get.offAllNamed(Routes.welcome);
  }
}
