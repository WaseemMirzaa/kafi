import 'dart:async';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/models/trial_outcome_reasons.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/validators.dart';
import 'package:kafi_app/views/shared/rate_app_dialog.dart';
import 'package:uuid/uuid.dart';

class TrialController extends GetxController {
  final ITrialService _trials = Get.find<ITrialService>();
  final IChatService _chat = Get.find<IChatService>();
  final AuthController _auth = Get.find<AuthController>();
  final IUserService _users = Get.find<IUserService>();
  final IHireService _hires = Get.find<IHireService>();
  final IApplicationService _apps = Get.find<IApplicationService>();
  final IStorageService _storage = Get.find<IStorageService>();
  final _uuid = const Uuid();

  /// Uploaded proof photos for the displayed trial, keyed by day index (1-based).
  final RxMap<int, DayProof> dayProofs = <int, DayProof>{}.obs;
  final RxBool isUploadingProof = false.obs;

  /// Real nanny cards for the loaded trials, keyed by nannyId — fetched from
  /// Firestore so the trial header shows the actual nanny, not seed data.
  final RxMap<String, NannyCardModel> nannyCards = <String, NannyCardModel>{}.obs;

  /// The real card for [nannyId]; a blank placeholder until the fetch resolves
  /// (never seed data).
  NannyCardModel nannyCardFor(String nannyId) =>
      nannyCards[nannyId] ??
      NannyCardModel(
        id: nannyId,
        initials: 'N',
        name: '',
        nationality: '',
        yearsExp: 0,
        jobType: 'Live-in',
        city: '',
        matchPercent: 0,
        tags: const [],
      );

  final Rx<TrialModel?> active = Rx<TrialModel?>(null);
  /// When opened via notification/deep-link with a specific `trialId`.
  final Rx<TrialModel?> selected = Rx<TrialModel?>(null);
  final RxList<TrialModel> all = <TrialModel>[].obs;

  /// The counterparty family's display name, resolved for the NANNY's view (the
  /// family already sees its own name via currentUser). Kept observable so the
  /// trial header updates when the async lookup lands.
  final RxnString familyDisplayName = RxnString();

  /// Trial shown on Screen 18 — deep-linked trial wins over `active`.
  TrialModel? get displayed => selected.value ?? active.value;
  final RxBool isLoading = false.obs;
  /// True while [onTrialRouteOpened] is refreshing / resolving a trialId.
  final RxBool isOpeningRoute = false.obs;

  final RxInt durationDays = 7.obs;
  // Starts at 0 so an offer can't be sent at a fabricated 150/day without the
  // family actually entering a rate (canSend requires dailyRate > 0) — CHT-5.
  final RxInt dailyRate = 0.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final RxString trialType = 'live-in'.obs;
  final RxString notes = ''.obs;
  /// Empty until the family picks (or we prefill from their job city).
  final RxString location = ''.obs;
  final RxBool paymentAcknowledged = false.obs;

  /// Sync form-field errors for Screen 31 (System Spec §14.4 V13–V15 + notes).
  /// Does not cover async T2/T3/T4 checks — those run in [validateTrialOffer].
  String? get trialOfferFormError {
    if (durationDays.value <= 0) return AppStrings.trialOfferDurationRequired;
    final rateErr = Validators.trialDailyRate(dailyRate.value);
    if (rateErr != null) return rateErr;
    final startErr = Validators.trialStartDate(startDate.value);
    if (startErr != null) return startErr;
    if (trialType.value != 'live-in' && trialType.value != 'live-out') {
      return AppStrings.trialOfferTypeRequired;
    }
    if (location.value.trim().isEmpty) return AppStrings.trialOfferLocationRequired;
    if (notes.value.length > FamilyConstants.maxTrialNotesLength) {
      return AppStrings.trialOfferNotesTooLong;
    }
    if (!paymentAcknowledged.value) return AppStrings.trialOfferAckRequired;
    return null;
  }

  bool get canSendOffer {
    final subs = Get.find<SubscriptionController>();
    return subs.hasActiveAccess && trialOfferFormError == null;
  }

