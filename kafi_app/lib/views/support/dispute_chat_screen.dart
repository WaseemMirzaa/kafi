import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/dispute_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/disputes_screen.dart'
    show disputeStatusChip, disputeCategoryLabel;
import 'package:url_launcher/url_launcher.dart';

/// The support conversation for a single dispute (reporter ↔ admin), realtime.
class DisputeChatScreen extends StatefulWidget {
  const DisputeChatScreen({super.key});

  @override
  State<DisputeChatScreen> createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends State<DisputeChatScreen> {
  final DisputeController controller = Get.find<DisputeController>();
  late final DisputeModel _dispute;

  @override
  void initState() {
    super.initState();
    _dispute = Get.arguments as DisputeModel;
    controller.openDisputeThread(_dispute);
  }

  @override
  void dispose() {
    controller.closeDisputeThread();
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
            _resolutionBanner(),
            _attachmentsStrip(),
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
            Obx(() {
              if (controller.isDisputeClosed) {
                final d = controller.activeDispute.value ?? _dispute;
                return _closedBanner(d);
              }
              return _composer();
            }),
          ],
        ),
      ),
    );
  }

  Widget _closedBanner(DisputeModel d) {
    final label = d.status == DisputeStatus.resolved
        ? AppStrings.supportStatusResolved.tr
        : AppStrings.supportStatusClosed.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FFF5),
        border: Border(top: BorderSide(color: Color(0xFFDCEFE4))),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: KafiTheme.nunito(11, color: KafiColors.grnD, w: FontWeight.w700),
      ),
    );
  }

  Widget _header() {
    return Obx(() {
      final d = controller.activeDispute.value ?? _dispute;
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
                  Text(disputeCategoryLabel(d.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.fredoka(13, color: const Color(0xFF5A2090), w: FontWeight.w800)),
                  Text(AppStrings.supportAgentName.tr,
                      style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
                ],
              ),
            ),
            disputeStatusChip(d.status),
          ],
        ),
      );
    });
  }

  /// Shows the admin's resolution once the dispute is resolved/dismissed.
  Widget _resolutionBanner() {
    return Obx(() {
      final d = controller.activeDispute.value ?? _dispute;
      final resolution = d.resolution;
      final closed =
          d.status == DisputeStatus.resolved || d.status == DisputeStatus.dismissed;
      if (!closed || resolution == null || resolution.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: KafiColors.grnL,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KafiColors.grnD.withValues(alpha: 0.25), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.disputeResolutionLabel.tr,
                style: KafiTheme.fredoka(10, color: KafiColors.grnD, w: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(resolution,
                style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w500)),
          ],
        ),
      );
    });
  }

  Widget _attachmentsStrip() {
    return Obx(() {
      final d = controller.activeDispute.value ?? _dispute;
      if (d.attachments.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFE2FF), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.reportAttachmentsTitle.tr,
                style: KafiTheme.fredoka(10, color: KafiColors.pur, w: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: d.attachments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final a = d.attachments[i];
                  return GestureDetector(
                    onTap: () => _openAttachment(a),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: KafiColors.inputBgP,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: KafiColors.purB),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: a.isImage
                          ? Image.network(a.url, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: KafiColors.ts,
                                  ))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf, color: KafiColors.pur, size: 22),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    a.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: KafiTheme.nunito(7, color: KafiColors.tm),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _openAttachment(DisputeAttachment a) async {
    final uri = Uri.tryParse(a.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _bubble(DisputeMessage m) {
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
