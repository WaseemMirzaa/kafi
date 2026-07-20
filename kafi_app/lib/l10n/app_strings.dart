/// Translation keys only — copy in locales/en_us.dart
abstract class AppStrings {
  static const appName = 'app_name';
  static const tagline = 'tagline';

  // Welcome
  static const welcomeSubtitle = 'welcome_subtitle';
  static const welcomeTagline = 'welcome_tagline';
  static const welcomeWhoAreYou = 'welcome_who_are_you';
  static const welcomeRoleHint = 'welcome_role_hint';
  static const welcomeHaveAccount = 'welcome_have_account';
  static const roleNannyTitle = 'role_nanny_title';
  static const roleNannySubtitle = 'role_nanny_subtitle';
  static const roleFamilyTitle = 'role_family_title';
  static const roleFamilySubtitle = 'role_family_subtitle';
  static const badgeFreeForever = 'badge_free_forever';
  static const badgeUploadProfile = 'badge_upload_profile';
  static const badgeGetFound = 'badge_get_found';
  static const badgeBrowseNannies = 'badge_browse_nannies';
  static const badgeSmartMatch = 'badge_smart_match';
  static const badgeFromPrice = 'badge_from_price';

  // Auth — nanny
  static const nannySignUpBanner = 'nanny_signup_banner';
  static const nannySignUpSub = 'nanny_signup_sub';
  static const nannyWelcomeBack = 'nanny_welcome_back';
  static const nannyWelcomeBackSub = 'nanny_welcome_back_sub';
  static const nannyHomeHiredTitle = 'nanny_home_hired_title';
  static const nannyHomeHiredSub = 'nanny_home_hired_sub';
  static const nannyHomeOnTrialTitle = 'nanny_home_on_trial_title';
  static const nannyHomeOnTrialSub = 'nanny_home_on_trial_sub';
  static const nannyHomeViewChat = 'nanny_home_view_chat';
  static const authEnterPhone = 'auth_enter_phone';
  static const authEnterPhoneSub = 'auth_enter_phone_sub';
  static const authPhoneLabel = 'auth_phone_label';
  static const authOtpNotice = 'auth_otp_notice';
  static const authSendOtp = 'auth_send_otp';
  static const authSendOtpSignIn = 'auth_send_otp_signin';
  static const authAlreadyAccount = 'auth_already_account';
  static const authSigninHint = 'auth_signin_hint';
  static const authSignInTitle = 'auth_signin_title';
  static const authSignInSub = 'auth_signin_sub';
  static const authRegisteredPhone = 'auth_registered_phone';
  static const authOrPassword = 'auth_or_password';
  static const authPasswordLabel = 'auth_password_label';
  static const authSignInPassword = 'auth_signin_password';
  static const authForgotPassword = 'auth_forgot_password';
  static const authNewSignUp = 'auth_new_signup';
  static const authAgreeTerms = 'auth_agree_terms';
  static const terms = 'terms';
  static const privacy = 'privacy';

  // Auth — family
  static const familyRegBanner = 'family_reg_banner';
  static const familyRegSub = 'family_reg_sub';
  static const familyPhoneLabel = 'family_phone_label';
  static const familyOtpNotice = 'family_otp_notice';
  static const familySigninHint = 'family_signin_hint';

  // OTP
  static const otpSmsReceived = 'otp_sms_received';
  static const otpSmsBody = 'otp_sms_body';
  static const otpSmsSentTo = 'otp_sms_sent_to';
  static const otpEnterTitle = 'otp_enter_title';
  static const otpEnterSub = 'otp_enter_sub';
  static const otpExpires = 'otp_expires';
  static const authVerifyOtp = 'auth_verify_otp';
  static const authVerify = 'auth_verify';
  static const authPhoneRequired = 'auth_phone_required';
  static const pwMismatch = 'pw_mismatch';
  static const otpExpiredMessage = 'otp_expired_message';
  static const otpResend = 'otp_resend';
  static const otpChangeNumber = 'otp_change_number';
  static const otpSecurityNotice = 'otp_security_notice';
  static const otpVerified = 'otp_verified';
  static const otpVerifiedSub = 'otp_verified_sub';
  static const otpNext1 = 'otp_next_1';
  static const otpNext2 = 'otp_next_2';
  static const otpNext3 = 'otp_next_3';
  static const otpWhatNext = 'otp_what_next';

  // Password
  static const createPwTitle = 'create_pw_title';
  static const createPwSub = 'create_pw_sub';
  static const createPwLabel = 'create_pw_label';
  static const createPwConfirm = 'create_pw_confirm';
  static const createPwSave = 'create_pw_save';
  static const pwStrong = 'pw_strong';
  static const pwGood = 'pw_good';
  static const pwWeak = 'pw_weak';

  // Errors / snackbars
  static const errorTitle = 'error_title';
  static const successTitle = 'success_title';
  static const phoneRequired = 'phone_required';
  static const authInvalidOtp = 'auth_invalid_otp';
  static const authOtpSentTitle = 'auth_otp_sent_title';
  static const authOtpSentBody = 'auth_otp_sent_body';
  static const authMissingFields = 'auth_missing_fields';
  static const authSessionLost = 'auth_session_lost';

  // Placeholders
  static const nannyInfo = 'nanny_info';
  static const nannyHome = 'nanny_home';
  static const familyForm = 'family_form';
  static const browse = 'browse';

  static const back = 'back';

  // Nanny onboarding — common
  static const stepXofY = 'step_x_of_y';
  static const nannyAboutYou = 'nanny_about_you';
  static const nannyAboutYouSub = 'nanny_about_you_sub';
  static const nextPhotos = 'next_photos';
  static const nextExp = 'next_exp';
  static const nextRefs = 'next_refs';
  static const nextDocs = 'next_docs';
  static const submitReview = 'submit_review';

