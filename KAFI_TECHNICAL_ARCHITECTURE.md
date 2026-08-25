# KAFI - Technical Architecture Document
## Flutter (GetX) + Firebase + React JS Admin Panel

---

# TABLE OF CONTENTS

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [GetX Controllers](#3-getx-controllers)
4. [Services Layer](#4-services-layer)
5. [Mocked Mode Configuration](#5-mocked-mode-configuration)
6. [Firebase Cloud Firestore Architecture](#6-firebase-cloud-firestore-architecture)
7. [Firebase Storage Architecture](#7-firebase-storage-architecture)
8. [Permission Handling](#8-permission-handling)
9. [Location Flows](#9-location-flows)
10. [Push Notifications Implementation](#10-push-notifications-implementation)
11. [Admin Panel (React JS)](#11-admin-panel-react-js)
12. [Security Rules](#12-security-rules)
13. [Error Handling Architecture](#13-error-handling-architecture)
14. [Edge Cases Summary](#14-edge-cases-summary)
15. [Permission Configuration Files](#15-permission-configuration-files)
16. [Operations & Monitoring](#16-operations--monitoring)
17. [Testing Strategy](#17-testing-strategy)
18. [Subscription Lockdown Architecture](#18-subscription-lockdown-architecture-post-expiration-access-control)

---

# 1. ARCHITECTURE OVERVIEW

## 1.1 Tech Stack

| Layer | Technology |
|-------|------------|
| **Mobile App** | Flutter 3.x + Dart |
| **State Management** | GetX (Get) |
| **Routing** | GetX Routes |
| **Dependency Injection** | GetX Bindings |
| **Backend** | Firebase (Firestore, Auth, Storage, FCM) |
| **Subscriptions** | RevenueCat SDK |
| **Admin Panel** | React JS + TypeScript |
| **Admin Backend** | Firebase (same Firestore) |

## 1.2 Layered Architecture

```
┌─────────────────────────────────────┐
│         UI (Views/Screens)          │
├─────────────────────────────────────┤
│      GetX Controllers (Logic)       │
├─────────────────────────────────────┤
│   Services (Abstract Interfaces)    │
├──────────────────┬──────────────────┤
│ FirebaseService  │   MockService    │
│  Implementation  │  Implementation  │
└──────────────────┴──────────────────┘
```

## 1.3 Mode Switching

Single environment flag in `main.dart` switches between:
- **Production Mode**: Real Firebase calls
- **Mocked Mode**: Local dummy data, same flows

---

# 2. PROJECT STRUCTURE

```
kafi_app/
├── lib/
│   ├── main.dart                    # Entry point + mode switcher
│   ├── config/
│   │   ├── app_config.dart          # USE_MOCK flag, env settings
│   │   ├── firebase_config.dart
│   │   └── routes.dart
│   ├── bindings/
│   │   ├── initial_binding.dart     # Services injection
│   │   ├── auth_binding.dart
│   │   ├── nanny_binding.dart
│   │   └── family_binding.dart
│   ├── controllers/
│   │   ├── auth_controller.dart
│   │   ├── nanny_profile_controller.dart
│   │   ├── family_profile_controller.dart
│   │   ├── job_post_controller.dart
│   │   ├── browse_controller.dart
│   │   ├── chat_controller.dart
│   │   ├── trial_controller.dart
│   │   ├── subscription_controller.dart
│   │   ├── notification_controller.dart
│   │   ├── shortlist_controller.dart
│   │   ├── application_controller.dart
│   │   ├── settings_controller.dart
│   │   └── permission_controller.dart
│   ├── services/
│   │   ├── interfaces/
│   │   │   ├── i_auth_service.dart
│   │   │   ├── i_user_service.dart
│   │   │   ├── i_job_service.dart
│   │   │   ├── i_chat_service.dart
│   │   │   ├── i_trial_service.dart
│   │   │   ├── i_storage_service.dart
│   │   │   ├── i_notification_service.dart
│   │   │   └── i_subscription_service.dart
│   │   ├── firebase/
│   │   │   ├── firebase_auth_service.dart
│   │   │   ├── firestore_user_service.dart
│   │   │   ├── firestore_job_service.dart
│   │   │   ├── firestore_chat_service.dart
│   │   │   ├── firestore_trial_service.dart
│   │   │   ├── firebase_storage_service.dart
│   │   │   ├── fcm_notification_service.dart
│   │   │   └── revenuecat_subscription_service.dart
│   │   ├── mock/
│   │   │   ├── mock_auth_service.dart
│   │   │   ├── mock_user_service.dart
│   │   │   ├── mock_job_service.dart
│   │   │   ├── mock_chat_service.dart
│   │   │   ├── mock_trial_service.dart
│   │   │   ├── mock_storage_service.dart
│   │   │   ├── mock_notification_service.dart
│   │   │   └── mock_subscription_service.dart
│   │   ├── location_service.dart
│   │   └── permission_service.dart
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── nanny_model.dart
│   │   ├── family_model.dart
│   │   ├── job_post_model.dart
│   │   ├── application_model.dart
│   │   ├── trial_model.dart
│   │   ├── chat_model.dart
│   │   ├── notification_model.dart
│   │   └── subscription_model.dart
│   ├── views/
│   │   ├── auth/
│   │   ├── nanny/
│   │   ├── family/
│   │   ├── shared/
│   │   └── widgets/
│   ├── data/
│   │   └── mock/
│   │       ├── mock_nannies.dart
│   │       ├── mock_families.dart
│   │       ├── mock_jobs.dart
│   │       └── mock_chats.dart
│   └── utils/
│       ├── validators.dart
│       ├── helpers.dart
│       └── constants.dart
└── pubspec.yaml
```

---

# 3. GETX CONTROLLERS

## 3.1 AuthController

```dart
class AuthController extends GetxController {
  final IAuthService _authService = Get.find();
  
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxBool isLoading = false.obs;
  RxString phoneNumber = ''.obs;
  RxString countryCode = '+971'.obs;
  RxString verificationId = ''.obs;
  RxString otpCode = ''.obs;
  RxInt otpTimer = 300.obs;
  
  Future<void> sendOtp();
  Future<void> verifyOtp();
  Future<void> resendOtp();
  Future<void> createPassword(String password);
  Future<void> loginWithPassword(String phone, String password);
  Future<void> forgotPassword();
  Future<void> logout();
  Future<void> deleteAccount();
  void setUserRole(UserType type);
}
```

## 3.2 NannyProfileController

```dart
class NannyProfileController extends GetxController {
  final IUserService _userService = Get.find();
  final IStorageService _storageService = Get.find();
  final PermissionService _permissionService = Get.find();
  
  Rx<NannyModel?> nanny = Rx<NannyModel?>(null);
  RxInt currentStep = 1.obs;
  RxList<File> photos = <File>[].obs;
  Rx<File?> introVideo = Rx<File?>(null);
  RxList<WorkExperience> experiences = <WorkExperience>[].obs;
  RxList<Reference> references = <Reference>[].obs;
  Rx<NannyDocuments> documents = NannyDocuments().obs;
  RxDouble profileScore = 0.0.obs;
  
  Future<void> savePersonalInfo(Map<String, dynamic> data);
  Future<void> uploadPhoto(File file);
  Future<void> removePhoto(int index);
  Future<void> uploadVideo(File file);
  Future<void> addExperience(WorkExperience exp);
  Future<void> addReference(Reference ref);
  Future<void> uploadDocument(DocumentType type, File file);
  Future<void> submitForReview();
  void calculateProfileScore();
}
```

## 3.3 FamilyProfileController

```dart
class FamilyProfileController extends GetxController {
  Rx<FamilyModel?> family = Rx<FamilyModel?>(null);
  RxInt currentStep = 1.obs;
  
  Future<void> saveFamilyInfo(Map<String, dynamic> data);
  Future<void> saveJobRequirements(Map<String, dynamic> data);
  RxInt get freeContactsRemaining;
  RxBool get isSubscribed;
}
```

## 3.4 JobPostController

```dart
class JobPostController extends GetxController {
  final IJobService _jobService = Get.find();
  
  RxList<JobPost> myJobs = <JobPost>[].obs;
  Rx<JobPost?> currentJob = Rx<JobPost?>(null);
  
  Future<void> createJobPost(JobPost job);
  Future<void> updateJobPost(String id, Map<String, dynamic> data);
  Future<void> pauseJob(String id);
  Future<void> closeJob(String id);
  Stream<List<JobPost>> watchMyJobs();
}
```

## 3.5 BrowseController (Family)

```dart
class BrowseController extends GetxController {
  final IUserService _userService = Get.find();
  
  RxList<NannyModel> nannies = <NannyModel>[].obs;
  RxList<NannyModel> filteredNannies = <NannyModel>[].obs;
  RxString searchQuery = ''.obs;
  Rx<NannyFilter> filter = NannyFilter().obs;
  RxBool isLoading = false.obs;
  
  Future<void> loadNannies();
  void applyFilter(NannyFilter filter);
  void searchNannies(String query);
  Future<bool> canViewProfile(String nannyId);
  Future<void> recordProfileView(String nannyId);
  double calculateMatchScore(NannyModel nanny, JobPost job);
}
```

## 3.6 ChatController

```dart
class ChatController extends GetxController {
  final IChatService _chatService = Get.find();
  final SubscriptionController _sub = Get.find();
  
  RxList<ChatThread> threads = <ChatThread>[].obs;
  Rx<ChatThread?> currentThread = Rx<ChatThread?>(null);
  RxList<Message> messages = <Message>[].obs;
  RxString messageInput = ''.obs;
  
  // Subscription gate for families
  RxBool isLocked = false.obs; // True when family sub is expired
  
  /// For family users: returns only threads with active trials when sub expired.
  /// For nanny users: always returns all threads.
  List<ChatThread> get visibleThreads {
    if (AuthController.to.currentUser.role == UserRole.NANNY) return threads;
    if (_sub.hasActiveAccess) return threads;
    // Expired: only show threads with active trials
    return threads.where((t) => t.hasActiveTrial).toList();
  }
  
  Future<void> loadThreads();
  Stream<List<Message>> watchMessages(String threadId);
  
  Future<void> sendMessage(String content) async {
    // Family must have active subscription OR thread has active trial
    if (AuthController.to.currentUser.role == UserRole.FAMILY) {
      final thread = currentThread.value;
      if (!_sub.hasActiveAccess && !(thread?.hasActiveTrial ?? false)) {
        ErrorHandler.showPaywall('chat_send', reason: 'subscription_expired');
        return;
      }
    }
    await _chatService.sendMessage(currentThread.value!.id, content);
  }
  
  Future<void> openThread(String threadId) async {
    if (AuthController.to.currentUser.role == UserRole.FAMILY) {
      final thread = threads.firstWhere((t) => t.id == threadId);
      if (!_sub.hasActiveAccess && !thread.hasActiveTrial) {
        // Show paywall instead of opening
        Get.toNamed('/subscription', arguments: {
          'reason': 'chat_locked',
          'returnTo': '/chat/$threadId',
        });
        return;
      }
    }
    // Normal open
    currentThread.value = threads.firstWhere((t) => t.id == threadId);
  }
  
  Future<void> sendTrialOffer(TrialOffer offer);
  Future<void> markAsRead(String threadId);
  Future<void> openOrCreateThread(String otherUserId);
  
  /// Called by SubscriptionController._applyLockdown()
  void onSubscriptionLocked() {
    isLocked.value = true;
    // Force close any open chat
    currentThread.value = null;
    messages.clear();
  }
  
  /// Called when re-subscription succeeds
  void onSubscriptionRestored() {
    isLocked.value = false;
    loadThreads(); // Re-fetch
  }
}
```

## 3.7 TrialController

```dart
class TrialController extends GetxController {
  final ITrialService _trialService = Get.find();
  
  RxList<Trial> trials = <Trial>[].obs;
  Rx<Trial?> activeTrial = Rx<Trial?>(null);
  Rx<TrialEvaluation> evaluation = TrialEvaluation().obs;
  RxInt remainingHours = 0.obs;
  
  Future<void> createTrial(Trial trial);
  Future<void> acceptTrial(String trialId);
  Future<void> declineTrial(String trialId);
  Future<void> counterTrial(String trialId, CounterOffer counter);
  Future<void> updateEvaluation(TrialEvaluation eval);
  Future<void> completeTrialAsHired(String trialId);
  Future<void> completeTrialAsNotHired(String trialId);
  Future<void> confirmPayment(String trialId);
  Future<void> reportPaymentIssue(String trialId);
}
```

## 3.8 SubscriptionController

```dart
class SubscriptionController extends GetxController {
  final ISubscriptionService _subService = Get.find();
  
  Rx<FamilySubscription> subscription = FamilySubscription().obs;
  RxList<SubscriptionPlan> availablePlans = <SubscriptionPlan>[].obs;
  RxBool isLoading = false.obs;
  
  // Derived computed states (used everywhere for gating UI)
  bool get hasActiveAccess =>
      subscription.value.status == SubscriptionStatus.ACTIVE ||
      subscription.value.status == SubscriptionStatus.CANCELLED_ACTIVE; // cancelled but within end-date
  
  bool get isExpired =>
      subscription.value.status == SubscriptionStatus.EXPIRED ||
      subscription.value.status == SubscriptionStatus.PAYMENT_FAILED;
  
  bool get contactsHidden => isExpired; // family loses contact access
  bool get chatLocked => isExpired;     // family chat list hidden
  
  Future<void> loadPlans();
  Future<void> purchasePlan(String planId);
  Future<void> restorePurchases();
  Future<void> cancelSubscription();
  Future<bool> isActive();
  Future<int> freeContactsRemaining();
  
  // Lockdown enforcement
  /// Called on app start, foreground resume, and Cloud Function trigger.
  /// Updates subscription state from RevenueCat and applies lockdown if expired.
  Future<void> refreshAndEnforce() async {
    final fresh = await _subService.getSubscription();
    subscription.value = fresh;
    if (isExpired) {
      _applyLockdown();
    }
  }
  
  void _applyLockdown() {
    // Triggers UI hide of chat list, phone numbers, etc.
    // ChatController & ProfileController react via Rx observers.
    Get.find<ChatController>().onSubscriptionLocked();
    Get.find<NannyProfileController>().onSubscriptionLocked();
  }
  
  /// Used by UI to gate any "premium" action.
  /// Returns true if access granted, false if paywall shown.
  bool requireSubscription(String featureName, {String? trialId}) {
    // Exception: active trial bypasses lockdown for trial chat/contacts
    if (trialId != null && _isActiveTrial(trialId)) return true;
    
    if (hasActiveAccess) return true;
    
    // Free contact path: only for status=FREE
    if (subscription.value.status == SubscriptionStatus.FREE) {
      // Caller checks freeContactsRemaining()
      return false;
    }
    
    // Expired: always show paywall
    Get.toNamed('/subscription', arguments: {'reason': 'expired', 'feature': featureName});
    return false;
  }
  
  bool _isActiveTrial(String trialId) {
    final trials = Get.find<TrialController>().myTrials;
    return trials.any((t) => t.id == trialId && t.status == TrialStatus.ACTIVE);
  }
}
```

## 3.9 NotificationController

```dart
class NotificationController extends GetxController {
  final INotificationService _notifService = Get.find();
  
  RxList<AppNotification> notifications = <AppNotification>[].obs;
  RxInt unreadCount = 0.obs;
  
  Future<void> initFCM();
  Future<void> requestPermission();
  Future<void> loadNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  void handleNotificationTap(RemoteMessage message);
}
```

## 3.10 ApplicationController, ShortlistController, SettingsController, PermissionController

```dart
class ApplicationController extends GetxController {
  RxList<Application> myApplications = <Application>[].obs;
  Future<void> applyToJob(String jobId, String? coverMessage);
  Future<void> withdrawApplication(String appId);
  Future<List<Application>> getApplicationsForJob(String jobId);
}

class ShortlistController extends GetxController {
  RxList<String> shortlistedNannyIds = <String>[].obs;
  Future<void> addToShortlist(String nannyId);
  Future<void> removeFromShortlist(String nannyId);
  Future<void> compareNannies(List<String> nannyIds);
}

class SettingsController extends GetxController {
  Rx<UserSettings> settings = UserSettings().obs;
  Future<void> updateNotificationSettings(NotificationSettings ns);
  Future<void> updateLanguage(String lang);
  Future<void> updatePrivacy(PrivacySettings ps);
}

class PermissionController extends GetxController {
  RxBool hasNotificationPermission = false.obs;
  RxBool hasCameraPermission = false.obs;
  RxBool hasGalleryPermission = false.obs;
  RxBool hasMicrophonePermission = false.obs;
  RxBool hasLocationPermission = false.obs;
  RxBool hasContactsPermission = false.obs;
  
  Future<void> checkAllPermissions();
  Future<bool> requestNotification();
  Future<bool> requestCamera();
  Future<bool> requestGallery();
  Future<bool> requestMicrophone();
  Future<bool> requestLocation();
  Future<void> openAppSettings();
}
```

---

# 4. SERVICES LAYER

## 4.1 Service Interfaces

```dart
abstract class IAuthService {
  Future<String> sendOtp(String phone);
  Future<UserModel?> verifyOtp(String verificationId, String code);
  Future<UserModel?> loginWithPassword(String phone, String password);
  Future<void> setPassword(String password);
  Future<void> resetPassword(String phone);
  Future<void> logout();
  Future<void> deleteAccount();
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
}

abstract class IUserService {
  Future<NannyModel?> getNanny(String id);
  Future<FamilyModel?> getFamily(String id);
  Future<void> updateNanny(String id, Map<String, dynamic> data);
  Future<void> updateFamily(String id, Map<String, dynamic> data);
  Stream<List<NannyModel>> watchNannies(NannyFilter filter);
  Future<void> recordProfileView(String familyId, String nannyId);
  Future<int> getFreeContactsUsed(String familyId);
}

abstract class IJobService {
  Future<String> createJob(JobPost job);
  Future<void> updateJob(String id, Map<String, dynamic> data);
  Future<JobPost?> getJob(String id);
  Stream<List<JobPost>> watchActiveJobs(JobFilter filter);
  /// Family Screen 14 — live approved+verified nanny catalogue (filter pills applied).
  Stream<List<NannyCard>> watchBrowseNannies({String? filter, JobPost? matchJob});
  Stream<List<JobPost>> watchFamilyJobs(String familyId);
  Future<void> closeJob(String id);
}

abstract class IChatService {
  Future<String> createOrGetThread(String familyId, String nannyId);
  Stream<List<ChatThread>> watchThreads(String userId);
  Stream<List<Message>> watchMessages(String threadId);
  Future<void> sendMessage(String threadId, Message message);
  Future<void> markRead(String threadId, String userId);
}

abstract class ITrialService {
  Future<String> createTrial(Trial trial);
  Future<void> respondToTrial(String id, TrialResponse response);
  Future<void> updateEvaluation(String id, TrialEvaluation eval);
  Future<void> completeTrial(String id, String outcome);
  Future<void> confirmPayment(String id);
  Stream<Trial?> watchActiveTrial(String userId);
  Stream<List<Trial>> watchTrials(String userId);
}

abstract class IStorageService {
  Future<String> uploadPhoto(File file, String userId);
  Future<String> uploadVideo(File file, String userId);
  Future<String> uploadDocument(File file, String userId, DocumentType type);
  Future<void> deleteFile(String url);
  Future<String> getDownloadUrl(String path);
  /// App impl also exposes `resolveDownloadUrl(pathOrUrl)` — HTTPS passthrough,
  /// `gs://` via `refFromURL`, Storage object paths via `ref(path).getDownloadURL()`.
}

abstract class INotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
  Stream<RemoteMessage> get onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp;
  Future<void> sendNotification(AppNotification notification);
  Stream<List<AppNotification>> watchNotifications(String userId);
}

abstract class ISubscriptionService {
  Future<void> initialize(String userId);
  Future<List<SubscriptionPlan>> getAvailablePlans();
  Future<bool> purchasePlan(String planId);
  Future<bool> restorePurchases();
  Future<bool> isSubscribed();
  Future<FamilySubscription> getCurrentSubscription();
  Stream<FamilySubscription> watchSubscription();
}
```

## 4.2 Firebase Service Implementations

```dart
class FirebaseAuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<String> sendOtp(String phone) async {
    Completer<String> completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        completer.completeError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    return completer.future;
  }
  
  @override
  Future<UserModel?> verifyOtp(String verificationId, String code) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    return _fetchUser(userCredential.user!.uid);
  }
  // ... other methods
}

class FirestoreUserService implements IUserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  @override
  Stream<List<NannyModel>> watchNannies(NannyFilter filter) {
    Query query = _db.collection('nannies')
        .where('isVerified', isEqualTo: true);
    
    if (filter.emirate != null) {
      query = query.where('preferredEmirates', arrayContains: filter.emirate);
    }
    if (filter.languages.isNotEmpty) {
      query = query.where('languages', arrayContainsAny: filter.languages);
    }
    
    return query.snapshots().map((snap) => 
      snap.docs.map((d) => NannyModel.fromMap(d.data() as Map<String, dynamic>)).toList()
    );
  }
}
```

## 4.3 Mock Service Implementations

```dart
class MockAuthService implements IAuthService {
  static const String mockOtp = '1234';
  UserModel? _currentUser;
  final StreamController<UserModel?> _authController = StreamController.broadcast();
  
  @override
  Future<String> sendOtp(String phone) async {
    await Future.delayed(Duration(seconds: 1));
    return 'mock-verification-id-${DateTime.now().millisecondsSinceEpoch}';
  }
  
  @override
  Future<UserModel?> verifyOtp(String verificationId, String code) async {
    await Future.delayed(Duration(seconds: 1));
    if (code != mockOtp) {
      throw Exception('Invalid OTP. Use 1234 in mock mode.');
    }
    _currentUser = MockData.defaultUser;
    _authController.add(_currentUser);
    return _currentUser;
  }
  
  @override
  Stream<UserModel?> get authStateChanges => _authController.stream;
}

class MockUserService implements IUserService {
  @override
  Stream<List<NannyModel>> watchNannies(NannyFilter filter) {
    return Stream.value(MockData.nannies)
        .map((nannies) => _applyFilter(nannies, filter));
  }
  
  @override
  Future<NannyModel?> getNanny(String id) async {
    await Future.delayed(Duration(milliseconds: 300));
    return MockData.nannies.firstWhereOrNull((n) => n.id == id);
  }
}

class MockData {
  static final List<NannyModel> nannies = [
    NannyModel(
      id: 'mock-nanny-1',
      fullName: 'Sarah Reyes',
      nationality: 'Filipino',
      // ... full mock data
    ),
    // Priya K., Amara K., Grace N., etc.
  ];
  
  static final List<FamilyModel> families = [...];
  static final List<JobPost> jobs = [...];
  static final List<ChatThread> threads = [...];
}
```

---

# 5. MOCKED MODE CONFIGURATION

## 5.1 App Config

```dart
// lib/config/app_config.dart
class AppConfig {
  static const bool USE_MOCK = true;          // ← Toggle this flag
  static const String ENVIRONMENT = 'dev';    // dev | staging | prod
  static const bool ENABLE_LOGS = true;
  static const String MOCK_OTP = '1234';
  static const Duration MOCK_DELAY = Duration(milliseconds: 500);
}
```

## 5.2 main.dart - Service Injection Switch

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!AppConfig.USE_MOCK) {
    await Firebase.initializeApp();
  }
  
  runApp(KafiApp());
}

class KafiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kafi',
      initialBinding: InitialBinding(),
      initialRoute: Routes.welcome,
      getPages: AppRoutes.routes,
    );
  }
}
```

## 5.3 Initial Binding (Service Switcher)

```dart
// lib/bindings/initial_binding.dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (AppConfig.USE_MOCK) {
      Get.put<IAuthService>(MockAuthService(), permanent: true);
      Get.put<IUserService>(MockUserService(), permanent: true);
      Get.put<IJobService>(MockJobService(), permanent: true);
      Get.put<IChatService>(MockChatService(), permanent: true);
      Get.put<ITrialService>(MockTrialService(), permanent: true);
      Get.put<IStorageService>(MockStorageService(), permanent: true);
      Get.put<INotificationService>(MockNotificationService(), permanent: true);
      Get.put<ISubscriptionService>(MockSubscriptionService(), permanent: true);
    } else {
      Get.put<IAuthService>(FirebaseAuthService(), permanent: true);
      Get.put<IUserService>(FirestoreUserService(), permanent: true);
      Get.put<IJobService>(FirestoreJobService(), permanent: true);
      Get.put<IChatService>(FirestoreChatService(), permanent: true);
      Get.put<ITrialService>(FirestoreTrialService(), permanent: true);
      Get.put<IStorageService>(FirebaseStorageService(), permanent: true);
      Get.put<INotificationService>(FCMNotificationService(), permanent: true);
      Get.put<ISubscriptionService>(RevenueCatService(), permanent: true);
    }
    
    Get.put(PermissionService(), permanent: true);
    Get.put(LocationService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
  }
}
```

## 5.4 Mock Data Strategy

| Data Type | Storage |
|-----------|---------|
| Mock Users | In-memory list |
| Mock Sessions | SharedPreferences (mock-only) |
| Mock Files | Placeholder URLs (network images) |
| Mock Notifications | In-memory stream |
| Mock OTP | Always `1234` |
| Mock Subscriptions | Toggle-able via debug menu |

---

# 6. FIREBASE CLOUD FIRESTORE ARCHITECTURE

## 6.1 Collection Structure

```
firestore/
├── users/{userId}                          # Base user record
│   ├── phone: string
│   ├── userType: 'nanny' | 'family'
│   ├── createdAt: Timestamp
│   ├── fcmTokens: array
│   └── settings: map
│
├── nannies/{nannyId}                       # Nanny profile (extends user)
│   ├── fullName, nationality, languages
│   ├── photos: array
│   ├── introVideo: string
│   ├── visaStatus, hasEID
│   ├── preferredEmirates: array
│   ├── experiences: subcollection
│   ├── references: subcollection
│   ├── documents: subcollection
│   ├── verificationStatus: string
│   ├── isVerified: boolean
│   ├── profileScore: number
│   └── stats: map
│
├── families/{familyId}                     # Family profile (extends user)
│   ├── fullName, nationality, city
│   ├── numberOfChildren, childrenAges
│   ├── religion, nannyReligionPreference
│   ├── subscription: map
│   ├── freeContactsUsed: number
│   ├── viewedProfiles: array
│   └── stats: map
│
├── jobPosts/{jobId}
│   ├── familyId: string (indexed)
│   ├── status: string (indexed)
│   ├── createdAt, expiresAt (indexed)
│   ├── jobType, salaryMin, salaryMax (indexed)
│   ├── languagesRequired: array (indexed)
│   ├── duties, benefits
│   └── visaSponsorshipType
│
├── applications/{applicationId}
│   ├── jobPostId: string (indexed)
│   ├── nannyId: string (indexed)
│   ├── familyId: string (indexed)
│   ├── status: string (indexed)
│   ├── matchScore: number
│   └── createdAt (indexed)
│
├── trials/{trialId}
│   ├── familyId, nannyId (indexed)
│   ├── status (indexed)
│   ├── startDate, endDate (indexed)
│   ├── dailyRate, durationDays
│   ├── evaluation: map
│   └── outcome: string
│
├── chatThreads/{threadId}
│   ├── participants: map
│   ├── lastMessage, lastMessageAt (indexed)
│   ├── unreadCount: map
│   └── messages/{messageId}              # Subcollection
│       ├── senderId, type, content
│       ├── createdAt (indexed)
│       └── readAt
│
├── notifications/{userId}/items/{notifId}
│   ├── type, title, body
│   ├── data: map
│   ├── read: boolean
│   └── createdAt (indexed)
│
├── shortlists/{userId}/items/{nannyId}
│   └── addedAt: Timestamp
│
├── reviews/{reviewId}
│   ├── reviewerId, revieweeId
│   ├── rating, comment
│   └── trialId
│
├── broadcasts/{broadcastId}
│   ├── title, body, targetAudience
│   ├── sentBy, sentAt
│   └── deliveryStats: map
│
├── admins/{adminId}
│   ├── email, role, permissions
│   └── lastLoginAt
│
└── settings/global                        # Singleton document
    ├── jobPostVisibilityDays: number
    ├── freeContactLimit: number
    ├── subscriptionPlans: array
    ├── matchAlgorithmWeights: map
    └── hideInactiveNannies: boolean       # When true, family Browse hides nannies with lastActiveAt older than 14 days (or missing)
```

`nannies/{id}.lastActiveAt` is written by the mobile app on nanny sign-in / app resume (`IUserService.touchNannyActive`). Family discovery (`IJobService.browseNannies` / `watchBrowseNannies`) applies the admin toggle client-side after the approved+verified query.
## 6.2 Required Indexes (composite)

| Collection | Fields |
|------------|--------|
| nannies | `isVerified` + `preferredEmirates` + `availability` |
| nannies | `isVerified` + `languages` + `profileScore` desc |
| jobPosts | `status` + `expiresAt` + `createdAt` desc |
| jobPosts | `familyId` + `status` + `createdAt` desc |
| applications | `nannyId` + `status` + `createdAt` desc |
| applications | `familyId` + `status` + `createdAt` desc |
| trials | `nannyId` + `status` |
| trials | `familyId` + `status` |
| chatThreads | `participants.familyId` + `lastMessageAt` desc |
| chatThreads | `participants.nannyId` + `lastMessageAt` desc |
| messages | `threadId` + `createdAt` asc |
| notifications | `userId` + `read` + `createdAt` desc |

## 6.3 Document Size Guidelines

| Document | Max Size | Notes |
|----------|----------|-------|
| User base | < 50KB | Settings + tokens |
| Nanny profile | < 200KB | Excluding media URLs |
| Job post | < 50KB | - |
| Message | < 5KB | Attachments via URL |
| Notification | < 2KB | - |

---

# 7. FIREBASE STORAGE ARCHITECTURE

## 7.1 Storage Structure

```
firebase-storage/
├── nannies/
│   └── {nannyId}/
│       ├── photos/
│       │   ├── photo_1_{timestamp}.jpg
│       │   ├── photo_2_{timestamp}.jpg
│       │   └── photo_5_{timestamp}.jpg (max 5)
│       ├── video/
│       │   └── intro_{timestamp}.mp4 (max 60s, max 50MB)
│       └── documents/
│           ├── passport.{ext}
│           ├── visa.{ext}
│           ├── eid_front.{ext}
│           ├── eid_back.{ext}
│           ├── training_cert_1.{ext}
│           └── police_clearance.{ext}
│
├── families/
│   └── {familyId}/
│       └── profile_photo.jpg
│
├── messages/
│   └── {threadId}/
│       └── attachments/
│           ├── {timestamp}_{filename}
│           └── ...
│
└── broadcasts/
    └── {broadcastId}/
        └── thumbnail.jpg
```

## 7.2 File Constraints

| File Type | Max Size | Allowed Formats | Compression |
|-----------|----------|-----------------|-------------|
| Profile Photo | 5 MB | JPG, PNG | Yes (1080px max) |
| Intro Video | 50 MB | MP4 | Server-side transcode |
| Documents | 10 MB | JPG, PNG, PDF | None |
| Chat Attachment | 10 MB | JPG, PNG, PDF | Optional |

## 7.3 Storage Service Methods

```dart
Future<String> uploadPhoto(File file, String userId) async {
  final ref = FirebaseStorage.instance
      .ref('nannies/$userId/photos/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
  
  final compressed = await ImageCompressor.compress(file, maxWidth: 1080);
  final task = await ref.putFile(compressed);
  return await task.ref.getDownloadURL();
}

Future<String> uploadVideo(File file, String userId) async {
  if (file.lengthSync() > 50 * 1024 * 1024) {
    throw Exception('Video must be under 50MB');
  }
  
  final duration = await VideoDuration.get(file);
  if (duration > 60) {
    throw Exception('Video must be 60 seconds or less');
  }
  
  final ref = FirebaseStorage.instance
      .ref('nannies/$userId/video/intro_${DateTime.now().millisecondsSinceEpoch}.mp4');
  
  final task = await ref.putFile(file);
  return await task.ref.getDownloadURL();
}
```

---

# 8. PERMISSION HANDLING

## 8.1 Required Permissions

| Permission | Why Needed | When Requested |
|------------|------------|----------------|
| **Camera** | Take photos, record video | Photo/video upload screens |
| **Photo Library** | Pick photos | Photo upload screens |
| **Microphone** | Record intro video | Video record screen |
| **Storage** | Save documents | Document upload (Android) |
| **Notifications** | Push notifications | After OTP verify |
| **Location** | Auto-detect emirate | Location-aware screens |
| **Contacts** | Verify references (optional) | References screen |

## 8.2 Permission Flow

```dart
class PermissionService extends GetxService {
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  Future<bool> requestPhotoLibrary() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    } else {
      if (await _isAndroid13Plus()) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
  }
  
  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  Future<bool> requestNotifications() async {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
  }
  
  Future<bool> requestLocation({bool always = false}) async {
    final status = always
        ? await Permission.locationAlways.request()
        : await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
  
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
  
  Future<PermissionRequestResult> requestWithRationale({
    required Permission permission,
    required String rationale,
    required String deniedMessage,
  }) async {
    final status = await permission.status;
    if (status.isGranted) return PermissionRequestResult.granted;
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(deniedMessage);
      return PermissionRequestResult.permanentlyDenied;
    }
    
    _showRationaleDialog(rationale);
    final newStatus = await permission.request();
    return newStatus.isGranted 
        ? PermissionRequestResult.granted 
        : PermissionRequestResult.denied;
  }
}
```

## 8.3 Permission Check Points (Flow-by-Flow)

| Flow | Permission | When | Action if Denied |
|------|------------|------|------------------|
| Welcome → Login | None | - | - |
| OTP sent | Notifications | After OTP verify | Show value prop, retry later |
| Nanny Photo Upload | Camera OR Photos | On tap "Add photo" | Show rationale, open settings |
| Nanny Video Record | Camera + Microphone | On tap "Record video" | Show rationale |
| Document Upload | Photos OR Files | On tap "Upload doc" | Show rationale |
| Browse Nannies | Location (optional) | First open of Browse | Allow skip, default to UAE |
| Chat Attachment | Photos | On tap attach | Show rationale |
| Profile photo | Camera OR Photos | On tap profile photo | Show rationale |

## 8.4 Rationale UI

```dart
void _showRationaleDialog(String message) {
  Get.dialog(AlertDialog(
    title: Text('Permission needed'),
    content: Text(message),
    actions: [
      TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
      ElevatedButton(
        onPressed: () { Get.back(); /* re-request */ },
        child: Text('Allow'),
      ),
    ],
  ));
}
```

---

# 9. LOCATION FLOWS

## 9.1 LocationService

```dart
class LocationService extends GetxService {
  final PermissionService _permissionService = Get.find();
  
  Future<Position?> getCurrentPosition() async {
    if (AppConfig.USE_MOCK) {
      return Position(
        latitude: 25.2048, longitude: 55.2708,  // Dubai
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0,
        speed: 0, speedAccuracy: 0,
        altitudeAccuracy: 0, headingAccuracy: 0,
      );
    }
    
    final granted = await _permissionService.requestLocation();
    if (!granted) return null;
    
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      await Geolocator.openLocationSettings();
      return null;
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }
  
  Future<String?> getEmirate(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return null;
    
    final administrativeArea = placemarks.first.administrativeArea ?? '';
    return _normalizeEmirate(administrativeArea);
  }
  
  String _normalizeEmirate(String input) {
    final mapping = {
      'dubai': 'Dubai',
      'abu dhabi': 'Abu Dhabi',
      'sharjah': 'Sharjah',
      'ajman': 'Ajman',
      'ras al khaimah': 'Ras Al Khaimah',
      'umm al quwain': 'Umm Al Quwain',
      'fujairah': 'Fujairah',
      'al ain': 'Al Ain',
    };
    return mapping[input.toLowerCase()] ?? input;
  }
}
```

## 9.2 Location Usage by Screen

| Screen | Usage |
|--------|-------|
| Nanny - Personal Info | Pre-fill "Current area" field |
| Family - Job Post | Pre-fill emirate dropdown |
| Browse Nannies | Filter by user's emirate by default |
| Profile screens | Display "Your area: Dubai" badge |

## 9.3 Location Permission Strategy

- **When in use** only (NOT background)
- Optional - users can manually select emirate
- Skip on first launch, request on use

---

# 10. PUSH NOTIFICATIONS IMPLEMENTATION

## 10.1 FCM Setup (Firebase Service)

```dart
class FCMNotificationService implements INotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  
  @override
  Future<void> initialize() async {
    await _requestPermission();
    await _setupLocalNotifications();
    await _saveTokenToFirestore();
    _listenToTokenRefresh();
    _setupForegroundHandler();
    _setupBackgroundHandler();
    _setupNotificationTap();
  }
  
  Future<void> _saveTokenToFirestore() async {
    final token = await _fcm.getToken();
    final userId = Get.find<AuthController>().currentUser.value?.id;
    if (token != null && userId != null) {
      await FirebaseFirestore.instance
          .collection('users').doc(userId)
          .update({'fcmTokens': FieldValue.arrayUnion([token])});
    }
  }
  
  void _setupForegroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }
  
  void _setupNotificationTap() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message.data);
    });
  }
  
  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_message':
        Get.toNamed('/chat', arguments: data['threadId']);
        break;
      case 'trial_offer_received':
        Get.toNamed('/trial/offer', arguments: data['trialId']);
        break;
      case 'new_application':
        Get.toNamed('/applications', arguments: data['applicationId']);
        break;
      case 'documents_approved':
        Get.toNamed('/nanny/dashboard');
        break;
      // ... all other types
    }
  }
}
```

## 10.2 Cloud Function Triggers (Backend Logic)

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// New message → notify recipient
exports.onNewMessage = functions.firestore
  .document('chatThreads/{threadId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const recipientId = await getRecipientId(context.params.threadId, message.senderId);
    const recipient = await getUser(recipientId);
    const sender = await getUser(message.senderId);
    
    return sendNotification(recipient.fcmTokens, {
      title: '💬 New message',
      body: `${sender.fullName}: ${message.content.substring(0, 80)}`,
      data: {
        type: 'new_message',
        threadId: context.params.threadId,
        senderId: message.senderId,
      },
    });
  });

// New application → notify family
exports.onNewApplication = functions.firestore
  .document('applications/{appId}')
  .onCreate(async (snap, context) => {
    const app = snap.data();
    const family = await getUser(app.familyId);
    const nanny = await getNanny(app.nannyId);
    
    return sendNotification(family.fcmTokens, {
      title: '📝 New application',
      body: `${nanny.fullName} applied - ${app.matchScore}% match`,
      data: {
        type: 'new_application',
        applicationId: context.params.appId,
      },
    });
  });

// Trial offer → notify nanny
exports.onTrialOffered = functions.firestore
  .document('trials/{trialId}')
  .onCreate(async (snap, context) => {
    const trial = snap.data();
    if (trial.status !== 'pending') return;
    
    const nanny = await getUser(trial.nannyId);
    const family = await getUser(trial.familyId);
    
    return sendNotification(nanny.fcmTokens, {
      title: '🎉 Trial offer received!',
      body: `${family.fullName} sent ${trial.durationDays}-day trial @ AED ${trial.dailyRate}/day`,
      data: {
        type: 'trial_offer_received',
        trialId: context.params.trialId,
      },
    });
  });

// Trial response → notify family
exports.onTrialResponse = functions.firestore
  .document('trials/{trialId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;
    
    const family = await getUser(after.familyId);
    const nanny = await getUser(after.nannyId);
    
    let payload;
    switch (after.status) {
      case 'accepted':
        payload = {
          title: '✅ Trial accepted',
          body: `${nanny.fullName} accepted your offer!`,
        };
        break;
      case 'declined':
        payload = {
          title: 'Trial declined',
          body: `${nanny.fullName} declined your offer`,
        };
        break;
      case 'countered':
        payload = {
          title: '🔄 Counter offer',
          body: `${nanny.fullName} sent a counter offer`,
        };
        break;
    }
    
    return sendNotification(family.fcmTokens, {
      ...payload,
      data: { type: `trial_${after.status}`, trialId: context.params.trialId },
    });
  });

// Document approved/rejected → notify nanny
exports.onDocumentReviewed = functions.firestore
  .document('nannies/{nannyId}/documents/{docId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;
    
    const nanny = await getUser(context.params.nannyId);
    const payload = after.status === 'approved'
      ? { title: '✅ Documents approved!', body: 'Your profile is now visible to families' }
      : { title: '❌ Action needed', body: `Document rejected: ${after.rejectionReason}` };
    
    return sendNotification(nanny.fcmTokens, {
      ...payload,
      data: { type: `documents_${after.status}` },
    });
  });

// Trial starting tomorrow (scheduled function)
exports.trialStartingReminder = functions.pubsub
  .schedule('every 1 hours').onRun(async (context) => {
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const trials = await admin.firestore()
      .collection('trials')
      .where('status', '==', 'accepted')
      .where('startDate', '<=', tomorrow)
      .get();
    
    return Promise.all(trials.docs.map(doc => {
      return sendBothPartiesNotification(doc.data(), {
        title: '⏰ Trial starts tomorrow!',
        body: `Trial starts at ${doc.data().startTime}`,
        data: { type: 'trial_starting_soon', trialId: doc.id },
      });
    }));
  });

// Subscription expiring (scheduled)
exports.subscriptionExpiringReminder = functions.pubsub
  .schedule('every day 09:00').onRun(async (context) => {
    const in3Days = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
    const families = await admin.firestore()
      .collection('families')
      .where('subscription.status', '==', 'active')
      .where('subscription.endDate', '<=', in3Days)
      .get();
    
    return Promise.all(families.docs.map(doc => {
      return sendNotification(doc.data().fcmTokens, {
        title: '💳 Expiring soon',
        body: 'Your subscription renews in 3 days',
        data: { type: 'subscription_expiring' },
      });
    }));
  });

// Subscription expired (scheduled hourly) - apply LOCKDOWN
// Transitions ACTIVE/CANCELLED past their endDate → EXPIRED
// Sets contactsHidden + chatLocked flags so client UI hides everything
exports.subscriptionExpiredEnforcer = functions.pubsub
  .schedule('every 1 hours').onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const families = await admin.firestore()
      .collection('families')
      .where('subscription.status', 'in', ['active', 'cancelled'])
      .where('subscription.endDate', '<=', now)
      .get();
    
    const batch = admin.firestore().batch();
    families.docs.forEach((doc) => {
      batch.update(doc.ref, {
        'subscription.status': 'expired',
        'subscription.expiredAt': now,
        'subscription.contactsHidden': true,
        'subscription.chatLocked': true,
      });
    });
    await batch.commit();
    
    // Push notifications
    return Promise.all(families.docs.map(doc => {
      return sendNotification(doc.data().fcmTokens, {
        title: '⚠️ Subscription expired',
        body: 'Renew to access your chats and contacts',
        data: { type: 'subscription_expired' },
      });
    }));
  });

// Subscription RevenueCat webhook → unified state sync
// Handles RENEWAL, CANCELLATION, EXPIRATION, BILLING_ISSUE, UNCANCELLATION, PRODUCT_CHANGE
exports.revenueCatWebhook = functions.https.onRequest(async (req, res) => {
  const event = req.body.event;
  const familyId = event.app_user_id;
  const familyRef = admin.firestore().collection('families').doc(familyId);
  
  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
    case 'UNCANCELLATION':
      // Restore full access
      await familyRef.update({
        'subscription.status': 'active',
        'subscription.endDate': new Date(event.expiration_at_ms),
        'subscription.contactsHidden': false,
        'subscription.chatLocked': false,
        'subscription.lastRenewalAt': admin.firestore.Timestamp.now(),
        'subscription.hasEverSubscribed': true,
      });
      await sendUserNotification(familyId, {
        title: event.type === 'RENEWAL' ? '✅ Subscription renewed' : '🎉 Welcome back!',
        body: event.type === 'RENEWAL'
          ? 'Subscription renewed successfully'
          : 'Full access restored - your chats are back',
      });
      break;
      
    case 'CANCELLATION':
      // User cancelled but still in period - keep access until endDate
      await familyRef.update({
        'subscription.status': 'cancelled',
        'subscription.autoRenew': false,
      });
      break;
      
    case 'EXPIRATION':
    case 'BILLING_ISSUE':
      // LOCKDOWN
      await familyRef.update({
        'subscription.status': event.type === 'BILLING_ISSUE' ? 'payment_failed' : 'expired',
        'subscription.expiredAt': admin.firestore.Timestamp.now(),
        'subscription.contactsHidden': true,
        'subscription.chatLocked': true,
      });
      await sendUserNotification(familyId, {
        title: '⚠️ Subscription expired',
        body: 'Your chats and contacts are locked. Renew to restore access',
        data: { type: 'subscription_expired' },
      });
      break;
  }
  
  res.status(200).send('OK');
});

// When a trial ends, re-check parent family subscription status
// If sub is expired and no other active trials, the trial chat becomes locked too
exports.onTrialEnded = functions.firestore
  .document('trials/{trialId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === after.status) return;
    if (after.status !== 'completed' && after.status !== 'cancelled') return;
    
    // Recompute activeTrialNannyIds on family doc (used by Firestore rules)
    const familyRef = admin.firestore().collection('families').doc(after.familyId);
    const activeTrials = await admin.firestore()
      .collection('trials')
      .where('familyId', '==', after.familyId)
      .where('status', '==', 'active')
      .get();
    
    const activeNannyIds = activeTrials.docs.map(d => d.data().nannyId);
    await familyRef.update({ activeTrialNannyIds: activeNannyIds });
  });
```

## 10.3 Local Notification Handling

```dart
Future<void> _showLocalNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'kafi_main', 'Kafi Notifications',
    importance: Importance.high, priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails();
  
  await _local.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode(message.data),
  );
}
```

## 10.4 Mock Notification Service

```dart
class MockNotificationService implements INotificationService {
  final List<AppNotification> _notifications = [];
  final _streamController = StreamController<List<AppNotification>>.broadcast();
  
  @override
  Future<void> initialize() async {
    _notifications.addAll(MockData.notifications);
    _streamController.add(_notifications);
  }
  
  @override
  Future<bool> requestPermission() async => true;
  
  @override
  Future<String?> getToken() async => 'mock-fcm-token';
  
  @override
  Future<void> sendNotification(AppNotification notification) async {
    _notifications.add(notification);
    _streamController.add(_notifications);
    
    // Show as local toast in mock mode
    Get.snackbar(
      notification.title,
      notification.body,
      snackPosition: SnackPosition.TOP,
    );
  }
  
  @override
  Stream<List<AppNotification>> watchNotifications(String userId) =>
      _streamController.stream;
}
```

---

# 11. ADMIN PANEL (REACT JS)

## 11.1 Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | React 18 + TypeScript |
| Routing | React Router v6 |
| State | Redux Toolkit OR Zustand |
| UI | TailwindCSS + Headless UI |
| Backend | Firebase (Firestore, Auth, Storage) |
| Charts | Recharts |
| Forms | React Hook Form + Zod |
| Build | Vite |

## 11.2 Project Structure

```
admin-panel/
├── src/
│   ├── App.tsx
│   ├── main.tsx
│   ├── config/
│   │   ├── firebase.ts
│   │   └── routes.ts
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── Layout.tsx
│   │   ├── ui/                       # Reusable components
│   │   └── charts/
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   ├── nannies/
│   │   │   ├── AllNannies.tsx
│   │   │   ├── VerifyDocuments.tsx
│   │   │   ├── ReviewVideos.tsx
│   │   │   └── NannyDetail.tsx
│   │   ├── families/
│   │   │   ├── AllFamilies.tsx
│   │   │   ├── Subscriptions.tsx
│   │   │   └── FamilyDetail.tsx
│   │   ├── business/
│   │   │   ├── Revenue.tsx
│   │   │   ├── Broadcast.tsx
│   │   │   └── Settings.tsx
│   │   └── Login.tsx
│   ├── services/
│   │   ├── auth.service.ts
│   │   ├── nanny.service.ts
│   │   ├── family.service.ts
│   │   ├── document.service.ts
│   │   ├── broadcast.service.ts
│   │   └── revenue.service.ts
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── useFirestore.ts
│   │   └── usePermissions.ts
│   ├── types/
│   │   └── *.d.ts                    # Same models as Flutter app
│   └── utils/
├── package.json
└── vite.config.ts
```

## 11.3 Admin Pages & Routes

| Route | Purpose |
|-------|---------|
| `/login` | Admin login (Firebase Auth) |
| `/` | Dashboard (metrics overview) |
| `/nannies` | All nannies list |
| `/nannies/verify` | Document verification queue |
| `/nannies/videos` | Video review queue |
| `/nannies/:id` | Nanny detail + edit |
| `/families` | All families list |
| `/families/subscriptions` | Subscription management |
| `/families/:id` | Family detail + edit |
| `/revenue` | Revenue dashboard + export |
| `/broadcast` | Send broadcast notifications |
| `/reports` | User reports queue (in-app “Report a problem”; Firestore `disputes`) |
| `/reports/:id` | Report detail + support chat; shows user IDs, profile snapshot, attachments, trial link |
| `/disputes`, `/disputes/:id` | Redirect to `/reports` (legacy) |
| `/support` | Support tickets queue |
| `/support/:id` | Support ticket detail |
| `/settings` | System settings (free contact limit, plans, etc.) |

## 11.4 Sample Service

```typescript
// services/document.service.ts
import { doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../config/firebase';

export async function approveDocument(
  nannyId: string,
  docId: string,
  adminId: string
) {
  await updateDoc(doc(db, `nannies/${nannyId}/documents/${docId}`), {
    status: 'approved',
    reviewedAt: serverTimestamp(),
    reviewedBy: adminId,
  });
}

export async function rejectDocument(
  nannyId: string,
  docId: string,
  adminId: string,
  reason: string
) {
  await updateDoc(doc(db, `nannies/${nannyId}/documents/${docId}`), {
    status: 'rejected',
    rejectionReason: reason,
    reviewedAt: serverTimestamp(),
    reviewedBy: adminId,
  });
}
```

## 11.5 Admin Auth Strategy

- Separate Firebase Auth users with `custom claims` for admin role
- Firestore Security Rules check: `request.auth.token.admin == true`
- Email + Password login (no phone OTP for admins)
- 2FA optional (TOTP)

---

# 12. SECURITY RULES

## 12.1 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuth() { return request.auth != null; }
    function isOwner(userId) { return request.auth.uid == userId; }
    function isAdmin() { return request.auth.token.admin == true; }
    // Family considered "subscribed" only when status is ACTIVE or CANCELLED-IN-PERIOD
    // (i.e. paid plan still within end date). EXPIRED / PAYMENT_FAILED revoke access.
    function isSubscribedFamily() {
      let famDoc = get(/databases/$(database)/documents/families/$(request.auth.uid));
      let status = famDoc.data.subscription.status;
      let endDate = famDoc.data.subscription.endDate;
      return (status == 'active' || status == 'cancelled')
             && endDate != null
             && endDate >= request.time;
    }
    
    // Returns true if the family has an ACTIVE trial with this nanny
    // (used to bypass subscription lock for active-trial chat/contact)
    function hasActiveTrialWith(nannyId) {
      // Cloud function precomputes trialNannyIds onto family doc to avoid expensive queries
      return get(/databases/$(database)/documents/families/$(request.auth.uid))
        .data.activeTrialNannyIds.hasAny([nannyId]);
    }
    
    // Returns true if family can access this thread
    // - Subscribed → yes
    // - Expired but has active trial in thread → yes
    function familyCanAccessThread(threadId) {
      let thread = get(/databases/$(database)/documents/chatThreads/$(threadId));
      let otherUserId = thread.data.nannyId;
      return isSubscribedFamily() || hasActiveTrialWith(otherUserId);
    }
    
    // Users
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isAuth() && isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
      allow delete: if isOwner(userId) || isAdmin();
    }
    
    // Nannies (publicly readable if verified)
    match /nannies/{nannyId} {
      allow read: if (resource.data.isVerified == true) 
                  || isOwner(nannyId) 
                  || isAdmin();
      allow create: if isAuth() && isOwner(nannyId);
      allow update: if isOwner(nannyId) || isAdmin();
      
      match /documents/{docId} {
        allow read: if isOwner(nannyId) || isAdmin();
        allow write: if isOwner(nannyId) || isAdmin();
      }
      
      match /experiences/{expId} {
        allow read: if true;  // Public
        allow write: if isOwner(nannyId);
      }
    }
    
    // Families
    match /families/{familyId} {
      allow read: if isOwner(familyId) || isAdmin();
      allow create: if isAuth() && isOwner(familyId);
      allow update: if isOwner(familyId) || isAdmin();
    }
    
    // Job Posts
    match /jobPosts/{jobId} {
      allow read: if isAuth();
      allow create: if isAuth() && request.resource.data.familyId == request.auth.uid;
      allow update, delete: if resource.data.familyId == request.auth.uid || isAdmin();
    }
    
    // Applications
    match /applications/{appId} {
      allow read: if resource.data.nannyId == request.auth.uid 
                  || resource.data.familyId == request.auth.uid
                  || isAdmin();
      allow create: if request.resource.data.nannyId == request.auth.uid;
      allow update: if resource.data.familyId == request.auth.uid;
    }
    
    // Trials
    match /trials/{trialId} {
      allow read: if resource.data.nannyId == request.auth.uid 
                  || resource.data.familyId == request.auth.uid
                  || isAdmin();
      allow create: if request.resource.data.familyId == request.auth.uid 
                    && isSubscribedFamily();
      allow update: if resource.data.nannyId == request.auth.uid 
                    || resource.data.familyId == request.auth.uid;
    }
    
    // Chat - subscription gate for families
    // Nannies: always full access to their own threads
    // Families: read only if subscription ACTIVE or thread has active trial
    //           send only if subscription ACTIVE or thread has active trial
    match /chatThreads/{threadId} {
      allow read: if request.auth.uid in resource.data.participants.values()
                  && (
                    // Nanny side - always allowed
                    request.auth.uid == resource.data.nannyId ||
                    // Family side - require active sub OR active trial
                    (request.auth.uid == resource.data.familyId 
                     && familyCanAccessThread(threadId))
                  );
      allow update: if request.auth.uid in resource.data.participants.values()
                    && (request.auth.uid == resource.data.nannyId
                        || familyCanAccessThread(threadId));
      allow create: if isAuth() 
                    && (request.auth.uid == request.resource.data.nannyId
                        || (request.auth.uid == request.resource.data.familyId
                            && isSubscribedFamily()));
      
      match /messages/{messageId} {
        // Read
        allow read: if request.auth.uid in 
          get(/databases/$(database)/documents/chatThreads/$(threadId))
            .data.participants.values()
          && (
            request.auth.uid == get(/databases/$(database)/documents/chatThreads/$(threadId)).data.nannyId
            || familyCanAccessThread(threadId)
          );
        // Send: families must be active OR have active trial; nannies always allowed
        allow create: if request.auth.uid in 
          get(/databases/$(database)/documents/chatThreads/$(threadId))
            .data.participants.values()
          && (
            request.auth.uid == get(/databases/$(database)/documents/chatThreads/$(threadId)).data.nannyId
            || familyCanAccessThread(threadId)
          );
        allow create: if request.auth.uid == request.resource.data.senderId;
      }
    }
    
    // Notifications
    match /notifications/{userId}/items/{notifId} {
      allow read, update, delete: if isOwner(userId);
      allow create: if isAdmin() || true; // Via Cloud Functions only
    }
    
    // Shortlists
    match /shortlists/{userId}/items/{nannyId} {
      allow read, write: if isOwner(userId);
    }
    
    // Settings (read-only for users)
    match /settings/{document=**} {
      allow read: if isAuth();
      allow write: if isAdmin();
    }
    
    // Admin
    match /admins/{adminId} {
      allow read, write: if isAdmin();
    }
  }
}
```

## 12.2 Firebase Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    function isAuth() { return request.auth != null; }
    function isOwner(userId) { return request.auth.uid == userId; }
    function isAdmin() { return request.auth.token.admin == true; }
    
    // Nanny photos (publicly readable - shown on profile)
    match /nannies/{userId}/photos/{photoId} {
      allow read: if isAuth();
      allow write: if isOwner(userId) 
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Nanny videos (publicly readable)
    match /nannies/{userId}/video/{videoId} {
      allow read: if isAuth();
      allow write: if isOwner(userId) 
                   && request.resource.size < 50 * 1024 * 1024
                   && request.resource.contentType.matches('video/.*');
    }
    
    // Nanny documents (PRIVATE - owner + admin only)
    match /nannies/{userId}/documents/{docId} {
      allow read: if isOwner(userId) || isAdmin();
      allow write: if isOwner(userId) 
                   && request.resource.size < 10 * 1024 * 1024;
    }
    
    // Family profile photo
    match /families/{userId}/profile_photo {
      allow read: if isAuth();
      allow write: if isOwner(userId);
    }
    
    // Chat attachments (thread participants only - enforced via Cloud Function)
    match /messages/{threadId}/attachments/{fileId} {
      allow read, write: if isAuth();
    }

    // Report / dispute evidence (images + PDF, max 10 MB). Path:
    // disputes/{disputeId}/attachments/{fileId}. Write: signed-in (file-time
    // upload before/with dispute create). Read: admin or dispute reporter.
    match /disputes/{disputeId}/attachments/{fileId} {
      allow read: if isAdmin()
        || (isAuth()
            && firestore.get(/databases/(default)/documents/disputes/$(disputeId)).data.reporterId
                == request.auth.uid);
      allow write: if isAuth()
                   && request.resource.size < 10 * 1024 * 1024
                   && (request.resource.contentType.matches('image/.*')
                       || request.resource.contentType == 'application/pdf');
    }
  }
}
```

### Dispute / report model (mobile + admin)

`DisputeModel` / admin `DisputeRow` include denormalized `reporterName` / `reporterType` / `reportedName` / `reportedType`, optional `reporterSnapshot` / `reportedSnapshot`, and optional `attachments[]`. `IDisputeService.fileDispute` accepts these fields; Storage uploads go to `disputes/{id}/attachments/` before/with the Firestore create.

---

# 13. ERROR HANDLING ARCHITECTURE

## 13.1 Error Class Hierarchy

```dart
// lib/utils/errors/app_error.dart
abstract class AppError implements Exception {
  final String code;
  final String message;       // User-facing
  final String? technical;    // Logging only
  final dynamic originalError;
  
  AppError({
    required this.code,
    required this.message,
    this.technical,
    this.originalError,
  });
}

// Auth errors
class AuthError extends AppError {
  AuthError({required super.code, required super.message, super.technical, super.originalError});
  
  factory AuthError.invalidPhone() => AuthError(
    code: 'auth/invalid-phone',
    message: 'Please enter a valid phone number',
  );
  factory AuthError.otpExpired() => AuthError(
    code: 'auth/otp-expired',
    message: 'Code expired. Tap resend.',
  );
  factory AuthError.otpIncorrect(int remaining) => AuthError(
    code: 'auth/otp-incorrect',
    message: 'Invalid code. $remaining attempts remaining.',
  );
  factory AuthError.rateLimited() => AuthError(
    code: 'auth/rate-limited',
    message: 'Too many attempts. Try again later.',
  );
  factory AuthError.accountSuspended() => AuthError(
    code: 'auth/suspended',
    message: 'Account suspended. Contact support.',
  );
  // ... A1-A20
}

// Permission errors
class PermissionError extends AppError {
  final Permission permission;
  final bool isPermanent;
  
  PermissionError({
    required this.permission,
    required this.isPermanent,
    required super.code,
    required super.message,
  });
}

// Upload errors
class UploadError extends AppError {
  factory UploadError.fileTooLarge(int maxMB) => UploadError._(
    code: 'upload/too-large',
    message: 'File too large. Max ${maxMB}MB.',
  );
  factory UploadError.invalidFormat() => UploadError._(
    code: 'upload/invalid-format',
    message: 'File type not supported',
  );
  factory UploadError.videoTooLong() => UploadError._(
    code: 'upload/video-too-long',
    message: 'Video must be 60 seconds or less',
  );
  factory UploadError.networkFailure() => UploadError._(
    code: 'upload/network',
    message: 'Upload failed. Tap to retry.',
  );
  UploadError._({required super.code, required super.message});
}

// Trial errors
class TrialError extends AppError {
  factory TrialError.notSubscribed() => TrialError._(
    code: 'trial/not-subscribed',
    message: 'Subscribe to send trial offers',
  );
  factory TrialError.nannyOnAnotherTrial() => TrialError._(
    code: 'trial/nanny-busy',
    message: 'Nanny is currently on another trial',
  );
  factory TrialError.startDatePassed() => TrialError._(
    code: 'trial/start-passed',
    message: 'Start date has passed',
  );
  TrialError._({required super.code, required super.message});
}

// Subscription errors
class SubscriptionError extends AppError {
  factory SubscriptionError.paymentDeclined() => SubscriptionError._(
    code: 'sub/declined',
    message: 'Payment failed. Try another method.',
  );
  factory SubscriptionError.contactsExhausted() => SubscriptionError._(
    code: 'sub/contacts-exhausted',
    message: 'All 5 free views used. Subscribe to continue.',
  );
  factory SubscriptionError.restoreFailed() => SubscriptionError._(
    code: 'sub/restore-failed',
    message: "Couldn't restore. Try again.",
  );
  SubscriptionError._({required super.code, required super.message});
}

// Network errors
class NetworkError extends AppError {
  factory NetworkError.noConnection() => NetworkError._(
    code: 'net/no-connection',
    message: 'No internet. Check your connection.',
  );
  factory NetworkError.timeout() => NetworkError._(
    code: 'net/timeout',
    message: 'Action took too long. Retry.',
  );
  factory NetworkError.serverDown() => NetworkError._(
    code: 'net/server-down',
    message: "We're experiencing issues. Try again.",
  );
  NetworkError._({required super.code, required super.message});
}

// Validation errors (field-level)
class ValidationError extends AppError {
  final String field;
  ValidationError({required this.field, required super.code, required super.message});
}
```

## 13.2 Error Handler / Reporter

```dart
class ErrorHandler {
  static void handle(dynamic error, {StackTrace? stack, String? context}) {
    AppError appError;
    
    if (error is AppError) {
      appError = error;
    } else if (error is FirebaseAuthException) {
      appError = _mapFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      appError = _mapFirebaseError(error);
    } else if (error is SocketException || error is TimeoutException) {
      appError = NetworkError.noConnection();
    } else {
      appError = UnknownError(
        code: 'unknown',
        message: 'Something went wrong. Try again.',
        originalError: error,
      );
    }
    
    // Log to Crashlytics (production only)
    if (!AppConfig.USE_MOCK) {
      FirebaseCrashlytics.instance.recordError(
        error, stack, 
        reason: context, 
        fatal: false,
      );
    }
    
    // Log to console
    if (AppConfig.ENABLE_LOGS) {
      print('[$context] ${appError.code}: ${appError.technical ?? appError.message}');
    }
    
    // Show to user
    _showUserError(appError);
  }
  
  static AppError _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number': return AuthError.invalidPhone();
      case 'too-many-requests': return AuthError.rateLimited();
      case 'session-expired': return AuthError.otpExpired();
      case 'invalid-verification-code': return AuthError.otpIncorrect(0);
      case 'user-disabled': return AuthError.accountSuspended();
      case 'network-request-failed': return NetworkError.noConnection() as AppError;
      default: return UnknownError(code: e.code, message: 'Auth error');
    }
  }
  
  static AppError _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return PermissionDeniedError();
      case 'unavailable':
        return NetworkError.serverDown() as AppError;
      case 'deadline-exceeded':
        return NetworkError.timeout() as AppError;
      case 'resource-exhausted':
        return RateLimitError();
      default:
        return UnknownError(code: e.code, message: 'Service error');
    }
  }
  
  static void _showUserError(AppError error) {
    Get.snackbar(
      'Oops',
      error.message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      duration: Duration(seconds: 4),
    );
  }
  
  static Future<T?> wrap<T>(Future<T> Function() action, {String? context}) async {
    try {
      return await action();
    } catch (e, stack) {
      handle(e, stack: stack, context: context);
      return null;
    }
  }
}
```

## 13.3 Controller-Level Error Handling Pattern

```dart
class AuthController extends GetxController {
  RxBool isLoading = false.obs;
  Rx<AppError?> lastError = Rx<AppError?>(null);
  RxInt otpAttemptsRemaining = 5.obs;
  
