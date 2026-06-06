import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/models/application_model.dart';
import 'package:kafi_app/models/chat_models.dart';
import 'package:kafi_app/models/nanny_card_model.dart';
import 'package:kafi_app/models/notification_model.dart';
import 'package:kafi_app/models/shortlist_model.dart';
import 'package:kafi_app/models/trial_model.dart';

/// Demo IDs — align with mock auth (`mock_family_1`, `mock_nanny_1` ↔ browse `n1`).
class MockDemoIds {
  static const family = 'mock_family_1';
  static const nannyUser = 'mock_nanny_1';
  static const nannyCard = 'n1';

  static const threadSarah = 't_n1';
  static const threadPriya = 't_n2';
  static const threadAmara = 't_n3';
  static const threadGrace = 't_n4';
  static const threadArchived = 't_n5';

  static const trialActive = 'tr_active';
  static const trialPending = 'tr_pending';
  static const trialCountered = 'tr_countered';
  static const trialCompleted = 'tr_completed';
  static const trialDeclined = 'tr_declined';
  static const trialNannyOffer = 'tr_nanny_offer';
}

/// Browse cards — varied match %, tags, availability (HTML browse feed).
const mockNannyCards = <NannyCardModel>[
  NannyCardModel(
    id: 'n1',
    initials: 'S',
    name: 'Sarah R.',
    nationality: 'Filipino',
    yearsExp: 5,
    jobType: 'Live-in',
    city: 'Dubai',
    matchPercent: 94,
    tags: ['English', 'Arabic', 'Newborn', 'Video'],
    availableNow: true,
    featured: true,
    verified: true,
    introVideoUrl: 'https://mock.kafi/v/sarah_intro.mp4',
  ),
  NannyCardModel(
    id: 'n2',
    initials: 'P',
    name: 'Priya K.',
    nationality: 'Indian',
    yearsExp: 3,
    jobType: 'Live-out',
    city: 'Abu Dhabi',
    matchPercent: 82,
    tags: ['Hindi', 'English', 'Toddler'],
    verified: true,
  ),
  NannyCardModel(
    id: 'n3',
    initials: 'A',
    name: 'Amara K.',
    nationality: 'Ethiopian',
    yearsExp: 4,
    jobType: 'Live-in',
    city: 'Sharjah',
    matchPercent: 88,
    tags: ['Arabic', 'Amharic'],
    verified: true,
  ),
  NannyCardModel(
    id: 'n4',
    initials: 'G',
    name: 'Grace N.',
    nationality: 'Ghanaian',
    yearsExp: 6,
    jobType: 'Live-in',
    city: 'Dubai',
    matchPercent: 71,
    tags: ['English', 'French'],
    verified: true,
  ),
  NannyCardModel(
    id: 'n5',
    initials: 'M',
    name: 'Maria L.',
    nationality: 'Filipino',
    yearsExp: 2,
    jobType: 'Live-out',
    city: 'Dubai',
    matchPercent: 65,
    tags: ['English', 'Tagalog'],
  ),
  NannyCardModel(
    id: 'n6',
    initials: 'N',
    name: 'Nadia H.',
    nationality: 'Lebanese',
    yearsExp: 7,
    jobType: 'Live-in',
    city: 'Abu Dhabi',
    matchPercent: 90,
    tags: ['Arabic', 'English', 'Cooking'],
    verified: true,
    featured: true,
  ),
  NannyCardModel(
    id: 'n7',
    initials: 'R',
    name: 'Rosa T.',
    nationality: 'Indonesian',
    yearsExp: 4,
    jobType: 'Live-in',
    city: 'Ajman',
    matchPercent: 78,
    tags: ['English', 'Infant care'],
    availableNow: true,
  ),
  NannyCardModel(
    id: 'n8',
    initials: 'K',
    name: 'Kavitha S.',
    nationality: 'Indian',
    yearsExp: 8,
    jobType: 'Live-in',
    city: 'Dubai Marina',
    matchPercent: 96,
    tags: ['English', 'Hindi', 'Newborn', 'First aid'],
    verified: true,
    availableNow: true,
  ),
];

