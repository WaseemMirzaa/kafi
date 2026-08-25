import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
import 'package:kafi_app/views/widgets/kafi_report_attachments.dart';
import 'package:uuid/uuid.dart';

/// Drives the dispute screens: the user's filed-reports list plus the live
/// support conversation of the currently open dispute (reporter ↔ admin).
/// Mirrors [TicketController] — disputes and tickets share the same shape.
class DisputeController extends GetxController {
  final IDisputeService _disputes = Get.find<IDisputeService>();
  final AuthController _auth = Get.find<AuthController>();
  final _uuid = const Uuid();

  final RxList<DisputeModel> disputes = <DisputeModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final Rx<DisputeModel?> activeDispute = Rx<DisputeModel?>(null);
  final RxList<DisputeMessage> messages = <DisputeMessage>[].obs;
  final inputCtrl = TextEditingController();
  final RxBool isSending = false.obs;
  StreamSubscription<List<DisputeMessage>>? _sub;
  StreamSubscription<DisputeModel?>? _disputeSub;

  bool get isDisputeClosed {
    final d = activeDispute.value;
    if (d == null) return true;
    return d.status == DisputeStatus.resolved || d.status == DisputeStatus.dismissed;
  }

  @override
  void onInit() {
    super.onInit();
    loadDisputes();
  }

  @override
  void onClose() {
    _sub?.cancel();
    _disputeSub?.cancel();
    inputCtrl.dispose();
    super.onClose();
  }