  Future<void> verifyOtp(String code) async {
    isLoading.value = true;
    lastError.value = null;
    
    try {
      if (code.length != 4) {
        throw ValidationError(
          field: 'otp',
          code: 'validation/length',
          message: 'Enter all 4 digits',
        );
      }
      
      final user = await _authService.verifyOtp(verificationId.value, code);
      
      if (user == null) {
        throw AuthError.otpIncorrect(--otpAttemptsRemaining.value);
      }
      
      currentUser.value = user;
      Get.offAllNamed(_routeForUser(user));
      
    } on AuthError catch (e) {
      lastError.value = e;
      ErrorHandler.handle(e, context: 'AuthController.verifyOtp');
    } catch (e, stack) {
      ErrorHandler.handle(e, stack: stack, context: 'AuthController.verifyOtp');
    } finally {
      isLoading.value = false;
    }
  }
}
```

## 13.4 Permission Error Handling

```dart
class PermissionService extends GetxService {
  Future<PermissionResult> requestWithFlow({
    required Permission permission,
    required String rationaleTitle,
    required String rationaleMessage,
    required String deniedSettingsMessage,
  }) async {
    final initial = await permission.status;
    
    if (initial.isGranted) {
      return PermissionResult.granted;
    }
    
    if (initial.isPermanentlyDenied) {
      final openSettings = await Get.dialog<bool>(AlertDialog(
        title: Text(rationaleTitle),
        content: Text(deniedSettingsMessage),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('Not now')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: Text('Open Settings')),
        ],
      )) ?? false;
      