  // Family → nanny reviews (post-trial rating)
  static const reviewTitle = 'review_title';
  static const reviewSubtitle = 'review_subtitle';
  static const reviewYourNanny = 'review_your_nanny';
  static const reviewYourFamily = 'review_your_family';
  static const reviewCommentHint = 'review_comment_hint';
  static const reviewSubmit = 'review_submit';
  static const reviewSkip = 'review_skip';
  static const reviewThanks = 'review_thanks';
  static const reviewFailed = 'review_failed';

  // Contact reveal
  static const contactUnavailable = 'contact_unavailable';
  static const contactLaunchFailed = 'contact_launch_failed';
  static const contactLoadFailed = 'contact_load_failed';
  static const addAnother = 'add_another';
  static const removeItem = 'remove_item';

  // Step 1 — sections
  static const secBasic = 'sec_basic';
  static const secVisa = 'sec_visa';
  static const secWorkLoc = 'sec_work_loc';
  static const secPersonal = 'sec_personal';
  static const secHealth = 'sec_health';
  static const secComfort = 'sec_comfort';
  static const secReligion = 'sec_religion';
  static const secEmergency = 'sec_emergency';
  static const secBio = 'sec_bio';

  static const fldFullName = 'fld_full_name';
  static const fldDob = 'fld_dob';
  static const fldAge = 'fld_age';
  static const fldNationality = 'fld_nationality';
  static const fldLanguages = 'fld_languages';
  static const fldVisaStatus = 'fld_visa_status';
  static const fldHasEid = 'fld_has_eid';
  static const fldTransferVisa = 'fld_transfer_visa';
  static const fldEmirates = 'fld_emirates';
  static const fldRelocate = 'fld_relocate';
  static const fldCurrentArea = 'fld_current_area';
  static const fldCity = 'fld_city';
  static const fldMarital = 'fld_marital';
  static const fldChildren = 'fld_children';
  static const fldChildrenCount = 'fld_children_count';
  static const fldHealth = 'fld_health';
  static const fldMeds = 'fld_meds';
  static const fldAllergies = 'fld_allergies';
  static const fldComfortCameras = 'fld_comfort_cameras';
  static const fldComfortPets = 'fld_comfort_pets';
  static const fldCooks = 'fld_cooks';
  static const fldNightShifts = 'fld_night_shifts';
  static const fldReligion = 'fld_religion';
  static const fldEmergencyName = 'fld_emergency_name';
  static const fldEmergencyRel = 'fld_emergency_rel';
  static const fldEmergencyPhone = 'fld_emergency_phone';
  static const fldBio = 'fld_bio';

  static const visaVisit = 'visa_visit';
  static const visaSponsored = 'visa_sponsored';
  static const visaOwn = 'visa_own';
  static const visaCancelled = 'visa_cancelled';
  static const visaOutside = 'visa_outside';

  static const emirateDubai = 'emirate_dubai';
  static const emirateAbuDhabi = 'emirate_abu_dhabi';
  static const emirateSharjah = 'emirate_sharjah';
  static const emirateAjman = 'emirate_ajman';
  static const emirateRak = 'emirate_rak';
  static const emirateFujairah = 'emirate_fujairah';
  static const emirateUaq = 'emirate_uaq';
  static const emirateAlAin = 'emirate_al_ain';

  static const yesShort = 'yes_short';
  static const noShort = 'no_short';
  static const depends = 'depends';

  // Step 2 — media
  static const mediaPhotos = 'media_photos';
  static const mediaPhotosTip = 'media_photos_tip';
  static const mediaUploadPhoto = 'media_upload_photo';
  static const mediaVideo = 'media_video';
  static const mediaVideoRule = 'media_video_rule';
  static const mediaUploadVideo = 'media_upload_video';

  // Step 3 — experience
  static const expTitle = 'exp_title';
  static const expSub = 'exp_sub';
  static const expJobTitle = 'exp_job_title';
  static const expEmployer = 'exp_employer';
  static const expCityCountry = 'exp_city_country';
  static const expFrom = 'exp_from';
  static const expTo = 'exp_to';
  static const expChildren = 'exp_children';
  static const expDuties = 'exp_duties';
  static const expReason = 'exp_reason';

  // Step 4 — refs
  static const refsTitle = 'refs_title';
  static const refsBanner = 'refs_banner';
  static const refsHas = 'refs_has';
  static const refsRel = 'refs_rel';
  static const refsCity = 'refs_city';
  static const refsYears = 'refs_years';
  static const refsCanConfirm = 'refs_can_confirm';
  static const refsCommit = 'refs_commit';

  // Step 5 — docs
  static const docsTitle = 'docs_title';
  static const docsWarning = 'docs_warning';
  static const docPassport = 'doc_passport';
  static const docVisa = 'doc_visa';
  static const docEid = 'doc_eid';
  static const docTraining = 'doc_training';
  static const docPolice = 'doc_police';
  static const docRequired = 'doc_required';
  static const docOptional = 'doc_optional';
  static const docUploaded = 'doc_uploaded';
  static const docMissing = 'doc_missing';
  static const docReviewing = 'doc_reviewing';
  static const docApproved = 'doc_approved';
  static const docRejected = 'doc_rejected';

  // Step 6 — pending
  static const pendingTitle = 'pending_title';
  static const pendingSub = 'pending_sub';
  static const pendingWhile = 'pending_while';
  static const nannyDocStatusTitle = 'nanny_doc_status_title';
  static const nannyIntroVideo = 'nanny_intro_video';
  static const nannyUpdateDocuments = 'nanny_update_documents';
  // Rejection flow (Spec §6.1)
  static const nannyRejectedTitle = 'nanny_rejected_title';
  static const nannyRejectedSub = 'nanny_rejected_sub';
  static const nannyRejectedBody = 'nanny_rejected_body';
  static const nannyRejectedReasonLabel = 'nanny_rejected_reason_label';
  static const nannyResubmit = 'nanny_resubmit';