  Future<void> loadDisputes() async {
    final uid = currentUserId(_auth);
    if (uid == null) {
      disputes.clear();
      return;
    }
    isLoading.value = true;
    error.value = null;
    try {
      disputes.value = await _disputes.getMyDisputes(uid);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Files a report about another user (fraud / abuse / no-show / payment /
  /// other) and refreshes the reports list. Resolves denormalized names/types
  /// + profile snapshots and uploads optional attachments before writing.
  Future<bool> createDispute({
    required String reportedUserId,
    required DisputeCategory category,
    required String description,
    String? relatedTrialId,
    String? reportedUserName,
    List<PendingReportAttachment> pendingAttachments = const [],
    bool showSuccessToast = true,
  }) async {
    final uid = currentUserId(_auth);
    final text = description.trim();
    final target = reportedUserId.trim();
    if (uid == null || text.isEmpty || target.isEmpty || target == uid) {
      return false;
    }
    isLoading.value = true;
    try {
      final meta = await _resolveParties(
        reporterId: uid,
        reportedUserId: target,
        reportedUserNameHint: reportedUserName,
      );
      final disputeId = _uuid.v4();

      // Create the dispute first (no attachments). Storage getDownloadURL and
      // the reporter-only read rule need the doc to exist before uploads finish;
      // attachment metadata is patched afterward.
      await _disputes.fileDispute(
        disputeId: disputeId,
        reporterId: uid,
        reportedUserId: target,
        category: category,
        description: text,
        relatedTrialId: relatedTrialId,
        reporterName: meta.reporterName,
        reporterType: meta.reporterType,
        reportedName: meta.reportedName,
        reportedType: meta.reportedType,
        reporterSnapshot: meta.reporterSnapshot,
        reportedSnapshot: meta.reportedSnapshot,
        attachments: const [],
      );

      if (pendingAttachments.isNotEmpty) {
        final uploaded = await _uploadAttachments(disputeId, pendingAttachments);
        if (uploaded.isNotEmpty) {
          await _disputes.updateAttachments(disputeId, uploaded);
        }
      }
      try {
        await loadDisputes();
      } catch (_) {}
      if (showSuccessToast) {
        Get.snackbar(AppStrings.successTitle.tr, AppStrings.reportSentToast.tr);
      }
      return true;
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<DisputeAttachment>> _uploadAttachments(
    String disputeId,
    List<PendingReportAttachment> pending,
  ) async {
    if (pending.isEmpty) return const [];
    if (!Get.isRegistered<IStorageService>()) return const [];
    final storage = Get.find<IStorageService>();
    final out = <DisputeAttachment>[];
    for (final file in pending) {
      final id = _uuid.v4();
      final path = 'disputes/$disputeId/attachments/$id.${file.ext}';
      final url = await storage.uploadBytes(
        path: path,
        bytes: file.bytes,
        contentType: file.contentType,
      );
      out.add(
        DisputeAttachment(
          id: id,
          url: url,
          storagePath: path,
          name: file.name,
          contentType: file.contentType,
          sizeBytes: file.bytes.length,
          uploadedAt: DateTime.now(),
        ),
      );
    }
    return out;
  }

  Future<_PartyMeta> _resolveParties({
    required String reporterId,
    required String reportedUserId,
    String? reportedUserNameHint,
  }) async {
    final user = _auth.currentUser.value;
    final reporterType = (user?.isNanny ?? false) ? 'nanny' : 'family';
    var reporterName = user?.fullName?.trim();
    if (reporterName == null || reporterName.isEmpty) {
      reporterName = null;
    }
    DisputeUserSnapshot? reporterSnapshot;
    DisputeUserSnapshot? reportedSnapshot;
    String? reportedName = reportedUserNameHint?.trim();
    if (reportedName != null && reportedName.isEmpty) reportedName = null;
    String? reportedType;

    if (!Get.isRegistered<IUserService>()) {
      return _PartyMeta(
        reporterName: reporterName,
        reporterType: reporterType,
        reportedName: reportedName,
        reportedType: reportedType,
        reporterSnapshot: DisputeUserSnapshot(phone: user?.phone),
        reportedSnapshot: null,
      );
    }

    final users = Get.find<IUserService>();
    try {
      if (reporterType == 'nanny') {
        final n = await users.getNanny(reporterId);
        reporterName ??= (n?.fullName.trim().isNotEmpty == true) ? n!.fullName.trim() : null;
        reporterSnapshot = DisputeUserSnapshot(
          phone: user?.phone,
          city: n?.currentArea,
          nationality: n?.nationality,
          status: n?.status.name,
        );
      } else {
        final f = await users.getFamily(reporterId);
        reporterName ??= (f?.fullName.trim().isNotEmpty == true) ? f!.fullName.trim() : null;
        reporterSnapshot = DisputeUserSnapshot(
          phone: user?.phone,
          city: f?.city,
          nationality: f?.nationality,
        );
      }
    } catch (_) {
      reporterSnapshot = DisputeUserSnapshot(phone: user?.phone);
    }

    try {
      final nanny = await users.getNanny(reportedUserId);
      if (nanny != null) {
        reportedType = 'nanny';
        reportedName ??=
            nanny.fullName.trim().isNotEmpty ? nanny.fullName.trim() : null;
        reportedSnapshot = DisputeUserSnapshot(
          city: nanny.currentArea,
          nationality: nanny.nationality,
          status: nanny.status.name,
        );
      } else {
        final family = await users.getFamily(reportedUserId);
        if (family != null) {
          reportedType = 'family';
          reportedName ??=
              family.fullName.trim().isNotEmpty ? family.fullName.trim() : null;
          reportedSnapshot = DisputeUserSnapshot(
            city: family.city,
            nationality: family.nationality,
          );
        }
      }
    } catch (_) {}

    return _PartyMeta(
      reporterName: reporterName,
      reporterType: reporterType,
      reportedName: reportedName,
      reportedType: reportedType,
      reporterSnapshot: reporterSnapshot,
      reportedSnapshot: reportedSnapshot,
    );
  }

  /// Binds the live message stream for [d] and watches the dispute doc so admin
  /// resolve/dismiss (and resolution text) appear without leaving the screen.
  void openDisputeThread(DisputeModel d) {
    activeDispute.value = d;
    messages.clear();
    _sub?.cancel();
    _disputeSub?.cancel();
    _sub = _disputes.watchMessages(d.id).listen(
      (list) => messages.value = list,
      onError: (e) => Get.log('dispute message stream error: $e', isError: true),
    );
    _disputeSub = _disputes.watchDispute(d.id).listen(
      (fresh) {
        if (fresh == null) return;
        activeDispute.value = fresh;
        final idx = disputes.indexWhere((x) => x.id == fresh.id);
        if (idx >= 0) disputes[idx] = fresh;
      },
      onError: (e) => Get.log('dispute status stream error: $e', isError: true),
    );
  }

  void closeDisputeThread() {
    _sub?.cancel();
    _sub = null;
    _disputeSub?.cancel();
    _disputeSub = null;
    activeDispute.value = null;
    messages.clear();
    inputCtrl.clear();
  }

  Future<void> sendMessage() async {
    final d = activeDispute.value;
    final text = inputCtrl.text.trim();
    if (d == null || text.isEmpty || isSending.value || isDisputeClosed) return;
    final uid = currentUserId(_auth) ?? '';
    isSending.value = true;
    inputCtrl.clear();
    try {
      await _disputes.sendMessage(
        d.id,
        DisputeMessage(
          id: _uuid.v4(),
          disputeId: d.id,
          senderId: uid,
          senderType: 'user',
          content: text,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      inputCtrl.text = text; // restore so the user can retry
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isSending.value = false;
    }
  }
}

class _PartyMeta {
  const _PartyMeta({
    this.reporterName,
    this.reporterType,
    this.reportedName,
    this.reportedType,
    this.reporterSnapshot,
    this.reportedSnapshot,
  });

  final String? reporterName;
  final String? reporterType;
  final String? reportedName;
  final String? reportedType;
  final DisputeUserSnapshot? reporterSnapshot;
  final DisputeUserSnapshot? reportedSnapshot;
}
