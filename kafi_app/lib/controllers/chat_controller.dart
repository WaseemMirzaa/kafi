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
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/hire_model.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
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
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxString activeThreadId = ''.obs;
  final inputCtrl = TextEditingController();
  final RxBool isLoading = false.obs;
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

  void setPendingOpen({String? threadId, String? nannyId, String? nannyName}) {
    if (threadId != null && threadId.isNotEmpty) _pendingThreadId = threadId;
    if (nannyId != null && nannyId.isNotEmpty) _pendingNannyId = nannyId;
    _pendingNannyName = nannyName;
  }

  Future<void> consumePendingOpen() async {
    try {
      if (_pendingThreadId != null) {
        final id = _pendingThreadId!;
        _pendingThreadId = null;
        await openThread(id);
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
      if (n.pendingChatThreadId != null || n.pendingChatNannyId != null) {
        setPendingOpen(
          threadId: n.pendingChatThreadId,
          nannyId: n.pendingChatNannyId,
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
      threads.value = list;
      threadsError.value = null;
      done();
    }, onError: (e) => done(e));
    await first.future;
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
    try {
      messages.value = await _chat.loadMessages(threadId);
    } catch (_) {
      // The stream below remains the live source of truth.
    }
    await _messagesSub?.cancel();
    _messagesSub = _chat.watchMessages(threadId).listen((serverMsgs) {
      // Keep any optimistic messages the stream hasn't caught up to yet, so a
      // just-sent message never blinks out before the server round-trip.
      final serverIds = serverMsgs.map((m) => m.id).toSet();
      final pending = messages.where((m) => !serverIds.contains(m.id)).toList();
      messages.value = [...serverMsgs, ...pending];
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

  /// Per docs: Family with expired subscription cannot send messages
  /// unless thread has an active trial.
  Future<void> sendCurrent() async {
    if (inputCtrl.text.trim().isEmpty || activeThreadId.value.isEmpty) return;

    // Check family subscription status before sending
    if (!_skipSubscriptionGates && !isNanny) {
      final thread = threads.firstWhereOrNull((t) => t.id == activeThreadId.value);
      if (_subs.isExpired && !(thread?.hasActiveTrial ?? false)) {
        Get.snackbar('Subscription Required', 'Renew to send messages');
        return;
      }
    }

    final senderId = _auth.currentUser.value?.id ?? 'family';
    final senderType = isNanny ? 'nanny' : 'family';
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
      await _syncFirestoreEntitlementsIfNeeded();
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

    if (!_skipSubscriptionGates && !isNanny) {
      final thread = threads.firstWhereOrNull((t) => t.id == activeThreadId.value);
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
      final userId = _auth.currentUser.value?.id ?? 'user';
      final storage = Get.find<IStorageService>();
      final url = await storage.uploadBytes(
        path: 'chats/${activeThreadId.value}/$userId/${_uuid.v4()}.jpg',
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      final senderId = _auth.currentUser.value?.id ?? userId;
      final senderType = isNanny ? 'nanny' : 'family';
      final msg = ChatMessage(
        id: _uuid.v4(),
        threadId: activeThreadId.value,
        senderId: senderId,
        senderType: senderType,
        content: '[image]',
        createdAt: DateTime.now(),
        type: MessageType.image,
        attachments: [
          Attachment(type: 'image', url: url, name: 'image.jpg'),
        ],
      );
      messages.add(msg);
      try {
        await _syncFirestoreEntitlementsIfNeeded();
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

  Future<void> sendTrialOffer(Map<String, dynamic> offerData) async {
    if (!_skipSubscriptionGates && !isNanny && _subs.isExpired) {
      Get.snackbar('Subscription Required', 'Renew to send trial offers');
      return;
    }
    final senderId = _auth.currentUser.value?.id ?? 'family';
    final senderType = isNanny ? 'nanny' : 'family';
    final msg = ChatMessage(
      id: _uuid.v4(),
      threadId: activeThreadId.value,
      senderId: senderId,
      senderType: senderType,
      content: 'Trial offer sent',
      createdAt: DateTime.now(),
      type: MessageType.trialOffer,
    );
    messages.add(msg);
    await _chat.sendMessage(activeThreadId.value, msg);
  }

  Future<void> markAsRead(String threadId) async {
    final idx = threads.indexWhere((t) => t.id == threadId);
    if (idx >= 0) {
      threads[idx] = threads[idx].copyWith(unreadCount: const UnreadCount());
    }
    final role = isNanny ? 'nanny' : 'family';
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