  // Dashboard
  static const dashStats = 'dash_stats';
  static const dashShortlists = 'dash_shortlists';
  static const dashViews = 'dash_views';
  static const dashRating = 'dash_rating';
  static const dashProfileQuality = 'dash_profile_quality';
  static const dashJobsForYou = 'dash_jobs_for_you';
  static const dashSeeAll = 'dash_see_all';
  static const dashKafiVerified = 'dash_kafi_verified';
  static const navHome = 'nav_home';
  static const navJobs = 'nav_jobs';
  static const navMessages = 'nav_messages';
  static const navProfile = 'nav_profile';
  static const navShortlist = 'nav_shortlist';
  static const settingsSubscription = 'settings_subscription';
  static const postNewJob = 'post_new_job';

  // Snackbars
  static const nannySubmittedTitle = 'nanny_submitted_title';
  static const nannySubmittedBody = 'nanny_submitted_body';
  static const nannyApprovedTitle = 'nanny_approved_title';
  static const nannyApprovedBody = 'nanny_approved_body';

  // Nanny Jobs
  static const nannyJobsTitle = 'nanny_jobs_title';
  static const jobDetailsTitle = 'job_details_title';
  static const nannyJobsMatching = 'nanny_jobs_matching';
  static const dashboardGreeting = 'dashboard_greeting';
  static const nannyJobsSearch = 'nanny_jobs_search';
  static const nannyStatsApplied = 'nanny_stats_applied';
  static const nannyStatsViewed = 'nanny_stats_viewed';
  static const nannyStatsOffers = 'nanny_stats_offers';
  static const nannyJobsEmpty = 'nanny_jobs_empty';
  static const nannyJobsEmptySub = 'nanny_jobs_empty_sub';
  static const nannyJobApply = 'nanny_job_apply';
  static const nannyMyApplications = 'nanny_my_applications';
  static const nannyNoApplications = 'nanny_no_applications';
  static const nannyNoApplicationsSub = 'nanny_no_applications_sub';
  static const nannyWithdraw = 'nanny_withdraw';
  static const matchGreat = 'match_great';
  static const matchLow = 'match_low';

  // Application Detail
  static const appDetailTitle = 'app_detail_title';
  static const appDetailJobInfo = 'app_detail_job_info';
  static const appDetailCoverMsg = 'app_detail_cover_msg';
  static const applyCoverTitle = 'apply_cover_title';
  static const applyCoverSub = 'apply_cover_sub';
  static const applyCoverHint = 'apply_cover_hint';
  static const applyCoverSend = 'apply_cover_send';
  static const appDetailApplied = 'app_detail_applied';
  static const appDetailViewed = 'app_detail_viewed';
  static const appDetailDeclined = 'app_detail_declined';
  static const appDetailWithdrawn = 'app_detail_withdrawn';
  static const appDetailShortlisted = 'app_detail_shortlisted';
  static const appDetailShortlistedMsg = 'app_detail_shortlisted_msg';
  static const appDetailTrialOffered = 'app_detail_trial_offered';
  static const appDetailTrialOfferedMsg = 'app_detail_trial_offered_msg';
  static const appDetailHired = 'app_detail_hired';
  static const appDetailHiredMsg = 'app_detail_hired_msg';
  static const appDetailDeclinedMsg = 'app_detail_declined_msg';
  static const appDetailWithdrawnMsg = 'app_detail_withdrawn_msg';
  static const appDetailPendingMsg = 'app_detail_pending_msg';
  static const appDetailViewedMsg = 'app_detail_viewed_msg';
  static const appDetailMessageFamily = 'app_detail_message_family';
  static const appDetailWithdrawConfirm = 'app_detail_withdraw_confirm';
  static const appDetailWithdrawNo = 'app_detail_withdraw_no';
  static const appDetailWithdrawYes = 'app_detail_withdraw_yes';
  static const appDetailCounterTitle = 'app_detail_counter_title';
  static const appDetailCounterHint = 'app_detail_counter_hint';
  static const appDetailCounterSend = 'app_detail_counter_send';
  static const appDetailAcceptConfirm = 'app_detail_accept_confirm';
  static const appDetailDeclineConfirm = 'app_detail_decline_confirm';
  static const appDetailTrialDuration = 'app_detail_trial_duration';
  static const appDetailTrialRate = 'app_detail_trial_rate';
  static const appDetailTrialStart = 'app_detail_trial_start';
  static const appDetailTrialType = 'app_detail_trial_type';
  static const appDetailTrialLocation = 'app_detail_trial_location';
  static const appDetailTrialTotal = 'app_detail_trial_total';
  static const appDetailTrialNotes = 'app_detail_trial_notes';

  // Shortlist
  static const shortlistTitle = 'shortlist_title';
  static const shortlistCompare = 'shortlist_compare';
  static const shortlistEmpty = 'shortlist_empty';
  static const shortlistEmptySub = 'shortlist_empty_sub';

  // Settings
  static const settingsTitle = 'settings_title';
  static const settingsNotifications = 'settings_notifications';
  static const settingsPush = 'settings_push';
  static const settingsPushSub = 'settings_push_sub';
  static const settingsMessages = 'settings_messages';
  static const settingsMessagesSub = 'settings_messages_sub';
  static const settingsTrials = 'settings_trials';
  static const settingsTrialsSub = 'settings_trials_sub';
  static const settingsJobMatches = 'settings_job_matches';
  static const settingsJobMatchesSub = 'settings_job_matches_sub';
  static const settingsProfileViews = 'settings_profile_views';
  static const settingsProfileViewsSub = 'settings_profile_views_sub';
  static const settingsMarketing = 'settings_marketing';
  static const settingsMarketingSub = 'settings_marketing_sub';
  static const settingsEmail = 'settings_email';
  static const settingsEmailSub = 'settings_email_sub';
  static const settingsLanguage = 'settings_language';
  static const settingsPrivacy = 'settings_privacy';
  static const settingsOnline = 'settings_online';
  static const settingsOnlineSub = 'settings_online_sub';
  static const settingsAccount = 'settings_account';
  static const settingsChangePassword = 'settings_change_password';
  static const settingsRestorePurchases = 'settings_restore_purchases';
  static const settingsRestoreDone = 'settings_restore_done';
  static const settingsTerms = 'settings_terms';
  static const settingsPrivacyPolicy = 'settings_privacy_policy';
  static const settingsDangerZone = 'settings_danger_zone';
  static const settingsLogout = 'settings_logout';
  static const settingsLogoutConfirm = 'settings_logout_confirm';
  static const settingsLogoutConfirmSub = 'settings_logout_confirm_sub';
  static const settingsDeleteAccount = 'settings_delete_account';