      if (openSettings) await openAppSettings();
      return PermissionResult.permanentlyDenied;
    }
    
    if (initial.isDenied) {
      final shouldRequest = await Get.dialog<bool>(AlertDialog(
        title: Text(rationaleTitle),
        content: Text(rationaleMessage),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Get.back(result: true), child: Text('Allow')),
        ],
      )) ?? false;
      
      if (!shouldRequest) return PermissionResult.denied;
      
      final newStatus = await permission.request();
      return newStatus.isGranted ? PermissionResult.granted : PermissionResult.denied;
    }
    
    return PermissionResult.denied;
  }
}

enum PermissionResult { granted, denied, permanentlyDenied }
```

## 13.5 Upload Error Handling

```dart
class FirebaseStorageService implements IStorageService {
  @override
  Future<String> uploadPhoto(File file, String userId) async {
    if (file.lengthSync() > 5 * 1024 * 1024) {
      throw UploadError.fileTooLarge(5);
    }
    
    final mime = lookupMimeType(file.path);
    if (mime == null || !mime.startsWith('image/')) {
      throw UploadError.invalidFormat();
    }
    
    final compressed = await _compressImage(file);
    final ref = FirebaseStorage.instance
        .ref('nannies/$userId/photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    try {
      final task = ref.putFile(compressed);
      
      task.snapshotEvents.listen((TaskSnapshot snap) {
        final progress = snap.bytesTransferred / snap.totalBytes;
        _uploadProgress.value = progress;
      });
      
      await task.timeout(Duration(minutes: 5));
      return await ref.getDownloadURL();
      
    } on TimeoutException {
      throw NetworkError.timeout();
    } on FirebaseException catch (e) {
      if (e.code == 'storage/quota-exceeded') {
        throw UploadError._(
          code: 'upload/quota',
          message: 'Upload failed. Contact support.',
        );
      }
      throw UploadError.networkFailure();
    }
  }
  
