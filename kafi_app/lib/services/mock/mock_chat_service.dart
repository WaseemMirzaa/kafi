import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/data/mock/mock_demo_seed.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';

class MockChatService implements IChatService {
  final Map<String, List<ChatMessage>> _byThread = {};
  final List<ChatThread> _threads = [];

  MockChatService() {
    final now = DateTime.now();
    _threads.addAll(buildMockChatThreads(now));
    _byThread.addAll(buildMockChatMessages(now));
  }

  @override
  Future<List<ChatThread>> listThreads(String userId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    final isNanny = userId.contains('nanny');
    return _threads.where((t) {
      if (isNanny) {
        return mockNannyIdMatches(userId, t.nannyId);
      }
      return t.familyId == userId;
    }).toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  @override
  Future<List<ChatMessage>> loadMessages(String threadId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return List<ChatMessage>.from(
      _byThread[threadId] ?? const [],
    );
  }

  @override
  Future<void> sendMessage(String threadId, ChatMessage message) async {
    _byThread.putIfAbsent(threadId, () => []).add(message);
    final i = _threads.indexWhere((t) => t.id == threadId);
    if (i >= 0) {
      _threads[i] = _threads[i].copyWith(
        lastMessage: message.content,
        lastMessageAt: message.createdAt,
      );
    }
  }

  @override
  Future<ChatThread> findOrCreateThread({
    required String familyId,
    required String nannyId,
    String? nannyName,
    String? familyName,
  }) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    try {
      return _threads.firstWhere((t) => t.familyId == familyId && t.nannyId == nannyId);
    } catch (_) {}

    final thread = ChatThread(
      id: 't_${nannyId}_${DateTime.now().millisecondsSinceEpoch}',
      familyId: familyId,
      nannyId: nannyId,
      nannyName: nannyName ?? 'Nanny',
      familyName: familyName ?? 'Family',
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      lastMessage: '',
    );
    _threads.add(thread);
    return thread;
  }

  @override
  Future<void> linkTrialToThread(String threadId, String trialId,
      {String? lastMessage, String? trialStatus}) async {
    final i = _threads.indexWhere((t) => t.id == threadId);
    if (i < 0) return;
    _threads[i] = _threads[i].copyWith(
      trialId: trialId,
      trialStatus: trialStatus ?? _threads[i].trialStatus ?? 'pending',
      lastMessage: lastMessage ?? '🤝 Trial offer sent',
      lastMessageAt: DateTime.now(),
    );
  }

  @override
  Future<void> markThreadRead(String threadId, String readerRole) async {
    final i = _threads.indexWhere((t) => t.id == threadId);
    if (i < 0) return;
    _threads[i] = _threads[i].copyWith(unreadCount: const UnreadCount());
  }
}
