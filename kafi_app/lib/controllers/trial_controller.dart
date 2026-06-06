import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
import 'package:uuid/uuid.dart';

class TrialController extends GetxController {
  final ITrialService _trials = Get.find<ITrialService>();
  final IChatService _chat = Get.find<IChatService>();
  final AuthController _auth = Get.find<AuthController>();
  final IDisputeService _disputes = Get.find<IDisputeService>();
  final _uuid = const Uuid();

  final Rx<TrialModel?> active = Rx<TrialModel?>(null);
  /// When opened via notification/deep-link with a specific `trialId`.
  final Rx<TrialModel?> selected = Rx<TrialModel?>(null);
  final RxList<TrialModel> all = <TrialModel>[].obs;

  /// Trial shown on Screen 18 — deep-linked trial wins over `active`.
  TrialModel? get displayed => selected.value ?? active.value;
  final RxBool isLoading = false.obs;

  final RxInt durationDays = 7.obs;
  final RxInt dailyRate = 150.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final RxString trialType = 'live-in'.obs;
  final RxString notes = ''.obs;
  final RxString location = 'Dubai Marina'.obs;
  final RxBool paymentAcknowledged = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  @override
  void onReady() {
    super.onReady();
    final args = Get.arguments;
    if (args is Map && args['trialId'] is String) {
      openTrialById(args['trialId'] as String);
    }
  }

  Future<void> openTrialById(String trialId) async {
    final t = await getTrial(trialId);
    selected.value = t;
  }

  Future<void> refreshAll() async {
    final familyId = currentFamilyId(_auth);
    final nannyId = _auth.currentUser.value?.isNanny == true ? currentUserId(_auth) : null;
    if (familyId != null) {
      all.value = await _trials.listTrials(familyId);
      active.value = await _trials.activeTrial(familyId);
    } else if (nannyId != null) {
      all.value = await _trials.listTrialsForNanny(nannyId);
      TrialModel? act;
      for (final t in all) {
        if (t.isActive) {
          act = t;
          break;
        }
      }
      active.value = act;
    }
  }

  Future<TrialModel?> getTrial(String trialId) => _trials.getTrial(trialId);

  bool get canSendOffer {
    final subs = Get.find<SubscriptionController>();
    return subs.hasActiveAccess && paymentAcknowledged.value && dailyRate.value > 0;
  }

