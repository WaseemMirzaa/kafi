import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/services/interfaces/i_ticket_service.dart';
import 'package:kafi_app/utils/auth_scope.dart';
import 'package:uuid/uuid.dart';

/// Drives the support-ticket screens: the user's ticket list plus the live
/// message thread of the currently open ticket (realtime, mirrors chat).
class TicketController extends GetxController {
  final ITicketService _tickets = Get.find<ITicketService>();
  final AuthController _auth = Get.find<AuthController>();
  final _uuid = const Uuid();

  final RxList<TicketModel> tickets = <TicketModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  final Rx<TicketModel?> activeTicket = Rx<TicketModel?>(null);
  final RxList<TicketMessage> messages = <TicketMessage>[].obs;
  final inputCtrl = TextEditingController();
  final RxBool isSending = false.obs;
  StreamSubscription<List<TicketMessage>>? _sub;
  StreamSubscription<TicketModel?>? _ticketSub;

  @override
  void onInit() {
    super.onInit();
    loadTickets();
  }

  @override
  void onClose() {
    _sub?.cancel();
    _ticketSub?.cancel();
    inputCtrl.dispose();
    super.onClose();
  }

  Future<void> loadTickets() async {
    final uid = currentUserId(_auth);
    if (uid == null) {
      tickets.clear();
      return;
    }
    isLoading.value = true;
    error.value = null;
    try {
      tickets.value = await _tickets.getMyTickets(uid);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Opens a new ticket and returns it (so the UI can navigate into it).
  Future<TicketModel?> createTicket({
    required String subject,
    required TicketCategory category,
    required String message,
    String? relatedTrialId,
  }) async {
    final uid = currentUserId(_auth);
    if (uid == null) return null;
    final openerType = (_auth.currentUser.value?.isNanny ?? false) ? 'nanny' : 'family';
    try {
      final id = await _tickets.openTicket(
        openerId: uid,
        openerType: openerType,
        subject: subject,
        category: category,
        firstMessage: message,
        relatedTrialId: relatedTrialId,
      );
      await loadTickets();
      return tickets.firstWhereOrNull((t) => t.id == id) ?? await _tickets.getTicket(id);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
      return null;
    }
  }

  /// Binds the live message stream for [t] and watches the ticket doc so admin
  /// status changes (resolved/closed) appear without leaving the screen.
  void openTicketThread(TicketModel t) {
    activeTicket.value = t;
    messages.clear();
    _sub?.cancel();
    _ticketSub?.cancel();
    _sub = _tickets.watchMessages(t.id).listen(
      (list) => messages.value = list,
      onError: (e) => Get.log('ticket message stream error: $e', isError: true),
    );
    _ticketSub = _tickets.watchTicket(t.id).listen(
      (fresh) {
        if (fresh == null) return;
        activeTicket.value = fresh;
        final idx = tickets.indexWhere((x) => x.id == fresh.id);
        if (idx >= 0) tickets[idx] = fresh;
      },
      onError: (e) => Get.log('ticket status stream error: $e', isError: true),
    );
  }

  void closeTicketThread() {
    _sub?.cancel();
    _sub = null;
    _ticketSub?.cancel();
    _ticketSub = null;
    activeTicket.value = null;
    messages.clear();
    inputCtrl.clear();
  }

  Future<void> sendMessage() async {
    final t = activeTicket.value;
    final text = inputCtrl.text.trim();
    if (t == null || text.isEmpty || isSending.value || t.isClosed) return;
    final uid = currentUserId(_auth) ?? '';
    isSending.value = true;
    inputCtrl.clear();
    try {
      await _tickets.sendMessage(
        t.id,
        TicketMessage(
          id: _uuid.v4(),
          ticketId: t.id,
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
