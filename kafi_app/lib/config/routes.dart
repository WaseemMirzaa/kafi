import 'package:get/get.dart';
import 'package:kafi_app/bindings/auth_binding.dart';
import 'package:kafi_app/bindings/family_binding.dart';
import 'package:kafi_app/bindings/nanny_binding.dart';
import 'package:kafi_app/views/auth/create_password_screen.dart';
import 'package:kafi_app/views/auth/password_reset_screen.dart';
import 'package:kafi_app/views/auth/login_family_screen.dart';
import 'package:kafi_app/views/auth/login_nanny_screen.dart';
import 'package:kafi_app/views/auth/otp_verify_screen.dart';
import 'package:kafi_app/views/auth/welcome_screen.dart';
import 'package:kafi_app/views/family/family_shell_screen.dart';
import 'package:kafi_app/views/family/compare_screen.dart';
import 'package:kafi_app/views/family/family_edit_screen.dart';
import 'package:kafi_app/views/family/family_form_screen.dart';
import 'package:kafi_app/views/family/notifications_screen.dart';
import 'package:kafi_app/views/family/pricing_screen.dart';
import 'package:kafi_app/views/family/profile_locked_screen.dart';
import 'package:kafi_app/views/family/profile_relocked_screen.dart';
import 'package:kafi_app/views/family/profile_unlocked_screen.dart';
import 'package:kafi_app/views/family/shortlist_screen.dart';
import 'package:kafi_app/views/family/smart_match_screen.dart';
import 'package:kafi_app/views/family/trial_offer_screen.dart';
import 'package:kafi_app/views/family/trial_screen.dart';
import 'package:kafi_app/views/family/video_player_screen.dart';
import 'package:kafi_app/views/legal/legal_screen.dart';
import 'package:kafi_app/views/nanny/job_detail_screen.dart';
import 'package:kafi_app/views/nanny/application_detail_screen.dart';
import 'package:kafi_app/views/nanny/my_applications_screen.dart';
import 'package:kafi_app/views/nanny/nanny_shell_screen.dart';
import 'package:kafi_app/views/nanny/nanny_docs_screen.dart';
import 'package:kafi_app/views/nanny/nanny_edit_profile_screen.dart';
import 'package:kafi_app/views/nanny/nanny_exp_screen.dart';
import 'package:kafi_app/views/nanny/nanny_info_screen.dart';
import 'package:kafi_app/views/nanny/nanny_media_screen.dart';
import 'package:kafi_app/views/nanny/nanny_pending_screen.dart';
import 'package:kafi_app/views/nanny/nanny_refs_screen.dart';
import 'package:kafi_app/views/shared/delete_account_screen.dart';

abstract class Routes {
  static const welcome = '/';
  static const loginNanny = '/login-nanny';
  static const loginFamily = '/login-family';
  static const otpVerify = '/otp-verify';
  static const createPassword = '/create-password';

  static const nannyInfo = '/nanny-info';
  static const nannyMedia = '/nanny-media';
  static const nannyExp = '/nanny-exp';
  static const nannyRefs = '/nanny-refs';
  static const nannyDocs = '/nanny-docs';
  static const nannyPending = '/nanny-pending';
  static const nannyHome = '/nanny-home';
  static const nannyJobs = '/nanny-jobs';
  static const nannyJobDetail = '/nanny-job-detail';
  static const nannyApplications = '/nanny-applications';
  static const nannyApplicationDetail = '/nanny-application-detail';
  static const nannyEditProfile = '/nanny-edit-profile';

  static const familyForm = '/family-form';
  static const familyEdit = '/family-edit';
  static const browse = '/browse';
  static const profileLocked = '/profile-locked';
  static const profileRelocked = '/profile-relocked';
  static const profileUnlocked = '/profile-unlocked';
  static const chat = '/chat';
  static const smartMatch = '/smart-match';
  static const trial = '/trial';
  static const trialOffer = '/trial-offer';
  static const pricing = '/pricing';
  static const shortlist = '/shortlist';
  static const compare = '/compare';
  static const settings = '/settings';
  static const notifications = '/notifications';
  static const passwordReset = '/password-reset';
  static const deleteAccount = '/delete-account';

  static const videoPlayer = '/video-player';
  static const terms = '/terms';
  static const privacy = '/privacy';
}

class AppRoutes {
  static final routes = <GetPage>[
    GetPage(name: Routes.welcome, page: () => const WelcomeScreen()),
    GetPage(name: Routes.loginNanny, page: () => const LoginNannyScreen(), binding: AuthBinding()),
    GetPage(name: Routes.loginFamily, page: () => const LoginFamilyScreen(), binding: AuthBinding()),
    GetPage(name: Routes.otpVerify, page: () => const OtpVerifyScreen(), binding: AuthBinding()),
    GetPage(name: Routes.createPassword, page: () => const CreatePasswordScreen(), binding: AuthBinding()),
    GetPage(name: Routes.nannyInfo, page: () => const NannyInfoScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyMedia, page: () => const NannyMediaScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyExp, page: () => const NannyExpScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyRefs, page: () => const NannyRefsScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyDocs, page: () => const NannyDocsScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyPending, page: () => const NannyPendingScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyHome, page: () => const NannyShellScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyJobs, page: () => const NannyShellScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyJobDetail, page: () => const JobDetailScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyApplications, page: () => const MyApplicationsScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyApplicationDetail, page: () => const ApplicationDetailScreen(), binding: NannyBinding()),
    GetPage(name: Routes.nannyEditProfile, page: () => const NannyEditProfileScreen(), binding: NannyBinding()),
    GetPage(name: Routes.familyForm, page: () => const FamilyFormScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.familyEdit, page: () => const FamilyEditScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.browse, page: () => const FamilyShellScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.profileLocked, page: () => const ProfileLockedScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.profileRelocked, page: () => const ProfileRelockedScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.profileUnlocked, page: () => const ProfileUnlockedScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.chat, page: () => const FamilyShellScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.smartMatch, page: () => const SmartMatchScreen(), binding: NannyBinding()),
    GetPage(name: Routes.trial, page: () => const TrialScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.pricing, page: () => const PricingScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.shortlist, page: () => const ShortlistScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.trialOffer, page: () => const TrialOfferScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.settings, page: () => const FamilyShellScreen(), binding: FamilyBinding()),
    // Notifications relies only on the permanent NotificationController/AuthController,
    // so it carries no role-specific binding (works for both family & nanny).
    GetPage(name: Routes.notifications, page: () => const NotificationsScreen()),
    GetPage(name: Routes.terms, page: () => const LegalScreen.terms()),
    GetPage(name: Routes.privacy, page: () => const LegalScreen.privacy()),
    GetPage(name: Routes.deleteAccount, page: () => const DeleteAccountScreen(), binding: AuthBinding()),
    GetPage(name: Routes.passwordReset, page: () => const PasswordResetScreen()),
    GetPage(name: Routes.compare, page: () => const CompareScreen(), binding: FamilyBinding()),
    GetPage(name: Routes.videoPlayer, page: () => const VideoPlayerScreen()),
  ];
}