  // Notifications
  static const notificationsTitle = 'notifications_title';
  static const notificationsMarkAll = 'notifications_mark_all';
  static const notificationsEmpty = 'notifications_empty';

  // Trial Offer
  static const trialOfferTitle = 'trial_offer_title';
  static const trialLocation = 'trial_location';
  static const trialOfferTo = 'trial_offer_to';
  static const trialOfferDuration = 'trial_offer_duration';
  static const trialOfferRate = 'trial_offer_rate';
  static const trialOfferStart = 'trial_offer_start';
  static const trialOfferType = 'trial_offer_type';
  static const trialOfferNotes = 'trial_offer_notes';
  static const trialOfferDisclaimer = 'trial_offer_disclaimer';
  static const trialOfferSend = 'trial_offer_send';
  static const trialOfferAckLabel = 'trial_offer_ack_label';
  static const trialAlreadyActive = 'trial_already_active';
  static const trialActiveNoApply = 'trial_active_no_apply';
  static const applyAlreadyApplied = 'apply_already_applied';

  // Family "Applicants" view (Spec §6.x — family receives applications)
  static const familyApplicants = 'family_applicants';
  static const familyApplicantsSub = 'family_applicants_sub';
  static const familyApplicantsEmpty = 'family_applicants_empty';
  static const familyApplicantsEmptySub = 'family_applicants_empty_sub';
  static const applicantShortlist = 'applicant_shortlist';
  static const applicantDecline = 'applicant_decline';
  static const applicantProfileUnavailable = 'applicant_profile_unavailable';
  // Application status labels (shared)
  static const appStatusPending = 'app_status_pending';
  static const appStatusViewed = 'app_status_viewed';
  static const appStatusShortlisted = 'app_status_shortlisted';
  static const appStatusTrialOffered = 'app_status_trial_offered';
  static const appStatusDeclined = 'app_status_declined';
  static const appStatusWithdrawn = 'app_status_withdrawn';
  static const appStatusHired = 'app_status_hired';
  static const trialCounterOffer = 'trial_counter_offer';
  static const trialStatusAccepted = 'trial_status_accepted';
  static const trialStatusActive = 'trial_status_active';
  static const trialStatusDeclined = 'trial_status_declined';
  static const trialStatusCountered = 'trial_status_countered';
  static const trialStatusCompleted = 'trial_status_completed';
  static const trialStatusCancelled = 'trial_status_cancelled';
  static const trialCounterAccepted = 'trial_counter_accepted';
  static const trialCounterDeclined = 'trial_counter_declined';
  static const chatExpiredListBanner = 'chat_expired_list_banner';
  static const nannyFullNameRequired = 'nanny_full_name_required';
  static const nannyDobRequired = 'nanny_dob_required';
  static const nannyLanguagesRequired = 'nanny_languages_required';
  static const nannyEmiratesRequired = 'nanny_emirates_required';
  static const nannyPhotosRequired = 'nanny_photos_required';
  static const nannyCompleteStep1 = 'nanny_complete_step1';
  static const nannyRequiredDocsMissing = 'nanny_required_docs_missing';
  static const subGraceBanner = 'sub_grace_banner';
  static const subFixNow = 'sub_fix_now';
  static const familyNameRequired = 'family_name_required';
  static const familyCityRequired = 'family_city_required';
  static const familyEditTitle = 'family_edit_title';
  static const familyEditSubtitle = 'family_edit_subtitle';
  static const familyEditSave = 'family_edit_save';
  static const contactsHiddenBanner = 'contacts_hidden_banner';
  static const trialOfferSubRequired = 'trial_offer_sub_required';
  static const trialOfferAckRequired = 'trial_offer_ack_required';
  static const trialOfferBubbleSent = 'trial_offer_bubble_sent';
  static const trialOfferSentSuccess = 'trial_offer_sent_success';
  static const trialOfferBubbleReceived = 'trial_offer_bubble_received';
  static const trialOfferBubbleDuration = 'trial_offer_bubble_duration';
  static const trialOfferBubbleRate = 'trial_offer_bubble_rate';
  static const trialOfferAccept = 'trial_offer_accept';
  static const trialOfferCounter = 'trial_offer_counter';
  static const trialOfferDecline = 'trial_offer_decline';
  static const trialOfferSelectDate = 'trial_offer_select_date';
  static const trialOfferNotesHint = 'trial_offer_notes_hint';
  static const trialOfferLiveInTitle = 'trial_offer_live_in_title';
  static const trialOfferLiveInSub = 'trial_offer_live_in_sub';
  static const trialOfferLiveOutTitle = 'trial_offer_live_out_title';
  static const trialOfferLiveOutSub = 'trial_offer_live_out_sub';
  static const trialOfferDurationDays = 'trial_offer_duration_days';
  static const trialOfferTotal = 'trial_offer_total';
  static const trialAcceptedMessage = 'trial_accepted_message';
  static const trialAcceptedToast = 'trial_accepted_toast';
  static const trialDeclinedMessage = 'trial_declined_message';
  static const trialCounteredMessage = 'trial_countered_message';
  static const trialCounteredToast = 'trial_countered_toast';

