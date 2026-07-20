import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/dispute_controller.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/settings_controller.dart' show SettingsController;
import 'package:kafi_app/models/user_model.dart' show UserSettings;
import 'package:kafi_app/controllers/subscription_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/utils/app_navigation.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _profileHeader(authCtrl),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
          if (Get.find<AuthController>().currentUser.value?.isNanny == true) ...[
            _sectionHeader(AppStrings.editProfileSection.tr),
            _editTile('🪪', AppStrings.editPersonalInfo.tr, Routes.nannyInfo),
            _editTile('📸', AppStrings.editMedia.tr, Routes.nannyMedia),
            _editTile('💼', AppStrings.editExperience.tr, Routes.nannyExp),
            _editTile('📞', AppStrings.editReferences.tr, Routes.nannyRefs),
            _editTile('📄', AppStrings.editDocuments.tr, Routes.nannyDocs),
            const SizedBox(height: 24),
            _actionTile(Icons.work_outline, 'My applications', () => Get.toNamed(Routes.nannyApplications)),
            const SizedBox(height: 8),
          ] else if (Get.find<AuthController>().currentUser.value?.isFamily == true) ...[
            _actionTile(Icons.people_alt_outlined, AppStrings.familyApplicants.tr,
                () => Get.toNamed(Routes.familyApplicants)),
            _actionTile(Icons.edit_outlined, AppStrings.familyEditTitle.tr,
                () => Get.toNamed(Routes.familyEdit)),
            _actionTile(Icons.workspace_premium_outlined, AppStrings.settingsSubscription.tr,
                () => Get.toNamed(Routes.pricing)),
            const SizedBox(height: 8),
          ],
          // Notification-type toggles are hidden in the profile tab.
          if (!embedInShell) ...[
            _sectionHeader(AppStrings.settingsNotifications.tr),
            _switchTile(
              AppStrings.settingsPush.tr,
              AppStrings.settingsPushSub.tr,
              (s) => s.pushNotifications,
              (v) => controller.updateSetting('pushNotifications', v),
            ),
            _switchTile(
              AppStrings.settingsMessages.tr,
              AppStrings.settingsMessagesSub.tr,
              (s) => s.messageNotifications,
              (v) => controller.updateSetting('messageNotifications', v),
            ),
            _switchTile(
              AppStrings.settingsTrials.tr,
              AppStrings.settingsTrialsSub.tr,
              (s) => s.trialNotifications,
              (v) => controller.updateSetting('trialNotifications', v),
            ),
            _switchTile(
              AppStrings.settingsJobMatches.tr,
              AppStrings.settingsJobMatchesSub.tr,
              (s) => s.jobMatchNotifications,
              (v) => controller.updateSetting('jobMatchNotifications', v),
            ),
            _switchTile(
              AppStrings.settingsProfileViews.tr,
              AppStrings.settingsProfileViewsSub.tr,
              (s) => s.profileViewNotifications,
              (v) => controller.updateSetting('profileViewNotifications', v),
            ),
            _switchTile(
              AppStrings.settingsMarketing.tr,
              AppStrings.settingsMarketingSub.tr,
              (s) => s.marketingNotifications,
              (v) => controller.updateSetting('marketingNotifications', v),
            ),
            _switchTile(
              AppStrings.settingsEmail.tr,
              AppStrings.settingsEmailSub.tr,
              (s) => s.emailNotifications,
              (v) => controller.updateSetting('emailNotifications', v),
            ),
            const SizedBox(height: 24),
          ],
          // Privacy (show-online-status) and language are hidden in the profile tab.
          if (!embedInShell) ...[
            _sectionHeader(AppStrings.settingsPrivacy.tr),
            _switchTile(
              AppStrings.settingsOnline.tr,
              AppStrings.settingsOnlineSub.tr,
              (s) => s.showOnlineStatus,
              (v) => controller.updateSetting('showOnlineStatus', v),
            ),
            const SizedBox(height: 24),
            _sectionHeader(AppStrings.settingsLanguage.tr),
            _languageTile(),
            const SizedBox(height: 24),
          ],
          _sectionHeader(AppStrings.settingsAccount.tr),
          // Support tickets — available to both roles.
          _actionTile(
            Icons.support_agent,
            AppStrings.settingsSupport.tr,
            () => Get.toNamed(Routes.support),
          ),
          // My reports (disputes filed about another user) — both roles.
          _actionTile(
            Icons.flag_outlined,
            AppStrings.settingsMyReports.tr,
            () {
              Get.find<DisputeController>().loadDisputes();
              Get.toNamed(Routes.disputes);
            },
          ),
          // Restore purchases is family-only (nannies have no paid subscription).
          if (!_isNanny)
            _actionTile(
              Icons.restore,
              AppStrings.settingsRestorePurchases.tr,
              () async {
                await Get.find<SubscriptionController>().restorePurchases();
                Get.snackbar(AppStrings.settingsRestorePurchases.tr, 'Purchases restored');
              },
            ),
          _actionTile(
            Icons.description_outlined,
            AppStrings.settingsTerms.tr,
            () => Get.toNamed(Routes.terms),
          ),
          _actionTile(
            Icons.privacy_tip_outlined,
            AppStrings.settingsPrivacyPolicy.tr,
            () => Get.toNamed(Routes.privacy),
          ),
                  const SizedBox(height: 24),
                  _dangerZone(authCtrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader(AuthController authCtrl) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _heroColors,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (!embedInShell)
                GestureDetector(
                  onTap: AppNavigation.back,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.arrow_back, color: _accent, size: 20),
                  ),
                ),
              Expanded(
                child: Text(embedInShell ? AppStrings.navProfile.tr : AppStrings.settingsTitle.tr,
                    style: KafiTheme.pacifico(17, color: _titleColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final u = authCtrl.currentUser.value;
            final name = (u?.fullName?.isNotEmpty == true)
                ? u!.fullName!
                : (u?.isFamily == true ? 'Family' : 'User');
            final sub = (u?.email?.isNotEmpty == true) ? u!.email! : (u?.phone ?? '');
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
            final isFamily = u?.isFamily == true;
            return Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _avatarColors,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(initial,
                          style: KafiTheme.fredoka(20, color: Colors.white, w: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KafiTheme.nunito(13.5, color: KafiColors.td, w: FontWeight.w900)),
                        if (sub.isNotEmpty)
                          Text(sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KafiTheme.nunito(9.5, color: KafiColors.ts, w: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (isFamily)
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.familyEdit),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: KafiColors.purL,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(AppStrings.familyEditTitle.tr,
                            style: KafiTheme.fredoka(10, color: KafiColors.pur, w: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: KafiTheme.nunito(11, w: FontWeight.w800, color: KafiColors.tm)),
    );
  }

  Widget _switchTile(
    String title,
    String subtitle,
    bool Function(UserSettings s) readValue,
    ValueChanged<bool> onChanged,
  ) {
    return Obx(
      () {
        final on = readValue(controller.settings.value);
        return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
            boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
        ),
        child: SwitchListTile(
          title: Text(title, style: KafiTheme.fredoka(14, w: FontWeight.w500)),
          subtitle: Text(subtitle, style: KafiTheme.nunito(10, color: KafiColors.ts)),
          value: on,
          onChanged: onChanged,
          activeTrackColor: KafiColors.roseL,
          thumbColor: WidgetStatePropertyAll(KafiColors.roseD),
        ),
      );
      },
    );
  }

  Widget _languageTile() {
    return Obx(
      () {
        final lang = controller.settings.value.language;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
                  boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),]
          ),
          child: ListTile(
            leading: Icon(Icons.language, color: _accent),
            title: Text(AppStrings.settingsLanguage.tr,
                style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
            subtitle: Text(
              lang.toLowerCase().startsWith('ar') ? 'العربية' : 'English',
              style: KafiTheme.nunito(10, color: KafiColors.ts),
            ),
            trailing: Icon(Icons.chevron_right, color: _accent),
            onTap: () => Get.dialog(
              SimpleDialog(
                title: Text(AppStrings.settingsLanguage.tr),
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      controller.changeLanguage('en');
                      Get.back();
                    },
                    child: const Text('English'),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      controller.changeLanguage('ar');
                      Get.back();
                    },
                    child: const Text('العربية'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Theme — purple for family, rose for nanny (matches each home screen).
  bool get _isNanny => Get.find<AuthController>().currentUser.value?.isNanny == true;
  Color get _accent => _isNanny ? KafiColors.roseD : KafiColors.pur;
  Color get _bg => _isNanny ? KafiColors.nannyBg : KafiColors.bgLight;
  List<Color> get _heroColors =>
      _isNanny ? const [Color(0xFFFFE0EC), Color(0xFFFFF4EE)] : const [Color(0xFFEEE0FF), Color(0xFFF0D8FF)];
  Color get _titleColor => _isNanny ? KafiColors.roseD : const Color(0xFF5A2090);
  List<Color> get _avatarColors =>
      _isNanny ? const [KafiColors.rose, KafiColors.roseD] : const [Color(0xFF9B6EDB), Color(0xFFC084FC)];

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
       boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),]
      ),
      child: ListTile(
        leading: Icon(icon, color: _accent),
        title: Text(title, style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
        trailing: Icon(Icons.chevron_right, color: _accent),
        onTap: onTap,
      ),
    );
  }

  // Emoji-led tile used for the nanny "Edit profile" section. Opens the given
  // onboarding screen in edit mode (Save & Close instead of Next).
  Widget _editTile(String emoji, String title, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 20)),
        title: Text(title, style: KafiTheme.nunito(12, color: KafiColors.td, w: FontWeight.w700)),
        trailing: Icon(Icons.chevron_right, color: _accent),
        onTap: () => Get.toNamed(route, arguments: {'editMode': true}),
      ),
    );
  }

  Widget _dangerZone(AuthController authCtrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(AppStrings.settingsDangerZone.tr),
        Container(
          decoration: BoxDecoration(
            color: KafiColors.redL,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: KafiColors.redD),
            title: Text(AppStrings.settingsLogout.tr, style: KafiTheme.fredoka(14, w: FontWeight.w500, color: KafiColors.redD)),
            onTap: () => _showLogoutDialog(authCtrl),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: KafiColors.redD, width: 1),
          ),
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: KafiColors.redD),
            title: Text(AppStrings.settingsDeleteAccount.tr, style: KafiTheme.fredoka(14, w: FontWeight.w500, color: KafiColors.redD)),
            onTap: () => Get.toNamed(Routes.deleteAccount),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(AuthController authCtrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: KafiColors.redL,
                  shape: BoxShape.circle,
                  border: Border.all(color: KafiColors.redD.withValues(alpha: 0.25), width: 2),
                ),
                child: const Icon(Icons.logout, color: KafiColors.redD, size: 26),
              ),
              const SizedBox(height: 14),
              Text(AppStrings.settingsLogoutConfirm.tr,
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(15, color: KafiColors.td, w: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(AppStrings.settingsLogoutConfirmSub.tr,
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(11, color: KafiColors.ts, w: FontWeight.w600).copyWith(height: 1.4)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: KafiColors.cardBorder, width: 1.5),
                        ),
                        child: Text(AppStrings.cancel.tr,
                            style: KafiTheme.fredoka(12, color: KafiColors.td, w: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Get.back();
                        await authCtrl.signOut();
                        Get.offAllNamed(Routes.welcome);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), KafiColors.redD]),
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(color: KafiColors.redD.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Text(AppStrings.settingsLogout.tr,
                            style: KafiTheme.fredoka(12, color: Colors.white, w: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