  /// Family sends trial offer → trial record + chat bubble (HTML + §6.5).
  Future<bool> sendTrialOffer({
    required String nannyId,
    required String nannyName,
    String? threadId,
  }) async {
    final subs = Get.find<SubscriptionController>();
    if (!subs.hasActiveAccess) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.trialOfferSubRequired.tr);
      return false;
    }
    if (!paymentAcknowledged.value) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.trialOfferAckRequired.tr);
      return false;
    }

    final familyId = currentFamilyId(_auth);
    if (familyId == null) return false;

    // Guard: no duplicate offer for the same nanny while one is active/pending/countered/accepted.
    final blocked = all.any((t) =>
        t.nannyId == nannyId &&
        const {TrialStatus.pending, TrialStatus.countered, TrialStatus.accepted, TrialStatus.active}
            .contains(t.status));
    if (blocked) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.trialAlreadyActive.tr);
      return false;
    }

    isLoading.value = true;
    try {
      final trialId = 'trial_${_uuid.v4()}';
      final start = startDate.value ?? DateTime.now().add(const Duration(days: 1));
      final trial = TrialModel(
        id: trialId,
        familyId: familyId,
        nannyId: nannyId,
        durationDays: durationDays.value,
        dailyRate: dailyRate.value,
        startDate: start,
        trialType: trialType.value,
        location: location.value,
        notes: notes.value.isEmpty ? null : notes.value,
        status: TrialStatus.pending,
        offeredAt: DateTime.now(),
      );

      await _trials.sendOffer(trial);

      ChatThread thread;
      if (threadId != null) {
        final list = await _chat.listThreads(familyId);
        thread = list.firstWhereOrNull((t) => t.id == threadId) ??
            await _chat.findOrCreateThread(
              familyId: familyId,
              nannyId: nannyId,
              nannyName: nannyName,
              familyName: _auth.currentUser.value?.fullName,
            );
      } else {
        thread = await _chat.findOrCreateThread(
          familyId: familyId,
          nannyId: nannyId,
          nannyName: nannyName,
          familyName: _auth.currentUser.value?.fullName,
        );
      }

      await _chat.linkTrialToThread(
        thread.id,
        trialId,
        lastMessage: '🤝 Trial offer sent',
        trialStatus: 'pending',
      );

      final familyUserId = currentUserId(_auth) ?? familyId;
      final msg = ChatMessage(
        id: _uuid.v4(),
        threadId: thread.id,
        senderId: familyUserId,
        senderType: 'family',
        content: AppStrings.trialOfferBubbleSent.tr,
        createdAt: DateTime.now(),
        type: MessageType.trialOffer,
        trialOfferId: trialId,
      );
      await _chat.sendMessage(thread.id, msg);

      if (Get.isRegistered<ChatController>()) {
        final chatCtrl = Get.find<ChatController>();
        if (chatCtrl.activeThreadId.value == thread.id) {
          chatCtrl.messages.add(msg);
        }
        await chatCtrl.refreshThreads();
      }

      _resetForm();
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialOfferSentSuccess.tr);
      return true;
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptTrial(String trialId, {String? threadId}) async {
    isLoading.value = true;
    try {
      await _trials.respondAccept(trialId);
      // Auto-promote to ACTIVE if start date is today/past (per §6.5).
      final trial = await _trials.getTrial(trialId);
      String threadStatus = 'accepted';
      if (trial != null && !trial.startDate.isAfter(DateTime.now())) {
        await _trials.recordOutcome(trialId, TrialStatus.active);
        threadStatus = 'active';
      }
      await _postTrialResponseMessage(
        trialId: trialId,
        threadId: threadId,
        type: MessageType.trialAccepted,
        content: AppStrings.trialAcceptedMessage.tr,
      );
      await refreshAll();
      // Persist the *actual* post-accept status so chat bypass logic and the
      // bubble status chip stay consistent with the trial doc.
      _updateThreadTrialStatus(threadId, threadStatus);
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialAcceptedToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Family accepts nanny's counter offer.
  Future<void> acceptCounter(String trialId, {String? threadId}) async {
    isLoading.value = true;
    try {
      final trial = await _trials.getTrial(trialId);
      if (trial?.counterOffer == null) return;
      final counter = trial!.counterOffer!;
      // Apply counter terms (rate/duration/start) AND mark accepted.
      await _trials.applyCounterAndAccept(trialId, counter);
      await _postTrialResponseMessage(
        trialId: trialId,
        threadId: threadId,
        type: MessageType.trialAccepted,
        content: AppStrings.trialCounterAccepted.trParams({'rate': '${counter.dailyRate}'}),
      );
      await refreshAll();
      _updateThreadTrialStatus(threadId, 'accepted');
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Family declines nanny's counter offer.
  Future<void> declineCounter(String trialId, {String? threadId}) async {
    isLoading.value = true;
    try {
      await _trials.recordOutcome(trialId, TrialStatus.declined);
      await _postTrialResponseMessage(
        trialId: trialId,
        threadId: threadId,
        type: MessageType.trialDeclined,
        content: AppStrings.trialCounterDeclined.tr,
      );
      await refreshAll();
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void _updateThreadTrialStatus(String? threadId, String trialStatus) {
    if (threadId == null) return;
    String? trialId;
    if (Get.isRegistered<ChatController>()) {
      final chatCtrl = Get.find<ChatController>();
      final idx = chatCtrl.threads.indexWhere((t) => t.id == threadId);
      if (idx >= 0) {
        trialId = chatCtrl.threads[idx].trialId;
        chatCtrl.threads[idx] = chatCtrl.threads[idx].copyWith(trialStatus: trialStatus);
      }
    }
    // Persist on the thread document so subscription bypass works on refresh.
    if (trialId != null && trialId.isNotEmpty) {
      _chat.linkTrialToThread(threadId, trialId, trialStatus: trialStatus);
    }
  }

  Future<void> declineTrial(String trialId, {String? threadId}) async {
    isLoading.value = true;
    try {
      await _trials.respondDecline(trialId);
      await _postTrialResponseMessage(
        trialId: trialId,
        threadId: threadId,
        type: MessageType.trialDeclined,
        content: AppStrings.trialDeclinedMessage.tr,
      );
      await refreshAll();
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> counterTrial(String trialId, {required int dailyRate, String? threadId}) async {
    isLoading.value = true;
    try {
      final trial = await _trials.getTrial(trialId);
      if (trial == null) return;
      await _trials.respondCounter(
        trialId,
        CounterOffer(
          dailyRate: dailyRate,
          startDate: trial.startDate,
          message: 'Counter offer',
          createdAt: DateTime.now(),
        ),
      );
      await _postTrialResponseMessage(
        trialId: trialId,
        threadId: threadId,
        type: MessageType.trialCountered,
        content: AppStrings.trialCounteredMessage.trParams({'rate': '$dailyRate'}),
      );
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialCounteredToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setOutcome(
    TrialStatus s, {
    TrialEvaluation? evaluation,
    String? outcomeLabel,
  }) async {
    final t = displayed;
    if (t == null) return;
    await _trials.recordOutcome(t.id, s,
        evaluation: evaluation, outcomeLabel: outcomeLabel);
    selected.value = null;
    await refreshAll();
  }

  Future<void> cancelTrial(String trialId, {String? reason}) async {
    isLoading.value = true;
    try {
      await _trials.cancelTrial(trialId, reason: reason);
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, 'Trial cancelled');
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmPaymentReceived(String trialId) async {
    isLoading.value = true;
    try {
      await _trials.confirmPaymentReceived(trialId);
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, 'Payment confirmed');
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reportPaymentIssue(String trialId, String description) async {
    isLoading.value = true;
    try {
      // Mark payment issue on the trial document
      await _trials.reportPaymentIssue(trialId, description);

      // Also write a `disputes` document so admin panel can action it
      final trial = all.firstWhereOrNull((t) => t.id == trialId);
      if (trial != null) {
        final uid = _auth.currentUser.value?.id ?? '';
        final reportedId = (_auth.currentUser.value?.isNanny ?? false) ? trial.familyId : trial.nannyId;
        await _disputes.fileDispute(
          reporterId: uid,
          reportedUserId: reportedId,
          category: DisputeCategory.payment,
          description: description,
          relatedTrialId: trialId,
        );
      }

      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, 'Issue reported');
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _postTrialResponseMessage({
    required String trialId,
    required MessageType type,
    required String content,
    String? threadId,
  }) async {
    final trial = await _trials.getTrial(trialId);
    if (trial == null) return;

    // Use the currently logged-in user to look up threads (works for both
    // family and nanny sides). `trial.nannyId` is the nanny CARD id, not a
    // user id, so passing it to `listThreads` would never resolve a thread.
    final lookupUserId = currentUserId(_auth) ?? trial.familyId;
    final threads = await _chat.listThreads(lookupUserId);
    final thread = threadId != null
        ? threads.firstWhereOrNull((t) => t.id == threadId)
        : threads.firstWhereOrNull(
            (t) => t.familyId == trial.familyId && t.nannyId == trial.nannyId,
          );
    if (thread == null) return;

    final senderId = currentUserId(_auth) ?? trial.nannyId;
    final msg = ChatMessage(
      id: _uuid.v4(),
      threadId: thread.id,
      senderId: senderId,
      senderType: _auth.currentUser.value?.isNanny == true ? 'nanny' : 'family',
      content: content,
      createdAt: DateTime.now(),
      type: type,
      trialOfferId: trialId,
    );
    await _chat.sendMessage(thread.id, msg);

    if (Get.isRegistered<ChatController>()) {
      final chatCtrl = Get.find<ChatController>();
      if (chatCtrl.activeThreadId.value == thread.id) {
        chatCtrl.messages.add(msg);
      }
      await chatCtrl.refreshThreads();
    }
  }

  void _resetForm() {
    durationDays.value = 7;
    dailyRate.value = 150;
    startDate.value = null;
    trialType.value = 'live-in';
    notes.value = '';
    paymentAcknowledged.value = false;
  }
}