List<ChatThread> buildMockChatThreads(DateTime now) => [
      ChatThread(
        id: MockDemoIds.threadSarah,
        familyId: MockDemoIds.family,
        nannyId: 'n1',
        nannyName: 'Sarah R.',
        familyName: 'Al Mahmood',
        createdAt: now.subtract(const Duration(days: 5)),
        lastMessageAt: now.subtract(const Duration(minutes: 18)),
        lastMessage: 'Yes, I can start Monday 🌸',
        unreadCount: const UnreadCount(family: 2, nanny: 0),
        trialId: MockDemoIds.trialActive,
        trialStatus: 'active',
      ),
      ChatThread(
        id: MockDemoIds.threadPriya,
        familyId: MockDemoIds.family,
        nannyId: 'n2',
        nannyName: 'Priya K.',
        familyName: 'Al Mahmood',
        createdAt: now.subtract(const Duration(days: 8)),
        lastMessageAt: now.subtract(const Duration(hours: 5)),
        lastMessage: 'Sure, evenings work for me.',
        unreadCount: const UnreadCount(family: 0, nanny: 1),
      ),
      ChatThread(
        id: MockDemoIds.threadAmara,
        familyId: MockDemoIds.family,
        nannyId: 'n3',
        nannyName: 'Amara K.',
        familyName: 'Al Mahmood',
        createdAt: now.subtract(const Duration(days: 2)),
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        lastMessage: '🤝 Trial offer sent',
        unreadCount: const UnreadCount(family: 0, nanny: 0),
        trialId: MockDemoIds.trialPending,
        trialStatus: 'pending',
      ),
      ChatThread(
        id: MockDemoIds.threadGrace,
        familyId: MockDemoIds.family,
        nannyId: 'n4',
        nannyName: 'Grace N.',
        familyName: 'Al Mahmood',
        createdAt: now.subtract(const Duration(days: 4)),
        lastMessageAt: now.subtract(const Duration(hours: 8)),
        lastMessage: 'Counter offer: AED 175/day',
        unreadCount: const UnreadCount(family: 1, nanny: 0),
        trialId: MockDemoIds.trialCountered,
        trialStatus: 'countered',
      ),
      ChatThread(
        id: MockDemoIds.threadArchived,
        familyId: MockDemoIds.family,
        nannyId: 'n6',
        nannyName: 'Nadia H.',
        familyName: 'Al Mahmood',
        createdAt: now.subtract(const Duration(days: 30)),
        lastMessageAt: now.subtract(const Duration(days: 12)),
        lastMessage: 'Trial completed — thank you!',
        trialId: MockDemoIds.trialCompleted,
        trialStatus: 'completed',
        status: ChatStatus.archived,
      ),
    ];