  /// Full Screen 31 send gate: form fields + §14.6 T1–T4.
  Future<String?> validateTrialOffer({required String nannyId}) async {
    final subs = Get.find<SubscriptionController>();
    if (!subs.hasActiveAccess) return AppStrings.trialOfferSubRequired;

    final formErr = trialOfferFormError;
    if (formErr != null) return formErr;

    final familyId = currentFamilyId(_auth);
    if (familyId == null) return AppStrings.errorTitle;

    // Pick up cancel / payment-confirm / report from Firestore before gating.
    await refreshAll();

    // T4 — family already on a live accepted/active trial (not paid/cancelled/reported).
    if (all.any((t) => t.familyId == familyId && t.isLiveTrial)) {
      return AppStrings.trialOfferFamilyActive;
    }

    // T3 — nanny already on a live trial with anyone.
    if (all.any((t) => t.nannyId == nannyId && t.isLiveTrial)) {
      return AppStrings.trialOfferNannyOnTrial;
    }

    // Duplicate / pending offer with this nanny (pending/countered/accepted/active
    // unless payment confirmed, payment issue reported, or otherwise terminal).
    if (all.any((t) => t.nannyId == nannyId && t.blocksNewTrialOffer)) {
      return AppStrings.trialAlreadyActive;
    }

    // T2 — nanny must be approved (still in verification otherwise).
    try {
      final nanny = await _users.getNanny(nannyId);
      if (nanny == null || nanny.status != NannyOnboardingStatus.approved) {
        return AppStrings.trialOfferNannyUnverified;
      }
    } catch (_) {
      return AppStrings.trialOfferNannyUnverified;
    }

    return null;
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  /// Called every time Screen 19 is pushed so deep-links and chat "View trial"
  /// still resolve when [TrialController] was already alive (permanent).
  Future<void> onTrialRouteOpened(dynamic args) async {
    isOpeningRoute.value = true;
    try {
      await refreshAll();
      final id = args is Map ? args['trialId'] as String? : null;
      if (id != null && id.isNotEmpty) {
        await openTrialById(id);
        return;
      }
      // No explicit id — show the current accepted/active trial, not a stale selection.
      if (selected.value != null &&
          active.value != null &&
          selected.value!.id != active.value!.id &&
          !selected.value!.isAcceptedOrActive) {
        selected.value = null;
      }
      final d = displayed;
      _hydrateEvalDraft(d?.evaluation);
      _bindDisplayedTrialWatch(d?.id);
      if (d != null) await loadDayProofs(d.id);
    } finally {
      isOpeningRoute.value = false;
    }
  }

  Future<void> openTrialById(String trialId) async {
    var t = await getTrial(trialId);
    t ??= all.firstWhereOrNull((x) => x.id == trialId);
    selected.value = t;
    await _resolveFamilyName();
    // Seed the evaluation checklist from any already-recorded evaluation so the
    // family resumes where it left off (and switching trials never carries a
    // stale draft over).
    _hydrateEvalDraft(t?.evaluation);
    _bindDisplayedTrialWatch(t?.id);
    if (t != null) await loadDayProofs(t.id);
  }

  void _hydrateEvalDraft(TrialEvaluation? e) {
    evalDraft.value = {
      'childInteractionAndPatience': e?.childInteractionAndPatience ?? false,
      'punctualityAndReliability': e?.punctualityAndReliability ?? false,
      'followingInstructions': e?.followingInstructions ?? false,
      'communicationAndLanguage': e?.communicationAndLanguage ?? false,
      'cookingFamilyFood': e?.cookingFamilyFood ?? false,
      'honestyAndTrustworthiness': e?.honestyAndTrustworthiness ?? false,
    };
  }

  StreamSubscription<TrialModel?>? _displayedTrialSub;
  String? _watchedTrialId;

  /// Live-sync the on-screen trial so the nanny sees checklist ticks as the
  /// family saves them (and either side sees status/payment changes).
  void _bindDisplayedTrialWatch(String? trialId) {
    if (trialId == null || trialId.isEmpty) {
      _displayedTrialSub?.cancel();
      _displayedTrialSub = null;
      _watchedTrialId = null;
      return;
    }
    if (_watchedTrialId == trialId && _displayedTrialSub != null) return;
    _watchedTrialId = trialId;
    _displayedTrialSub?.cancel();
    _displayedTrialSub = _trials.watchTrial(trialId).listen(
      (t) {
        if (t == null) return;
        if (selected.value?.id == t.id) {
          selected.value = t;
        }
        if (active.value?.id == t.id) {
          active.value = t;
        }
        final idx = all.indexWhere((x) => x.id == t.id);
        if (idx >= 0) all[idx] = t;
        // Keep family's draft aligned with the persisted checklist (and update
        // the nanny's read-only view via [displayed].evaluation).
        _hydrateEvalDraft(t.evaluation);
      },
      onError: (e) => Get.log('watchTrial failed: $e', isError: true),
    );
  }

  @override
  void onClose() {
    _displayedTrialSub?.cancel();
    super.onClose();
  }

  /// Resolves the counterparty family's name for the nanny's trial view. The
  /// family viewer already sees its own name (currentUser), so this only runs
  /// for a nanny and reads the family profile by the displayed trial's familyId.
  Future<void> _resolveFamilyName() async {
    if (_auth.currentUser.value?.isNanny != true) {
      familyDisplayName.value = null;
      return;
    }
    final fid = displayed?.familyId;
    if (fid == null || fid.isEmpty) {
      familyDisplayName.value = null;
      return;
    }
    try {
      final fam = await _users.getFamily(fid);
      familyDisplayName.value = fam?.fullName;
    } catch (_) {
      // Non-critical — the header falls back to a neutral label.
      familyDisplayName.value = null;
    }
  }

  Future<void> refreshAll() async {
    final familyId = currentFamilyId(_auth);
    final nannyId = _auth.currentUser.value?.isNanny == true ? currentUserId(_auth) : null;
    if (familyId != null) {
      all.value = await _trials.listTrials(familyId);
      TrialModel? act;
      try {
        act = await _trials.activeTrial(familyId);
      } catch (e) {
        Get.log('activeTrial query failed: $e', isError: true);
      }
      // Fallback: derive from the already-loaded list so a missing composite
      // index or empty whereIn result never leaves Screen 19 blank while chat
      // still shows "Trial in progress".
      act ??= all.firstWhereOrNull((t) => t.isLiveTrial || t.isAwaitingOutcome);
      // Prefer a still-current trial even if the status query returned something
      // stale from cache; awaitingOutcome remains a valid destination too.
      if (act != null && !(act.isLiveTrial || act.isAwaitingOutcome)) {
        act = all.firstWhereOrNull((t) => t.isLiveTrial || t.isAwaitingOutcome);
      }
      active.value = act;
    } else if (nannyId != null) {
      try {
        all.value = await _trials.listTrialsForNanny(nannyId);
      } catch (e) {
        Get.log('listTrialsForNanny failed: $e', isError: true);
        // Keep prior [all]; chat bubbles still call ensureTrialInList by id.
      }
      // Match chat banner / family activeTrial: live accepted OR active.
      active.value = all.firstWhereOrNull((t) => t.isLiveTrial);
    }
    await _loadNannyCards();
    await _resolveFamilyName();
    final d = displayed;
    if (d != null) await loadDayProofs(d.id);
  }

  /// The current 1-based trial day (date-floored, clamped to the trial length).
  int currentTrialDay(TrialModel t) {
    final start = DateTime(t.startDate.year, t.startDate.month, t.startDate.day);
    final today = DateTime.now();
    final idx = today.difference(start).inDays + 1;
    return idx.clamp(1, t.durationDays);
  }

  Future<void> loadDayProofs(String trialId) async {
    try {
      final list = await _trials.listDayProofs(trialId);
      dayProofs.assignAll({for (final p in list) p.dayIndex: p});
    } catch (_) {
      // Non-fatal — the proof grid just shows empty slots.
    }
  }

  /// Nanny uploads (or replaces) her proof photo for [dayIndex] of [t].
  Future<void> uploadDayProof(TrialModel t, int dayIndex, ImageSource source) async {
    final permissions = Get.find<PermissionController>();
    final allowed = source == ImageSource.camera
        ? await permissions.requestCamera()
        : await permissions.ensureGallery();
    if (!allowed) return;

    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return;

    isUploadingProof.value = true;
    try {
      final nannyId = currentUserId(_auth) ?? t.nannyId;
      String url;
      if (AppConfig.useMock) {
        // Mock storage returns a local path; keep the picked file path so the
        // family view can render it with Image.file.
        url = picked.path;
      } else {
        final bytes = await picked.readAsBytes();
        url = await _storage.uploadBytes(
          path: 'trial_proofs/${t.id}/$nannyId/day_$dayIndex.jpg',
          bytes: bytes,
          contentType: 'image/jpeg',
        );
      }
      await _trials.saveDayProof(t.id, dayIndex, imageUrl: url, nannyId: nannyId);
      await loadDayProofs(t.id);
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialProofUploaded.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isUploadingProof.value = false;
    }
  }

  /// Fetches the real nanny doc for each loaded trial and builds a card.
  Future<void> _loadNannyCards() async {
    final ids = all.map((t) => t.nannyId).toSet();
    if (ids.isEmpty) return;
    final loaded = <String, NannyCardModel>{};
    await Future.wait(ids.map((id) async {
      try {
        final n = await _users.getNanny(id);
        if (n != null) loaded[id] = NannyCardModel.fromNanny(n);
      } catch (e) {
        Get.log('getNanny($id) failed: $e', isError: true);
      }
    }));
    nannyCards.assignAll(loaded);
  }

  Future<TrialModel?> getTrial(String trialId) => _trials.getTrial(trialId);

  /// Chat offer bubbles look up trials in [all]. If a nanny's list query is
  /// empty/stale, fetch by id once and merge so both sides see full details
  /// (System Spec §3.7 TrialOfferBubble).
  final Set<String> _ensuringTrialIds = {};

  Future<void> ensureTrialInList(String trialId) async {
    if (trialId.isEmpty || all.any((t) => t.id == trialId)) return;
    if (!_ensuringTrialIds.add(trialId)) return;
    try {
      final t = await _trials.getTrial(trialId);
      if (t != null && !all.any((x) => x.id == trialId)) {
        all.add(t);
      }
    } catch (_) {
      // Bubble falls back to title-only until the next refreshAll.
    } finally {
      _ensuringTrialIds.remove(trialId);
    }
  }

  /// Family sends trial offer → trial record + chat bubble (HTML + §6.5).
  Future<bool> sendTrialOffer({
    required String nannyId,
    required String nannyName,
    String? threadId,
  }) async {
    final validationError = await validateTrialOffer(nannyId: nannyId);
    if (validationError != null) {
      Get.snackbar(AppStrings.errorTitle.tr, validationError.tr);
      return false;
    }

    final familyId = currentFamilyId(_auth);
    if (familyId == null) return false;

    isLoading.value = true;
    try {
      // If this nanny applied to one of the family's jobs, link the trial to
      // that application: thread its jobPostId (so the eventual hire maps back
      // to the job for the My-Jobs "Hired" pill) and flip the application to
      // `trialOffered` so the Applicants list reflects the offer. Best-effort —
      // a lookup failure must never block the offer itself.
      ApplicationModel? linkedApp;
      try {
        final apps = await _apps.getApplicationsForFamily(familyId);
        linkedApp = apps.firstWhereOrNull((a) =>
            a.nannyId == nannyId &&
            const {
              ApplicationStatus.pending,
              ApplicationStatus.viewed,
              ApplicationStatus.shortlisted,
            }.contains(a.status));
      } catch (_) {
        // No application link — a browse/chat-initiated offer is still valid.
      }

      final trialId = 'trial_${_uuid.v4()}';
      final start = startDate.value!;
      final trial = TrialModel(
        id: trialId,
        familyId: familyId,
        nannyId: nannyId,
        jobPostId: linkedApp?.jobPostId,
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

      if (linkedApp != null) {
        try {
          await _apps.offerTrial(linkedApp.id);
        } catch (_) {
          // The trial offer already succeeded; the badge is cosmetic.
        }
      }

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
        lastMessage: AppStrings.trialOfferSentPreview.tr,
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
    // A nanny may hold at most 2 concurrent jobs; block accepting a 3rd.
    if (await _nannyAtJobCap()) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyJobCapReached.tr);
      return;
    }
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
      final t = all.firstWhereOrNull((x) => x.id == trialId) ??
          await _trials.getTrial(trialId);
      if (t != null) {
        await _flipThreadTrialStatus(t, TrialStatus.declined.name);
      } else if (threadId != null) {
        _updateThreadTrialStatus(threadId, TrialStatus.declined.name);
      }
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

  /// Best-effort thread-status sync when the caller has a [TrialModel] but not
  /// the thread id. Keeps chat pills/bypass state aligned after decline,
  /// cancellation, payment confirmation, or payment-issue flows.
  Future<void> _flipThreadTrialStatus(TrialModel trial, String trialStatus) async {
    try {
      final lookupUserId = currentUserId(_auth) ?? trial.familyId;
      final threads = await _chat.listThreads(lookupUserId);
      final thread = threads.firstWhereOrNull(
        (t) =>
            t.trialId == trial.id ||
            (t.familyId == trial.familyId && t.nannyId == trial.nannyId),
      );
      if (thread != null) {
        _updateThreadTrialStatus(thread.id, trialStatus);
      }
    } catch (_) {
      // Non-fatal — the next thread refresh or backend trigger will reconcile it.
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
      final t = all.firstWhereOrNull((x) => x.id == trialId) ??
          await _trials.getTrial(trialId);
      if (t != null) {
        await _flipThreadTrialStatus(t, TrialStatus.declined.name);
      } else if (threadId != null) {
        _updateThreadTrialStatus(threadId, TrialStatus.declined.name);
      }
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
          message: AppStrings.trialCounterOfferLabel.tr,
          createdAt: DateTime.now(),
        ),
      );
      await _postTrialResponseMessage(
        trialId: trialId,
        threadId: threadId,
        type: MessageType.trialCountered,
        content: AppStrings.trialCounteredMessage.trParams({'rate': '$dailyRate'}),
      );
      _updateThreadTrialStatus(threadId, TrialStatus.countered.name);
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialCounteredToast.tr);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// The family's in-progress evaluation checklist for the trial being viewed,
  /// keyed by [TrialEvaluation] field name. Ticked in the trial screen, persisted
  /// immediately so the nanny's view stays in sync, and included again when an
  /// outcome is recorded.
  final RxMap<String, bool> evalDraft = <String, bool>{}.obs;

  Future<void> toggleEval(String key) async {
    evalDraft[key] = !(evalDraft[key] ?? false);
    final t = displayed;
    if (t == null) return;
    try {
      await _trials.saveEvaluation(t.id, buildEvaluation());
    } catch (e) {
      // Revert the local tick so UI matches the failed write.
      evalDraft[key] = !(evalDraft[key] ?? false);
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    }
  }

  TrialEvaluation buildEvaluation() => TrialEvaluation(
        childInteractionAndPatience: evalDraft['childInteractionAndPatience'] ?? false,
        punctualityAndReliability: evalDraft['punctualityAndReliability'] ?? false,
        followingInstructions: evalDraft['followingInstructions'] ?? false,
        communicationAndLanguage: evalDraft['communicationAndLanguage'] ?? false,
        cookingFamilyFood: evalDraft['cookingFamilyFood'] ?? false,
        honestyAndTrustworthiness: evalDraft['honestyAndTrustworthiness'] ?? false,
      );

  /// Family's mutual-outcome response once the trial reaches
  /// `awaitingOutcome` (§2.3 truth table). Writes only the family's own
  /// side — hire-creation and the terminal `completed` status are resolved
  /// server-side by `onTrialOutcomeResolved` once both parties have
  /// responded, never decided on the client (see plan §1/§4.2).
  Future<void> familyRecordOutcome({
    required String outcome,
    NotHiredReason? reason,
  }) async {
    final t = displayed;
    if (t == null) return;
    isLoading.value = true;
    try {
      await _trials.setFamilyOutcome(
        t.id,
        outcome: outcome,
        evaluation: buildEvaluation(),
        notHiredReason: reason?.name,
      );
      // refreshAll() only recomputes `active`; a deep-linked `selected` (e.g.
      // opened from chat's "View Trial") would otherwise keep showing the
      // pre-response trial and the buttons could appear tappable again.
      if (selected.value?.id == t.id) {
        selected.value = await _trials.getTrial(t.id);
      }
      await refreshAll();
      if (outcome == 'hired') {
        final nannyName = nannyCards[t.nannyId]?.name ?? '';
        Get.snackbar(
          AppStrings.successTitle.tr,
          AppStrings.trialFamilyWaitingSnackbar.trParams({'name': nannyName}),
        );
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Nanny's mutual-outcome response once the trial reaches
  /// `awaitingOutcome`. Writes only the nanny's own side — see
  /// [familyRecordOutcome]. The "waiting for the family" state is already
  /// communicated by the screen's banner once `nannyConfirmedHire` is true
  /// (§7), so no snackbar here — kept minimal per plan.
  Future<void> nannyRecordOutcome(String outcome) async {
    final t = displayed;
    if (t == null) return;
    isLoading.value = true;
    try {
      await _trials.setNannyOutcome(t.id, outcome: outcome);
      // See familyRecordOutcome — keeps a deep-linked `selected` in sync.
      if (selected.value?.id == t.id) {
        selected.value = await _trials.getTrial(t.id);
      }
      await refreshAll();
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// A nanny may hold at most 2 concurrent jobs — active hires plus
  /// accepted/active trials. Enforced nanny-side (the security rules stop a
  /// family from reading a nanny's other hires). A read failure never blocks.
  Future<bool> _nannyAtJobCap() async {
    if (!(_auth.currentUser.value?.isNanny ?? false)) return false;
    final nannyId = currentUserId(_auth);
    if (nannyId == null) return false;
    try {
      final hires = await _hires.getHiresForNanny(nannyId);
      final activeHires = hires.where((h) => h.isActive).length;
      final activeTrials = all.where((t) => t.isLiveTrial).length;
      return activeHires + activeTrials >= 2;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelTrial(String trialId, {String? reason}) async {
    isLoading.value = true;
    try {
      await _trials.cancelTrial(trialId, reason: reason);
      // Drop the chat "active trial" badge / lockdown bypass for both parties
      // (same path as setOutcome). Without this, thread.trialStatus stays
      // accepted/active and chat keeps showing the trial pill.
      final t = all.firstWhereOrNull((x) => x.id == trialId) ??
          await _trials.getTrial(trialId);
      if (t != null) {
        await _flipThreadTrialStatus(t, TrialStatus.cancelled.name);
      }
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialCancelledToast.tr);
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
      final t = all.firstWhereOrNull((x) => x.id == trialId) ??
          await _trials.getTrial(trialId);
      if (t != null) {
        // Payment confirm is post-trial — retire the chat "ON TRIAL" bar/badges.
        await _flipThreadTrialStatus(
          t,
          t.isAcceptedOrActive ? TrialStatus.completed.name : t.status.name,
        );
      }
      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialPaymentConfirmedToast.tr);
      // Positive settlement moment — invite a store rating (throttled).
      await RateAppPrompt.maybeShow();
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
      // (snapshot-only — payment sheet has no attachment UI in v1).
      final trial = all.firstWhereOrNull((t) => t.id == trialId) ??
          await _trials.getTrial(trialId);
      if (trial != null) {
        final reportedId =
            (_auth.currentUser.value?.isNanny ?? false) ? trial.familyId : trial.nannyId;
        if (!Get.isRegistered<DisputeController>()) {
          Get.put(DisputeController(), permanent: true);
        }
        final filed = await Get.find<DisputeController>().createDispute(
          reportedUserId: reportedId,
          category: DisputeCategory.payment,
          description: description,
          relatedTrialId: trialId,
          showSuccessToast: false,
        );
        if (!filed) {
          throw Exception(AppStrings.reportUnavailable.tr);
        }
        await _flipThreadTrialStatus(trial, TrialStatus.completed.name);
      }

      await refreshAll();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.trialIssueReportedToast.tr);
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

    final senderId = currentUserId(_auth);
    if (senderId == null) return;
    final senderType = thread.senderTypeFor(senderId);
    if (senderType == null) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      threadId: thread.id,
      senderId: senderId,
      senderType: senderType,
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
    dailyRate.value = 0;
    startDate.value = null;
    trialType.value = 'live-in';
    notes.value = '';
    location.value = '';
    paymentAcknowledged.value = false;
  }
}