  Future<File> _compressImage(File file) async {
    // Compress to max 1080px, 80% quality
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path.replaceAll('.jpg', '_c.jpg'),
      quality: 80,
      minWidth: 1080,
      minHeight: 1080,
    );
    return File(compressed!.path);
  }
}
```

## 13.6 Network Connectivity Handling

```dart
class ConnectivityService extends GetxService {
  RxBool isOnline = true.obs;
  StreamSubscription? _sub;
  
  @override
  void onInit() {
    super.onInit();
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = result != ConnectivityResult.none;
      if (isOnline.value) _onReconnect();
    });
  }
  
  void _onReconnect() {
    // Retry queued actions
    Get.find<ChatController>().retryFailedMessages();
    Get.find<NotificationController>().syncMissed();
  }
  
  Future<T> requireOnline<T>(Future<T> Function() action) async {
    if (!isOnline.value) throw NetworkError.noConnection();
    return await action();
  }
}

// Widget wrapper
class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (Get.find<ConnectivityService>().isOnline.value) return SizedBox.shrink();
      return Container(
        color: Colors.orange,
        padding: EdgeInsets.all(8),
        child: Row(children: [
          Icon(Icons.cloud_off, color: Colors.white),
          SizedBox(width: 8),
          Text('No internet connection', style: TextStyle(color: Colors.white)),
        ]),
      );
    });
  }
}
```

## 13.7 Retry & Queue Strategy

```dart
class ActionQueue {
  final List<QueuedAction> _queue = [];
  
