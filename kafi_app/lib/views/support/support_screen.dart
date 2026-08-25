import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/ticket_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/relative_time.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_chip.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

/// Support inbox — the user's tickets, with a "New ticket" flow. Shared by both
/// families and nannies (drives [TicketController]).
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  TicketController get controller => Get.find<TicketController>();

  @override
  void initState() {
    super.initState();
    // Permanent TicketController only loads once on first create — refresh
    // whenever Support is opened so admin status changes aren't stale.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: KafiColors.pur,
        onPressed: _openNewTicket,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: Text(AppStrings.supportNewTicket.tr,
            style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w700)),
      ),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.tickets.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: KafiColors.pur));
                }
                if (controller.error.value != null && controller.tickets.isEmpty) {
                  return _errorState();
                }
                if (controller.tickets.isEmpty) return _emptyState();
                return RefreshIndicator(
                  color: KafiColors.pur,
                  onRefresh: controller.loadTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                    itemCount: controller.tickets.length,
                    itemBuilder: (_, i) => _ticketCard(controller.tickets[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.supportTitle.tr,
                    style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090))),
                Text(AppStrings.supportSubtitle.tr,
                    style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the tickets read fails (was previously masked as the empty
  /// "no tickets" state) — SUP-1.
  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: KafiColors.pur.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(AppStrings.loadErrorTitle.tr,
              style: KafiTheme.nunito(13, color: KafiColors.td, w: FontWeight.w700)),
          const SizedBox(height: 14),
          TextButton(
            onPressed: controller.loadTickets,
            child: Text(AppStrings.retry.tr,
                style: KafiTheme.fredoka(12, color: KafiColors.pur, w: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent, size: 52, color: KafiColors.ts.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(AppStrings.supportEmpty.tr,
              style: KafiTheme.nunito(13, color: KafiColors.ts, w: FontWeight.w700)),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(AppStrings.supportEmptySub.tr,
                textAlign: TextAlign.center,
                style: KafiTheme.nunito(10, color: KafiColors.ts)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _openNewTicket,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: KafiColors.pur, borderRadius: BorderRadius.circular(12)),
              child: Text(AppStrings.supportNewTicket.tr,
                  style: KafiTheme.nunito(12, color: Colors.white, w: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketCard(TicketModel t) {
    return GestureDetector(
      onTap: () async {
        await Get.toNamed(Routes.supportTicket, arguments: t);
        await controller.loadTickets();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFEFE2FF), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x129B6EDB), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(t.subject.isNotEmpty ? t.subject : categoryLabel(t.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(12.5, color: KafiColors.td, w: FontWeight.w800)),
                ),
                statusChip(t.status),
              ],
            ),
            if ((t.lastMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(t.lastMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KafiTheme.nunito(10, color: KafiColors.tm)),
            ],
            const SizedBox(height: 7),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: KafiColors.purL, borderRadius: BorderRadius.circular(10)),
                  child: Text(categoryLabel(t.category),
                      style: KafiTheme.fredoka(8.5, color: const Color(0xFF6D3BC7), w: FontWeight.w700)),
                ),
                const Spacer(),
                Text(_time(t.lastMessageAt ?? t.createdAt),
                    style: KafiTheme.nunito(8.5, color: KafiColors.ts, w: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNewTicket() {
    Get.bottomSheet(
      const _NewTicketSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _time(DateTime dt) => RelativeTime.ago(dt);
}

/// Shared label + status-chip helpers (also used by the ticket thread screen).
String categoryLabel(TicketCategory c) => switch (c) {
      TicketCategory.account => AppStrings.supportCatAccount.tr,
      TicketCategory.payment => AppStrings.supportCatPayment.tr,
      TicketCategory.trial => AppStrings.supportCatTrial.tr,
      TicketCategory.hiring => AppStrings.supportCatHiring.tr,
      TicketCategory.technical => AppStrings.supportCatTechnical.tr,
      TicketCategory.other => AppStrings.supportCatOther.tr,
    };

Widget statusChip(TicketStatus s) {
  final (label, bg, fg) = switch (s) {
    TicketStatus.open => (AppStrings.supportStatusOpen.tr, KafiColors.ambL, KafiColors.ambD),
    TicketStatus.investigating =>
      (AppStrings.supportStatusInvestigating.tr, KafiColors.purpL, KafiColors.purpD),
    TicketStatus.resolved => (AppStrings.supportStatusResolved.tr, KafiColors.grnL, KafiColors.grnD),
    TicketStatus.closed =>
      (AppStrings.supportStatusClosed.tr, KafiColors.grey.withValues(alpha: 0.2), KafiColors.grey),
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: KafiTheme.fredoka(9, w: FontWeight.w700, color: fg)),
  );
}

/// Bottom-sheet form to open a new ticket. Stateful so its controllers are
/// disposed cleanly.
class _NewTicketSheet extends StatefulWidget {
  const _NewTicketSheet();

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  TicketCategory _category = TicketCategory.other;
  bool _busy = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.supportFillFields.tr);
      return;
    }
    setState(() => _busy = true);
    final ticket = await Get.find<TicketController>().createTicket(
      subject: subject,
      category: _category,
      message: message,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Get.back(); // close the sheet
    if (ticket != null) Get.toNamed(Routes.supportTicket, arguments: ticket);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: KafiColors.cardBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Text(AppStrings.supportNewTicket.tr, style: KafiTheme.pacifico(16, color: KafiColors.pur)),
            const SizedBox(height: 14),
            KafiTextField(label: AppStrings.supportSubjectLabel.tr, controller: _subject, purple: true),
            const SizedBox(height: 12),
            Text(AppStrings.supportCategoryLabel.tr,
                style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final c in TicketCategory.values)
                  KafiChip(
                    label: categoryLabel(c),
                    selected: _category == c,
                    variant: KafiChipVariant.purple,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            KafiTextField(
              label: AppStrings.supportMessageLabel.tr,
              controller: _message,
              purple: true,
              maxLines: 4,
              maxLength: 800,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KafiColors.pur,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppStrings.supportSubmit.tr,
                        style: KafiTheme.fredoka(13, color: Colors.white, w: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