  // Family — post job
  static const familyFormTitle = 'family_form_title';
  static const familyFormSub = 'family_form_sub';
  static const familySectionYou = 'family_section_you';
  static const familySectionReligion = 'family_section_religion';
  static const familySectionRole = 'family_section_role';
  static const familySectionDuties = 'family_section_duties';
  static const familySectionBenefits = 'family_section_benefits';
  static const familySectionSalary = 'family_section_salary';
  static const familySectionVisa = 'family_section_visa';
  static const findMyNanny = 'find_my_nanny';
  static const fldChildrenAges = 'fld_children_ages';
  static const fldHomeLanguages = 'fld_home_languages';
  static const fldRoles = 'fld_roles';
  static const fldJobType = 'fld_job_type';
  static const jobLiveIn = 'job_live_in';
  static const jobLiveOut = 'job_live_out';
  static const fldDuties = 'fld_duties';
  static const fldBenefits = 'fld_benefits';
  static const fldSalaryMin = 'fld_salary_min';
  static const fldSalaryMax = 'fld_salary_max';
  static const fldTrialDays = 'fld_trial_days';
  static const fldTrialRate = 'fld_trial_rate';
  static const fldSponsorship = 'fld_sponsorship';
  static const spFull = 'sp_full';
  static const spShared = 'sp_shared';
  static const spResidence = 'sp_residence';
  static const spNone = 'sp_none';
  static const spCommit = 'sp_commit';

  // Browse
  static const browseGoodMorning = 'browse_good_morning';
  static const browseHello = 'browse_hello';
  static const browseSearchHint = 'browse_search_hint';
  static const searchHint = 'search_hint';
  static const browseTopMatches = 'browse_top_matches';
  static const seeAll = 'see_all';
  static const verifiedBadge = 'verified_badge';
  static const matchSuffix = 'match_suffix';
  static const availableNow = 'available_now';

  // Profile
  static const profileLockedTitle = 'profile_locked_title';
  static const profileLockedSub = 'profile_locked_sub';
  static const yearsExp = 'years_exp';
  static const rating = 'rating';
  static const reviews = 'reviews';
  static const skillsSpecialties = 'skills_specialties';
  static const contactLocked = 'contact_locked';
  static const contactUnlocked = 'contact_unlocked';
  static const subscribeUnlockTitle = 'subscribe_unlock_title';
  static const subscribeUnlockSub = 'subscribe_unlock_sub';
  static const subscribeNow = 'subscribe_now';
  static const perWeek = 'per_week';
  static const perkUnlimited = 'perk_unlimited';
  static const perkVideos = 'perk_videos';
  static const perkTrials = 'perk_trials';
  static const perkCancel = 'perk_cancel';
  static const monthlyActive = 'monthly_active';
  static const whatsappHer = 'whatsapp_her';
  static const callHer = 'call_her';
  static const inAppChat = 'in_app_chat';
  static const watchIntroVideo = 'watch_intro_video';
  static const fullCv = 'full_cv';
  static const downloadCv = 'download_cv';
  static const shortlist = 'shortlist';
  static const sendTrialOffer = 'send_trial_offer';
  static const subExpiredBanner = 'sub_expired_banner';
  static const renewNow = 'renew_now';

  // Chat
  static const chatTitle = 'chat_title';
  static const chatExpiredTitle = 'chat_expired_title';
  static const chatExpiredSub = 'chat_expired_sub';
  static const chatUnavailable = 'chat_unavailable';
  static const chatExpiredBody = 'chat_expired_body';
  static const viewPlans = 'view_plans';
  static const chatHintActive = 'chat_hint_active';
  static const chatSend = 'chat_send';
  static const chatTrialBadge = 'chat_trial_badge';
  static const chatEmptyTitle = 'chat_empty_title';
  static const chatEmptySub = 'chat_empty_sub';
  static const chatSearchHint = 'chat_search_hint';
  static const chatOnTrialBadge = 'chat_on_trial_badge';
  static const chatHiredBadge = 'chat_hired_badge';
  static const chatHiredPill = 'chat_hired_pill';
  static const chatOnlineStatus = 'chat_online_status';
  static const chatYou = 'chat_you';
  static const chatNewConversation = 'chat_new_conversation';
  static const chatNewConversationSub = 'chat_new_conversation_sub';
  static const chatPickTitle = 'chat_pick_title';
  static const chatPickSub = 'chat_pick_sub';
  static const chatTrialActiveBanner = 'chat_trial_active_banner';
  static const chatViewTrial = 'chat_view_trial';
  static const chatPrivacyTitle = 'chat_privacy_title';
  static const chatPrivacyPhone = 'chat_privacy_phone';
  static const chatPrivacyInApp = 'chat_privacy_in_app';
  static const chatPrivacyNumber = 'chat_privacy_number';

  // Smart match
  static const smartGood = 'smart_good';
  static const smartLow = 'smart_low';
  static const smartTitle = 'smart_title';
  static const smartGoBack = 'smart_go_back';
  static const smartApplyAnyway = 'smart_apply_anyway';
  static const smartSendApp = 'smart_send_app';
  static const smartJobMissing = 'smart_job_missing';
  static const smartAppSent = 'smart_app_sent';
  static const smartAppSentSub = 'smart_app_sent_sub';
  static const smartAppSentDone = 'smart_app_sent_done';
  static const smartApplyingTitle = 'smart_applying_title';
  static const smartApplyingSub = 'smart_applying_sub';
  static const smartScoreSubGood = 'smart_score_sub_good';
  static const smartScoreSubLow = 'smart_score_sub_low';
  static const smartCheckLang = 'smart_check_lang';
  static const smartCheckExp = 'smart_check_exp';
  static const smartCheckRole = 'smart_check_role';
  static const smartCheckVisa = 'smart_check_visa';
  static const smartCheckSalary = 'smart_check_salary';
  static const browseNoMatch = 'browse_no_match';

  // Trial
  static const trialActive = 'trial_active';
  static const trialRemaining = 'trial_remaining';
  static const trialEval = 'trial_eval';
  static const trialHire = 'trial_hire';
  static const trialNotThisTime = 'trial_not_this_time';