  Future<T> executeWithRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    while (attempt < maxAttempts) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        if (e is NetworkError) {
          await Future.delayed(delay * attempt);
          continue;
        }
        rethrow;
      }
    }
    throw NetworkError.timeout();
  }
  
  void enqueue(QueuedAction action) {
    _queue.add(action);
    _flushIfOnline();
  }
}
```

## 13.8 Session & Auth State Errors

```dart
class SessionMonitor extends GetxService {
  @override
  void onInit() {
    super.onInit();
    Get.find<IAuthService>().authStateChanges.listen((user) {
      if (user == null && Get.currentRoute != Routes.welcome) {
        _handleForceLogout();
      }
    });
  }
  
  void _handleForceLogout() {
    Get.find<AuthController>().logout();
    Get.offAllNamed(Routes.welcome);
    Get.snackbar('Session expired', 'Please sign in again');
  }
}
```

## 13.9 Error Logging & Monitoring

| Tool | Purpose |
|------|---------|
| Firebase Crashlytics | Fatal & non-fatal errors |
| Firebase Performance | API latency, slow renders |
| Firebase Analytics | Error event tracking |
| Console logs | Dev mode only |

```dart
// Log non-fatal error
FirebaseCrashlytics.instance.recordError(
  error,
  stack,
  reason: 'context_string',
  fatal: false,
  information: ['userId: $userId', 'screen: $screen'],
);

