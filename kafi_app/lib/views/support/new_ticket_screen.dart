import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/ticket_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/ticket_model.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/support/support_screen.dart' show categoryLabel;
import 'package:kafi_app/views/widgets/kafi_chip.dart';
import 'package:kafi_app/views/widgets/kafi_text_field.dart';

/// Full-screen form to open a support ticket (replaces the old bottom sheet,
/// which could lose the form / feel like a "disconnect" on submit).
class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
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
    if (_busy) return;
    setState(() => _busy = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final ticket = await Get.find<TicketController>().createTicket(
        subject: subject,
        category: _category,
        message: message,
      );
      if (!mounted) return;
      if (ticket == null) {
        // createTicket already showed a snackbar — keep the form so they can retry.
        return;
      }
      // Replace this screen with the thread (do not Get.back first — that used
      // to pop Support itself when submitted from a sheet).
      await Get.offNamed(Routes.supportTicket, arguments: ticket);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: KafiColors.bgLight,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              _hero(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KafiTextField(
                        label: AppStrings.supportSubjectLabel.tr,
                        controller: _subject,
                        purple: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.supportCategoryLabel.tr,
                        style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800),
                      ),
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
                              onTap: () {
                                if (_busy) return;
                                setState(() => _category = c);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      KafiTextField(
                        label: AppStrings.supportMessageLabel.tr,
                        controller: _message,
                        purple: true,
                        maxLines: 6,
                        maxLength: 800,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KafiColors.pur,
                            disabledBackgroundColor:
                                KafiColors.pur.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  AppStrings.supportSubmit.tr,
                                  style: KafiTheme.fredoka(
                                    13,
                                    color: Colors.white,
                                    w: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            onTap: _busy ? null : AppNavigation.back,
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: KafiColors.pur, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.supportNewTicket.tr,
                  style: KafiTheme.pacifico(17, color: const Color(0xFF5A2090)),
                ),
                Text(
                  AppStrings.supportSubtitle.tr,
                  style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
