/// Locale-aware push/inbox notification copy for Cloud Functions triggers.
///
/// Mirrors the admin panel's `locales/t.ts` pattern (flat key → string map,
/// `{name}` placeholder interpolation) but stays server-side only: there is no
/// shared runtime between the Functions bundle and the admin panel/Flutter app,
/// so the dictionary is duplicated here rather than imported cross-package.

export type Locale = 'en' | 'ar';

type Params = Record<string, string | number>;

/// A loosely-typed Firestore document that may carry a locale preference.
/// Covers every shape seen in the codebase: the Flutter app writes
/// `users/{uid}.settings.language` (`UserSettings.language`, default 'en'),
/// while `locale` / `preferredLanguage` / `language` at the top level are
/// checked defensively in case a doc ever carries one directly (e.g. a
/// denormalized `nannies`/`families` doc merged with its `users` doc).
export interface LocaleBearer {
  locale?: unknown;
  preferredLanguage?: unknown;
  language?: unknown;
  settings?: { language?: unknown } | null;
  [key: string]: unknown;
}

/// Normalizes any of the recognized locale fields to a supported `Locale`,
/// defaulting to 'en'. Accepts full tags like 'ar-AE' or 'en_US'.
export function resolveLocale(doc: LocaleBearer | null | undefined): Locale {
  const raw =
    doc?.settings?.language ?? doc?.locale ?? doc?.preferredLanguage ?? doc?.language;
  if (typeof raw !== 'string') return 'en';
  return raw.trim().toLowerCase().startsWith('ar') ? 'ar' : 'en';
}

/// Best-effort locale for HTTP endpoints that run before any Firestore user
/// doc can be read (e.g. the one-time admin bootstrap call, which by
/// definition happens before an `admins` doc exists). Reads the first tag off
/// a standard `Accept-Language` header; defaults to 'en'.
export function resolveLocaleFromHeader(acceptLanguage: string | string[] | undefined): Locale {
  const header = Array.isArray(acceptLanguage) ? acceptLanguage[0] : acceptLanguage;
  if (!header) return 'en';
  const first = header.split(',')[0]?.trim().toLowerCase();
  return first?.startsWith('ar') ? 'ar' : 'en';
}

function interpolate(str: string, params?: Params): string {
  if (!params) return str;
  return str.replace(/\{(\w+)\}/g, (match, key: string) =>
    Object.prototype.hasOwnProperty.call(params, key) ? String(params[key]) : match,
  );
}