// Custom error event
FirebaseAnalytics.instance.logEvent(
  name: 'app_error',
  parameters: {
    'code': error.code,
    'screen': Get.currentRoute,
    'user_type': userType,
  },
);
```

## 13.10 Error UI Components

| Component | When to Use |
|-----------|-------------|
| Snackbar (top) | Brief errors, dismissable |
| Banner | Persistent (offline, expired sub) |
| Inline field error | Form validation |
| Full-screen error | Catastrophic failures, maintenance |
| Modal dialog | Action confirmation, permission rationale |
| Retry CTA | Network failures |
| Empty state | No data scenarios |

## 13.11 Maintenance Mode

```dart
// Check Remote Config on app start
final maintenanceMode = FirebaseRemoteConfig.instance.getBool('maintenance_mode');
final minAppVersion = FirebaseRemoteConfig.instance.getString('min_app_version');

if (maintenanceMode) {
  runApp(MaintenanceScreen());
  return;
}

if (currentVersion < minAppVersion) {
  runApp(ForceUpdateScreen());
  return;
}
```

---

# 14. EDGE CASES SUMMARY

## 14.1 Race Conditions

| Scenario | Solution |
|----------|----------|
| Two families view nanny simultaneously | Both succeed (no exclusivity) |
| Two families send trial to same nanny | Both pending, nanny picks one |
| Family subscribes during free view | Migrate to subscribed, refund view |
| Admin & user edit same doc | Firestore transactions, last-write-wins |
| OTP entered while expiring | Server-side timestamp validation |

## 14.2 Data Integrity

| Scenario | Solution |
|----------|----------|
| Orphaned data after deletion | Cloud Function cleanup cascade |
| Failed upload leaves URL ref | Verify before saving model |
| Notification token rotation | Update on every app start |
| Subscription drift (Apple vs DB) | RevenueCat webhook + periodic sync |
| Profile score recalc | Cloud Function on profile update |

## 14.3 Migration & Versioning

| Scenario | Solution |
|----------|----------|
| Old app version with new schema | Min version check + force update |
| Field added to model | Default values in Firestore queries |
| Field removed | Ignored on read, removed gradually |
| Schema breaking change | New collection + migration script |

---

# 15. PERMISSION CONFIGURATION FILES

## 15.1 Android Manifest

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- Camera & Media -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    
    <!-- Photos (Android 13+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
    
    <!-- Storage (Android <13) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="29"/>
    
    <!-- Location -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    
    <!-- Notifications (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <!-- Make phone calls -->
    <uses-permission android:name="android.permission.CALL_PHONE"/>
    
    <!-- Features -->
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.microphone" android:required="false"/>
    
    <!-- Queries (Android 11+) for WhatsApp/phone intents -->
    <queries>
        <intent>
            <action android:name="android.intent.action.DIAL"/>
            <data android:scheme="tel"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW"/>
            <data android:scheme="https"/>
        </intent>
        <package android:name="com.whatsapp"/>
    </queries>
</manifest>
```

## 15.2 iOS Info.plist

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- Camera -->
    <key>NSCameraUsageDescription</key>
    <string>Kafi needs camera access to take profile photos and record your intro video.</string>
    
    <!-- Photos -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Kafi needs photo library access to upload profile photos and documents.</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Kafi needs photo library access to save photos.</string>
    
    <!-- Microphone -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Kafi needs microphone access to record your intro video.</string>
    
    <!-- Location -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Kafi uses your location to pre-fill your emirate for better matches.</string>
    
    <!-- Contacts (optional) -->
    <key>NSContactsUsageDescription</key>
    <string>Kafi can suggest references from your contacts. This is optional.</string>
    
    <!-- App Tracking -->
    <key>NSUserTrackingUsageDescription</key>
    <string>Allow Kafi to track usage to improve your experience.</string>
    
    <!-- LSApplicationQueriesSchemes for WhatsApp/Phone -->
    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>tel</string>
        <string>whatsapp</string>
        <string>mailto</string>
    </array>
</dict>
```

## 15.3 pubspec.yaml Dependencies

```yaml
name: kafi_app
description: UAE Nanny/Domestic Helper Marketplace
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  get: ^4.6.6
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  firebase_messaging: ^14.7.0
  firebase_analytics: ^10.7.0
  firebase_crashlytics: ^3.4.0
  firebase_remote_config: ^4.3.0
  
  # Subscriptions
  purchases_flutter: ^6.0.0  # RevenueCat
  
  # Permissions
  permission_handler: ^11.0.0
  
  # Media
  image_picker: ^1.0.0
  camera: ^0.10.5
  video_player: ^2.8.0
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.0
  
  # Location
  geolocator: ^10.1.0
  geocoding: ^2.1.0
  
  # Local notifications
  flutter_local_notifications: ^16.0.0
  
  # Phone validation
  intl_phone_field: ^3.2.0
  libphonenumber_plugin: ^0.3.3
  
  # File handling
  file_picker: ^6.1.0
  mime: ^1.0.4
  path_provider: ^2.1.0
  
  # Storage
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  
  # Network
  dio: ^5.4.0
  connectivity_plus: ^5.0.0
  
  # Utilities
  url_launcher: ^6.2.0  # For phone calls, WhatsApp
  intl: ^0.18.0
  uuid: ^4.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
```

---

# 16. OPERATIONS & MONITORING

## 16.1 Logging Strategy

| Level | Use Case | Destination |
|-------|----------|-------------|
| `verbose` | Dev debugging | Console only |
| `info` | User actions, navigation | Console + Analytics |
| `warning` | Recoverable issues | Crashlytics non-fatal |
| `error` | Unhandled errors | Crashlytics fatal |

## 16.2 Key Metrics to Monitor

| Metric | Tool | Alert Threshold |
|--------|------|------------------|
| Crash-free users | Crashlytics | < 99% |
| App start time | Performance | > 3s |
| Firestore latency | Performance | > 1s avg |
| Image load failures | Custom | > 5% |
| OTP success rate | Custom | < 90% |
| Payment success rate | RevenueCat | < 95% |
| FCM delivery rate | FCM Analytics | < 90% |

## 16.3 Backup Strategy

| Data | Backup Method | Frequency |
|------|---------------|-----------|
| Firestore | Scheduled export to Cloud Storage | Daily |
| Firebase Storage | Cross-region replication | Real-time |
| Cloud Functions code | Git repository | Per commit |
| Admin panel code | Git repository | Per commit |

## 16.4 Disaster Recovery

| Scenario | Plan |
|----------|------|
| Firestore region outage | Failover region (multi-region setup) |
| Single document corruption | Restore from daily backup |
| Mass data deletion (accident) | Roll back from latest backup |
| Compromised admin account | Revoke all admin tokens, audit logs |

## 16.5 Health Checks

```dart
// Run on app start
class HealthCheck {
  static Future<HealthStatus> check() async {
    final results = await Future.wait([
      _checkFirebaseConnection(),
      _checkMinAppVersion(),
      _checkMaintenanceMode(),
      _checkServerTime(),
    ]);
    
    return HealthStatus(
      online: results[0],
      versionOk: results[1],
      maintenanceMode: results[2],
      timeOk: results[3],
    );
  }
}
```

---

# 17. TESTING STRATEGY

## 17.1 Test Layers

| Layer | Tool | Coverage |
|-------|------|----------|
| Unit tests | flutter_test, mockito | 70%+ controllers/services |
| Widget tests | flutter_test | Critical screens |
| Integration tests | integration_test | Full flows |
| E2E tests | Patrol / Flutter Driver | Auth, trial, payment |

## 17.2 Mock Mode for Testing

```dart
// Toggle in test setup
setUp(() {
  AppConfig.USE_MOCK = true;
  Get.testMode = true;
  // Initial bindings use mocks
});

testWidgets('Family can browse nannies', (tester) async {
  await tester.pumpWidget(KafiApp());
  await tester.tap(find.text('I am a Family'));
  // ... test full flow with mock data
});
```

## 17.3 Test Data Sets

- 10 mock nannies (varied nationalities, locations)
- 5 mock families (subscribed + free + **expired** + payment-failed + cancelled-in-period)
- 3 mock job posts
- Sample chat threads (active + locked-by-expiration)
- Sample trials in different states

---

# 18. SUBSCRIPTION LOCKDOWN ARCHITECTURE (POST-EXPIRATION ACCESS CONTROL)

## 18.1 Overview

When a family's subscription expires (or renewal fails), the system enters **lockdown mode**:
- **Contacts hidden**: All nanny phone numbers re-blurred everywhere
- **Chat inaccessible**: Chat list hidden, individual chats locked, sending blocked
- **CV downloads disabled**
- **Profile views locked** (even previously viewed)
- **Trial offers disabled**
- **Active trials are the only exception** — their chat/contacts remain accessible until trial ends

Data is **NOT deleted** — only hidden behind a paywall. Re-subscription instantly restores everything.

## 18.2 State Model

```dart
// lib/models/subscription_status.dart
enum SubscriptionStatus {
  FREE,                // Never subscribed
  ACTIVE,              // Paid + within end date
  CANCELLED_ACTIVE,    // Cancelled but still in period (full access until endDate)
  EXPIRED,             // Past end date - LOCKDOWN
  PAYMENT_FAILED,      // Renewal failed - LOCKDOWN
}

class FamilySubscription {
  SubscriptionStatus status;
  String? plan;
  Timestamp? startDate;
  Timestamp? endDate;
  bool autoRenew;
  String? revenueCatId;
  
  // History
  bool hasEverSubscribed;
  Timestamp? expiredAt;
  Timestamp? lastRenewalAt;
  
  // Derived flags (also persisted for Firestore rules)
  bool contactsHidden;  // true when status in [EXPIRED, PAYMENT_FAILED]
  bool chatLocked;     // true when status in [EXPIRED, PAYMENT_FAILED]
}
```

## 18.3 State Transitions

```
FREE ──(subscribe)──→ ACTIVE
ACTIVE ──(renewal)──→ ACTIVE (extends end date)
ACTIVE ──(cancel within period)──→ CANCELLED_ACTIVE
CANCELLED_ACTIVE ──(reach endDate)──→ EXPIRED [LOCKDOWN]
ACTIVE ──(reach endDate, no renewal)──→ EXPIRED [LOCKDOWN]
ACTIVE ──(payment fail)──→ PAYMENT_FAILED [LOCKDOWN]
EXPIRED / PAYMENT_FAILED ──(re-subscribe)──→ ACTIVE [RESTORE]
```

## 18.4 Where the Lock Is Enforced (Defense in Depth)

| Layer | Mechanism |
|-------|-----------|
| **Firestore Rules** | `familyCanAccessThread()` blocks read/write on chats; nanny doc reads strip phone for non-active families |
| **Cloud Functions** | Scheduled hourly `subscriptionExpiredEnforcer` updates state; RevenueCat webhook responds in real-time |
| **GetX Controllers** | `SubscriptionController.hasActiveAccess` gates UI; `ChatController` observes and clears state |
| **UI Layer** | Widgets check `hasActiveAccess` before rendering phone/CV/chat |
| **Service Layer** | `IUserService.getNannyForFamily()` returns phone=null when family is expired |

## 18.5 ProfileController - Hide Contacts

```dart
class NannyProfileController extends GetxController {
  final SubscriptionController _sub = Get.find();
  
  /// Returns nanny phone only when family has access
  String? get displayPhoneNumber {
    if (AuthController.to.currentUser.role == UserRole.NANNY) {
      return _profile.value?.phone; // Nanny sees own
    }
    
    // Family: check sub state + trial exception
    if (_sub.hasActiveAccess) return _profile.value?.phone;
    
    if (_hasActiveTrialWithThisNanny()) return _profile.value?.phone;
    
    return null; // Hidden
  }
  
  bool get canDownloadCV => _sub.hasActiveAccess;
  bool get canSendTrialOffer => _sub.hasActiveAccess;
  bool get canCall => displayPhoneNumber != null;
  bool get canWhatsApp => displayPhoneNumber != null;
  
  bool _hasActiveTrialWithThisNanny() {
    final nannyId = _profile.value?.id;
    final trials = Get.find<TrialController>().myTrials;
    return trials.any((t) =>
      t.nannyId == nannyId && t.status == TrialStatus.ACTIVE);
  }
  
  void onSubscriptionLocked() {
    // Force rebuild - hides phone/CV/Call buttons
    update();
  }
}
```

## 18.6 Chat List Widget - Hide Threads

```dart
class ChatListScreen extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Family + Expired sub: show paywall (unless there's an active trial chat)
      if (AuthController.to.currentUser.role == UserRole.FAMILY
          && controller.isLocked.value
          && controller.visibleThreads.isEmpty) {
        return _SubscriptionLockedEmptyState(
          onRenew: () => Get.toNamed('/subscription',
            arguments: {'reason': 'chat_locked'}),
        );
      }
      
      // Otherwise show visible threads only
      return ListView.builder(
        itemCount: controller.visibleThreads.length,
        itemBuilder: (_, i) => ChatThreadTile(controller.visibleThreads[i]),
      );
    });
  }
}

