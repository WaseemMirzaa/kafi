import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/l10n/locales/en_us.dart';

/// Arabic (UAE) translations.
/// Falls back to English (`enUs`) for keys not translated here.
final Map<String, String> arAe = Map<String, String>.from(enUs)
  ..addAll({
    // App
    AppStrings.appName: 'كافي',
    AppStrings.tagline: 'الاختيار الصحيح',

    // Welcome
    AppStrings.welcomeWhoAreYou: 'من أنت؟',
    AppStrings.welcomeRoleHint: 'اختر دورك للبدء',
    AppStrings.welcomeHaveAccount: 'هل لديك حساب؟',
    AppStrings.roleNannyTitle: 'مربية',
    AppStrings.roleNannySubtitle: 'أبحث عن عمل',
    AppStrings.roleFamilyTitle: 'عائلة',
    AppStrings.roleFamilySubtitle: 'أبحث عن مربية',

    // Auth
    AppStrings.authEnterPhone: 'أدخل رقم هاتفك',
    AppStrings.authEnterPhoneSub: 'سنرسل لك رمز التحقق عبر الرسائل القصيرة',
    AppStrings.authPhoneLabel: 'رقم الهاتف',
    AppStrings.authSendOtp: 'إرسال الرمز',
    AppStrings.authVerify: 'تحقق',
    AppStrings.authVerifyOtp: 'تحقق وتابع',
    AppStrings.authPhoneRequired: 'الرجاء إدخال رقم الهاتف',
    AppStrings.authInvalidOtp: 'رمز التحقق غير صحيح',
    AppStrings.authForgotPassword: 'نسيت كلمة المرور؟',
    AppStrings.authPasswordLabel: 'كلمة المرور',
    AppStrings.authSignInPassword: 'تسجيل الدخول',
    AppStrings.terms: 'الشروط',
    AppStrings.privacy: 'الخصوصية',
    AppStrings.errorTitle: 'خطأ',
    AppStrings.successTitle: 'نجاح',

    // OTP
    AppStrings.otpEnterTitle: 'أدخل رمز التحقق',
    AppStrings.otpResend: 'لم يصل الرمز؟ إعادة الإرسال',
    AppStrings.otpChangeNumber: 'تغيير الرقم',
    AppStrings.otpVerified: 'تم التحقق',
    AppStrings.otpVerifiedSub: 'تم التحقق من رقم هاتفك',

    // Password
    AppStrings.createPwTitle: 'أنشئ كلمة مرور',
    AppStrings.createPwSub: 'أنشئ كلمة مرور قوية لحسابك',
    AppStrings.createPwLabel: 'كلمة المرور',
    AppStrings.createPwConfirm: 'تأكيد كلمة المرور',
    AppStrings.createPwSave: 'حفظ',
    AppStrings.pwStrong: 'قوية',
    AppStrings.pwGood: 'جيدة',
    AppStrings.pwWeak: 'ضعيفة',
    AppStrings.pwMismatch: 'كلمتا المرور غير متطابقتين',

    // Password Reset
    AppStrings.pwResetTitle: 'إعادة تعيين كلمة المرور',
    AppStrings.pwResetEnterPhone: 'أدخل رقم هاتفك لاستلام رمز التحقق.',
    AppStrings.pwResetSendOtp: 'إرسال الرمز',
    AppStrings.pwResetEnterOtp: 'أدخل الرمز المرسل لرقمك.',
    AppStrings.pwResetOtpSent: 'تم إرسال الرمز إلى @phone',
    AppStrings.pwResetNewPassword: 'كلمة المرور الجديدة',
    AppStrings.pwResetConfirmPassword: 'تأكيد كلمة المرور',
    AppStrings.pwResetSuccess: 'تمت إعادة تعيين كلمة المرور',
    AppStrings.pwResetSuccessMessage: 'تم تحديث كلمة المرور. الرجاء تسجيل الدخول.',

    // Browse / family
    AppStrings.browse: 'تصفح',
    AppStrings.browseGoodMorning: 'صباح الخير',
    AppStrings.browseHello: 'مرحباً، @name',
    AppStrings.browseSearchHint: 'ابحث عن مربية...',
    AppStrings.browseTopMatches: 'أفضل المطابقات',
    AppStrings.browseNoMatch: 'لا توجد نتائج',
    AppStrings.seeAll: 'عرض الكل',

    // Profile
    AppStrings.shortlist: 'المفضلة',
    AppStrings.sendTrialOffer: 'إرسال عرض تجربة',
    AppStrings.whatsappHer: 'واتساب',
    AppStrings.callHer: 'اتصل',
    AppStrings.inAppChat: 'محادثة',
    AppStrings.fullCv: 'السيرة الذاتية',
    AppStrings.monthlyActive: 'اشتراك نشط',
    AppStrings.subExpiredBanner: 'انتهى اشتراكك. جدد للوصول.',
    AppStrings.renewNow: 'جدد الآن',

    // Chat
    AppStrings.chatTitle: 'المحادثات',
    AppStrings.chatExpiredTitle: 'المحادثات مقفلة',
    AppStrings.chatExpiredSub: 'جدد اشتراكك للوصول',
    AppStrings.chatEmptyTitle: 'لا توجد رسائل بعد',
    AppStrings.chatEmptySub: 'ستظهر محادثاتك هنا.',
    AppStrings.chatSearchHint: 'ابحث في المحادثات...',
    AppStrings.chatOnTrialBadge: 'تجربة',
    AppStrings.chatOnlineStatus: '🟢 متصل الآن · موثّق ✓',
    AppStrings.chatYou: 'أنت',
    AppStrings.chatNewConversation: '+ ابدأ محادثة جديدة',
    AppStrings.chatNewConversationSub: 'تصفح المربيات ← عرض الملف ← أرسل رسالة',
    AppStrings.chatPickTitle: 'ابدأ محادثة جديدة',
    AppStrings.chatPickSub: 'اختر مربية لمراسلتها',
    AppStrings.settingsSubscription: 'الاشتراك والدفع',
    AppStrings.postNewJob: 'أضف وظيفة جديدة',
    AppStrings.chatTrialActiveBanner: 'تجربة جارية',
    AppStrings.chatViewTrial: 'عرض التجربة',
    AppStrings.chatPrivacyTitle: '🔒 كيف يعمل التواصل في كافي',
    AppStrings.chatPrivacyPhone: '📞 هاتف المربية: اتصل أو واتساب مباشرة',
    AppStrings.chatPrivacyInApp: '💬 الدردشة داخل التطبيق: متاحة دائمًا',
    AppStrings.chatPrivacyNumber: '🔒 رقمك: لا يظهر أبدًا — يبقى خاصًا',

    // Trial
    AppStrings.trialOfferTitle: 'عرض تجربة',
    AppStrings.trialActive: 'التجربة نشطة',
    AppStrings.trialRemaining: '@days أيام متبقية',

    // Pricing
    AppStrings.pricingTitle: 'الأسعار',
    AppStrings.pricingChoose: 'اختر الخطة',
    AppStrings.pricingPopular: 'الأكثر شيوعاً',
    AppStrings.pricingVatNote: 'الأسعار شاملة ضريبة القيمة المضافة 5%',

    // Settings
    AppStrings.settingsTitle: 'الإعدادات',
    AppStrings.settingsNotifications: 'الإشعارات',
    AppStrings.settingsPrivacy: 'الخصوصية',
    AppStrings.settingsTerms: 'الشروط والأحكام',
    AppStrings.settingsLogout: 'تسجيل الخروج',

    // Notifications
    AppStrings.notificationsTitle: 'الإشعارات',
    AppStrings.notificationsEmpty: 'لا توجد إشعارات',

    // Common
    AppStrings.cancel: 'إلغاء',
    AppStrings.confirm: 'تأكيد',
    AppStrings.goBack: 'رجوع',

    // Delete account
    AppStrings.deleteAccountTitle: 'حذف الحساب',
    AppStrings.deleteAccountQuestion: 'هل تريد حذف حسابك؟',
    AppStrings.deleteAccountWarning: 'هذا الإجراء نهائي ولا يمكن التراجع عنه.',
    AppStrings.deleteAccountBtn: 'حذف الحساب',
    AppStrings.deletePermanently: 'حذف نهائي',
    AppStrings.accountDeleted: 'تم حذف الحساب',

    // Legal
    AppStrings.legalTermsTitle: 'الشروط والأحكام',
    AppStrings.legalPrivacyTitle: 'سياسة الخصوصية',

    // Error handling
    AppStrings.subscriptionRequired: 'يتطلب اشتراك',
    AppStrings.subscriptionExpiredMessage: 'انتهى اشتراكك. جدد للمتابعة.',
    AppStrings.subscribeToAccess: 'اشترك للوصول لهذه الميزة.',
    AppStrings.noInternet: 'لا يوجد اتصال بالإنترنت',
    AppStrings.checkConnection: 'تحقق من اتصالك وحاول مرة أخرى.',
    AppStrings.sessionExpired: 'انتهت الجلسة',
    AppStrings.pleaseSignInAgain: 'يرجى تسجيل الدخول مرة أخرى.',
    AppStrings.permissionNotificationDenied: 'تم رفض الإشعارات. فعّلها من الإعدادات للبقاء على اطلاع.',
    AppStrings.permissionPermanentlyDeniedTitle: 'الإذن مطلوب',
    AppStrings.permissionPermanentlyDeniedBody: 'تم رفض هذا الإذن بشكل دائم. افتح الإعدادات لتفعيله.',
    AppStrings.permissionOpenSettings: 'فتح الإعدادات',
    // Application Detail
    AppStrings.appDetailTitle: 'تفاصيل الطلب',
    AppStrings.appDetailJobInfo: 'معلومات الوظيفة',
    AppStrings.appDetailCoverMsg: 'رسالتك التعريفية',
    AppStrings.appDetailApplied: 'تم التقديم',
    AppStrings.appDetailViewed: 'شوهد من قبل الأسرة',
    AppStrings.appDetailDeclined: 'تم رفض الطلب',
    AppStrings.appDetailWithdrawn: 'تم سحب الطلب',
    AppStrings.appDetailShortlisted: 'أنت في القائمة المختصرة!',
    AppStrings.appDetailShortlistedMsg: 'أضافتك الأسرة إلى قائمتها المختصرة. قد تتواصل معك قريباً لترتيب فترة تجريبية.',
    AppStrings.appDetailTrialOffered: 'تلقيت عرض تجريبي!',
    AppStrings.appDetailTrialOfferedMsg: 'تريد أسرة مقابلتك لفترة تجريبية مدفوعة. راجع التفاصيل وقم بالرد.',
    AppStrings.appDetailHired: 'تهانينا — تم التوظيف!',
    AppStrings.appDetailHiredMsg: 'اختارتك الأسرة لهذا المنصب. تحقق من رسائلك للخطوات التالية.',
    AppStrings.appDetailDeclinedMsg: 'للأسف قررت هذه الأسرة عدم المضي قدماً. استمر في التقديم!',
    AppStrings.appDetailWithdrawnMsg: 'لقد سحبت هذا الطلب.',
    AppStrings.appDetailPendingMsg: 'تم إرسال طلبك! سيتم إخطار الأسرة. سنبلغك بمجرد ردهم.',
    AppStrings.appDetailViewedMsg: 'اطلعت الأسرة على ملفك الشخصي — هذه علامة جيدة!',
    AppStrings.appDetailMessageFamily: 'مراسلة الأسرة',
    AppStrings.appDetailWithdrawConfirm: 'هل أنت متأكد من سحب هذا الطلب؟',
    AppStrings.appDetailWithdrawNo: 'إبقاؤه',
    AppStrings.appDetailWithdrawYes: 'سحب',
    AppStrings.appDetailCounterTitle: 'إرسال عرض مضاد',
    AppStrings.appDetailCounterHint: 'السعر اليومي المقترح (درهم)',
    AppStrings.appDetailCounterSend: 'إرسال العرض',
    AppStrings.appDetailAcceptConfirm: 'قبول عرض التجربة؟',
    AppStrings.appDetailDeclineConfirm: 'رفض عرض التجربة؟',
    AppStrings.appDetailTrialDuration: 'المدة',
    AppStrings.appDetailTrialRate: 'السعر اليومي',
    AppStrings.appDetailTrialStart: 'تاريخ البدء',
    AppStrings.appDetailTrialType: 'النوع',
    AppStrings.appDetailTrialLocation: 'الموقع',
    AppStrings.appDetailTrialTotal: 'إجمالي الأرباح',
    AppStrings.appDetailTrialNotes: 'ملاحظات الأسرة',

    // Validation — generic (System Spec §14.4)
    AppStrings.valRequired: 'هذا الحقل مطلوب',
    AppStrings.valDobInvalid: 'تاريخ ميلاد غير صالح',
    AppStrings.valAgeMin18: 'يجب أن يكون عمرك 18 عامًا أو أكثر لاستخدام كافي',
    AppStrings.valPhoneInvalid: 'الرجاء إدخال رقم هاتف صحيح',
    AppStrings.valSalaryOrder: 'يجب أن يكون الحد الأدنى للراتب أقل من الحد الأقصى',

    // Auth errors & flow (System Spec §14.1)
    AppStrings.authPhoneInvalid: 'الرجاء إدخال رقم هاتف صحيح',
    AppStrings.authOtpIncorrect: 'رمز غير صحيح. يرجى التحقق والمحاولة مرة أخرى.',
    AppStrings.authOtpSendFailed: 'تعذّر إرسال الرمز. تحقق من رقمك وحاول مرة أخرى.',
    AppStrings.authOtpRateLimited: 'محاولات كثيرة. يرجى المحاولة لاحقًا.',
    AppStrings.authOtpMaxAttempts: 'محاولات خاطئة كثيرة. يرجى المحاولة لاحقًا.',
    AppStrings.authNoAccount: 'لا يوجد حساب بهذا الرقم',
    AppStrings.authAccountExists: 'يوجد حساب بالفعل. سجّل الدخول بدلاً من ذلك.',
    AppStrings.authWrongRole: 'هذا الرقم مسجّل بدور مختلف. رقم واحد = دور واحد.',
    AppStrings.authQuotaExceeded: 'الخدمة مشغولة. يرجى المحاولة بعد قليل.',
    AppStrings.authWrongPassword: 'كلمة المرور غير صحيحة. حاول مرة أخرى.',
    AppStrings.authReauthRequired: 'لأمان حسابك، يرجى التحقق مرة أخرى.',
    AppStrings.authCodeSent: 'تم إرسال رمز التحقق إلى @phone',
    AppStrings.authLearnMore: 'اعرف المزيد',
    AppStrings.authUseOtpInstead: 'استخدم رمز OTP بدلاً من ذلك',
    AppStrings.authQuickSafeEasy: 'سريع وآمن وسهل.',
    AppStrings.authDidntReceive: 'لم يصلك الرمز؟ ',
    AppStrings.otpResendShort: 'إعادة إرسال الرمز',
    AppStrings.authAgreePrefix: 'بالمتابعة فإنك توافق على ',
    AppStrings.authAgreeAnd: ' و ',

    // Nanny onboarding — required-field messages (System Spec §3.2 / §14.4)
    AppStrings.nannyNationalityRequired: 'الرجاء اختيار جنسيتك.',
    AppStrings.nannyVisaRequired: 'الرجاء اختيار حالة التأشيرة / الوضع القانوني.',
    AppStrings.nannyMaritalRequired: 'الرجاء اختيار حالتك الاجتماعية.',
    AppStrings.nannyChildrenCountRequired: 'الرجاء إدخال عدد أطفالك.',
    AppStrings.nannyEmergencyNameRequired: 'الرجاء إدخال اسم جهة اتصال الطوارئ.',
    AppStrings.nannyEmergencyRelRequired: 'الرجاء إدخال صلة القرابة بجهة الاتصال.',
    AppStrings.nannyEmergencyPhoneRequired: 'الرجاء إدخال رقم هاتف طوارئ صحيح.',
    AppStrings.nannyBioRequired: 'الرجاء كتابة نبذة قصيرة عنك.',

    // Nanny onboarding — labels
    AppStrings.nannyComfortFaith: 'هل أنت مرتاحة للعمل في منزل من ديانة مختلفة؟',
    AppStrings.nannyReligionPrivacyNote:
        'هذه المعلومات اختيارية وخاصة تمامًا. تساعد العائلات في إيجاد توافق ثقافي مريح.',
    AppStrings.nannyReligiousPractices: 'الممارسات الدينية (اختياري)',

    // Family onboarding — required-field messages (System Spec §3.3 / §3.4 / §14.4)
    AppStrings.familyNationalityRequired: 'الرجاء اختيار جنسيتك.',
    AppStrings.familyChildrenAgesRequired: 'الرجاء إدخال أعمار أطفالك.',
    AppStrings.familyLanguagesRequired: 'الرجاء اختيار لغة منزلية واحدة على الأقل.',
    AppStrings.familyRolesRequired: 'الرجاء اختيار دور واحد على الأقل تحتاجه.',
    AppStrings.familyScheduleRequired: 'الرجاء وصف جدول العمل.',
    AppStrings.familyDutiesRequired: 'الرجاء اختيار مهمة واحدة على الأقل.',
    AppStrings.familyBenefitsRequired: 'الرجاء اختيار ميزة واحدة على الأقل تقدمها.',
    AppStrings.familyTrialDaysRequired: 'الرجاء اختيار مدة التجربة.',
    AppStrings.familyTrialRateRequired: 'الرجاء تحديد السعر اليومي للتجربة.',

    // Nanny onboarding — work preferences (System Spec §3.2)
    AppStrings.nannySecWorkPrefs: 'تفضيلات العمل',
    AppStrings.jobBoth: 'كلاهما',
    AppStrings.nannyAvailability: 'متى يمكنك البدء؟',
    AppStrings.nannyAvailableFrom: 'من تاريخ محدد',
    AppStrings.nannyAvailableFromDate: 'متاحة اعتباراً من',
    AppStrings.nannyAvailableFromRequired: 'الرجاء اختيار تاريخ البدء.',

    // Location picker
    AppStrings.locationChange: 'تغيير',
    AppStrings.locationDetecting: 'جارٍ تحديد موقعك…',
  });