  // Pricing
  static const pricingTitle = 'pricing_title';
  static const pricingFreeBanner = 'pricing_free_banner';
  static const pricingFreeUsed = 'pricing_free_used';
  static const pricingVatNote = 'pricing_vat_note';
  static const pricingChoose = 'pricing_choose';
  static const pricingPopular = 'pricing_popular';

  // Legal
  static const legalTermsTitle = 'legal_terms_title';
  static const legalPrivacyTitle = 'legal_privacy_title';
  static const legalLastUpdated = 'legal_last_updated';

  // Delete Account
  static const deleteAccountTitle = 'delete_account_title';
  static const deleteAccountQuestion = 'delete_account_question';
  static const deleteAccountWarning = 'delete_account_warning';
  static const deleteWillRemove = 'delete_will_remove';
  static const deleteItemProfile = 'delete_item_profile';
  static const deleteItemChats = 'delete_item_chats';
  static const deleteItemTrials = 'delete_item_trials';
  static const deleteItemSubscription = 'delete_item_subscription';
  static const deleteSelectReason = 'delete_select_reason';
  static const deleteAccountBtn = 'delete_account_btn';
  static const deleteFinalConfirm = 'delete_final_confirm';
  static const deleteFinalWarning = 'delete_final_warning';
  static const deleteTypeDelete = 'delete_type_delete';
  static const deletePermanently = 'delete_permanently';
  static const accountDeleted = 'account_deleted';
  static const accountDeletedMessage = 'account_deleted_message';
  static const cancel = 'cancel';
  static const confirm = 'confirm';
  static const goBack = 'go_back';
  static const retry = 'retry';
  static const loadErrorTitle = 'load_error_title';
  static const loadErrorSub = 'load_error_sub';

  // Hire continuation (resign / terminate)
  static const hireResignAction = 'hire_resign_action';
  static const hireResignTitle = 'hire_resign_title';
  static const hireResignBody = 'hire_resign_body';
  static const hireResignedToast = 'hire_resigned_toast';
  static const hireEndAction = 'hire_end_action';
  static const hireEndTitle = 'hire_end_title';
  static const hireEndBody = 'hire_end_body';
  static const hireEndedToast = 'hire_ended_toast';
  static const hireActiveBanner = 'hire_active_banner';
  static const nannyJobCapReached = 'nanny_job_cap_reached';

  // Family "My Jobs" management
  static const myJobsTitle = 'my_jobs_title';
  static const myJobsSubtitle = 'my_jobs_subtitle';
  static const myJobsEmpty = 'my_jobs_empty';
  static const myJobsEmptySub = 'my_jobs_empty_sub';
  static const myJobsPostNew = 'my_jobs_post_new';
  static const jobStatusActiveLabel = 'job_status_active_label';
  static const jobStatusPausedLabel = 'job_status_paused_label';
  static const jobStatusClosedLabel = 'job_status_closed_label';
  static const jobStatusExpiredLabel = 'job_status_expired_label';
  static const jobHiredWith = 'job_hired_with';
  static const jobApplicantsN = 'job_applicants_n';
  static const jobActionEdit = 'job_action_edit';
  static const jobActionDelete = 'job_action_delete';
  static const jobActionPause = 'job_action_pause';
  static const jobActionReopen = 'job_action_reopen';
  static const jobActionClose = 'job_action_close';
  static const jobDeleteTitle = 'job_delete_title';
  static const jobDeleteBody = 'job_delete_body';
  static const jobDeletedToast = 'job_deleted_toast';
  static const jobUpdatedToast = 'job_updated_toast';
  static const jobEditTitle = 'job_edit_title';
  static const jobFieldTitle = 'job_field_title';
  static const jobFieldSchedule = 'job_field_schedule';
  static const jobFieldSalaryMin = 'job_field_salary_min';
  static const jobFieldSalaryMax = 'job_field_salary_max';

  // Daily trial proof
  static const trialProofTitle = 'trial_proof_title';
  static const trialProofNannySub = 'trial_proof_nanny_sub';
  static const trialProofFamilySub = 'trial_proof_family_sub';
  static const trialProofDay = 'trial_proof_day';
  static const trialProofAdd = 'trial_proof_add';
  static const trialProofPending = 'trial_proof_pending';
  static const trialProofUploaded = 'trial_proof_uploaded';

  // Support tickets
  static const settingsSupport = 'settings_support';
  static const supportTitle = 'support_title';
  static const supportSubtitle = 'support_subtitle';
  static const supportEmpty = 'support_empty';
  static const supportEmptySub = 'support_empty_sub';
  static const supportNewTicket = 'support_new_ticket';
  static const supportJustNow = 'support_just_now';
  static const supportSubjectLabel = 'support_subject_label';
  static const supportCategoryLabel = 'support_category_label';
  static const supportMessageLabel = 'support_message_label';
  static const supportSubmit = 'support_submit';
  static const supportFillFields = 'support_fill_fields';
  static const supportThreadEmpty = 'support_thread_empty';
  static const supportAgentName = 'support_agent_name';
  static const supportMessageHint = 'support_message_hint';
  static const supportCatAccount = 'support_cat_account';
  static const supportCatPayment = 'support_cat_payment';
  static const supportCatTrial = 'support_cat_trial';
  static const supportCatHiring = 'support_cat_hiring';
  static const supportCatTechnical = 'support_cat_technical';
  static const supportCatOther = 'support_cat_other';
  static const supportStatusOpen = 'support_status_open';
  static const supportStatusInvestigating = 'support_status_investigating';
  static const supportStatusResolved = 'support_status_resolved';
  static const supportStatusClosed = 'support_status_closed';