class _SubscriptionLockedEmptyState extends StatelessWidget {
  final VoidCallback onRenew;
  const _SubscriptionLockedEmptyState({required this.onRenew});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Your subscription has expired',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Renew to view your chats and contacts',
              style: TextStyle(color: Colors.grey)),
          SizedBox(height: 24),
          ElevatedButton(onPressed: onRenew, child: Text('Renew Subscription')),
        ],
      ),
    );
  }
}
```

## 18.7 MockSubscriptionService - Lockdown Simulation

```dart
class MockSubscriptionService implements ISubscriptionService {
  FamilySubscription _current = FamilySubscription(
    status: SubscriptionStatus.FREE,
    autoRenew: false,
    hasEverSubscribed: false,
    contactsHidden: false,
    chatLocked: false,
  );
  
  // Test helper - simulate expiration
  void simulateExpiration() {
    _current = _current.copyWith(
      status: SubscriptionStatus.EXPIRED,
      expiredAt: Timestamp.now(),
      contactsHidden: true,
      chatLocked: true,
    );
    // Trigger controllers
    Get.find<SubscriptionController>().subscription.value = _current;
    Get.find<SubscriptionController>().refreshAndEnforce();
  }
  
  // Test helper - simulate re-subscription
  Future<void> simulateRenewal() async {
    _current = _current.copyWith(
      status: SubscriptionStatus.ACTIVE,
      endDate: Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
      contactsHidden: false,
      chatLocked: false,
      lastRenewalAt: Timestamp.now(),
    );
    Get.find<SubscriptionController>().subscription.value = _current;
    Get.find<ChatController>().onSubscriptionRestored();
  }
  
  @override
  Future<FamilySubscription> getSubscription() async => _current;
}
```

## 18.8 Reactive UI Updates

When the subscription state changes (via Cloud Function webhook or local refresh), the following chain fires:

```
RevenueCat webhook / Cloud Function
       ↓
Firestore family doc updated (status: EXPIRED, contactsHidden: true)
       ↓
SubscriptionController stream listener fires
       ↓
SubscriptionController.subscription Rx updates
       ↓
ChatController.onSubscriptionLocked() called
       ↓
NannyProfileController.onSubscriptionLocked() called
       ↓
All `Obx()` widgets observing these controllers rebuild
       ↓
