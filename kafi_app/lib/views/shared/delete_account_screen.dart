import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/utils/errors/error_handler.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

/// Delete Account flow per App Documentation Screen 29B
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _authCtrl = Get.find<AuthController>();
  final _confirmController = TextEditingController();
  final RxInt _step = 1.obs;
  final RxString _selectedReason = ''.obs;
  final RxBool _isDeleting = false.obs;

  List<String> get _reasons => [
        AppStrings.deleteReasonFoundNannyJob.tr,
        AppStrings.deleteReasonNotSatisfied.tr,
        AppStrings.deleteReasonPrivacy.tr,
        AppStrings.deleteReasonTooExpensive.tr,
        AppStrings.deleteReasonAppIssues.tr,
        AppStrings.deleteReasonOther.tr,
      ];

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isNanny => _authCtrl.currentUser.value?.isNanny == true;
  List<Color> get _heroColors =>
      _isNanny ? const [Color(0xFFFFE0EC), Color(0xFFFFF4EE)] : const [Color(0xFFEEE0FF), Color(0xFFF0D8FF)];
  Color get _accent => _isNanny ? KafiColors.roseD : KafiColors.pur;
  Color get _titleColor => _isNanny ? KafiColors.roseD : const Color(0xFF5A2090);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KafiColors.bgLight,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _hero(),
            Expanded(child: Obx(() => _step.value == 1 ? _buildStep1() : _buildStep2())),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _heroColors,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: AppNavigation.back,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, color: _accent, size: 20),
            ),
          ),
          Expanded(
            child: Text(AppStrings.deleteAccountTitle.tr,
                style: KafiTheme.pacifico(17, color: _titleColor)),
          ),
        ],
      ),
    );
  }

  Widget _reasonTile(String reason) {
    return Obx(() {
      final selected = _selectedReason.value == reason;
      return GestureDetector(
        onTap: () => _selectedReason.value = reason,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF0F0) : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: const Color(0xFFFFE8EF), width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? KafiColors.redD : KafiColors.ts,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(reason,
                  style: KafiTheme.nunito(11,
                      color: selected ? KafiColors.redD : KafiColors.td,
                      w: selected ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 30),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              shape: BoxShape.circle,
              border: Border.all(color: KafiColors.redD.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.warning_amber_rounded, size: 30, color: KafiColors.redD),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.deleteAccountQuestion.tr,
            style: KafiTheme.nunito(16, color: KafiColors.td, w: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.deleteAccountWarning.tr,
            style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KafiColors.redD.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.deleteWillRemove.tr,
                  style: KafiTheme.nunito(11, color: KafiColors.redD, w: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _deleteItem(AppStrings.deleteItemProfile.tr),
                _deleteItem(AppStrings.deleteItemChats.tr),
                _deleteItem(AppStrings.deleteItemTrials.tr),
                _deleteItem(AppStrings.deleteItemSubscription.tr),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.deleteSelectReason.tr,
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFFFE8EF), width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x10FF5F96), blurRadius: 6)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Column(children: _reasons.map(_reasonTile).toList()),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFFFD8E8), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppStrings.cancel.tr,
                      style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ElevatedButton(
                      onPressed: _selectedReason.value.isNotEmpty ? () => _step.value = 2 : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KafiColors.redD,
                        disabledBackgroundColor: KafiColors.redD.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        AppStrings.deleteAccountBtn.tr,
                        style: KafiTheme.nunito(12, color: Colors.white, w: FontWeight.w800),
                      ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 30),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5E5),
              shape: BoxShape.circle,
              border: Border.all(color: KafiColors.redD.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.warning_amber_rounded, size: 30, color: KafiColors.redD),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.deleteFinalConfirm.tr,
            style: KafiTheme.nunito(16, color: KafiColors.td, w: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.deleteFinalWarning.tr,
            style: KafiTheme.nunito(10.5, color: KafiColors.ts, w: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.deleteTypeDelete.tr,
              style: KafiTheme.nunito(11, color: KafiColors.td, w: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            textAlign: TextAlign.center,
            style: KafiTheme.nunito(14, color: KafiColors.td, w: FontWeight.w800),
            decoration: InputDecoration(
              hintText: AppStrings.deleteConfirmWord.tr,
              hintStyle: KafiTheme.nunito(14, color: KafiColors.ts),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.redD),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: KafiColors.ts.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: KafiColors.redD, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _step.value = 1,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFFFD8E8), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppStrings.goBack.tr,
                      style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => ElevatedButton(
                      onPressed: _confirmController.text.toUpperCase() ==
                                  AppStrings.deleteConfirmWord.tr.toUpperCase() &&
                              !_isDeleting.value
                          ? _deleteAccount
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KafiColors.redD,
                        disabledBackgroundColor: KafiColors.redD.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isDeleting.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              AppStrings.deletePermanently.tr,
                              style: KafiTheme.nunito(12, color: Colors.white, w: FontWeight.w800),
                            ),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.close, size: 14, color: KafiColors.redD),
          const SizedBox(width: 7),
          Text(text, style: KafiTheme.nunito(10, color: KafiColors.redD, w: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    _isDeleting.value = true;

    try {
      await _authCtrl.deleteAccount(_selectedReason.value);
      _isDeleting.value = false;

      Get.snackbar(
        AppStrings.accountDeleted.tr,
        AppStrings.accountDeletedMessage.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: KafiColors.grnL,
        colorText: KafiColors.grnD,
      );
      Get.offAllNamed(Routes.welcome);
    } catch (e, stack) {
      _isDeleting.value = false;
      ErrorHandler.handle(e, stack: stack, context: 'DeleteAccountScreen._deleteAccount');
    }
  }
}
