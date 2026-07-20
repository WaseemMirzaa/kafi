import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadDisputes();
  }

  @override
  void onClose() {
    _sub?.cancel();
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

  /// Binds the live message stream for [d] and refreshes the dispute doc so the
  /// header reflects the latest admin-owned status/resolution.
  void openDisputeThread(DisputeModel d) {
    activeDispute.value = d;
    messages.clear();
    _sub?.cancel();
    _sub = _disputes.watchMessages(d.id).listen(
          (list) => messages.value = list,
          onError: (_) {},
        );
    _refreshDispute(d.id);
  }

  Future<void> _refreshDispute(String disputeId) async {
    try {
      final fresh = await _disputes.getDispute(disputeId);
      if (fresh != null && activeDispute.value?.id == disputeId) {
        activeDispute.value = fresh;
      }
    } catch (_) {
      // Non-fatal — the passed-in dispute stays as the header source.
    }
  }

  void closeDisputeThread() {
    _sub?.cancel();
    _sub = null;
    activeDispute.value = null;
    messages.clear();
    inputCtrl.clear();
  }

  Future<void> sendMessage() async {
    final d = activeDispute.value;
    final text = inputCtrl.text.trim();
    if (d == null || text.isEmpty || isSending.value) return;
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