Chat list → hidden / Paywall shown
Profile screens → phone blurred, Call/WA buttons removed
```

## 18.9 Permission Check Points (Updated)

| Action | Check |
|--------|-------|
| Open chat list | `subController.hasActiveAccess \|\| hasActiveTrials` |
| Open chat thread | `hasActiveAccess \|\| thread.hasActiveTrial` |
| Send message | `hasActiveAccess \|\| thread.hasActiveTrial` |
| View nanny phone | `hasActiveAccess \|\| activeTrialWithNanny` |
| Tap Call/WhatsApp | `hasActiveAccess \|\| activeTrialWithNanny` |
| Download CV | `hasActiveAccess` |
| Send trial offer | `hasActiveAccess` |
| View nanny full profile | `hasActiveAccess` (or 5 free if FREE state) |

## 18.10 Error Cases Added

| Code | Scenario | Behavior |
|------|----------|----------|
| `sub/expired-chat` | Family taps expired chat | Show paywall, preserve thread ID for deep-link resume |
| `sub/expired-contact` | Family taps locked Call/WhatsApp | Hide buttons, show "Renew to contact" |
| `sub/expired-cv` | Family taps CV download | Show paywall |
| `sub/expired-trial` | Family tries to send trial offer | Show paywall |
| `sub/expired-profile-view` | Family taps full profile | Show paywall |
| `sub/active-trial-bypass` | Lockdown but trial active | Allow access, log bypass for audit |
| `sub/restore-success` | RevenueCat restore after expiration | Unlock everything, ⚡ PUSH success |
| `sub/payment-grace` | Billing retry pending | Show banner: "Update payment to keep access" |

---

## Implementation History

| Date (YYYY-MM-DD) | Task | Status | Summary |
|-------------------|------|--------|---------|
| 2026-05-19 | Phase 0 scaffold | Done | `kafi_app/` §2 layout, GetX bindings/controllers, mock+Firebase stubs, `USE_MOCK`; `admin-panel/` §11 routes/pages; `functions/` §10.2 trigger stubs |
| 2026-05-19 | Auth UI foundation v8 | Done | `lib/views/widgets/*` kit, auth screens, `routes.dart` screen-map routes, AuthBinding |
| 2026-05-19 | Restart Task 1 — auth flow | Done | Flutter recreated: l10n `.tr`, `utils/constants/`, mock services, 5 HTML auth screens (welcome→create-pw), analyze+test pass |
| 2026-05-19 | Task 2 — Nanny onboarding | Done | NannyProfileController + 6 step screens + dashboard; IUserService/IStorageService with Mock + Firestore/FirebaseStorage impls; `firebase_*` deps; nanny_constants; l10n keys; routes wired |
| 2026-05-19 | Task 3 — Family flow | Done | FamilyBinding + 5 controllers (Browse/Chat/Trial/Subscription/FamilyProfile); 10 screens (form→browse→profile→chat→trial→pricing→legal); IJobService, IChatService, ITrialService, ISubscriptionService + mock impls; l10n expanded |
| 2026-05-19 | Task 4 — Admin + Functions | Done | `admin-panel/`: Vite+React+TailwindCSS+Zustand, 11 pages matching §11 routes, StatCard/Sidebar/Layout components; `functions/`: v2 triggers (onNewMessage, onTrialOffered, onDocumentReviewed, scheduled enforcers), revenueCatWebhook for subscription state |
| 2026-05-19 | Audit & Compliance Pass | Done | Added missing controllers per §3 (Notification, Application, Shortlist, Settings, Permission, JobPost); missing models per §4 specs; full subscription lockdown per §18; nanny job screens per §24; family screens per §26-31 |
| 2026-05-19 | Full Model Sync | Done | Updated UserModel (fcmTokens, settings per §3.1); NannyModel (all §3.2 fields: stats, salary, availability, cuisines); FamilyModel (subscription object, petTypes, stats); JobPostModel (schedule, skills, contract); TrialModel (counterOffer, evaluation, payment); ChatModels (Message attachments, UnreadCount per-user); MatchService per §9; AuthConstants country codes per §1.5 |
| 2026-05-19 | Error Handling & Delete Account | Done | Implemented full §13 error handling: AppError hierarchy (Auth/Permission/Upload/Trial/Subscription/Network/Validation), ErrorHandler with wrap/handle, ConnectivityService per §13.6, SessionMonitor per §13.8; Delete Account flow per App Doc §29B with 2-step confirmation; added connectivity_plus + permission_handler deps |
| 2026-05-19 | Trial Offer Flow Completion | Done | Extended `ITrialService` and `IChatService` APIs; implemented mock/firestore offer+response methods; `TrialController` now creates trial records, links `trialId` to threads, posts trial chat messages, and handles accept/decline/counter actions |
| 2026-05-19 | Audit gap closure (end-to-end) | Done | Added `firestore.rules` + `storage.rules` + `firebase.json` + `firestore.indexes.json` per §11; admin panel switched from mock stubs to live service layer (`admin-panel/src/services/firestore.ts`) covering Nanny/Family/Subscription override/Disputes/Broadcast/Settings/Revenue with CSV export; new `/disputes` module with resolve flow; admin auth now uses real Firebase + custom-claim `admin==true` check; mobile `ITrialService` extended with cancel/confirmPayment/reportIssue/recordOutcome (mock + firestore); `SmartMatch` scorer per §6.7; `SessionMonitor` enforces 90-day inactivity logout per §21 |
| 2026-05-19 | Reaudit fix-pass (12 areas) | Done | New `functions/src/triggers/broadcast.ts` (queued→sending→sent w/ deliveryStats) & `delete.ts` (cascade chats/trials/applications/auth on user delete) wired in `index.ts`; `triggers/trial.ts` adds `onTrialEnded` that recomputes `families.activeTrialNannyIds`; `triggers/webhook.ts` aligns BILLING_ISSUE to `paymentFailed`, handles `PRODUCT_CHANGE`, requires shared-secret auth; new `scripts/set-admin-claims.ts` seeds admin custom claim + `admins/{uid}` doc; admin-panel `useMock` reads `VITE_USE_MOCK` env. Flutter side: `FirestoreUserService` uses dot-notation merge for settings + transactional `recordProfileView` to prevent duplicate free-view burns; `SubscriptionController` keeps grace-state access, exposes `viewedNannyIds` cache; `ChatThread.trialStatus` cached so bypass requires ACTIVE trial; `TrialController` adds `acceptCounter`/`declineCounter`, auto-promotes accepted→active when start date reached; new `views/family/profile_relocked_screen.dart` + browse routing; Screen 27A nanny edit profile via `NannyEditProfileScreen` + `saveProfileDraft`; full settings toggles + language switcher; Arabic locale (`ar_ae.dart`) rewritten to use only valid keys. |
| 2026-05-19 | Permissions, handlers & location picker | Done | `lib/services/permission_service.dart` rewritten with real `permission_handler` calls (replaces stubs); `openSettings()` calls `openAppSettings()`. `NannyProfileController.uploadPhoto/Video/Document` and `ChatController.sendImage` all call `PermissionController.ensureGallery()` / `ensureCameraAndMic()` before access; denied → snackbar + early return. `auth_controller.dart`: `verifyOtpAndNavigate` guards `otpSecondsLeft <= 0`; `otp_verify_screen.dart` button disabled when expired. `trial_controller.dart`: `sendTrialOffer` rejects duplicate offer per nanny. `IChatService` + mock/Firestore impls: `markThreadRead(threadId, role)` added; wired from `openThread`. `NannyProfileController.saveProfileDraft` calls `calculateProfileScore()` post-save. `browse_screen.dart`: no-views-left snackbar + low-views hint. New `lib/views/widgets/kafi_location_picker.dart`: two-column UAE emirate/area `BottomSheet` widget; wired to nanny info, trial offer, and family form city fields. New l10n keys: `otpExpiredMessage`, `permissionGalleryDenied`, `permissionCameraDenied`, `trialAlreadyActive`, `freeViewsRemaining`, `noFreeViewsLeft`, `renewToSendImages`, `locationPickerTitle`, `locationPickerHint`, `anyArea`, `done`, `trialLocation`, `fldCity`. |
| 2026-05-19 | Google Places location picker (Uber-style) | Done | Added `google_maps_flutter ^2.9`, `geolocator ^13`, `http ^1.2` to pubspec; `AppConstants.googleMapsApiKey/placesBias/placesRegion` added; Android `AndroidManifest.xml` and iOS `AppDelegate.swift` wired with API key. New `lib/services/places_service.dart`: `autocomplete()` (Places Autocomplete API, UAE-biased), `getDetails()` (Place Details), `reverseGeocode()` (Geocoding API). `KafiLocationPicker` rewritten as full Uber-style bottom sheet: debounced search input, real-time Google predictions list, "Use my current location" (Geolocator GPS + reverse geocode), `GoogleMap` with animated pin on selection, address card overlay, confirm button. All existing wiring (nanny info, trial offer, family form) preserved. New l10n keys: `locationSearchHint`, `locationUseCurrentLocation`, `locationGPSSubtitle`, `locationSearchPrompt`, `locationSearchSubPrompt`, `locationConfirm`, `locationServiceDisabled`, `locationPermissionDenied`. |
| 2026-05-19 | Audit round 2 fixes | Done | Flutter: counter bubble family actions, `ChatController` pending deep-links, `TrialModel.fromMap`, chat attachments in Firestore, FCM foreground snackbar + `removeToken` on logout, `ApplicationModel` Timestamp parsing. Admin: `reviewDocument` embedded array, `ProtectedRoute` `isAdmin`. Functions: `chatThreads` cascade, `nanny.ts` on parent doc, `notifications.ts` token merge + prune, `scheduled.ts` batched expiry + `reminderSent`. |
| 2026-05-19 | Broken flows + bug bash | Done | **Flutter**: `trial_controller.dart` looks up threads via `currentUserId(_auth) ?? trial.familyId` and routes counter-accept through new `ITrialService.applyCounterAndAccept`. `IChatService.linkTrialToThread` adds `trialStatus`; mock + Firestore + seed write/read it; `_threadFromMap` exposes it. `kafi_trial_offer_bubble.dart` switched to `Obx` (TrialController.all) — buttons conditional on `TrialStatus.pending`, counter offer + status chip rendered. `SubscriptionController.recordViewIfAllowed` lets expired families revisit already-viewed nannies. `BrowseScreen` slim expired banner above the live list; `AppNavigation.openNannyProfile` chooses Locked / Re-Locked / Unlocked. `ChatController.visibleThreads` returns all threads + `openThreadForNanny` deep-link helper. `ChatScreen` now `StatefulWidget` and parses `Get.arguments` (`threadId` / `nannyId`). `NotificationController.handleNotificationTap` dispatches to `ChatController.openThread` / `openThreadForNanny`; `registerToken` re-runs on every user change. `FamilyShellScreen._shellGraceBanner` shown on non-browse tabs. `password_reset_screen.dart` calls `IAuthService.verifyPasswordResetOtp` (interface + mock + Firebase impls). `firebase_auth_service.finalizePhoneRegistration` + mock equivalent preserve `hasPassword` for returning users. `AuthController.sendOtpAndNavigate` only navigates on `sendOtp` success. Login screens now `StatefulWidget` and call `prepare*Login` in `initState`. `NannyProfileController` save methods validate required fields and wrap in try/catch/finally with snackbars. `shortlist_screen.dart` taps route via `AppNavigation`. `SessionMonitor._handleSessionExpired` clears `AuthController.currentUser`. `AppNotification.fromMap` resilient to Firestore Timestamps / ISO / int / missing. `FcmNotificationService.initialize` wires `onMessage`, `onMessageOpenedApp`, `getInitialMessage`, `onTokenRefresh`. New `lib/views/family/family_edit_screen.dart` (Screen 27B) wired via `Routes.familyEdit` + entry in `SettingsScreen`; `FamilyProfileController._hydrateFromCurrentUser` + `saveEdit()` + shared `_persist` (re-uses existing job post id to avoid duplicates). `NannyProfileController._hydrate` extended to fill all fields (DOB, nationality, languages, visa, EID, transferVisa, emirates, relocate, currentArea, marital, children, health/meds/allergies, comfort flags, religion, emergency contact, bio). **Cloud Functions**: `triggers/delete.ts` cascade extended to `shortlists`, `jobs`, `notifications`, `reviews`, and family-side `applications`. `firebase_auth_service.deleteAccount` writes `deletionAudits/{uid}` then deletes the `users/{uid}` doc to fire the trigger; admin SDK still cleans up auth as a safety net. **Admin Panel**: `Dashboard.tsx` rebuilt as a stateful component pulling counts from services + functional approve/reject queue; `VerifyDocuments.tsx` adds per-document approve/reject via `NannyService.reviewDocument`; `Broadcast.tsx`/`ReviewVideos.tsx` wrap async in try/catch with surfaced errors; `useAuth.ts` initializes `loading: true` until `onAuthStateChanged` resolves. `functions/src/triggers/broadcast.ts` supports `audience: 'subscribers'` (batched `in` over active subscriptions) and wraps the whole handler in try/catch updating broadcast `status: 'failed'` on error. |
| 2026-05-19 | P2 audit fixes | Done | **Flutter**: `lib/models/dispute_model.dart` (DisputeModel, DisputeCategory, DisputeStatus); `lib/services/interfaces/i_dispute_service.dart` (IDisputeService); `lib/services/mock/mock_dispute_service.dart`; `lib/services/firebase/firestore_dispute_service.dart` — writes to `disputes` collection with `reporterId`, `reportedUserId`, `category`, `description`, `relatedTrialId`, `status: open`. `TrialController.reportPaymentIssue` calls `IDisputeService.fileDispute` (category=payment) after `ITrialService.reportPaymentIssue`. `InitialBinding` registers `IDisputeService` for both mock and Firebase modes. **Admin Panel**: `NannyRow.introVideoStatus` + `introVideoRejectionReason` added to interface; `NannyService.reviewVideo(id, status, adminId, reason?)` patches only video fields on Firestore doc; `listPendingVideos` now queries `introVideoStatus == 'pending'` (composite index added); `ReviewVideos.tsx` calls `reviewVideo` instead of full `approve/reject`. `TrialService.listActive()` (with mock and Firebase impl) added; `Dashboard.tsx` loads `activeTrials` state and renders live trial rows with countdown. All-nannies, families, nationality breakdown, city breakdown, subscription breakdown tables replaced with arrays from `NannyService.list()` / `FamilyService.list()`. **Functions**: `triggers/delete.ts` `onUserDeleted` calls `_deleteStorageFolder(prefix)` (uses `firebase-admin/storage` `bucket.getFiles({prefix})`) for `users/{uid}/`, `nannies/{uid}/`, `families/{uid}/`. **Indexes**: `firestore.indexes.json` updated with 12 new composite indexes covering applications/jobPostId, chatThreads compound, notifications/read, disputes/reporterId, shortlists compound, jobs/status+city, subscriptions/status+endDate, trials status+startDate and reminderSent variant, nannies/status+introVideoStatus. |

---

*Document Version: 1.6*
*Last Updated: May 19, 2026*

| 2026-07-17 | About You Uber location picker (mock) | Done | `kafi_location_picker.dart`: mock/no-key branch now opens `_MockUberLocationSheet` (same UX shell as live Places sheet) instead of `_PlainLocationSheet`; returns `KafiLocation` so About You `currentAreaCtrl` is filled with the display name. New `lib/utils/constants/location_constants.dart` (`uaeAreas`, `mockCurrentArea`). Live `_LocationPickerSheet` unchanged. |
| 2026-07-17 | Native media and location permissions | Done | Android manifest includes optional camera/microphone features, image/video capture queries, granular image/video media permissions, Android 14 selected-media permission, legacy storage fallback, and fine/coarse location. iOS Info.plist usage descriptions cover camera, microphone, Photos, and when-in-use location; Podfile enables corresponding `permission_handler` macros. `PermissionService` handles iOS limited Photos and Android legacy/granular media. Nanny media actions now select camera/gallery and request only the relevant permission set. |

| 2026-07-17 | Media screen photo/video preview | Done | `MockStorageService` writes temp files instead of data URIs. New `kafi_media_image.dart`. `nanny_media_screen` cover/thumbs use `KafiMediaImage`; `_IntroVideoPreview` uses `VideoPlayerController.file` for local paths + visible player. `NannyProfileController` mock picks store `picked.path` directly. |

| 2026-07-17 | Real GPS + Maps location picker | Done | `KafiLocationPicker` gates on API key only (not `AppConfig.useMock`). `_LocationPickerSheet` always shows `GoogleMap` + fixed pin, auto GPS, camera-idle reverse geocode. `PlaceDetails.shortLabel` / neighbourhood. Still requires key in `app_constants.dart`, AndroidManifest, AppDelegate. |

| 2026-07-31 | Family first-job onboarding gate | Done | `AuthController.familyMustPostFirstJob` + resume `enforceFamilyFirstJobGate`; `FamilyFormScreen` PopScope/hide back; `AppNavigation.back`/`familyGoToTab`/`openChat` blocked; `FamilyShellScreen` redirects gated families to `/family-form` |

| 2026-07-31 | Post-job location/schedule/FT-PT + browse bugs | Done | Family form Uber location + work-days sheet; FT/PT slot prep; BrowseController myJobs refresh; shortlist rules create; VideoPlayer args Map cast; toggleShortlist feedback |
| 2026-07-31 | Watch intro video playback | Done | `IStorageService.resolveDownloadUrl` (Firebase + mock); `VideoPlayerScreen` resolves gs:// and Storage paths before `networkUrl`; error + retry UI; `AppNavigation.openIntroVideo` |
| 2026-07-31 | Select Location iOS crash + map picker | Done | `kafiEditableTextContextMenu` avoids iOS SystemContextMenu assert in sheets; wired on location/search/OTP/phone TextFields; deferred Select Location autofocus |
| 2026-07-31 | SystemContextMenu assert (global) | Done | `GetMaterialApp.builder` sets `supportsShowingSystemContextMenu: false`; location/search sheets use no-op context menu + no autofocus |
| 2026-07-31 | Trial offer form validations | Done | `TrialController.validateTrialOffer` + form error getter; `Validators.trialDailyRate`/`trialStartDate`; TrialOfferScreen notes maxLength + inline error |
| 2026-07-31 | Chat send permission-denied | Done | `ChatThread.senderTypeFor`; auth reads `type`/`userType`; rules: safe `familySub`/`hasActiveTrialWith`, nanny thread create; mock sync rethrows on chat path |
| 2026-07-31 | Browse home missing nannies | Done | `FirestoreJobService.browseNannies` removed `.limit(50)`; fetches full approved+verified query result |
| 2026-07-31 | Chat conversation single loader | Done | `ChatController.isLoadingMessages` + conversation list Center loader; `KafiTrialOfferBubble` drops FutureBuilder spinners |
| 2026-07-31 | Trial screen empty while in progress | Done | `TrialController.onTrialRouteOpened` + `isAcceptedOrActive` for nanny; list fallback when activeTrial query fails |
| 2026-07-31 | Ticket status stale after admin resolve | Done | `ITicketService.watchTicket`; TicketController updates activeTicket + list; SupportScreen reloads on open |
| 2026-07-31 | Admin Reports (not Disputes) + hide IDs | Done | Admin UI routes `/reports` (+ `/disputes` redirect); Safety nav label Reports; report detail omits document/user IDs |
| 2026-07-31 | Mobile reports vs support listings | Done | `report_user_sheet` uses `DisputeController.createDispute` (not `TicketController`); My reports vs Support split |
| 2026-07-31 | Nanny chat report flag | Done | `_reportCounterparty` resolves via thread.nannyId/familyId; `showReportProblemSheet` uses root `showModalBottomSheet` |
| 2026-07-31 | Admin badges + iOS push + notif deep-links | Done | Sidebar `count>0`; AppDelegate Messaging.apnsToken; FCM APNs payload; notification taps → profile/job/chat/trial |
| 2026-08-03 | Trial checklist sync both parties | Done | `ITrialService.saveEvaluation` + `watchTrial`; `toggleEval` writes Firestore; Screen 19 binds live trial snap |
| 2026-08-03 | Profile quality remaining gaps | Done | `ProfileQualityScore` helper + `NannyProfileController.profileQuality`; dashboard card lists remaining factors |
| 2026-08-03 | Admin panel + Functions i18n (EN/AR) | Done | `admin-panel/src/locales/{en,ar,t}.ts` (692 flat keys, `{param}` interpolation) + `context/LocaleContext.tsx` (`useSyncExternalStore`, EN\|AR toggle in Settings, `dir` RTL/LTR); every page/component/hook/service wired via `t()`, incl. cross-domain status-label helpers (`nannyProfileStatusLabel`, `subscriptionStatusLabel/PlanLabel`, `trialStatusLabel`, `disputeStatusLabel`, `ticketStatusLabel`, `docStatusLabel`, `personTypeLabel` in `utils/nannyLabels.ts`) so badges/filters/options never render raw Firestore enum strings; date formatters (`MessageThread`, `nannyLabels.formatDate/fmtDate`, `Revenue` trend) switch `en-GB`/`ar-AE` via `getLocale()`. `functions/src/i18n/notifications.ts` — new module with `Locale`, `resolveLocale` (Firestore user doc `locale`/`preferredLanguage`/`language`/`settings.language`, default `en`), `resolveLocaleFromHeader` (`Accept-Language`, for bootstrap), `tn()`/`notif()` template helpers; all push/inbox title+body in `triggers/{nanny,trial,scheduled,webhook,chat,dispute,ticket,stats}.ts` plus `mockSubscription.ts`/`bootstrapAdmin.ts` client-facing errors now resolve through the recipient's locale (`ensureFirstAdmin`/`resolvePassword` take `locale` for the bootstrap-password config error). `admin-panel npm run build` and `functions npm run build` both pass. |
| 2026-08-03 | Full i18n verification (3 clean cycles) | Done | Flutter: AppStrings + relative_time + job_type_label + app_error/.tr; admin locales + LocaleContext; functions i18n/notifications; 3 consecutive zero-leftover scans FE+BE |
| 2026-08-06 | Nanny trial offer Accept/Decline | Done | `KafiTrialOfferBubble.onDecline` + chat `_viewerIsNannyOnActiveThread`; application detail refreshes `TrialController` for pending actions |
| 2026-08-06 | Nanny jobs live feed | Done | Implemented `IJobService.watchActiveJobs`; `JobPostController` subscribes for nannies; removed browseJobs hard limit of 50 |
| 2026-08-06 | Family browse live feed | Done | `IJobService.watchBrowseNannies`; `BrowseController` subscribes (restarts on filter/job); mock merges session-approved nannies via `MockBrowseBus` |
| 2026-08-06 | Cancelled trial clears chat active badge | Done | `TrialController.cancelTrial`/`declineTrial` call `_flipThreadTrialStatus`; `onTrialEnded` updates `chatThreads.trialStatus` |
| 2026-08-06 | Family counter Accept/Decline in chat | Done | `KafiTrialOfferBubble` family counter CTAs; chat message watch refreshes trials on newest counter/accept/decline |
| 2026-08-06 | Hide chat trial bar when trial ends | Done | `ChatController.showsActiveTrialUi` + payment-confirm flips thread status; list/conversation bars reactive to TrialController |
| 2026-08-06 | Family applicants live inbox | Done | `watchApplicationsForFamily/Nanny`; ApplicationController subscribes; Applicants screen reloads on open |
| 2026-08-06 | Admin Verify docs badge stale | Done | Sidebar badges re-fetch on route change + `refreshAdminBadges` after nanny approve/reject/video review so Verify docs counter matches the empty queue |
| 2026-08-06 | Admin↔user report/ticket realtime | Done | Mobile `IDisputeService.watchDispute` + DisputeController status stream (mirrors tickets); admin `DisputeService`/`TicketService.watch` + `watchMessages` on report & support detail so family/nanny↔admin chat and resolution are live |
| 2026-08-06 | Family Applicants multi-job inbox | Done | `subscribeFamilyInbox` (role-explicit); familyId query without orderBy; Applicants job chips; `onNewApplication` increments `jobs.applicationsCount` and backfills `familyId`; My Jobs overlays live counts |
| 2026-08-06 | Trial offer gate after end | Done | `TrialModel.blocksNewTrialOffer` / `isLiveTrial`; validateTrialOffer refresh; confirmPayment/reportPaymentIssue set `completed` |
| 2026-08-06 | Rate app after payment confirm | Done | `confirmPaymentReceived` → `RateAppPrompt.maybeShow`; trial screen payment block shown to family |

| 2026-08-06 | Trial offer chat bubble details | Done | `KafiTrialOfferBubble` full Screen 31 rows (incl. starting from + notes + total); `TrialController.ensureTrialInList`; `openThread` prefetches offer trials by id |

| 2026-08-06 | Applicants job filter names | Done | Applicants job filter labels resolve via JobPostController.myJobs display names |

| 2026-08-06 | Messages bottom-nav badge | Done | `KafiBottomNavItem.badgeCount` + `ChatController.navMessageBadgeCount` / `onMessagesTabOpened` |

| 2026-08-06 | Report user info + attachments | Done | `DisputeModel` snapshot + attachments; `IDisputeService.fileDispute` extended; Storage rules `disputes/{id}/attachments`; admin `DisputeRow`/`DisputeDetail` IDs+gallery; `App.tsx` ProtectedRoute `PageLoader` |

| 2026-08-06 | Hide inactive nannies listing | Done | `NannyListingActivity` + fixed `browseNannies` filter (null lastActiveAt hidden); `touchNannyActive` on app resume; `settings/global.hideInactiveNannies` documented |

| 2026-08-06 | Report attach storage auth | Done | Report filing: create dispute then upload; Storage read for signed-in on dispute attachments; reporter may patch `attachments` only |

| 2026-08-06 | Admin reports + last active | Done | Admin Reports attachment DocViewer gallery; list shows reporter/reported IDs; `NannyRow.lastActiveAt` on All Nannies + profile |
