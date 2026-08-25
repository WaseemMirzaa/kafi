import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/hire_model.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
import 'package:kafi_app/views/shared/rate_app_dialog.dart';
import 'package:uuid/uuid.dart';

/// Chat controller per Technical Architecture §3.6
/// Implements subscription-gated messaging and lockdown behavior.
class ChatController extends GetxController {
  final IChatService _chat = Get.find<IChatService>();
  final AuthController _auth = Get.find<AuthController>();
  final SubscriptionController _subs = Get.find<SubscriptionController>();
  final IUserService _user = Get.find<IUserService>();
  final IHireService _hire = Get.find<IHireService>();
  final _uuid = const Uuid();

  final RxList<ChatThread> threads = <ChatThread>[].obs;

  /// Active hires for the current user, keyed by the *counterparty* id (the
  /// nanny's id when a family is signed in, the family's id when a nanny is).
  /// Drives the "Hired" badge on the chat list and conversation header.
  final RxMap<String, HireModel> _activeHires = <String, HireModel>{}.obs;

  /// The active hire tied to this thread, if the two parties are in an ongoing
  /// employment relationship. Null when there is no active hire.
  HireModel? activeHireFor(ChatThread t) =>
      _activeHires[isNanny ? t.familyId : t.nannyId];

  /// Ends the active hire on [t] — the family terminates, the nanny resigns
  /// (role-aware reason). Refreshes so the "Hired" badge clears. The caller
  /// (chat header) confirms first.
  Future<void> endActiveHire(ChatThread t) async {
    final hire = activeHireFor(t);
    if (hire == null) return;
    try {
      await _hire.endHire(
        hire.id,
        reason: isNanny ? HireEndReason.resigned : HireEndReason.terminated,
      );
      await refreshThreads();
      Get.snackbar(
        AppStrings.successTitle.tr,
        isNanny ? AppStrings.hireResignedToast.tr : AppStrings.hireEndedToast.tr,
      );
      // Peer reviews were retired — invite the user to rate the app instead.
      await RateAppPrompt.maybeShow();
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxString activeThreadId = ''.obs;
  final inputCtrl = TextEditingController();
  final RxBool isLoading = false.obs;
  /// True while the open conversation's initial message fetch is in flight.
  /// Drives a single list-level loader (not per-bubble spinners).
  final RxBool isLoadingMessages = false.obs;
  final RxBool isLocked = false.obs;
  final RxnString threadsError = RxnString();

  // Live Firestore subscriptions — threads list + the open thread's messages.
  StreamSubscription<List<ChatThread>>? _threadsSub;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  Worker? _authWorker;
  bool _pickingImage = false;

  String? _pendingThreadId;
  String? _pendingNannyId;
  String? _pendingNannyName;
  String? _pendingFamilyId;
  String? _pendingFamilyName;

  /// Bumped whenever [setPendingOpen] queues a deep-link so an already-mounted
  /// [ChatScreen] can react (tab switches alone do not re-run initState).
  final RxInt pendingOpenTick = 0.obs;

  /// Unread total last acknowledged when the Messages tab / chat list was opened.
  /// Bottom-nav badge = current unread minus this baseline (new messages only).
  final RxInt _navUnreadBaseline = 0.obs;

  /// Role-aware unread across all threads (family sees `unreadCount.family`).
  int get totalUnreadCount {
    var n = 0;
    for (final t in threads) {
      n += isNanny ? t.unreadCount.nanny : t.unreadCount.family;
    }
    return n;
  }

  /// Count shown on the shell Messages tab. Clears when [onMessagesTabOpened]
  /// runs; returns again only for unread that arrive after that visit.
  int get navMessageBadgeCount {
    // Read Rx so Obx rebuilds when baseline is cleared or threads update.
    final baseline = _navUnreadBaseline.value;
    final total = totalUnreadCount;
    final badge = total - (baseline > total ? total : baseline);
    return badge > 0 ? badge : 0;
  }

  /// Call when the Messages tab (or standalone chat list) becomes visible.
  void onMessagesTabOpened() {
    _navUnreadBaseline.value = totalUnreadCount;
  }

  void setPendingOpen({
    String? threadId,
    String? nannyId,
    String? nannyName,
    String? familyId,
    String? familyName,
  }) {
    if (threadId != null && threadId.isNotEmpty) _pendingThreadId = threadId;
    if (nannyId != null && nannyId.isNotEmpty) _pendingNannyId = nannyId;
    _pendingNannyName = nannyName;
    if (familyId != null && familyId.isNotEmpty) _pendingFamilyId = familyId;
    _pendingFamilyName = familyName;
    pendingOpenTick.value++;
  }

  Future<void> consumePendingOpen() async {
    try {
      if (_pendingThreadId != null) {
        final id = _pendingThreadId!;
        _pendingThreadId = null;
        await openThread(id);
        return;
      }
      if (_pendingFamilyId != null) {
        final id = _pendingFamilyId!;
        final name = _pendingFamilyName;
        _pendingFamilyId = null;
        _pendingFamilyName = null;
        await openThreadForFamily(familyId: id, familyName: name);
        return;
      }
      if (_pendingNannyId != null) {
        final id = _pendingNannyId!;
        final name = _pendingNannyName;
        _pendingNannyId = null;
        _pendingNannyName = null;
        await openThreadForNanny(nannyId: id, nannyName: name);
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }

  bool get isSubscriptionExpired => _subs.isExpired;
  bool get isSubscribed => _subs.isSubscribed;
  bool get isNanny => _auth.currentUser.value?.isNanny ?? false;
  bool get _skipSubscriptionGates => AppConfig.subscriptionUsesMock;

  /// Per docs §3.6 & §Subscription Lockdown:
  /// - Nanny users: always see all threads
  /// - Family with active subscription: see all threads
  /// All threads are visible regardless of subscription state — expired
  /// families still see their history (so they understand what's locked).
  /// Opening a thread without an active trial is gated by `openThread`,
  /// which redirects to the paywall.
  List<ChatThread> get visibleThreads => threads;

  @override
  void onInit() {
    super.onInit();
    _authWorker = ever<dynamic>(_auth.currentUser, (_) => refreshThreads());
    refreshThreads();
    // Transfer notification deep-link queued before this controller existed.
    if (Get.isRegistered<NotificationController>()) {
      final n = Get.find<NotificationController>();
      if (n.pendingChatThreadId != null ||
          n.pendingChatNannyId != null ||
          n.pendingChatFamilyId != null) {
        setPendingOpen(
          threadId: n.pendingChatThreadId,
          nannyId: n.pendingChatNannyId,
          familyId: n.pendingChatFamilyId,
        );
        n.clearPendingChatOpen();
      }
    }
    ever(_subs.isLocked, (locked) {
      if (locked) {
        onSubscriptionLocked();
      } else {
        onSubscriptionRestored();
      }
    });
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    _messagesSub?.cancel();
    _threadsSub?.cancel();
    inputCtrl.dispose();
    super.onClose();
  }

  Future<void> _syncFirestoreEntitlementsIfNeeded() async {
    if (!AppConfig.subscriptionUsesMock) return;
    final familyId = currentFamilyId(_auth);
    if (familyId == null) return;
    final subs = Get.find<ISubscriptionService>();
    if (subs is MockSubscriptionService) {
      await subs.syncEntitlementsToFirestore(familyId);
    }
  }

  /// Binds the thread list to a live Firestore stream (new messages, unread
  /// counts and trial links update without a manual refresh). Completes after
  /// the first snapshot so callers that then open a thread see it populated.
  Future<void> refreshThreads() async {
    final id = currentUserId(_auth);
    if (id == null) {
      threads.clear();
      threadsError.value = null;
      return;
    }
    isLoading.value = true;
    threadsError.value = null;
    await _syncFirestoreEntitlementsIfNeeded();
    await _loadActiveHires(id);
    try {
      threads.value = await _chat.listThreads(id);
    } catch (_) {
      // Keep the stream path as the source of truth; this is only a bootstrap fallback.
    }
    await _threadsSub?.cancel();
    final first = Completer<void>();
    void done([Object? error]) {
      isLoading.value = false;
      if (error != null) {
        threadsError.value = error.toString();
      }
      if (!first.isCompleted) first.complete();
    }

    _threadsSub = _chat.watchThreads(id).listen((list) {
      threads.value = _reconcileTerminalTrialBadges(list);
      threadsError.value = null;
      done();
    }, onError: (e) => done(e));
    await first.future;
  }

  /// If a thread still has accepted/active [ChatThread.trialStatus] but the
  /// linked trial is already cancelled/completed/declined (or payment confirmed),
  /// clear the badge locally and heal the thread doc.
  List<ChatThread> _reconcileTerminalTrialBadges(List<ChatThread> list) {
    if (!Get.isRegistered<TrialController>()) return list;
    final byId = {
      for (final t in Get.find<TrialController>().all) t.id: t,
    };
    if (byId.isEmpty) return list;
    return list.map((th) {
      final tid = th.trialId;
      if (tid == null || tid.isEmpty || !th.hasActiveTrial) return th;
      final trial = byId[tid];
      if (trial == null) return th;
      final ended = !trial.isLiveTrial;
      if (!ended) return th;
      final status = trial.nannyConfirmedPayment || trial.paymentIssueReported
          ? TrialStatus.completed.name
          : trial.status.name;
      _chat.linkTrialToThread(th.id, tid, trialStatus: status).ignore();
      return th.copyWith(trialStatus: status);
    }).toList();
  }

  /// Whether chat list / conversation should show the active-trial bar & badges.
  /// Uses live [TrialController] when available so cancel / complete / payment
  /// confirmed hide the UI even if [ChatThread.trialStatus] is briefly stale.
  bool showsActiveTrialUi(ChatThread t) {
    final tid = t.trialId;
    if (tid == null || tid.isEmpty) return false;
    if (Get.isRegistered<TrialController>()) {
      final trial =
          Get.find<TrialController>().all.firstWhereOrNull((x) => x.id == tid);
      if (trial != null) {
        return trial.isLiveTrial;
      }
    }
    return t.hasActiveTrial;
  }

  /// Loads the current user's active hires into [_activeHires], keyed by the
  /// counterparty id. Non-fatal — a failure just means no "Hired" badge shows.
  Future<void> _loadActiveHires(String id) async {
    try {
      final hires =
          isNanny ? await _hire.getHiresForNanny(id) : await _hire.getHiresForFamily(id);
      final map = <String, HireModel>{};
      for (final h in hires.where((h) => h.isActive)) {
        map[isNanny ? h.familyId : h.nannyId] = h;
      }
      _activeHires.assignAll(map);
    } catch (_) {
      // Leave any prior map in place; badges degrade gracefully.
    }
  }

  /// Per docs: Family must have active subscription OR thread has active trial
  /// to open a chat thread. Otherwise redirect to paywall.
  void closeThread() {
    _messagesSub?.cancel();
    _messagesSub = null;
    activeThreadId.value = '';
    isLoadingMessages.value = false;
    messages.clear();
    inputCtrl.clear();
  }

  ChatThread? get activeThread {
    if (activeThreadId.value.isEmpty) return null;
    return threads.firstWhereOrNull((t) => t.id == activeThreadId.value);
  }

  /// Reveal the chatting nanny's real phone so the family can call or WhatsApp
  /// directly from the conversation. Entitlement (active subscription / trial /
  /// spent free-contact) is enforced server-side by the onContactRevealRequested
  /// function; returns null when there's no open thread or the reveal is denied.
  Future<String?> revealActiveNannyPhone() async {
    final thread = activeThread;
    if (thread == null) return null;
    return _user.revealContact(thread.familyId, thread.nannyId);
  }

  Future<void> openThread(String threadId) async {
    if (!_skipSubscriptionGates && !isNanny && _subs.isExpired) {
      final thread = threads.firstWhereOrNull((t) => t.id == threadId);
      if (thread == null || !thread.hasActiveTrial) {
        Get.toNamed(Routes.pricing, arguments: {
          'reason': 'chat_locked',
          'returnTo': '/chat/$threadId',
        });
        return;
      }
    }
    activeThreadId.value = threadId;
    messages.clear();
    isLoadingMessages.value = true;
    try {
      messages.value = await _chat.loadMessages(threadId);
      // Prefetch trials so offer bubbles render full §3.7 details (duration,
      // rate, type, location) — not title-only when the list query is stale.
      if (Get.isRegistered<TrialController>()) {
        final trialCtrl = Get.find<TrialController>();
        await trialCtrl.refreshAll();
        for (final m in messages) {
          final tid = m.trialOfferId;
          if (tid != null) await trialCtrl.ensureTrialInList(tid);
        }
      }
    } catch (_) {
      // The stream below remains the live source of truth.
    } finally {
      isLoadingMessages.value = false;
    }
    await _messagesSub?.cancel();
    _messagesSub = _chat.watchMessages(threadId).listen((serverMsgs) {
      // Keep any optimistic messages the stream hasn't caught up to yet, so a
      // just-sent message never blinks out before the server round-trip.
      final serverIds = serverMsgs.map((m) => m.id).toSet();
      final pending = messages.where((m) => !serverIds.contains(m.id)).toList();
      messages.value = [...serverMsgs, ...pending];
      // Live counter / accept / decline from the other party — refresh trials so
      // family Accept/Decline buttons see TrialStatus.countered immediately.
      final newest = serverMsgs.isEmpty ? null : serverMsgs.last;
      if (newest != null &&
          Get.isRegistered<TrialController>() &&
          (newest.type == MessageType.trialCountered ||
              newest.type == MessageType.trialAccepted ||
              newest.type == MessageType.trialDeclined)) {
        Get.find<TrialController>().refreshAll();
      }
    }, onError: (_) {});
    try {
      await markAsRead(threadId);
    } catch (_) {
      // Read failures should not block opening the conversation in dev mode.
    }
  }

  /// Finds (or creates) and opens the family↔nanny thread by nanny id.
  /// Used by shortlist, browse, and notification deeplinks that pass
  /// `nannyId` instead of an explicit `threadId`.
  Future<void> openThreadForNanny({required String nannyId, String? nannyName}) async {
    final familyId = currentUserId(_auth);
    if (familyId == null) return;
    final existing = threads.firstWhereOrNull((t) => t.nannyId == nannyId);
    if (existing != null) {
      await openThread(existing.id);
      return;
    }
    // Don't auto-create for free-tier families on expired sub (no contacts).
    if (!_skipSubscriptionGates && !isNanny && _subs.isExpired) {
      Get.toNamed(Routes.pricing, arguments: {'reason': 'chat_locked'});
      return;
    }
    // Free-tier families (never subscribed) can only message a nanny *after*
    // they've consumed a profile view for that nanny — per §8.4 (free contact
    // matrix). Subscribed and grace-period users skip this check.
    if (!_skipSubscriptionGates &&
        !isNanny &&
        _subs.state.value == SubscriptionState.free &&
        !_subs.viewedNannyIds.contains(nannyId)) {
      Get.toNamed(Routes.pricing,
          arguments: {'reason': 'chat_view_required', 'nannyId': nannyId});
      return;
    }
    try {
      await _syncFirestoreEntitlementsIfNeeded();
      final thread = await _chat.findOrCreateThread(
        familyId: familyId,
        nannyId: nannyId,
        nannyName: nannyName,
        familyName: _auth.currentUser.value?.fullName,
      );
      await refreshThreads();
      await openThread(thread.id);
    } catch (e) {
      final msg = e.toString().contains('permission-denied')
          ? AppStrings.chatUnavailable.tr
          : e.toString();
      Get.snackbar(AppStrings.errorTitle.tr, msg);
    }
  }

  /// Nanny-side counterpart to [openThreadForNanny]: finds (or creates) and
  /// opens the thread with the counterparty **family** ([familyId]). Resolving
  /// by familyId — never the nanny's own id — is what stops a nanny engaged
  /// with several families from landing in the wrong conversation. Nannies are
  /// never subscription-gated.
  Future<void> openThreadForFamily({required String familyId, String? familyName}) async {
    final me = _auth.currentUser.value;
    if (me == null || familyId.isEmpty) return;
    final existing = threads.firstWhereOrNull((t) => t.familyId == familyId);
    if (existing != null) {
      await openThread(existing.id);
      return;
    }
    try {
      final thread = await _chat.findOrCreateThread(
        familyId: familyId,
        nannyId: me.id,
        nannyName: me.fullName,
        familyName: familyName,
      );
      await refreshThreads();
      await openThread(thread.id);
    } catch (e) {
      final msg = e.toString().contains('permission-denied')
          ? AppStrings.chatUnavailable.tr
          : e.toString();
      Get.snackbar(AppStrings.errorTitle.tr, msg);
    }
  }

  /// Per docs: Family with expired subscription cannot send messages
  /// unless thread has an active trial.
  Future<void> sendCurrent() async {
    if (inputCtrl.text.trim().isEmpty || activeThreadId.value.isEmpty) return;

    final senderId = _auth.currentUser.value?.id;
    if (senderId == null || senderId.isEmpty) return;

    final thread = threads.firstWhereOrNull((t) => t.id == activeThreadId.value);
    final senderType = thread?.senderTypeFor(senderId) ?? (isNanny ? 'nanny' : 'family');
    final sendingAsFamily = senderType == 'family';

    // Check family subscription status before sending
    if (!_skipSubscriptionGates && sendingAsFamily) {
      if (_subs.isExpired && !(thread?.hasActiveTrial ?? false)) {
        Get.snackbar(AppStrings.subscriptionRequired.tr, AppStrings.renewToSendMessages.tr);
        return;
      }
    }

    final msg = ChatMessage(
      id: _uuid.v4(),
      threadId: activeThreadId.value,
      senderId: senderId,
      senderType: senderType,
      content: inputCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    messages.add(msg);
    inputCtrl.clear();
    try {
      if (sendingAsFamily) await _syncFirestoreEntitlementsIfNeeded();
      await _chat.sendMessage(activeThreadId.value, msg);
    } catch (e) {
      messages.removeWhere((m) => m.id == msg.id);
      inputCtrl.text = msg.content;
      final text = e.toString().contains('permission-denied')
          ? AppStrings.chatUnavailable.tr
          : e.toString();
      Get.snackbar(AppStrings.errorTitle.tr, text);
    }
  }

  Future<void> sendImage() async {
    if (activeThreadId.value.isEmpty || _pickingImage) return;

    final senderId = _auth.currentUser.value?.id;
    if (senderId == null || senderId.isEmpty) return;

    final thread = threads.firstWhereOrNull((t) => t.id == activeThreadId.value);
    final senderType = thread?.senderTypeFor(senderId) ?? (isNanny ? 'nanny' : 'family');
    final sendingAsFamily = senderType == 'family';

    if (!_skipSubscriptionGates && sendingAsFamily) {
      if (_subs.isExpired && !(thread?.hasActiveTrial ?? false)) {
        Get.snackbar(AppStrings.subscriptionRequired.tr, AppStrings.renewToSendImages.tr);
        return;
      }
    }

    if (!await Get.find<PermissionController>().ensureGallery()) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.permissionGalleryDenied.tr);
      return;
    }

    _pickingImage = true;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final storage = Get.find<IStorageService>();
      final url = await storage.uploadBytes(
        path: 'chats/${activeThreadId.value}/$senderId/${_uuid.v4()}.jpg',
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      final msg = ChatMessage(
        id: _uuid.v4(),
        threadId: activeThreadId.value,
        senderId: senderId,
        senderType: senderType,
        content: AppStrings.chatImagePreview.tr,
        createdAt: DateTime.now(),
        type: MessageType.image,
        attachments: [
          Attachment(type: 'image', url: url, name: 'image.jpg'),
        ],
      );
      messages.add(msg);
      try {
        if (sendingAsFamily) await _syncFirestoreEntitlementsIfNeeded();
        await _chat.sendMessage(activeThreadId.value, msg);
      } catch (e) {
        messages.removeWhere((m) => m.id == msg.id);
        final text = e.toString().contains('permission-denied')
            ? AppStrings.chatUnavailable.tr
            : e.toString();
        Get.snackbar(AppStrings.errorTitle.tr, text);
      }
    } finally {
      _pickingImage = false;
    }
  }

  Future<void> markAsRead(String threadId) async {
    final idx = threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      threads[idx] = threads[idx].copyWith(unreadCount: const UnreadCount());
    }
    final uid = _auth.currentUser.value?.id;
    final thread = idx >= 0 ? threads[idx] : threads.firstWhereOrNull((t) => t.id == threadId);
    final role = (uid != null ? thread?.senderTypeFor(uid) : null) ?? (isNanny ? 'nanny' : 'family');
    await _chat.markThreadRead(threadId, role);
  }

  /// Called by SubscriptionController._applyLockdown()
  ///
  /// Per System Spec §8.5 (Subscription lockdown bypass): when an expired
  /// family has an active trial, the corresponding chat must stay open. So
  /// we only force-close the active thread when it does NOT have an active
  /// trial linked to it.
  void onSubscriptionLocked() {
    if (_skipSubscriptionGates) return;
    isLocked.value = true;
    final open = activeThread;
    if (open == null || !open.hasActiveTrial) {
      _messagesSub?.cancel();
      _messagesSub = null;
      activeThreadId.value = '';
      messages.clear();
    }
  }

  /// Called when re-subscription succeeds
  void onSubscriptionRestored() {
    isLocked.value = false;
    refreshThreads();
  }
}