const en = {
  // ── Nanny profile / documents (triggers/nanny.ts) ──────────────────────
  'nanny.docApproved.title': '✅ Document approved',
  'nanny.docApproved.body': '{docType} verified — keep going!',
  'nanny.docRejected.title': '❌ Action needed',
  'nanny.docRejected.body': '{docType} rejected: {reason}',
  'nanny.docRejected.defaultReason': 'Please re-upload',
  'nanny.profileApproved.title': '🎉 Profile approved!',
  'nanny.profileApproved.body': 'Your profile is now visible to families.',
  'nanny.profileRejected.title': '❌ Profile rejected',
  'nanny.profileRejected.defaultBody': 'Please review the feedback and re-submit.',
  'nanny.profileSubmitted.title': '📋 Profile submitted',
  'nanny.profileSubmitted.body': 'Admin is reviewing your profile (1–24 hours).',
  'nanny.accountDisabled.title': '🚫 Account disabled',
  'nanny.accountDisabled.body':
    'Your Kafi account has been disabled by an administrator. Please contact support.',
  'nanny.accountRestored.title': '✅ Account restored',
  'nanny.accountRestored.body': 'Your Kafi account has been re-enabled. Welcome back!',
  'nanny.introVideoApproved.title': '✅ Intro video approved',
  'nanny.introVideoApproved.body': 'Your introduction video is now visible to families.',
  'nanny.introVideoRejected.title': '❌ Intro video needs changes',
  'nanny.introVideoRejected.defaultBody': 'Please re-record your introduction video.',

  // ── Applications & trials (triggers/trial.ts) ──────────────────────────
  'application.new.title': '📝 New application',
  'application.new.body': '{nannyName} applied - {matchScore}% match',
  'application.new.defaultNannyName': 'A nanny',
  'application.viewed.title': '👀 Application viewed',
  'application.viewed.body': '{famName} viewed your application for {jobTitle}',
  'application.declined.title': 'Application update',
  'application.declined.body': '{famName} passed on your application for {jobTitle}',
  'application.defaultFamilyName': 'A family',
  'application.defaultJobTitle': 'your application',
  'trial.offerReceived.title': '🎉 Trial offer received!',
  'trial.offerReceived.body': '{famName} sent {days}-day trial @ AED {rate}/day',
  'trial.counterAccepted.title': '✅ Counter accepted',
  'trial.counterAccepted.body': '{famName} accepted your counter offer!',
  'trial.counterDeclined.title': 'Counter declined',
  'trial.counterDeclined.body': '{famName} declined your counter offer',
  'trial.defaultFamilyName': 'The family',
  'trial.accepted.title': '✅ Trial accepted',
  'trial.accepted.body': '{nannyName} accepted your offer!',
  'trial.declined.title': 'Trial declined',
  'trial.declined.body': '{nannyName} declined your offer',
  'trial.countered.title': '🔄 Counter offer',
  'trial.countered.body': '{nannyName} sent a counter offer',
  'trial.defaultNannyName': 'Nanny',
  'trial.completedFamily.title': '✅ Trial completed',
  'trial.completedFamily.body': 'The trial is complete — decide whether to hire.',
  'trial.completedNanny.title': '✅ Trial completed',
  'trial.completedNanny.body': 'Your trial is complete. The family will confirm next steps.',
  'trial.cancelled.title': 'Trial cancelled',
  'trial.cancelled.body': 'The trial has been cancelled.',
  'trial.startingSoon.title': '⏰ Trial starts tomorrow!',
  'trial.startingSoon.body': 'Trial starts at {time}',
  'trial.startingSoon.defaultTime': 'scheduled time',
  'trial.outcomePendingFamily.title': 'How did the trial go?',
  'trial.outcomePendingFamily.body': 'Let us know how it went with your nanny.',
  'trial.outcomePendingNanny.title': 'What happened after your trial?',
  'trial.outcomePendingNanny.body': 'Tell us if you got the job.',

  // ── Subscription (triggers/scheduled.ts, triggers/webhook.ts) ─────────
  'subscription.expiringSoon.title': '💳 Expiring soon',
  'subscription.expiringSoon.body': 'Your subscription renews in 3 days',
  'subscription.expiredEnforced.title': '⚠️ Subscription expired',
  'subscription.expiredEnforced.body': 'Renew to access your chats and contacts',
  'subscription.active.title': '✅ Subscription active',
  'subscription.active.body': 'Full access unlocked - browse, chat, and contact nannies!',
  'subscription.cancelled.title': 'Subscription cancelled',
  'subscription.cancelled.body': 'Your access continues until the end of the current period',
  'subscription.expiredWebhook.title': '⚠️ Subscription expired',
  'subscription.expiredWebhook.body': 'Renew to access chats and contacts',
  'subscription.paymentFailed.title': '❌ Payment failed',
  'subscription.paymentFailed.body': 'Update your payment method to continue access',
  'subscription.resumed.title': '🎉 Subscription resumed',
  'subscription.resumed.body': 'Your plan will renew automatically',
  'subscription.planUpdated.title': 'Plan updated',
  'subscription.planUpdated.body': 'Your subscription plan has changed.',

  // ── Chat (triggers/chat.ts) ─────────────────────────────────────────────
  'chat.newMessage.title': '💬 New message',
  'chat.newMessage.body': '{senderName}: {content}',
  'chat.defaultSenderName': 'Someone',

  // ── Disputes / reports (triggers/dispute.ts) ───────────────────────────
  'dispute.reply.title': '🎧 Support replied to your report',
  'dispute.resolved.title': '✅ Report resolved',
  'dispute.resolved.defaultBody': 'Our team has resolved your report.',
  'dispute.dismissed.title': '📋 Report closed',
  'dispute.dismissed.defaultBody': 'Our team has reviewed and closed your report.',

  // ── Support tickets (triggers/ticket.ts) ───────────────────────────────
  'ticket.reply.title': '🎧 Support replied',
  'ticket.resolved.title': '✅ Ticket resolved',
  'ticket.resolved.defaultBody': 'Our team has resolved your support ticket.',
  'ticket.closed.title': '📋 Ticket closed',
  'ticket.closed.defaultBody': 'Our team has closed your support ticket.',

  // ── Hires (triggers/stats.ts) ───────────────────────────────────────────
  'hire.hired.title': '🎉 You\u2019ve been hired!',
  'hire.hired.body': '{familyName} hired you. Your profile is now hidden from search — continue in Messages.',
  'hire.defaultFamilyName': 'A family',
  'hire.nannyResigned.title': 'Nanny resigned',
  'hire.nannyResigned.body': '{nannyName} has ended the hire.',
  'hire.defaultNannyName': 'Your nanny',
  'hire.completed.title': 'Hire completed',
  'hire.completed.body': 'Your hire with {familyName} has been completed.',
  'hire.ended.title': 'Hire ended',
  'hire.ended.body': '{familyName} has ended the hire.',

  // ── mockSubscription.ts (dev-only HttpsError messages) ─────────────────
  'error.signInRequired': 'Sign in required.',
  'error.mockSubscriptionDisabled': 'Mock subscription sync is disabled.',
  'error.stateRequired': 'state is required.',

  // ── bootstrapAdmin.ts (one-time admin bootstrap HTTP response messages) ─
  'error.adminAlreadyExists': 'An admin account already exists.',
  'error.firstAdminCreated':
    'First admin created. Sign in with the credentials below and change the password in Firebase Console.',
  'error.unknownError': 'Unknown error',
  'error.bootstrapPasswordMissing':
    'KAFI_ADMIN_BOOTSTRAP_PASSWORD must be set to a strong value (at least 8 characters) before the first admin can be bootstrapped.',
} as const;