  // Disputes / reports (reporter ↔ admin support chat)
  static const settingsMyReports = 'settings_my_reports';
  static const disputesTitle = 'disputes_title';
  static const disputesSubtitle = 'disputes_subtitle';
  static const disputesEmpty = 'disputes_empty';
  static const disputesEmptySub = 'disputes_empty_sub';
  static const disputeResolutionLabel = 'dispute_resolution_label';
  static const disputeCatFraud = 'dispute_cat_fraud';
  static const disputeCatAbuse = 'dispute_cat_abuse';
  static const disputeCatNoShow = 'dispute_cat_no_show';
  static const disputeCatPayment = 'dispute_cat_payment';
  static const disputeCatOther = 'dispute_cat_other';
  static const disputeStatusOpen = 'dispute_status_open';
  static const disputeStatusInvestigating = 'dispute_status_investigating';
  static const disputeStatusResolved = 'dispute_status_resolved';
  static const disputeStatusDismissed = 'dispute_status_dismissed';
  // Report a problem (file a dispute from chat / trial)
  static const reportProblemTitle = 'report_problem_title';
  static const reportProblemSub = 'report_problem_sub';
  static const reportProblemCategory = 'report_problem_category';
  static const reportProblemDescHint = 'report_problem_desc_hint';
  static const reportProblemSend = 'report_problem_send';
  static const reportSentToast = 'report_sent_toast';
  static const reportEmptyDesc = 'report_empty_desc';

  // Password Reset
  static const pwResetTitle = 'pw_reset_title';
  static const pwResetEnterPhone = 'pw_reset_enter_phone';
  static const pwResetSendOtp = 'pw_reset_send_otp';
  static const pwResetEnterOtp = 'pw_reset_enter_otp';
  static const pwResetOtpSent = 'pw_reset_otp_sent';
  static const pwResetNewPassword = 'pw_reset_new_password';
  static const pwResetConfirmPassword = 'pw_reset_confirm_password';
  static const pwResetSuccess = 'pw_reset_success';
  static const pwResetSuccessMessage = 'pw_reset_success_message';

  // Edit profile (Screen 27A)
  static const editProfile = 'edit_profile';
  static const editBio = 'edit_bio';
  static const editBioHint = 'edit_bio_hint';
  static const editLanguages = 'edit_languages';
  static const editEmergencyContact = 'edit_emergency_contact';
  static const editComfort = 'edit_comfort';
  static const profileUpdated = 'profile_updated';
  static const profileSaveFailed = 'profile_save_failed';
  static const saveAndClose = 'save_and_close';
  static const editProfileSection = 'edit_profile_section';
  static const editPersonalInfo = 'edit_personal_info';
  static const editMedia = 'edit_media';
  static const editExperience = 'edit_experience';
  static const editReferences = 'edit_references';
  static const editDocuments = 'edit_documents';
  static const save = 'save';
  static const done = 'done';
  static const locationPickerTitle = 'location_picker_title';
  static const locationPickerHint = 'location_picker_hint';
  static const locationSearchHint = 'location_search_hint';
  static const locationUseCurrentLocation = 'location_use_current_location';
  static const locationGPSSubtitle = 'location_gps_subtitle';
  static const locationSearchPrompt = 'location_search_prompt';
  static const locationSearchSubPrompt = 'location_search_sub_prompt';
  static const locationConfirm = 'location_confirm';
  static const locationServiceDisabled = 'location_service_disabled';
  static const locationPermissionDenied = 'location_permission_denied';
  static const locationManualHint = 'location_manual_hint';
  static const anyArea = 'any_area';

  // Permissions
  static const permissionGalleryDenied = 'permission_gallery_denied';
  static const permissionCameraDenied = 'permission_camera_denied';
  static const permissionNotificationDenied = 'permission_notification_denied';
  static const permissionPermanentlyDeniedTitle = 'permission_permanently_denied_title';
  static const permissionPermanentlyDeniedBody = 'permission_permanently_denied_body';
  static const permissionOpenSettings = 'permission_open_settings';
  static const renewToSendImages = 'renew_to_send_images';
  static const freeViewsRemaining = 'free_views_remaining';
  static const noFreeViewsLeft = 'no_free_views_left';

  // Error Handling
  static const subscriptionRequired = 'subscription_required';
  static const subscriptionExpiredMessage = 'subscription_expired_message';
  static const subscribeToAccess = 'subscribe_to_access';
  static const noInternet = 'no_internet';
  static const checkConnection = 'check_connection';
  static const sessionExpired = 'session_expired';
  static const pleaseSignInAgain = 'please_sign_in_again';

  // Validation — generic (System Spec §14.4)
  static const valRequired = 'val_required';
  static const valDobInvalid = 'val_dob_invalid';
  static const valAgeMin18 = 'val_age_min_18';
  static const valPhoneInvalid = 'val_phone_invalid';
  static const valSalaryOrder = 'val_salary_order';
  static const valSalaryTooHigh = 'val_salary_too_high';
  static const valExpDatesInvalid = 'val_exp_dates_invalid';

  // Auth errors & flow (System Spec §14.1) — live phone auth
  static const authPhoneInvalid = 'auth_phone_invalid';
  static const authOtpIncorrect = 'auth_otp_incorrect';
  static const authOtpSendFailed = 'auth_otp_send_failed';
  static const authSmsRegionDisabled = 'auth_sms_region_disabled';
  static const authOtpRateLimited = 'auth_otp_rate_limited';
  static const authOtpMaxAttempts = 'auth_otp_max_attempts';
  static const authNoAccount = 'auth_no_account';
  static const authAccountExists = 'auth_account_exists';
  static const authWrongRole = 'auth_wrong_role';
  static const authQuotaExceeded = 'auth_quota_exceeded';
  static const authWrongPassword = 'auth_wrong_password';
  static const authReauthRequired = 'auth_reauth_required';
  static const authCodeSent = 'auth_code_sent';
  static const authLearnMore = 'auth_learn_more';
  static const authUseOtpInstead = 'auth_use_otp_instead';
  static const authQuickSafeEasy = 'auth_quick_safe_easy';
  static const authDidntReceive = 'auth_didnt_receive';
  static const otpResendShort = 'otp_resend_short';
  static const otpResendIn = 'otp_resend_in';
  static const startupOfflineTitle = 'startup_offline_title';
  static const startupOfflineSub = 'startup_offline_sub';
  static const authAgreePrefix = 'auth_agree_prefix';
  static const authAgreeAnd = 'auth_agree_and';

