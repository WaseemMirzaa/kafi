import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/ticket_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/support_screen.dart' show statusChip, categoryLabel;

/// The conversation for a single support ticket (user ↔ admin), realtime.
class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final TicketController controller = Get.find<TicketController>();
  late final TicketModel _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = Get.arguments as TicketModel;
    controller.openTicketThread(_ticket);
  }

  @override
  void dispose() {
    controller.closeTicketThread();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Obx(() {
                final msgs = controller.messages;
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(AppStrings.supportThreadEmpty.tr,
                        style: KafiTheme.nunito(11, color: KafiColors.ts)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _bubble(msgs[i]),
                );
              }),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEE0FF), Color(0xFFF0D8FF)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: AppNavigation.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ticket.subject.isNotEmpty ? _ticket.subject : categoryLabel(_ticket.category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KafiTheme.fredoka(13, color: const Color(0xFF5A2090), w: FontWeight.w800)),
                Text(categoryLabel(_ticket.category),
                    style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
          statusChip(_ticket.status),
        ],
      ),
    );
  }

  Widget _bubble(TicketMessage m) {
    final mine = !m.isAdmin;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(colors: [KafiColors.pur, Color(0xFF7B5BD5)])
              : null,
          color: mine ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: const Color(0xFFEFE2FF), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(AppStrings.supportAgentName.tr,
                    style: KafiTheme.fredoka(8.5, color: KafiColors.purpD, w: FontWeight.w700)),
              ),
            Text(m.content,
                style: KafiTheme.nunito(11.5,
                    color: mine ? Colors.white : KafiColors.td, w: FontWeight.w500)),
          ],
        ),
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
          border: Border(top: BorderSide(color: Color(0xFFEFE2FF))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.inputCtrl,
                minLines: 1,
                maxLines: 4,
                style: KafiTheme.nunito(12, color: KafiColors.td),
                decoration: InputDecoration(
                  hintText: AppStrings.supportMessageHint.tr,
                  hintStyle: KafiTheme.nunito(11, color: KafiColors.ts),
                  filled: true,
                  fillColor: const Color(0xFFF7F5FC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => GestureDetector(
                  onTap: controller.isSending.value ? null : controller.sendMessage,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(color: KafiColors.pur, shape: BoxShape.circle),
                    child: controller.isSending.value
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
