import 'dart:async';

import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/services/interfaces/i_ticket_service.dart';
import 'package:uuid/uuid.dart';

class MockTicketService implements ITicketService {
  final List<TicketModel> _tickets = [];
  final Map<String, List<TicketMessage>> _messages = {};
  final Map<String, StreamController<List<TicketMessage>>> _controllers = {};
  final Map<String, StreamController<TicketModel?>> _ticketControllers = {};
  final _uuid = const Uuid();
  int _seq = 0;

  StreamController<List<TicketMessage>> _ctrl(String ticketId) =>
      _controllers.putIfAbsent(ticketId, () => StreamController.broadcast());

  StreamController<TicketModel?> _ticketCtrl(String ticketId) =>
      _ticketControllers.putIfAbsent(ticketId, () => StreamController.broadcast());

  void _emitTicket(String ticketId) {
    TicketModel? found;
    for (final t in _tickets) {
      if (t.id == ticketId) {
        found = t;
        break;
      }
    }
    final c = _ticketControllers[ticketId];
    if (c != null && !c.isClosed) c.add(found);
  }
  @override
  Future<String> openTicket({
    required String openerId,
    required String openerType,
    required String subject,
    required TicketCategory category,
    required String firstMessage,
    String? relatedTrialId,
  }) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final id = 'ticket_${++_seq}';
    final now = DateTime.now();
    _tickets.insert(
      0,
      TicketModel(
        id: id,
        openerId: openerId,
        openerType: openerType,
        subject: subject,
        category: category,
        relatedTrialId: relatedTrialId,
        lastMessage: firstMessage,
        createdAt: now,
        lastMessageAt: now,
      ),
    );
    _messages[id] = [
      TicketMessage(
        id: _uuid.v4(),
        ticketId: id,
        senderId: openerId,
        senderType: 'user',
        content: firstMessage,
        createdAt: now,
      ),
    ];
    return id;
  }

  @override
  Future<List<TicketModel>> getMyTickets(String userId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _tickets.where((t) => t.openerId == userId).toList();
  }

  @override
  Future<TicketModel?> getTicket(String ticketId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    for (final t in _tickets) {
      if (t.id == ticketId) return t;
    }
    return null;
  }

  @override
  Stream<TicketModel?> watchTicket(String ticketId) {
    final c = _ticketCtrl(ticketId);
    scheduleMicrotask(() {
      TicketModel? found;
      for (final t in _tickets) {
        if (t.id == ticketId) {
          found = t;
          break;
        }
      }
      c.add(found);
    });
    return c.stream;
  }

  @override
  Stream<List<TicketMessage>> watchMessages(String ticketId) {
    final c = _ctrl(ticketId);
    scheduleMicrotask(() => c.add(List.of(_messages[ticketId] ?? const [])));
    return c.stream;
  }

  @override
  Future<List<TicketMessage>> loadMessages(String ticketId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return List.of(_messages[ticketId] ?? const []);
  }

  @override
  Future<void> sendMessage(String ticketId, TicketMessage message) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final list = _messages.putIfAbsent(ticketId, () => []);
    list.add(message);
    _ctrl(ticketId).add(List.of(list));
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx >= 0) {
      _tickets[idx] = _tickets[idx].copyWith(
        lastMessage: message.content,
        lastMessageAt: message.createdAt,
      );
      _emitTicket(ticketId);
    }
  }
}