Map<String, List<ChatMessage>> buildMockChatMessages(DateTime now) {
  const family = MockDemoIds.family;
  const nannySender = 'n1';

  return {
    MockDemoIds.threadSarah: [
      ChatMessage(
        id: 'm_s1',
        threadId: MockDemoIds.threadSarah,
        senderId: family,
        senderType: 'family',
        content: 'Hi Sarah, are you still available for a live-in role?',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      ChatMessage(
        id: 'm_s2',
        threadId: MockDemoIds.threadSarah,
        senderId: nannySender,
        senderType: 'nanny',
        content: 'Hello! Yes, I am available from next week.',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
      ChatMessage(
        id: 'm_s3',
        threadId: MockDemoIds.threadSarah,
        senderId: family,
        senderType: 'family',
        content: '🤝 Trial Offer Sent',
        type: MessageType.trialOffer,
        trialOfferId: MockDemoIds.trialActive,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      ChatMessage(
        id: 'm_s4',
        threadId: MockDemoIds.threadSarah,
        senderId: nannySender,
        senderType: 'nanny',
        content: '✅ Trial accepted.',
        type: MessageType.trialAccepted,
        trialOfferId: MockDemoIds.trialActive,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ChatMessage(
        id: 'm_s5',
        threadId: MockDemoIds.threadSarah,
        senderId: nannySender,
        senderType: 'nanny',
        content: 'Yes, I can start Monday 🌸',
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
    ],
    MockDemoIds.threadPriya: [
      ChatMessage(
        id: 'm_p1',
        threadId: MockDemoIds.threadPriya,
        senderId: family,
        senderType: 'family',
        content: 'Hi Priya — do you do live-out in Abu Dhabi?',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ChatMessage(
        id: 'm_p2',
        threadId: MockDemoIds.threadPriya,
        senderId: 'n2',
        senderType: 'nanny',
        content: 'Yes, I prefer live-out near Khalifa City.',
        createdAt: now.subtract(const Duration(days: 2, minutes: -30)),
      ),
      ChatMessage(
        id: 'm_p3',
        threadId: MockDemoIds.threadPriya,
        senderId: family,
        senderType: 'family',
        content: 'Could you share your toddler-care experience?',
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      ChatMessage(
        id: 'm_p4',
        threadId: MockDemoIds.threadPriya,
        senderId: 'n2',
        senderType: 'nanny',
        content: 'Sure, evenings work for me.',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
    ],
    MockDemoIds.threadAmara: [
      ChatMessage(
        id: 'm_a1',
        threadId: MockDemoIds.threadAmara,
        senderId: family,
        senderType: 'family',
        content: 'We loved your profile — would you consider a 7-day trial?',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      ChatMessage(
        id: 'm_a2',
        threadId: MockDemoIds.threadAmara,
        senderId: family,
        senderType: 'family',
        content: '🤝 Trial Offer Sent',
        type: MessageType.trialOffer,
        trialOfferId: MockDemoIds.trialPending,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ],
    MockDemoIds.threadGrace: [
      ChatMessage(
        id: 'm_g1',
        threadId: MockDemoIds.threadGrace,
        senderId: family,
        senderType: 'family',
        content: '🤝 Trial Offer Sent',
        type: MessageType.trialOffer,
        trialOfferId: MockDemoIds.trialCountered,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ChatMessage(
        id: 'm_g2',
        threadId: MockDemoIds.threadGrace,
        senderId: 'n4',
        senderType: 'nanny',
        content: 'Counter offer: AED 175/day',
        type: MessageType.trialCountered,
        trialOfferId: MockDemoIds.trialCountered,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ],
    MockDemoIds.threadArchived: [
      ChatMessage(
        id: 'm_n1',
        threadId: MockDemoIds.threadArchived,
        senderId: family,
        senderType: 'family',
        content: 'Thank you for the trial week!',
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      ChatMessage(
        id: 'm_n2',
        threadId: MockDemoIds.threadArchived,
        senderId: 'n6',
        senderType: 'nanny',
        content: 'Trial completed — thank you!',
        type: MessageType.system,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    ],
  };
}

Map<String, TrialModel> buildMockTrials(DateTime now) => {
      MockDemoIds.trialActive: TrialModel(
        id: MockDemoIds.trialActive,
        familyId: MockDemoIds.family,
        nannyId: 'n1',
        durationDays: 7,
        dailyRate: 150,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5, hours: 14)),
        status: TrialStatus.active,
        location: 'Dubai Marina',
        notes: 'Newborn care focus',
        offeredAt: now.subtract(const Duration(days: 3)),
        startedAt: now.subtract(const Duration(days: 1)),
        evaluation: const TrialEvaluation(
          childInteractionAndPatience: true,
          punctualityAndReliability: true,
          followingInstructions: true,
          communicationAndLanguage: false,
          cookingFamilyFood: false,
          honestyAndTrustworthiness: true,
        ),
      ),
      MockDemoIds.trialPending: TrialModel(
        id: MockDemoIds.trialPending,
        familyId: MockDemoIds.family,
        nannyId: 'n3',
        durationDays: 7,
        dailyRate: 150,
        startDate: now.add(const Duration(days: 3)),
        status: TrialStatus.pending,
        location: 'Sharjah',
        offeredAt: now.subtract(const Duration(hours: 2)),
      ),
      MockDemoIds.trialCountered: TrialModel(
        id: MockDemoIds.trialCountered,
        familyId: MockDemoIds.family,
        nannyId: 'n4',
        durationDays: 5,
        dailyRate: 150,
        startDate: now.add(const Duration(days: 5)),
        status: TrialStatus.countered,
        location: 'Dubai',
        offeredAt: now.subtract(const Duration(days: 2)),
        counterOffer: CounterOffer(
          dailyRate: 175,
          startDate: now.add(const Duration(days: 6)),
          message: 'Can we do AED 175/day?',
          createdAt: now.subtract(const Duration(hours: 8)),
        ),
      ),
      MockDemoIds.trialCompleted: TrialModel(
        id: MockDemoIds.trialCompleted,
        familyId: MockDemoIds.family,
        nannyId: 'n6',
        durationDays: 7,
        dailyRate: 140,
        startDate: now.subtract(const Duration(days: 20)),
        endDate: now.subtract(const Duration(days: 13)),
        status: TrialStatus.completed,
        location: 'Abu Dhabi',
        offeredAt: now.subtract(const Duration(days: 25)),
        completedAt: now.subtract(const Duration(days: 12)),
        outcome: 'passed',
        evaluation: const TrialEvaluation(
          childInteractionAndPatience: true,
          punctualityAndReliability: true,
          followingInstructions: true,
          honestyAndTrustworthiness: true,
        ),
      ),
      MockDemoIds.trialDeclined: TrialModel(
        id: MockDemoIds.trialDeclined,
        familyId: MockDemoIds.family,
        nannyId: 'n5',
        durationDays: 3,
        dailyRate: 120,
        startDate: now.add(const Duration(days: 10)),
        status: TrialStatus.declined,
        location: 'Dubai',
        offeredAt: now.subtract(const Duration(days: 6)),
        respondedAt: now.subtract(const Duration(days: 5)),
      ),
      // Pending trial offer for nanny n1 from family_4 — matches app_n1_trial application
      MockDemoIds.trialNannyOffer: TrialModel(
        id: MockDemoIds.trialNannyOffer,
        familyId: 'family_4',
        nannyId: 'n1',
        jobPostId: 'job_4',
        durationDays: 5,
        dailyRate: 160,
        startDate: now.add(const Duration(days: 4)),
        trialType: 'live-out',
        location: 'Sharjah',
        notes: 'Looking for someone reliable for weekend coverage.',
        status: TrialStatus.pending,
        offeredAt: now.subtract(const Duration(hours: 12)),
      ),
    };

List<ApplicationModel> buildMockApplications(DateTime now) => [
      ApplicationModel(
        id: 'app_n1_pending',
        jobPostId: 'job_1',
        nannyId: 'n1',
        familyId: 'family_1',
        status: ApplicationStatus.pending,
        matchScore: 91,
        coverMessage: 'I have 5 years newborn experience in Dubai.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ApplicationModel(
        id: 'app_n1_viewed',
        jobPostId: 'job_2',
        nannyId: 'n1',
        familyId: 'family_2',
        status: ApplicationStatus.viewed,
        matchScore: 78,
        createdAt: now.subtract(const Duration(days: 4)),
        viewedAt: now.subtract(const Duration(days: 3)),
      ),
      ApplicationModel(
        id: 'app_n1_shortlisted',
        jobPostId: 'job_3',
        nannyId: 'n1',
        familyId: 'family_3',
        status: ApplicationStatus.shortlisted,
        matchScore: 88,
        createdAt: now.subtract(const Duration(days: 6)),
        viewedAt: now.subtract(const Duration(days: 5)),
        respondedAt: now.subtract(const Duration(days: 4)),
      ),
      ApplicationModel(
        id: 'app_n1_trial',
        jobPostId: 'job_4',
        nannyId: 'n1',
        familyId: 'family_4',
        status: ApplicationStatus.trialOffered,
        matchScore: 72,
        createdAt: now.subtract(const Duration(days: 8)),
        respondedAt: now.subtract(const Duration(days: 1)),
      ),
      ApplicationModel(
        id: 'app_n1_declined',
        jobPostId: 'job_1',
        nannyId: 'n1',
        familyId: 'family_1',
        status: ApplicationStatus.declined,
        matchScore: 46,
        createdAt: now.subtract(const Duration(days: 10)),
        respondedAt: now.subtract(const Duration(days: 9)),
      ),
      ApplicationModel(
        id: 'app_n1_hired',
        jobPostId: 'job_3',
        nannyId: 'n1',
        familyId: 'family_3',
        status: ApplicationStatus.hired,
        matchScore: 95,
        createdAt: now.subtract(const Duration(days: 20)),
        respondedAt: now.subtract(const Duration(days: 15)),
      ),
      ApplicationModel(
        id: 'app_n1_withdrawn',
        jobPostId: 'job_2',
        nannyId: 'n1',
        familyId: 'family_2',
        status: ApplicationStatus.withdrawn,
        matchScore: 60,
        createdAt: now.subtract(const Duration(days: 12)),
        withdrawnAt: now.subtract(const Duration(days: 11)),
      ),
      ApplicationModel(
        id: 'app_fam_pending',
        jobPostId: 'job_family_demo',
        nannyId: 'n2',
        familyId: MockDemoIds.family,
        status: ApplicationStatus.pending,
        matchScore: 82,
        coverMessage: 'Available immediately for live-out.',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      ApplicationModel(
        id: 'app_fam_viewed',
        jobPostId: 'job_family_demo',
        nannyId: 'n3',
        familyId: MockDemoIds.family,
        status: ApplicationStatus.viewed,
        matchScore: 88,
        createdAt: now.subtract(const Duration(days: 1)),
        viewedAt: now.subtract(const Duration(hours: 12)),
      ),
      ApplicationModel(
        id: 'app_fam_shortlisted',
        jobPostId: 'job_family_demo',
        nannyId: 'n8',
        familyId: MockDemoIds.family,
        status: ApplicationStatus.shortlisted,
        matchScore: 96,
        createdAt: now.subtract(const Duration(days: 3)),
        respondedAt: now.subtract(const Duration(days: 2)),
      ),
      ApplicationModel(
        id: 'app_fam_trial',
        jobPostId: 'job_family_demo',
        nannyId: 'n4',
        familyId: MockDemoIds.family,
        status: ApplicationStatus.trialOffered,
        matchScore: 71,
        createdAt: now.subtract(const Duration(days: 5)),
        respondedAt: now.subtract(const Duration(days: 4)),
      ),
    ];

List<ShortlistItem> buildMockShortlist() => [
      ShortlistItem(
        id: 'sl_1',
        familyId: MockDemoIds.family,
        nannyId: 'n1',
        nannyName: 'Sarah R.',
        addedAt: DateTime(2026, 5, 10),
      ),
      ShortlistItem(
        id: 'sl_2',
        familyId: MockDemoIds.family,
        nannyId: 'n2',
        nannyName: 'Priya K.',
        addedAt: DateTime(2026, 5, 12),
      ),
      ShortlistItem(
        id: 'sl_3',
        familyId: MockDemoIds.family,
        nannyId: 'n8',
        nannyName: 'Kavitha S.',
        addedAt: DateTime(2026, 5, 15),
        notes: 'Top match for newborn',
      ),
    ];

List<AppNotification> buildMockNotifications(String userId, {required bool isNanny}) {
  final now = DateTime.now();
  final prefix = isNanny ? 'nn' : 'fn';
  final specs = _mockNotificationSpecs(isNanny);

  final list = NotificationType.values.map((type) {
    final spec = specs[type]!;
    final index = NotificationType.values.indexOf(type);
    final age = Duration(hours: index * 4, minutes: index * 7);
    final read = index >= NotificationType.values.length - 6;
    return AppNotification(
      id: '${prefix}_${type.name}',
      userId: userId,
      type: type,
      title: spec.title,
      body: spec.body,
      data: spec.data,
      read: read,
      readAt: read ? now.subtract(age - const Duration(hours: 1)) : null,
      createdAt: now.subtract(age),
    );
  }).toList();

  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
}

/// One mock row per [NotificationType] — copy varies slightly by role.
Map<NotificationType, _MockNotifSpec> _mockNotificationSpecs(bool isNanny) {
  if (isNanny) {
    return {
      NotificationType.newMessage: _MockNotifSpec(
        'New message',
        'Al Mahmood family: Can you start Monday?',
        {'route': Routes.chat, 'threadId': MockDemoIds.threadSarah},
      ),
      NotificationType.newApplication: _MockNotifSpec(
        'Application submitted',
        'Your application to Live-in Nanny · Dubai was sent',
        {'route': Routes.nannyApplications},
      ),
      NotificationType.applicationViewed: _MockNotifSpec(
        'Application viewed',
        'Khanna family viewed your application',
        {'route': Routes.nannyApplications},
      ),
      NotificationType.applicationDeclined: _MockNotifSpec(
        'Application declined',
        'Al Mansoori family declined your application',
        {'route': Routes.nannyApplications},
      ),
      NotificationType.trialOfferReceived: _MockNotifSpec(
        'Trial offer received',
        'Al Mahmood sent a 7-day paid trial · AED 150/day',
        {'route': Routes.chat, 'threadId': MockDemoIds.threadAmara},
      ),
      NotificationType.trialAccepted: _MockNotifSpec(
        'Trial accepted',
        'You accepted the Dubai Marina trial offer',
        {'route': Routes.chat, 'threadId': MockDemoIds.threadSarah},
      ),
      NotificationType.trialDeclined: _MockNotifSpec(
        'Trial declined',
        'You declined a trial offer from a Dubai family',
        {'route': Routes.nannyApplications},
      ),
      NotificationType.trialCountered: _MockNotifSpec(
        'Counter offer sent',
        'You proposed AED 175/day on Grace\'s trial offer',
        {'route': Routes.chat, 'threadId': MockDemoIds.threadGrace},
      ),
      NotificationType.trialStartingSoon: _MockNotifSpec(
        'Trial starts soon',
        'Your trial with Al Mahmood starts in 24 hours',
        {'route': Routes.chat, 'threadId': MockDemoIds.threadSarah},
      ),
      NotificationType.trialEndingSoon: _MockNotifSpec(
        'Trial ending soon',
        'Active trial ends in 2 days — stay in touch with the family',
        {'route': Routes.chat, 'threadId': MockDemoIds.threadSarah},
      ),
      NotificationType.trialCompleted: _MockNotifSpec(
        'Trial completed',
        'Your 7-day trial with Nadia H. family is complete',
        {'route': Routes.nannyApplications},
      ),
      NotificationType.hired: _MockNotifSpec(
        'You\'re hired! 🎉',
        'Smith family marked you as hired after your trial',
        {'route': Routes.nannyApplications},
      ),
      NotificationType.profileViewed: _MockNotifSpec(
        'Profile viewed',
        '3 families viewed your profile today',
        {'route': Routes.nannyHome},
      ),
      NotificationType.documentsApproved: _MockNotifSpec(
        'Documents approved',
        'Your ID and references are verified ✓',
        {'route': Routes.nannyDocs},
      ),
      NotificationType.documentsRejected: _MockNotifSpec(
        'Documents need update',
        'Please re-upload your passport scan (blurry photo)',
        {'route': Routes.nannyDocs},
      ),
      NotificationType.profileVerified: _MockNotifSpec(
        'Kafi Verified badge 🌸',
        'Your profile is now verified and visible to families',
        {'route': Routes.nannyHome},
      ),
      NotificationType.subscriptionExpiring: _MockNotifSpec(
        'Family subscription ending',
        'A family you chat with may have limited access soon',
        {'route': Routes.chat},
      ),
      NotificationType.subscriptionRenewed: _MockNotifSpec(
        'Family renewed',
        'Al Mahmood renewed their subscription — chat is fully active',
        {'route': Routes.chat},
      ),
      NotificationType.subscriptionExpired: _MockNotifSpec(
        'Family subscription expired',
        'Messages may be delayed until the family renews',
        {'route': Routes.chat},
      ),
      NotificationType.freeContactsLow: _MockNotifSpec(
        'Tip: complete your video',
        'Profiles with intro videos get 2× more family views',
        {'route': Routes.nannyMedia},
      ),
      NotificationType.systemAnnouncement: _MockNotifSpec(
        'Kafi platform update',
        'Trial offers and smart match are live — update your profile',
        {'route': Routes.nannyHome},
      ),
    };
  }

  return {
    NotificationType.newMessage: _MockNotifSpec(
      'New message',
      'Sarah R.: Yes, I can start Monday 🌸',
      {'route': Routes.chat, 'threadId': MockDemoIds.threadSarah},
    ),
    NotificationType.newApplication: _MockNotifSpec(
      'New application',
      'Priya K. applied to your Live-in Nanny post',
      {'route': Routes.browse},
    ),
    NotificationType.applicationViewed: _MockNotifSpec(
      'Application viewed',
      'You viewed Amara K.\'s application',
      {'route': Routes.browse},
    ),
    NotificationType.applicationDeclined: _MockNotifSpec(
      'Application declined',
      'You declined Maria L.\'s application',
      {'route': Routes.browse},
    ),
    NotificationType.trialOfferReceived: _MockNotifSpec(
      'Trial offer sent',
      'Your trial offer to Amara K. was delivered',
      {'route': Routes.chat, 'threadId': MockDemoIds.threadAmara},
    ),
    NotificationType.trialAccepted: _MockNotifSpec(
      'Trial accepted',
      'Sarah R. accepted your 7-day trial offer',
      {'route': Routes.trial, 'trialId': MockDemoIds.trialActive},
    ),
    NotificationType.trialDeclined: _MockNotifSpec(
      'Trial declined',
      'Maria L. declined your trial offer',
      {'route': Routes.chat},
    ),
    NotificationType.trialCountered: _MockNotifSpec(
      'Counter offer',
      'Grace N. proposed AED 175/day',
      {'route': Routes.chat, 'threadId': MockDemoIds.threadGrace},
    ),
    NotificationType.trialStartingSoon: _MockNotifSpec(
      'Trial starts tomorrow',
      'Sarah\'s trial begins May 20 at 8:00 AM',
      {'route': Routes.trial, 'trialId': MockDemoIds.trialActive},
    ),
    NotificationType.trialEndingSoon: _MockNotifSpec(
      'Trial ending soon',
      'Sarah\'s trial ends in 5 days — complete your evaluation',
      {'route': Routes.trial, 'trialId': MockDemoIds.trialActive},
    ),
    NotificationType.trialCompleted: _MockNotifSpec(
      'Trial completed',
      'Your trial with Nadia H. is complete — add an outcome',
      {'route': Routes.trial, 'trialId': MockDemoIds.trialCompleted},
    ),
    NotificationType.hired: _MockNotifSpec(
      'Nanny hired! 🎉',
      'You marked Sarah R. as hired after a successful trial',
      {'route': Routes.profileUnlocked, 'nannyId': 'n1'},
    ),
    NotificationType.profileViewed: _MockNotifSpec(
      'Profile viewed',
      'You viewed Kavitha S.\'s profile (shortlisted)',
      {'route': Routes.shortlist},
    ),
    NotificationType.documentsApproved: _MockNotifSpec(
      'Nanny verified',
      'Sarah R.\'s documents were approved by Kafi admin',
      {'route': Routes.profileUnlocked, 'nannyId': 'n1'},
    ),
    NotificationType.documentsRejected: _MockNotifSpec(
      'Document issue',
      'A nanny on your shortlist needs to re-upload documents',
      {'route': Routes.shortlist},
    ),
    NotificationType.profileVerified: _MockNotifSpec(
      'Verified nanny available',
      'Kavitha S. just received the Kafi Verified badge',
      {'route': Routes.browse},
    ),
    NotificationType.subscriptionExpiring: _MockNotifSpec(
      'Subscription expiring',
      'Your plan renews in 3 days',
      {'route': Routes.pricing},
    ),
    NotificationType.subscriptionRenewed: _MockNotifSpec(
      'Subscription renewed',
      'Weekly plan renewed — full access restored',
      {'route': Routes.pricing},
    ),
    NotificationType.subscriptionExpired: _MockNotifSpec(
      'Subscription expired',
      'Renew to unlock chats, contacts, and trial offers',
      {'route': Routes.pricing},
    ),
    NotificationType.freeContactsLow: _MockNotifSpec(
      'Free views running low',
      'You have used 3 of 5 free profile views',
      {'route': Routes.pricing},
    ),
    NotificationType.systemAnnouncement: _MockNotifSpec(
      'Welcome to Kafi 🌸',
      'Browse verified nannies and send trial offers when subscribed',
      {'route': Routes.browse},
    ),
  };
}

class _MockNotifSpec {
  const _MockNotifSpec(this.title, this.body, this.data);
  final String title;
  final String body;
  final Map<String, dynamic> data;
}

/// Maps mock nanny login id to browse card id.
bool mockNannyIdMatches(String loginId, String cardId) =>
    loginId == cardId || (loginId == MockDemoIds.nannyUser && cardId == MockDemoIds.nannyCard);
