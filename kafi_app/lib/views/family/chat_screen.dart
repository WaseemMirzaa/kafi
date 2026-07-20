import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/browse_controller.dart';
import 'package:kafi_app/controllers/chat_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/controllers/trial_controller.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/widgets/kafi_primary_button.dart';
import 'package:kafi_app/views/widgets/kafi_trial_offer_bubble.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController controller;
  late final SubscriptionController subs;
  final _searchCtrl = TextEditingController();
  final _query = ''.obs;

  bool get embedInShell => widget.embedInShell;

  // Accent palette switches by role: families chat in purple, nannies in rose.
  List<Color> get _accent => controller.isNanny
      ? const [KafiColors.rose, KafiColors.roseD]
      : const [KafiColors.pur, Color(0xFFC084FC)];

  // Light header gradient + solid accent, role-aware.
  List<Color> get _heroGradient => controller.isNanny
      ? const [Color(0xFFFFE0EC), Color(0xFFFFF4EE)]
      : const [Color(0xFFEEE0FF), Color(0xFFF0D8FF)];
  Color get _accentSolid => controller.isNanny ? KafiColors.roseD : KafiColors.pur;

  // Avatar gradient palette (matches the web .av1–.av4 cycle).
  static const List<List<Color>> _avatarGradients = [
    [Color(0xFFFF8FAB), Color(0xFFFF5C8A)],
    [Color(0xFFFFB347), Color(0xFFFF8042)],
    [Color(0xFF6DBF8A), Color(0xFF3DAA65)],
    [Color(0xFF9B6EDB), Color(0xFFC084FC)],
  ];

  List<Color> _avatarGradient(String seed) =>
      _avatarGradients[seed.isEmpty ? 0 : seed.codeUnitAt(0) % _avatarGradients.length];

  @override
  void initState() {
    super.initState();
    controller = Get.find<ChatController>();
    subs = Get.find<SubscriptionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await controller.refreshThreads();
      final args = Get.arguments;
      if (args is Map) {
        if (args['threadId'] is String && (args['threadId'] as String).isNotEmpty) {
          await controller.openThread(args['threadId'] as String);
          return;
        }
        if (args['nannyId'] is String && (args['nannyId'] as String).isNotEmpty) {
          await controller.openThreadForNanny(
            nannyId: args['nannyId'] as String,
            nannyName: args['nannyName'] as String?,
          );
          return;
        }
      }
      await controller.consumePendingOpen();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final inThread = controller.activeThreadId.value.isNotEmpty;
      final canPopRoute = !embedInShell && Navigator.of(context).canPop();

      return PopScope(
        canPop: !inThread && canPopRoute,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (inThread) controller.closeThread();
        },
        child: Scaffold(
          backgroundColor: controller.isNanny
              ? Colors.white
              : (inThread ? const Color(0xFFFFF7FA) : KafiColors.bgLight),
          body: SafeArea(
            top: true,
            bottom: false,
            child: () {
              if (!controller.isNanny &&
                  controller.isSubscriptionExpired &&
                  controller.visibleThreads.isEmpty) {
                return _expiredOverlay();
              }
              return inThread ? _conversation() : _inbox(canPopRoute);
            }(),
          ),
        ),
      );
    });
  }

  // ══════════════════════════ INBOX (messages list) ════════════════════════
  Widget _inbox(bool canPopRoute) {
    return Column(
      children: [
        _inboxHeader(canPopRoute),
        if (!controller.isNanny && controller.isSubscriptionExpired)
          GestureDetector(
            onTap: () => Get.toNamed(Routes.pricing),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              color: KafiColors.ambL,
              child: Text(AppStrings.chatExpiredListBanner.tr,
                  style: KafiTheme.nunito(10, color: const Color(0xFF7A4A00), w: FontWeight.w700)),
            ),
          ),
        Expanded(
          child: Obx(() {
            final q = _query.value.trim().toLowerCase();
            final threads = q.isEmpty
                ? controller.visibleThreads
                : controller.visibleThreads
                    .where((t) => _displayName(t).toLowerCase().contains(q))
                    .toList();
            if (controller.isLoading.value && controller.visibleThreads.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.visibleThreads.isEmpty) return _emptyThreadList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
              children: [
                for (final t in threads) ...[
                  _threadCard(t),
                  const SizedBox(height: 4),
                ],
                if (!controller.isNanny) ...[
                  const SizedBox(height: 2),
                  _newConversationCard(),
                ],
                const SizedBox(height: 10),
                _privacyNote(),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _inboxHeader(bool canPopRoute) {
    final titleColor = controller.isNanny ? KafiColors.roseD : const Color(0xFF5A2090);
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _heroGradient,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (canPopRoute)
                GestureDetector(
                  onTap: Get.back,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back, color: _accentSolid, size: 20),
                  ),
                ),
              Text(AppStrings.chatTitle.tr, style: KafiTheme.pacifico(17, color: titleColor)),
              const Spacer(),
              _circleIconBtn(Icons.search, () {}),
              const SizedBox(width: 5),
              _circleIconBtn(Icons.notifications_outlined, AppNavigation.openNotifications),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 5, offset: Offset(0, 1))],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: KafiColors.ts, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => _query.value = v,
                    style: KafiTheme.nunito(11, color: KafiColors.td),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      border: InputBorder.none,
                      hintText: AppStrings.chatSearchHint.tr,
                      hintStyle: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27,
        height: 27,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1AFF5F96), blurRadius: 7, offset: Offset(0, 2))],
        ),
        child: Icon(icon, color: _accentSolid, size: 14),
      ),
    );
  }

  String _displayName(ChatThread t) {
    final name = controller.isNanny ? t.familyName : t.nannyName;
    return name.isNotEmpty ? name : AppStrings.chatTitle.tr;
  }

  Widget _threadCard(ChatThread t) {
    final name = _displayName(t);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final unread = _unreadForCurrentRole(t);
    final onTrial = t.hasActiveTrial;
    final gradient = onTrial
        ? const [KafiColors.rose, KafiColors.roseD]
        : _avatarGradient(name);

    return GestureDetector(
      onTap: () => controller.openThread(t.id),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: onTrial ? KafiColors.grnL : Colors.transparent, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 9, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with online dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: KafiTheme.fredoka(16, color: Colors.white, w: FontWeight.w900)),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: KafiColors.grn,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(
                    t.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KafiTheme.nunito(9.5,
                        color: onTrial
                            ? KafiColors.grnD
                            : (unread > 0 ? KafiColors.td : KafiColors.ts),
                        w: unread > 0 || onTrial ? FontWeight.w700 : FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(_formatTime(t.lastMessageAt),
                          style: KafiTheme.nunito(8, color: KafiColors.ts, w: FontWeight.w600)),
                      if (onTrial) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: KafiColors.grnL,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(AppStrings.chatTrialBadge.tr,
                              style: KafiTheme.fredoka(8, color: KafiColors.grnD, w: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (onTrial)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: KafiColors.grn,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(AppStrings.chatOnTrialBadge.tr,
                        style: KafiTheme.fredoka(7.5, color: Colors.white, w: FontWeight.w700)),
                  )
                else if (unread > 0)
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: KafiColors.roseD,
                      shape: BoxShape.circle,
                    ),
                    child: Text('$unread',
                        style: KafiTheme.fredoka(9, color: Colors.white, w: FontWeight.w800)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _newConversationCard() {
    return GestureDetector(
      onTap: _showNewConversationSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [KafiColors.roseP, Color(0xFFFFF0F8)]),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: KafiColors.roseL, width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Text(AppStrings.chatNewConversation.tr,
                style: KafiTheme.nunito(11, color: KafiColors.roseD, w: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(AppStrings.chatNewConversationSub.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // Popup to pick a candidate to message, then opens the thread inline.
  void _showNewConversationSheet() {
    final candidates = Get.isRegistered<BrowseController>()
        ? Get.find<BrowseController>().results.toList()
        : <NannyCardModel>[];
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KafiColors.roseL,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            Text(AppStrings.chatPickTitle.tr,
                style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(AppStrings.chatPickSub.tr,
                style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
            const SizedBox(height: 12),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(AppStrings.chatEmptySub.tr,
                    style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: Get.height * 0.55),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _candidateRow(candidates[i]),
                ),
              ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _candidateRow(NannyCardModel card) {
    return GestureDetector(
      onTap: () {
        Get.back();
        controller.openThreadForNanny(nannyId: card.id, nannyName: card.name);
      },
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _avatarGradient(card.name),
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(card.initials,
                    style: KafiTheme.fredoka(15, color: Colors.white, w: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(11.5, color: KafiColors.td, w: FontWeight.w800)),
                  Text('${card.nationality} · ${card.yearsExp} yrs · ${card.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w600)),
                ],
              ),
            ),
            const Text('🗨️', style: TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _privacyNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [KafiColors.purL, Color(0xFFEDE4FF)]),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.chatPrivacyTitle.tr,
              style: KafiTheme.nunito(9.5, color: KafiColors.pur, w: FontWeight.w800)),
          const SizedBox(height: 4),
          _privacyLine(AppStrings.chatPrivacyPhone.tr),
          _privacyLine(AppStrings.chatPrivacyInApp.tr),
          _privacyLine(AppStrings.chatPrivacyNumber.tr),
        ],
      ),
    );
  }

  Widget _privacyLine(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: KafiTheme.nunito(9, color: const Color(0xFF4A2080), w: FontWeight.w600)
                .copyWith(height: 1.5)),
      );

  Widget _emptyThreadList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 52, color: KafiColors.roseL.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(AppStrings.chatEmptyTitle.tr,
              style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(AppStrings.chatEmptySub.tr,
              textAlign: TextAlign.center,
              style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600)),
        ],
      ),
    );
  }

  // ══════════════════════════ CONVERSATION (thread) ════════════════════════
  Widget _conversation() {
    final thread = controller.activeThread;
    final name = thread == null ? AppStrings.chatTitle.tr : _displayName(thread);

    return Column(
      children: [
        _chatTopbar(name),
        _contactStrip(),
        if (thread?.hasActiveTrial ?? false) _trialBanner(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFFFF7FA), _accent.last.withValues(alpha: 0.05)],
              ),
            ),
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                itemCount: controller.messages.length,
                itemBuilder: (_, i) {
                  final msg = controller.messages[i];
                  if (msg.type == MessageType.system) return _systemBubble(msg);
                  if (_isTrialBubble(msg)) return _trialBubble(msg);
                  final isNannyView = controller.isNanny;
                  final mine = isNannyView
                      ? (msg.senderType == 'nanny' || msg.senderId.startsWith('mock_nanny'))
                      : (msg.senderType == 'family' || msg.senderId.startsWith('mock_family'));
                  if (msg.type == MessageType.image) return _imageBubble(msg, mine);
                  return _bubble(msg, mine, name);
                },
              ),
            ),
          ),
        ),
        _composer(),
      ],
    );
  }

  Widget _chatTopbar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _accent,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: controller.closeThread,
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
            ),
            child: Center(
              child: Text(initial, style: KafiTheme.fredoka(15, color: Colors.white, w: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w900)),
                Text(AppStrings.chatOnlineStatus.tr,
                    style: KafiTheme.nunito(9, color: Colors.white.withValues(alpha: 0.85), w: FontWeight.w600)),
              ],
            ),
          ),
          if (controller.isSubscribed && !controller.isNanny) ...[
            _topbarAction(Icons.chat, const Color(0xFF25D366),
                () => _launchNannyContact(whatsapp: true)),
            const SizedBox(width: 6),
            _topbarAction(Icons.call, Colors.white,
                () => _launchNannyContact(whatsapp: false),
                iconColor: _accent.last),
          ],
        ],
      ),
    );
  }

  /// Reveal the nanny's real phone (server-side entitlement check) and open the
  /// dialer or WhatsApp. Replaces the old mock snackbar.
  Future<void> _launchNannyContact({required bool whatsapp}) async {
    final phone = await controller.revealActiveNannyPhone();
    if (phone == null || phone.trim().isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.contactUnavailable.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = whatsapp
        ? Uri.parse('https://wa.me/$digits')
        : Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.contactLaunchFailed.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _topbarAction(IconData icon, Color bg, VoidCallback onTap, {Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 15),
      ),
    );
  }

  // Entry point to the Trial System screen when this thread has an active trial.
  Widget _trialBanner() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.trial),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [KafiColors.grnL, Color(0xFFD0F5E0)]),
          border: Border(bottom: BorderSide(color: Color(0xFFB0E8C8), width: 1)),
        ),
        child: Row(
          children: [
            const Text('🤝', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(AppStrings.chatTrialActiveBanner.tr,
                  style: KafiTheme.fredoka(10, color: KafiColors.grnD, w: FontWeight.w700)),
            ),
            Text(AppStrings.chatViewTrial.tr,
                style: KafiTheme.fredoka(10, color: KafiColors.grnD, w: FontWeight.w700)),
            const Icon(Icons.chevron_right, color: KafiColors.grnD, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _contactStrip() {
    // Nannies never carry a paid subscription, so they always see the active
    // hint — the "subscription expired" copy is family-only.
    final subscribed = controller.isNanny || controller.isSubscribed;
    final accentColor = controller.isNanny ? KafiColors.pur : KafiColors.grnD;
    final bg = controller.isNanny
        ? const [KafiColors.purL, Color(0xFFEDE4FF)]
        : const [KafiColors.grnL, Color(0xFFD0F5E0)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: subscribed ? bg : const [KafiColors.ambL, Color(0xFFFFE8C0)]),
        border: Border(bottom: BorderSide(color: KafiColors.cardBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(subscribed ? Icons.verified_user : Icons.lock_outline,
              color: subscribed ? accentColor : const Color(0xFFA06010), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subscribed
                  ? AppStrings.chatHintActive.tr
                  : AppStrings.chatExpiredListBanner.tr,
              style: KafiTheme.fredoka(9.5,
                  color: subscribed ? accentColor : const Color(0xFF7A4A00), w: FontWeight.w700),
            ),
          ),
          if (subscribed && !controller.isNanny) ...[
            _ccsButton('📞 ${AppStrings.callHer.tr.split(' ').first}', KafiColors.grnD,
                () => _launchNannyContact(whatsapp: false)),
            const SizedBox(width: 5),
            _ccsButton('WhatsApp', const Color(0xFF25D366),
                () => _launchNannyContact(whatsapp: true)),
          ],
        ],
      ),
    );
  }

  Widget _ccsButton(String label, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: KafiTheme.fredoka(9.5, color: Colors.white, w: FontWeight.w700)),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFFFE8EF), width: 1)),
        ),
        child: Obx(() {
          final isNanny = Get.find<AuthController>().currentUser.value?.isNanny == true;
          final t = controller.activeThread;
          final locked = !isNanny && subs.isExpired && !(t?.hasActiveTrial ?? false);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: locked ? null : controller.sendImage,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: KafiColors.roseP, shape: BoxShape.circle),
                  child: Icon(Icons.attach_file,
                      color: locked ? KafiColors.ts : KafiColors.roseD, size: 16),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: TextField(
                  controller: controller.inputCtrl,
                  enabled: !locked,
                  minLines: 1,
                  maxLines: 4,
                  style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: locked ? AppStrings.chatExpiredListBanner.tr : AppStrings.chatSend.tr,
                    hintStyle: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w500),
                    filled: true,
                    fillColor: locked ? KafiColors.cardBorder : const Color(0xFFFFF7FA),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFFFD8E8), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: KafiColors.roseD, width: 1.5),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFFFD8E8), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: locked ? null : controller.sendCurrent,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: locked ? [KafiColors.ts, KafiColors.ts] : _accent),
                    shape: BoxShape.circle,
                    boxShadow: locked
                        ? null
                        : [BoxShadow(color: _accent.last.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Message bubbles ───────────────────────────────────────────────────────
  Widget _bubble(ChatMessage m, bool mine, String otherName) {
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        gradient: mine ? LinearGradient(colors: _accent) : null,
        color: mine ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(mine ? 14 : 4),
          bottomRight: Radius.circular(mine ? 4 : 14),
        ),
        boxShadow: [
          BoxShadow(
              color: mine ? _accent.last.withValues(alpha: 0.2) : const Color(0x0F000000),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Text(m.content,
          style: KafiTheme.nunito(10.5,
              color: mine ? Colors.white : KafiColors.td, w: FontWeight.w600)
              .copyWith(height: 1.45)),
    );

    final avatar = _msgAvatar(mine, otherName);
    final time = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(_formatClock(m.createdAt),
          style: KafiTheme.nunito(8, color: KafiColors.ts, w: FontWeight.w600)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: mine
            ? [
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [bubble, time]),
                const SizedBox(width: 6),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bubble, time]),
              ],
      ),
    );
  }

  Widget _msgAvatar(bool mine, String otherName) {
    final gradient = mine ? _accent : _avatarGradient(otherName);
    final you = AppStrings.chatYou.tr;
    final initial = mine
        ? (you.isNotEmpty ? you[0].toUpperCase() : 'Y')
        : (otherName.isNotEmpty ? otherName[0].toUpperCase() : '?');
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(initial, style: KafiTheme.fredoka(10, color: Colors.white, w: FontWeight.w800)),
      ),
    );
  }

  Widget _imageBubble(ChatMessage m, bool mine) {
    final url = m.attachments.isNotEmpty ? m.attachments.first.url : '';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KafiColors.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: url.isEmpty
              ? Container(
                  width: 180,
                  height: 120,
                  color: KafiColors.roseP,
                  child: const Icon(Icons.image, color: KafiColors.tm, size: 32))
              : Image.network(url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                        width: 180,
                        height: 120,
                        color: KafiColors.roseP,
                        child: const Icon(Icons.broken_image, color: KafiColors.tm),
                      )),
        ),
      ),
    );
  }

  Widget _systemBubble(ChatMessage m) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4)],
        ),
        child: Text(m.content,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(9, color: KafiColors.ts, w: FontWeight.w700).copyWith(height: 1.4)),
      ),
    );
  }

  bool _isTrialBubble(ChatMessage m) {
    return m.type == MessageType.trialOffer ||
        m.type == MessageType.trialAccepted ||
        m.type == MessageType.trialDeclined ||
        m.type == MessageType.trialCountered;
  }

  Widget _trialBubble(ChatMessage m) {
    final isNanny = Get.find<AuthController>().currentUser.value?.isNanny == true;
    final threadId = controller.activeThreadId.value;
    final trialCtrl = Get.find<TrialController>();
    final hasId = m.trialOfferId != null;

    return KafiTrialOfferBubble(
      message: m,
      isNannyView: isNanny,
      onAccept: hasId && isNanny
          ? () => trialCtrl.acceptTrial(m.trialOfferId!, threadId: threadId)
          : null,
      onCounter: hasId && isNanny ? () => _showCounterDialog(m.trialOfferId!, threadId) : null,
      onAcceptCounter: hasId && !isNanny
          ? () => trialCtrl.acceptCounter(m.trialOfferId!, threadId: threadId)
          : null,
      onDeclineCounter: hasId && !isNanny
          ? () => trialCtrl.declineCounter(m.trialOfferId!, threadId: threadId)
          : null,
    );
  }

  Future<void> _showCounterDialog(String trialId, String threadId) async {
    final rateCtrl = TextEditingController(text: '150');
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.trialOfferCounter.tr, style: KafiTheme.fredoka(14, color: KafiColors.td)),
        content: TextField(
          controller: rateCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppStrings.trialOfferRate.tr,
            filled: true,
            fillColor: KafiColors.inputBg,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.confirm.tr, style: const TextStyle(color: KafiColors.roseD)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final rate = int.tryParse(rateCtrl.text) ?? 0;
      if (rate > 0) {
        await Get.find<TrialController>().counterTrial(trialId, dailyRate: rate, threadId: threadId);
      }
    }
  }

  Widget _expiredOverlay() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: KafiColors.ts),
            const SizedBox(height: 12),
            Text(AppStrings.chatExpiredTitle.tr,
                style: KafiTheme.nunito(16, color: KafiColors.td, w: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(AppStrings.chatExpiredSub.tr, style: KafiTheme.nunito(11, color: KafiColors.tm)),
            const SizedBox(height: 8),
            Text(AppStrings.chatExpiredBody.tr,
                textAlign: TextAlign.center, style: KafiTheme.nunito(10, color: KafiColors.ts)),
            const SizedBox(height: 16),
            KafiPrimaryButton(label: AppStrings.renewNow.tr, onPressed: () => Get.toNamed(Routes.pricing)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.toNamed(Routes.pricing),
              child: Text(AppStrings.viewPlans.tr, style: KafiTheme.fredoka(11, color: KafiColors.roseD)),
            ),
          ],
        ),
      ),
    );
  }

  int _unreadForCurrentRole(ChatThread t) =>
      controller.isNanny ? t.unreadCount.nanny : t.unreadCount.family;

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return _formatClock(dt);
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}