const ar: Record<keyof typeof en, string> = {
  'nanny.docApproved.title': '✅ تم اعتماد المستند',
  'nanny.docApproved.body': 'تم التحقق من {docType} — استمري!',
  'nanny.docRejected.title': '❌ إجراء مطلوب',
  'nanny.docRejected.body': 'تم رفض {docType}: {reason}',
  'nanny.docRejected.defaultReason': 'يرجى إعادة الرفع',
  'nanny.profileApproved.title': '🎉 تم اعتماد الملف الشخصي!',
  'nanny.profileApproved.body': 'ملفك الشخصي أصبح مرئيًا للعائلات الآن.',
  'nanny.profileRejected.title': '❌ تم رفض الملف الشخصي',
  'nanny.profileRejected.defaultBody': 'يرجى مراجعة الملاحظات وإعادة التقديم.',
  'nanny.profileSubmitted.title': '📋 تم إرسال الملف الشخصي',
  'nanny.profileSubmitted.body': 'الإدارة تراجع ملفك الشخصي (١–٢٤ ساعة).',
  'nanny.accountDisabled.title': '🚫 تم تعطيل الحساب',
  'nanny.accountDisabled.body': 'تم تعطيل حسابك على Kafi من قبل أحد المشرفين. يرجى التواصل مع الدعم.',
  'nanny.accountRestored.title': '✅ تم استعادة الحساب',
  'nanny.accountRestored.body': 'تم إعادة تفعيل حسابك على Kafi. مرحبًا بعودتك!',
  'nanny.introVideoApproved.title': '✅ تم اعتماد الفيديو التعريفي',
  'nanny.introVideoApproved.body': 'فيديوك التعريفي أصبح مرئيًا للعائلات الآن.',
  'nanny.introVideoRejected.title': '❌ الفيديو التعريفي يحتاج تعديلات',
  'nanny.introVideoRejected.defaultBody': 'يرجى إعادة تسجيل فيديوك التعريفي.',

  'application.new.title': '📝 طلب توظيف جديد',
  'application.new.body': 'تقدّمت {nannyName} — نسبة توافق {matchScore}%',
  'application.new.defaultNannyName': 'إحدى المربيات',
  'application.viewed.title': '👀 تمت مشاهدة الطلب',
  'application.viewed.body': 'شاهدت {famName} طلبك لوظيفة {jobTitle}',
  'application.declined.title': 'تحديث على الطلب',
  'application.declined.body': 'تجاوزت {famName} طلبك لوظيفة {jobTitle}',
  'application.defaultFamilyName': 'إحدى العائلات',
  'application.defaultJobTitle': 'طلبك',
  'trial.offerReceived.title': '🎉 تم استلام عرض تجربة!',
  'trial.offerReceived.body': 'أرسلت {famName} عرض تجربة لمدة {days} يوم بمعدل {rate} درهم/يوم',
  'trial.counterAccepted.title': '✅ تم قبول العرض المضاد',
  'trial.counterAccepted.body': 'قبلت {famName} عرضك المضاد!',
  'trial.counterDeclined.title': 'تم رفض العرض المضاد',
  'trial.counterDeclined.body': 'رفضت {famName} عرضك المضاد',
  'trial.defaultFamilyName': 'العائلة',
  'trial.accepted.title': '✅ تم قبول التجربة',
  'trial.accepted.body': 'قبلت {nannyName} عرضك!',
  'trial.declined.title': 'تم رفض التجربة',
  'trial.declined.body': 'رفضت {nannyName} عرضك',
  'trial.countered.title': '🔄 عرض مضاد',
  'trial.countered.body': 'أرسلت {nannyName} عرضًا مضادًا',
  'trial.defaultNannyName': 'المربية',
  'trial.completedFamily.title': '✅ اكتملت التجربة',
  'trial.completedFamily.body': 'اكتملت التجربة — قرري ما إذا كنتِ ستوظفينها.',
  'trial.completedNanny.title': '✅ اكتملت التجربة',
  'trial.completedNanny.body': 'اكتملت تجربتك. ستؤكد العائلة الخطوات التالية.',
  'trial.cancelled.title': 'تم إلغاء التجربة',
  'trial.cancelled.body': 'تم إلغاء التجربة.',
  'trial.startingSoon.title': '⏰ تبدأ التجربة غدًا!',
  'trial.startingSoon.body': 'تبدأ التجربة في {time}',
  'trial.startingSoon.defaultTime': 'الوقت المحدد',
  'trial.outcomePendingFamily.title': 'كيف سارت التجربة؟',
  'trial.outcomePendingFamily.body': 'أخبرينا كيف سارت الأمور مع المربية.',
  'trial.outcomePendingNanny.title': 'ماذا حدث بعد تجربتك؟',
  'trial.outcomePendingNanny.body': 'أخبرينا إذا حصلتِ على الوظيفة.',

  'subscription.expiringSoon.title': '💳 ستنتهي قريبًا',
  'subscription.expiringSoon.body': 'يتجدد اشتراكك خلال ٣ أيام',
  'subscription.expiredEnforced.title': '⚠️ انتهى الاشتراك',
  'subscription.expiredEnforced.body': 'جددي اشتراكك للوصول إلى محادثاتك وجهات الاتصال',
  'subscription.active.title': '✅ الاشتراك مفعّل',
  'subscription.active.body': 'تم فتح الوصول الكامل — تصفحي وتواصلي مع المربيات!',
  'subscription.cancelled.title': 'تم إلغاء الاشتراك',
  'subscription.cancelled.body': 'يستمر وصولك حتى نهاية الفترة الحالية',
  'subscription.expiredWebhook.title': '⚠️ انتهى الاشتراك',
  'subscription.expiredWebhook.body': 'جددي اشتراكك للوصول إلى المحادثات وجهات الاتصال',
  'subscription.paymentFailed.title': '❌ فشلت عملية الدفع',
  'subscription.paymentFailed.body': 'يرجى تحديث طريقة الدفع لمواصلة الوصول',
  'subscription.resumed.title': '🎉 تم استئناف الاشتراك',
  'subscription.resumed.body': 'سيتجدد اشتراكك تلقائيًا',
  'subscription.planUpdated.title': 'تم تحديث الخطة',
  'subscription.planUpdated.body': 'تم تغيير خطة اشتراكك.',

  'chat.newMessage.title': '💬 رسالة جديدة',
  'chat.newMessage.body': '{senderName}: {content}',
  'chat.defaultSenderName': 'شخص ما',

  'dispute.reply.title': '🎧 رد فريق الدعم على بلاغك',
  'dispute.resolved.title': '✅ تم حل البلاغ',
  'dispute.resolved.defaultBody': 'قام فريقنا بحل بلاغك.',
  'dispute.dismissed.title': '📋 تم إغلاق البلاغ',
  'dispute.dismissed.defaultBody': 'راجع فريقنا بلاغك وأغلقه.',

  'ticket.reply.title': '🎧 رد فريق الدعم',
  'ticket.resolved.title': '✅ تم حل التذكرة',
  'ticket.resolved.defaultBody': 'قام فريقنا بحل تذكرة الدعم الخاصة بك.',
  'ticket.closed.title': '📋 تم إغلاق التذكرة',
  'ticket.closed.defaultBody': 'أغلق فريقنا تذكرة الدعم الخاصة بك.',

  'hire.hired.title': '🎉 تم توظيفك!',
  'hire.hired.body': 'وظّفتك {familyName}. أصبح ملفك الشخصي مخفيًا الآن من نتائج البحث — تابعي في الرسائل.',
  'hire.defaultFamilyName': 'إحدى العائلات',
  'hire.nannyResigned.title': 'استقالت المربية',
  'hire.nannyResigned.body': 'أنهت {nannyName} التوظيف.',
  'hire.defaultNannyName': 'مربيتك',
  'hire.completed.title': 'اكتمل التوظيف',
  'hire.completed.body': 'اكتمل توظيفك مع {familyName}.',
  'hire.ended.title': 'انتهى التوظيف',
  'hire.ended.body': 'أنهت {familyName} التوظيف.',

  'error.signInRequired': 'يرجى تسجيل الدخول.',
  'error.mockSubscriptionDisabled': 'مزامنة الاشتراك التجريبي معطّلة.',
  'error.stateRequired': 'الحقل state مطلوب.',

  'error.adminAlreadyExists': 'يوجد حساب مشرف بالفعل.',
  'error.firstAdminCreated':
    'تم إنشاء أول حساب مشرف. سجّلي الدخول بالبيانات أدناه وغيّري كلمة المرور من Firebase Console.',
  'error.unknownError': 'خطأ غير معروف',
  'error.bootstrapPasswordMissing':
    'يجب ضبط متغيّر البيئة KAFI_ADMIN_BOOTSTRAP_PASSWORD بقيمة قوية (8 أحرف على الأقل) قبل إنشاء أول حساب مشرف.',
};

export type NotificationKey = keyof typeof en;

/// Translates a notification copy key for the given locale, interpolating
/// `{name}`-style placeholders. Falls back to the English string if a locale
/// entry is somehow missing (keeps a bad key from throwing in a trigger).
export function tn(key: NotificationKey, locale: Locale, params?: Params): string {
  const dict = locale === 'ar' ? ar : en;
  return interpolate(dict[key] ?? en[key], params);
}

/// Builds a `{ title, body }` pair for a two-part key prefix, e.g.
/// `notif('nanny.docApproved', 'ar', { docType })` reads
/// `nanny.docApproved.title` + `nanny.docApproved.body`.
export function notif(
  prefix: string,
  locale: Locale,
  params?: Params,
): { title: string; body: string } {
  return {
    title: tn(`${prefix}.title` as NotificationKey, locale, params),
    body: tn(`${prefix}.body` as NotificationKey, locale, params),
  };
}