  // Nanny onboarding — required-field messages (System Spec §3.2 / §14.4)
  static const nannyNationalityRequired = 'nanny_nationality_required';
  static const nannyVisaRequired = 'nanny_visa_required';
  static const nannyMaritalRequired = 'nanny_marital_required';
  static const nannyChildrenCountRequired = 'nanny_children_count_required';
  static const nannyEmergencyNameRequired = 'nanny_emergency_name_required';
  static const nannyEmergencyRelRequired = 'nanny_emergency_rel_required';
  static const nannyEmergencyPhoneRequired = 'nanny_emergency_phone_required';
  static const nannyBioRequired = 'nanny_bio_required';

  // Nanny onboarding — labels (were hardcoded)
  static const nannyComfortFaith = 'nanny_comfort_faith';
  static const nannyReligionPrivacyNote = 'nanny_religion_privacy_note';
  static const nannyReligiousPractices = 'nanny_religious_practices';

  // Family onboarding — required-field messages (System Spec §3.3 / §3.4 / §14.4)
  static const familyNationalityRequired = 'family_nationality_required';
  static const familyChildrenAgesRequired = 'family_children_ages_required';
  static const familyChildrenInvalid = 'family_children_invalid';
  static const familyLanguagesRequired = 'family_languages_required';
  static const familyRolesRequired = 'family_roles_required';
  static const familyScheduleRequired = 'family_schedule_required';
  static const familyDutiesRequired = 'family_duties_required';
  static const familyBenefitsRequired = 'family_benefits_required';
  static const familyTrialDaysRequired = 'family_trial_days_required';
  static const familyTrialRateRequired = 'family_trial_rate_required';

  // Nanny onboarding — work preferences (System Spec §3.2)
  static const nannySecWorkPrefs = 'nanny_sec_work_prefs';
  static const jobBoth = 'job_both';
  static const nannyAvailability = 'nanny_availability';
  static const nannyAvailableFrom = 'nanny_available_from';
  static const nannyAvailableFromDate = 'nanny_available_from_date';
  static const nannyAvailableFromRequired = 'nanny_available_from_required';

  // Location picker
  static const locationChange = 'location_change';
  static const locationDetecting = 'location_detecting';

  // Nanny media + docs (onboarding)
  static const nannyCurrentAreaRequired = 'nanny_current_area_required';
  static const nannyPhotosMin3 = 'nanny_photos_min3';
  static const nannyVideoRequired = 'nanny_video_required';
  static const nannyVideoTooLong = 'nanny_video_too_long';
  static const mediaCover = 'media_cover';
  static const mediaIntroVideo = 'media_intro_video';
  static const mediaVideoReady = 'media_video_ready';
  static const docUploading = 'doc_uploading';
  static const docUploadingHint = 'doc_uploading_hint';
  static const docUploadFailed = 'doc_upload_failed';
  static const docPickFailed = 'doc_pick_failed';
  static const docTooLarge = 'doc_too_large';

  // Family job — employment type + edit fields
  static const fldEmployment = 'fld_employment';
  static const employmentFullTime = 'employment_full_time';
  static const employmentPartTime = 'employment_part_time';
  static const familyJobTypeLimit = 'family_job_type_limit';
  static const fldSchedule = 'fld_schedule';
  static const fldAboutFamily = 'fld_about_family';
  static const fldHouseRules = 'fld_house_rules';

  // Account blocked (admin)
  static const accountBlocked = 'account_blocked';
  static const accountBlockedSub = 'account_blocked_sub';
  static const blockedTitle = 'blocked_title';
  static const blockedBody = 'blocked_body';
  static const blockedContact = 'blocked_contact';
  static const blockedLogout = 'blocked_logout';

  // Nanny media + docs screen labels (l10n sweep)
  static const mediaTitle = 'media_title';
  static const mediaSubtitle = 'media_subtitle';
  static const mediaPhotosHeader = 'media_photos_header';
  static const mediaVideoHeader = 'media_video_header';
  static const mediaTapAdd = 'media_tap_add';
  static const mediaPhotoRule = 'media_photo_rule';
  static const mediaChoosePhotoSource = 'media_choose_photo_source';
  static const mediaChooseVideoSource = 'media_choose_video_source';
  static const mediaTakePhoto = 'media_take_photo';
  static const mediaChooseGallery = 'media_choose_gallery';
  static const mediaRecordVideo = 'media_record_video';
  static const mediaPhotoViews = 'media_photo_views';
  static const mediaRecordTitle = 'media_record_title';
  static const mediaRecordSub = 'media_record_sub';
  static const docsScreenTitle = 'docs_screen_title';
  static const docsScreenSubtitle = 'docs_screen_subtitle';
  static const docsMandatoryHeader = 'docs_mandatory_header';
  static const docsOptionalHeader = 'docs_optional_header';
  static const docPassportSub = 'doc_passport_sub';
  static const docVisaSub = 'doc_visa_sub';
  static const docTrainingSub = 'doc_training_sub';
  static const docPoliceSub = 'doc_police_sub';
  static const docEidSub = 'doc_eid_sub';
  static const docEidHave = 'doc_eid_have';
  static const docEidNone = 'doc_eid_none';

  // Experience + references screen labels (l10n sweep)
  static const expAddJob = 'exp_add_job';
  static const expPreviousJob = 'exp_previous_job';
  static const refsSubtitle = 'refs_subtitle';
  static const refsHasYes = 'refs_has_yes';
  static const refsHasNo = 'refs_has_no';
  static const refsAboutThem = 'refs_about_them';
  static const refsSectionHeader = 'refs_section_header';
  static const refsHowWork = 'refs_how_work';
  static const refsAddAnother = 'refs_add_another';
  static const refsReferenceNum = 'refs_reference_num';
  static const refsCallable = 'refs_callable';
  static const refsShareNote = 'refs_share_note';
  static const refsNeedOne = 'refs_need_one';
}
