import 'package:get/get.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/notification_controller.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/services/connectivity_service.dart';
import 'package:kafi_app/services/firebase/fcm_notification_service.dart';
import 'package:kafi_app/services/firebase/firebase_auth_service.dart';
import 'package:kafi_app/services/firebase/firebase_storage_service.dart';
import 'package:kafi_app/services/firebase/firestore_application_service.dart';
import 'package:kafi_app/services/firebase/firestore_chat_service.dart';
import 'package:kafi_app/services/firebase/firestore_job_service.dart';
import 'package:kafi_app/services/firebase/firestore_dispute_service.dart';
import 'package:kafi_app/services/firebase/firestore_hire_service.dart';
import 'package:kafi_app/services/firebase/firestore_review_service.dart';
import 'package:kafi_app/services/firebase/firestore_ticket_service.dart';
import 'package:kafi_app/services/firebase/firestore_shortlist_service.dart';
import 'package:kafi_app/services/firebase/firestore_subscription_service.dart';
import 'package:kafi_app/services/firebase/firestore_trial_service.dart';
import 'package:kafi_app/services/firebase/firestore_user_service.dart';
import 'package:kafi_app/services/interfaces/i_application_service.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/interfaces/i_chat_service.dart';
import 'package:kafi_app/services/interfaces/i_dispute_service.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_review_service.dart';
import 'package:kafi_app/services/interfaces/i_ticket_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_notification_service.dart';
import 'package:kafi_app/services/interfaces/i_shortlist_service.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_subscription_service.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/location_service.dart';
import 'package:kafi_app/services/match_service.dart';
import 'package:kafi_app/services/mock/mock_application_service.dart';
import 'package:kafi_app/services/mock/mock_auth_service.dart';
import 'package:kafi_app/services/mock/mock_chat_service.dart';
import 'package:kafi_app/services/mock/mock_job_service.dart';
import 'package:kafi_app/services/mock/mock_notification_service.dart';
import 'package:kafi_app/services/mock/mock_dispute_service.dart';
import 'package:kafi_app/services/mock/mock_hire_service.dart';
import 'package:kafi_app/services/mock/mock_review_service.dart';
import 'package:kafi_app/services/mock/mock_ticket_service.dart';
import 'package:kafi_app/services/mock/mock_shortlist_service.dart';
import 'package:kafi_app/services/mock/mock_storage_service.dart';
import 'package:kafi_app/services/mock/mock_subscription_service.dart';
import 'package:kafi_app/services/mock/mock_trial_service.dart';
import 'package:kafi_app/services/mock/mock_user_service.dart';
import 'package:kafi_app/services/permission_service.dart';
import 'package:kafi_app/services/session_monitor.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final mockSubscription = AppConfig.subscriptionUsesMock;

    if (AppConfig.useMock) {
      Get.put<IAuthService>(MockAuthService(), permanent: true);
      Get.put<IUserService>(MockUserService(), permanent: true);
      Get.put<IStorageService>(MockStorageService(), permanent: true);
      Get.put<IJobService>(MockJobService(), permanent: true);
      Get.put<IChatService>(MockChatService(), permanent: true);
      Get.put<ITrialService>(MockTrialService(), permanent: true);
      Get.put<INotificationService>(MockNotificationService(), permanent: true);
      Get.put<ISubscriptionService>(MockSubscriptionService(), permanent: true);
      Get.put<IApplicationService>(MockApplicationService(), permanent: true);
      Get.put<IShortlistService>(MockShortlistService(), permanent: true);
      Get.put<IDisputeService>(MockDisputeService(), permanent: true);
      Get.put<IReviewService>(MockReviewService(), permanent: true);
      Get.put<IHireService>(MockHireService(), permanent: true);
      Get.put<ITicketService>(MockTicketService(), permanent: true);
    } else {
      Get.put<IAuthService>(FirebaseAuthService(), permanent: true);
      Get.put<IUserService>(FirestoreUserService(), permanent: true);
      Get.put<IStorageService>(FirebaseStorageServiceImpl(), permanent: true);
      Get.put<IJobService>(FirestoreJobService(), permanent: true);
      Get.put<IChatService>(FirestoreChatService(), permanent: true);
      Get.put<ITrialService>(FirestoreTrialService(), permanent: true);
      Get.put<INotificationService>(FcmNotificationService(), permanent: true);
      Get.put<ISubscriptionService>(
        mockSubscription ? MockSubscriptionService() : FirestoreSubscriptionService(),
        permanent: true,
      );
      Get.put<IApplicationService>(FirestoreApplicationService(), permanent: true);
      Get.put<IShortlistService>(FirestoreShortlistService(), permanent: true);
      Get.put<IDisputeService>(FirestoreDisputeService(), permanent: true);
      Get.put<IReviewService>(FirestoreReviewService(), permanent: true);
      Get.put<IHireService>(FirestoreHireService(), permanent: true);
      Get.put<ITicketService>(FirestoreTicketService(), permanent: true);
    }

    Get.put(PermissionService(), permanent: true);
    Get.put(LocationService(), permanent: true);
    Get.put(MatchService(), permanent: true);
    Get.put(ConnectivityService(), permanent: true);
    Get.put(SessionMonitor(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(PermissionController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
  }
}
