import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/family_shell_controller.dart';
import 'package:kafi_app/controllers/nanny_shell_controller.dart';
import 'package:kafi_app/controllers/shortlist_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_card_model.dart';

/// Shared navigation helpers for consistent flows across screens.
class AppNavigation {
  AppNavigation._();

  /// Safe "back" for header back buttons. Pops the current route when there is
  /// one to pop; otherwise (e.g. the screen was reached via [Get.offAllNamed],
  /// so the stack is empty) it falls back to the role-appropriate home instead
  /// of silently doing nothing. Behaves exactly like [Get.back] in the common
  /// case where a previous route exists.
  static void back() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
      return;
    }
    final user = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().currentUser.value
        : null;
    if (user == null) {
      Get.offAllNamed(Routes.welcome);
    } else if (user.isNanny) {
      Get.offAllNamed(Routes.nannyHome);
    } else {
      Get.offAllNamed(Routes.browse);
    }
  }

  static void openNotifications() => Get.toNamed(Routes.notifications);

  static void openNannyProfile(NannyCardModel card) {
    final subs = Get.find<SubscriptionController>();
    final wasViewed = subs.viewedNannyIds.contains(card.id);
    final String route;
    if (subs.isSubscribed) {
      route = Routes.profileUnlocked;
    } else if (subs.isExpired) {
      route = wasViewed ? Routes.profileRelocked : Routes.profileLocked;
    } else {
      route = Routes.profileLocked;
    }
    Get.toNamed(route, arguments: card);
  }

  static void openChat({String? nannyId, String? nannyName}) {
    // Queue the conversation so the Messages tab opens straight into the
    // thread (rather than the inbox) once it builds.
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
      Get.toNamed(Routes.chat, arguments: nannyId != null ? {'nannyId': nannyId} : null);
    }
  }

  static Future<void> toggleShortlist(NannyCardModel card) async {
    if (!Get.isRegistered<ShortlistController>()) {
      Get.put(ShortlistController());
    }
    final sl = Get.find<ShortlistController>();
    if (sl.isShortlisted(card.id)) {
      await sl.removeFromShortlist(card.id);
      Get.snackbar(AppStrings.shortlistTitle.tr, 'Removed from shortlist');
    } else {
      await sl.addToShortlist(card.id);
      Get.snackbar(AppStrings.shortlistTitle.tr, 'Added to shortlist');
    }
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

  static void mockContactAction(String channel) {
    Get.snackbar(channel, 'Contact action — production build');
  }

  static void familyGoToTab(int index) {
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
}
