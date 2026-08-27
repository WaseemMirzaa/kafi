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

  // Rate-the-app prompt (replaces the retired peer review dialog)
  static const rateAppTitle = 'rate_app_title';
  static const rateAppSubtitle = 'rate_app_subtitle';
  static const rateAppCta = 'rate_app_cta';
  static const rateAppLater = 'rate_app_later';
  static const rateAppThanks = 'rate_app_thanks';

  // Contact reveal
  static const contactUnavailable = 'contact_unavailable';
  static const contactLaunchFailed = 'contact_launch_failed';
  static const contactLoadFailed = 'contact_load_failed';
  static const contactRevealing = 'contact_revealing';
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
  static const nannyCurrentEmirateLabel = 'nanny_current_emirate_label';
  static const nannyAnyEmirate = 'nanny_any_emirate';
  static const fldCurrentArea = 'fld_current_area';
  static const fldCity = 'fld_city';
  static const fldSelectEmirate = 'fld_select_emirate';
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
  static const expCountry = 'exp_country';
  static const expCity = 'exp_city';
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
  static const dashProfileQualityScore = 'dash_profile_quality_score';
  static const dashJobsForYou = 'dash_jobs_for_you';
  static const qcProfileComplete = 'qc_profile_complete';
  static const qcVerifiedBadge = 'qc_verified_badge';
  static const qcVideoUploaded = 'qc_video_uploaded';
  static const qcMultiplePhotos = 'qc_multiple_photos';
  static const qcPoliceClearance = 'qc_police_clearance';
  static const qcTrainingCert = 'qc_training_cert';
  static const qcRecentlyActive = 'qc_recently_active';
  static const qcReferences = 'qc_references';
  static const qcWorkExperience = 'qc_work_experience';
  static const qcPtsBonus = 'qc_pts_bonus';
  static const qcStillNeeded = 'qc_still_needed';
  static const qcAllComplete = 'qc_all_complete';
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
  static const nannyJobAlreadyApplied = 'nanny_job_already_applied';
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
  static const trialOfferRateHint = 'trial_offer_rate_hint';
  static const trialOfferInfoBanner = 'trial_offer_info_banner';
  static const trialOfferStart = 'trial_offer_start';
  static const trialOfferType = 'trial_offer_type';
  static const trialOfferNotes = 'trial_offer_notes';
  static const trialOfferDisclaimer = 'trial_offer_disclaimer';
  static const trialOfferSend = 'trial_offer_send';
  static const trialOfferAckLabel = 'trial_offer_ack_label';
  static const trialAlreadyActive = 'trial_already_active';
  static const trialActiveNoApply = 'trial_active_no_apply';
  static const applyAlreadyApplied = 'apply_already_applied';
  static const applyJobUnavailable = 'apply_job_unavailable';

  // Family "Applicants" view (Spec §6.x — family receives applications)
  static const familyApplicants = 'family_applicants';
  static const familyApplicantsSub = 'family_applicants_sub';
  static const familyApplicantsEmpty = 'family_applicants_empty';
  static const applicantsAllJobs = 'applicants_all_jobs';
  static const applicantsUntitledJob = 'applicants_untitled_job';
  static const applicantsNoMatch = 'applicants_no_match';
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
  static const subGraceTitle = 'sub_grace_title';
  static const subGraceBody = 'sub_grace_body';
  static const familyNameRequired = 'family_name_required';
  static const familyCityRequired = 'family_city_required';
  static const familyEditTitle = 'family_edit_title';
  static const familyEditSubtitle = 'family_edit_subtitle';
  static const familyEditSave = 'family_edit_save';
  static const contactsHiddenBanner = 'contacts_hidden_banner';
  static const trialOfferSubRequired = 'trial_offer_sub_required';
  static const trialOfferAckRequired = 'trial_offer_ack_required';
  static const trialOfferRateRequired = 'trial_offer_rate_required';
  static const trialOfferRateTooLow = 'trial_offer_rate_too_low';
  static const trialOfferRateTooHigh = 'trial_offer_rate_too_high';
  static const trialOfferDurationRequired = 'trial_offer_duration_required';
  static const trialOfferStartRequired = 'trial_offer_start_required';
  static const trialOfferStartPast = 'trial_offer_start_past';
  static const trialOfferLocationRequired = 'trial_offer_location_required';
  static const trialOfferTypeRequired = 'trial_offer_type_required';
  static const trialOfferNotesTooLong = 'trial_offer_notes_too_long';
  static const trialOfferNannyUnverified = 'trial_offer_nanny_unverified';
  static const trialOfferNannyOnTrial = 'trial_offer_nanny_on_trial';
  static const trialOfferFamilyActive = 'trial_offer_family_active';
  static const trialOfferBubbleSent = 'trial_offer_bubble_sent';
  static const trialOfferSentSuccess = 'trial_offer_sent_success';
  static const trialOfferBubbleReceived = 'trial_offer_bubble_received';
  static const trialOfferBubbleDuration = 'trial_offer_bubble_duration';
  static const trialOfferBubbleRate = 'trial_offer_bubble_rate';
  static const trialOfferBubbleTotal = 'trial_offer_bubble_total';
  static const trialOfferBubbleTypeLiveIn = 'trial_offer_bubble_type_live_in';
  static const trialOfferBubbleTypeLiveOut = 'trial_offer_bubble_type_live_out';
  static const trialOfferBubbleStartFrom = 'trial_offer_bubble_start_from';
  static const trialOfferBubbleLocationOnly = 'trial_offer_bubble_location_only';
  static const trialOfferBubbleNotes = 'trial_offer_bubble_notes';
  static const trialOfferBubbleLocation = 'trial_offer_bubble_location';
  static const trialOfferBubbleLocationStartOnly = 'trial_offer_bubble_location_start_only';
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

  // Family form — hardcoded chrome (labels, hints, prompts). Data values
  // (religion names, pet types) stay untranslated like the other constant chips.
  static const familyNameHint = 'family_name_hint';
  static const familyYourNationality = 'family_your_nationality';
  static const familyChildrenAgesHint = 'family_children_ages_hint';
  static const familyHomeCameras = 'family_home_cameras';
  static const familyHasCameras = 'family_has_cameras';
  static const familyNoCameras = 'family_no_cameras';
  static const familyPets = 'family_pets';
  static const familyAboutPrompt = 'family_about_prompt';
  static const familyAboutLabel = 'family_about_label';
  static const familyAboutHint = 'family_about_hint';
  static const familyReligionBanner = 'family_religion_banner';
  static const familyReligionLabel = 'family_religion_label';
  static const familyReligionPrefPrompt = 'family_religion_pref_prompt';
  static const familyReligionPrefNone = 'family_religion_pref_none';
  static const familyReligionPrefMuslim = 'family_religion_pref_muslim';
  static const familyReligionPrefSame = 'family_religion_pref_same';
  static const familyReligionPrefOpen = 'family_religion_pref_open';
  static const familyHouseRulesLabel = 'family_house_rules_label';
  static const familyHouseRulesHint = 'family_house_rules_hint';
  static const familyScheduleHint = 'family_schedule_hint';
  static const familySchedulePickDays = 'family_schedule_pick_days';
  static const familyScheduleSheetTitle = 'family_schedule_sheet_title';
  static const familyScheduleSheetSub = 'family_schedule_sheet_sub';
  static const familyScheduleDone = 'family_schedule_done';
  static const familyBothJobSlotsFilled = 'family_both_job_slots_filled';
  static const familyEmploymentLockedHint = 'family_employment_locked_hint';
  static const browseFilterByJob = 'browse_filter_by_job';
  static const browseFilterByJobSub = 'browse_filter_by_job_sub';
  static const browseNoJobsYet = 'browse_no_jobs_yet';
  static const browseAllMatches = 'browse_all_matches';
  static const shortlistAdded = 'shortlist_added';
  static const shortlistRemoved = 'shortlist_removed';
  static const shortlistAlreadyAdded = 'shortlist_already_added';
  static const shortlistNeedFamily = 'shortlist_need_family';
  static const shortlistSaveFailed = 'shortlist_save_failed';
  static const fldLocation = 'fld_location';
  static const familyTrialDaysN = 'family_trial_days_n';

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
  static const videoIntroTitle = 'video_intro_title';
  static const videoLoading = 'video_loading';
  static const videoUnavailable = 'video_unavailable';
  static const videoLoadFailed = 'video_load_failed';
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
  // Smart-match contextual checklist (pass/fail rows with live job data).
  static const smartLangFallback = 'smart_lang_fallback';
  static const smartLangPass = 'smart_lang_pass';
  static const smartLangFail = 'smart_lang_fail';
  static const smartExpYears = 'smart_exp_years';
  static const smartExpFallback = 'smart_exp_fallback';
  static const smartExpPass = 'smart_exp_pass';
  static const smartExpFail = 'smart_exp_fail';
  static const smartRoleLiveOut = 'smart_role_live_out';
  static const smartRoleLiveIn = 'smart_role_live_in';
  static const smartRoleMatches = 'smart_role_matches';
  static const smartRoleNoMatch = 'smart_role_no_match';
  static const smartRoleLine = 'smart_role_line';
  static const smartVisaPass = 'smart_visa_pass';
  static const smartVisaFail = 'smart_visa_fail';
  static const smartSalaryPass = 'smart_salary_pass';
  static const smartSalaryFail = 'smart_salary_fail';
  static const smartJobSummary = 'smart_job_summary';
  static const browseNoMatch = 'browse_no_match';

  // Trial
  static const trialActive = 'trial_active';
  static const trialRemaining = 'trial_remaining';
  static const trialEval = 'trial_eval';
  static const trialHire = 'trial_hire';
  static const trialNotThisTime = 'trial_not_this_time';

  // Trial screen — active-trial detail (header, eval, empty, payment, dialogs)
  static const trialFamilyGeneric = 'trial_family_generic';
  static const trialYourFamily = 'trial_your_family';
  static const trialSummaryLine = 'trial_summary_line';
  static const trialPartyFamilyRole = 'trial_party_family_role';
  static const trialUaeFallback = 'trial_uae_fallback';
  static const trialPartyNannyRole = 'trial_party_nanny_role';
  static const trialRevealed = 'trial_revealed';
  static const trialEvalChildInteraction = 'trial_eval_child_interaction';
  static const trialEvalPunctuality = 'trial_eval_punctuality';
  static const trialEvalInstructions = 'trial_eval_instructions';
  static const trialEvalCommunication = 'trial_eval_communication';
  static const trialEvalCooking = 'trial_eval_cooking';
  static const trialEvalHonesty = 'trial_eval_honesty';
  static const trialCancelAction = 'trial_cancel_action';
  static const trialEmptyTitle = 'trial_empty_title';
  static const trialEmptySub = 'trial_empty_sub';
  static const trialBrowseNannies = 'trial_browse_nannies';
  static const trialPaymentConfirmed = 'trial_payment_confirmed';
  static const trialIssueReportedBanner = 'trial_issue_reported_banner';
  static const trialReportIssue = 'trial_report_issue';
  static const trialConfirmPayment = 'trial_confirm_payment';
  static const trialCancelConfirmTitle = 'trial_cancel_confirm_title';
  static const trialCancelConfirmBody = 'trial_cancel_confirm_body';
  static const trialCancelReasonHint = 'trial_cancel_reason_hint';
  static const trialKeep = 'trial_keep';
  static const trialReportIssueTitle = 'trial_report_issue_title';
  static const trialReportIssueHint = 'trial_report_issue_hint';
  static const trialSendReport = 'trial_send_report';

  // Trial outcome — mutual hire confirmation (awaitingOutcome)
  static const trialAwaitingResponseLabel = 'trial_awaiting_response_label';
  static const trialOutcomePromptFamily = 'trial_outcome_prompt_family';
  static const trialFamilyHireAction = 'trial_family_hire_action';
  static const trialKeepSearchingAction = 'trial_keep_searching_action';
  static const trialFamilyWaitingSnackbar = 'trial_family_waiting_snackbar';
  static const trialWaitingForNannyBanner = 'trial_waiting_for_nanny_banner';
  static const trialReasonSkip = 'trial_reason_skip';
  static const notHiredReasonNotRightMatch = 'not_hired_reason_not_right_match';
  static const notHiredReasonSalary = 'not_hired_reason_salary';
  static const notHiredReasonSchedule = 'not_hired_reason_schedule';
  static const notHiredReasonLocation = 'not_hired_reason_location';
  static const notHiredReasonNannyDeclined = 'not_hired_reason_nanny_declined';
  static const notHiredReasonFoundSomeoneElse = 'not_hired_reason_found_someone_else';
  static const notHiredReasonOther = 'not_hired_reason_other';
  static const trialOutcomePromptNanny = 'trial_outcome_prompt_nanny';
  static const trialNannyGotJobAction = 'trial_nanny_got_job_action';
  static const trialNannyStillLookingAction = 'trial_nanny_still_looking_action';
  static const trialNannyWaitingBanner = 'trial_nanny_waiting_banner';

  // Hire reactivation — nanny makes her profile available again
  static const reactivationCardTitle = 'reactivation_card_title';
  static const reactivationCardCta = 'reactivation_card_cta';
  static const reactivationReasonJobDidntWorkOut = 'reactivation_reason_job_didnt_work_out';
  static const reactivationReasonFamilyEnded = 'reactivation_reason_family_ended';
  static const reactivationReasonIDecidedToLeave = 'reactivation_reason_i_decided_to_leave';
  static const reactivationReasonTemporaryEnded = 'reactivation_reason_temporary_ended';
  static const reactivationReasonOther = 'reactivation_reason_other';
  static const reactivationReasonPreferNotToSay = 'reactivation_reason_prefer_not_to_say';

  // Pricing
  static const pricingTitle = 'pricing_title';
  static const pricingFreeBanner = 'pricing_free_banner';
  static const pricingFreeUsed = 'pricing_free_used';
  static const pricingVatNote = 'pricing_vat_note';
  static const pricingChoose = 'pricing_choose';
  static const pricingPopular = 'pricing_popular';
  static const pricingUpgradeTitle = 'pricing_upgrade_title';
  static const pricingUpgradePlan = 'pricing_upgrade_plan';
  static const pricingHeroSub = 'pricing_hero_sub';
  static const pricingFeatContacts = 'pricing_feat_contacts';
  static const pricingFeatVideos = 'pricing_feat_videos';
  static const pricingFeatCvs = 'pricing_feat_cvs';
  static const pricingFeatSmartMatch = 'pricing_feat_smart_match';
  static const pricingFeatTrials = 'pricing_feat_trials';
  static const pricingFeatChat = 'pricing_feat_chat';
  static const pricingFeatCallWa = 'pricing_feat_call_wa';
  static const pricingFeatPosts = 'pricing_feat_posts';
  static const pricingAllInclude = 'pricing_all_include';
  static const pricingOnlyDiff = 'pricing_only_diff';
  static const pricingDescMonthly = 'pricing_desc_monthly';
  static const pricingDescWeekly = 'pricing_desc_weekly';
  static const pricingJobHighlighted = 'pricing_job_highlighted';
  static const pricingCurrentPlan = 'pricing_current_plan';
  static const pricingTrustUae = 'pricing_trust_uae';
  static const pricingTrust5Star = 'pricing_trust_5star';
  static const pricingDaysAccess = 'pricing_days_access';
  static const pricingDescValue = 'pricing_desc_value';
  static const pricingValidDays = 'pricing_valid_days';
  static const pricingVatLine = 'pricing_vat_line';
  static const pricingSelectPlan = 'pricing_select_plan';
  static const pricingPeriodMonth = 'pricing_period_month';
  static const pricingPeriodWeek = 'pricing_period_week';
  static const pricingPeriod2Months = 'pricing_period_2months';
  static const subscriptionActiveMsg = 'subscription_active_msg';

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
  static const jobPostedToast = 'job_posted_toast';
  static const jobEditTitle = 'job_edit_title';
  static const jobEditFullDetails = 'job_edit_full_details';
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
  static const reportUnavailable = 'report_unavailable';
  static const reportAttachLabel = 'report_attach_label';
  static const reportAttachHint = 'report_attach_hint';
  static const reportAttachGallery = 'report_attach_gallery';
  static const reportAttachCamera = 'report_attach_camera';
  static const reportAttachFile = 'report_attach_file';
  static const reportAttachMax = 'report_attach_max';
  static const reportAttachTooLarge = 'report_attach_too_large';
  static const reportAttachType = 'report_attach_type';
  static const reportAttachPickFailed = 'report_attach_pick_failed';
  static const reportAttachCount = 'report_attach_count';
  static const reportAttachmentsTitle = 'report_attachments_title';
  static const reportOpenPdf = 'report_open_pdf';

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
  static const renewToSendMessages = 'renew_to_send_messages';
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
  static const authKeychainError = 'auth_keychain_error';
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
  static const familyRoleOtherRequired = 'family_role_other_required';
  static const familyScheduleRequired = 'family_schedule_required';
  static const familyDaysOffRequired = 'family_days_off_required';
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

  // Nanny onboarding — employment type + part-time availability
  static const nannySecEmployment = 'nanny_sec_employment';
  static const nannyEmploymentQuestion = 'nanny_employment_question';
  static const nannyEmpFullLiveIn = 'nanny_emp_full_live_in';
  static const nannyEmpFullLiveOut = 'nanny_emp_full_live_out';
  static const nannyEmpPartTime = 'nanny_emp_part_time';
  static const nannyEmploymentTypeRequired = 'nanny_employment_type_required';
  static const nannyPartTimeQuestion = 'nanny_part_time_question';
  static const nannyPartTimeFrom = 'nanny_part_time_from';
  static const nannyPartTimeUntil = 'nanny_part_time_until';
  static const nannyPartTimeAvailabilityRequired = 'nanny_part_time_availability_required';
  static const dayMon = 'day_mon';
  static const dayTue = 'day_tue';
  static const dayWed = 'day_wed';
  static const dayThu = 'day_thu';
  static const dayFri = 'day_fri';
  static const daySat = 'day_sat';
  static const daySun = 'day_sun';

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
  static const fldRolePrompt = 'fld_role_prompt';
  static const fldRoleOther = 'fld_role_other';
  static const fldDaysOff = 'fld_days_off';
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

  // Nanny info screen — l10n sweep
  static const dateFormatHint = 'date_format_hint';
  static const nannyFullNameHint = 'nanny_full_name_hint';
  static const nannyVisaInfoBanner = 'nanny_visa_info_banner';
  static const visaVisitSub = 'visa_visit_sub';
  static const visaSponsoredSub = 'visa_sponsored_sub';
  static const visaOwnSub = 'visa_own_sub';
  static const visaCancelledSub = 'visa_cancelled_sub';
  static const visaOutsideSub = 'visa_outside_sub';
  static const nannyEidCardTitle = 'nanny_eid_card_title';
  static const nannyEidCardDesc = 'nanny_eid_card_desc';
  static const nannyEidYes = 'nanny_eid_yes';
  static const nannyEidNo = 'nanny_eid_no';
  static const nannyTransferYes = 'nanny_transfer_yes';
  static const nannyTransferNo = 'nanny_transfer_no';
  static const nannyTransferDepends = 'nanny_transfer_depends';
  static const nannyWorkLocBanner = 'nanny_work_loc_banner';
  static const emirateDubaiSub = 'emirate_dubai_sub';
  static const emirateAbuDhabiSub = 'emirate_abu_dhabi_sub';
  static const emirateSharjahSub = 'emirate_sharjah_sub';
  static const emirateAjmanSub = 'emirate_ajman_sub';
  static const emirateRakSub = 'emirate_rak_sub';
  static const emirateFujairahSub = 'emirate_fujairah_sub';
  static const emirateUaqSub = 'emirate_uaq_sub';
  static const emirateAlAinSub = 'emirate_al_ain_sub';
  static const nannyRelocateYes = 'nanny_relocate_yes';
  static const nannyRelocateNo = 'nanny_relocate_no';
  static const maritalMarried = 'marital_married';
  static const maritalSingle = 'marital_single';
  static const maritalDivorced = 'marital_divorced';
  static const maritalWidowed = 'marital_widowed';
  static const nannyHasChildrenYes = 'nanny_has_children_yes';
  static const nannyHasChildrenNo = 'nanny_has_children_no';
  static const nannyHealthBanner = 'nanny_health_banner';
  static const healthYesDescribe = 'health_yes_describe';
  static const fldHealthNo = 'fld_health_no';
  static const fldMedsNo = 'fld_meds_no';
  static const fldAllergiesNo = 'fld_allergies_no';
  static const healthDescribeLabel = 'health_describe_label';
  static const healthDescribeHint = 'health_describe_hint';
  static const nannyComfortBanner = 'nanny_comfort_banner';
  static const comfortCamerasYes = 'comfort_cameras_yes';
  static const comfortCamerasNo = 'comfort_cameras_no';
  static const comfortPetsYes = 'comfort_pets_yes';
  static const comfortPetsNo = 'comfort_pets_no';
  static const comfortCooksYes = 'comfort_cooks_yes';
  static const comfortCooksNo = 'comfort_cooks_no';
  static const comfortNightYes = 'comfort_night_yes';
  static const comfortNightNo = 'comfort_night_no';
  static const religionMuslim = 'religion_muslim';
  static const religionChristian = 'religion_christian';
  static const religionHindu = 'religion_hindu';
  static const religionBuddhist = 'religion_buddhist';
  static const religionJewish = 'religion_jewish';
  static const religionOther = 'religion_other';
  static const nannyFaithYes = 'nanny_faith_yes';
  static const nannyFaithNo = 'nanny_faith_no';
  static const nannyReligiousPracticesHint = 'nanny_religious_practices_hint';
  static const emergencyRelSpouse = 'emergency_rel_spouse';
  static const emergencyRelParent = 'emergency_rel_parent';
  static const emergencyRelSibling = 'emergency_rel_sibling';
  static const emergencyRelChild = 'emergency_rel_child';
  static const emergencyRelFriend = 'emergency_rel_friend';
  static const emergencyRelOther = 'emergency_rel_other';
  static const fldBioHint = 'fld_bio_hint';

  // Nanny media screen — l10n sweep
  static const mediaRuleMaxDuration = 'media_rule_max_duration';
  static const mediaRuleLighting = 'media_rule_lighting';
  static const mediaRuleNoPhone = 'media_rule_no_phone';
  static const mediaWhatToSay = 'media_what_to_say';
  static const mediaSayName = 'media_say_name';
  static const mediaSayChildren = 'media_say_children';
  static const mediaSayLove = 'media_say_love';

  // Nanny experience screen — l10n sweep
  static const expEmployerHint = 'exp_employer_hint';
  static const expChildrenHint = 'exp_children_hint';
  static const expDutiesHint = 'exp_duties_hint';
  static const monthJan = 'month_jan';
  static const monthFeb = 'month_feb';
  static const monthMar = 'month_mar';
  static const monthApr = 'month_apr';
  static const monthMay = 'month_may';
  static const monthJun = 'month_jun';
  static const monthJul = 'month_jul';
  static const monthAug = 'month_aug';
  static const monthSep = 'month_sep';
  static const monthOct = 'month_oct';
  static const monthNov = 'month_nov';
  static const monthDec = 'month_dec';

  // Nanny references screen — l10n sweep
  static const refsStep1 = 'refs_step1';
  static const refsStep2 = 'refs_step2';
  static const refsStep3 = 'refs_step3';
  static const refsStep4 = 'refs_step4';
  static const refsYearsHint = 'refs_years_hint';
  static const refsCanConfirmHint = 'refs_can_confirm_hint';

  // Nanny docs screen — l10n sweep
  static const docConditional = 'doc_conditional';

  // Nanny edit profile screen — language chip labels
  static const languageEnglish = 'language_english';
  static const languageArabic = 'language_arabic';
  static const languageFrench = 'language_french';
  static const languageHindi = 'language_hindi';
  static const languageTagalog = 'language_tagalog';
  static const languageAmharic = 'language_amharic';

  // --- i18n sweep jobs/apps ---
  // Shared
  static const nannySuffix = 'nanny_suffix';
  static const jobSalaryRange = 'job_salary_range';
  static const timeDaysAgo = 'time_days_ago';
  static const timeHoursAgo = 'time_hours_ago';
  static const timeMinutesAgo = 'time_minutes_ago';

  // Jobs home — filters
  static const jobsFilterAll = 'jobs_filter_all';
  static const jobsFilterNewborn = 'jobs_filter_newborn';

  // Job detail screen
  static const jobDetailFamilySuffix = 'job_detail_family_suffix';
  static const jobDetailSectionTitle = 'job_detail_section_title';
  static const jobDetailFieldJobType = 'job_detail_field_job_type';
  static const jobDetailFieldSchedule = 'job_detail_field_schedule';
  static const jobDetailNotSpecified = 'job_detail_not_specified';
  static const jobDetailFieldStartDate = 'job_detail_field_start_date';
  static const jobDetailImmediate = 'job_detail_immediate';
  static const jobDetailFlexible = 'job_detail_flexible';
  static const jobDetailFieldDuration = 'job_detail_field_duration';
  static const jobDetailPermanent = 'job_detail_permanent';
  static const jobDetailContractMonths = 'job_detail_contract_months';
  static const jobDetailContract = 'job_detail_contract';
  static const jobDetailFieldSalary = 'job_detail_field_salary';
  static const jobDetailSalaryRange = 'job_detail_salary_range';
  static const jobDetailRequirementsTitle = 'job_detail_requirements_title';
  static const jobDetailFieldLanguages = 'job_detail_field_languages';
  static const jobDetailBenefitsTitle = 'job_detail_benefits_title';
  static const jobDetailVisaSponsoredTitle = 'job_detail_visa_sponsored_title';
  static const jobDetailVisaOwnTitle = 'job_detail_visa_own_title';
  static const jobDetailVisaSponsoredSub = 'job_detail_visa_sponsored_sub';
  static const jobDetailVisaOwnSub = 'job_detail_visa_own_sub';

  // Nanny-side application status labels (badges + timeline + date rows).
  // Distinct from the family-facing appStatus* keys ("New"/"Trial offered")
  // which use applicant-list framing, not the nanny's own-application framing.
  static const nannyAppStatusPending = 'nanny_app_status_pending';
  static const nannyAppStatusViewed = 'nanny_app_status_viewed';
  static const nannyAppStatusShortlisted = 'nanny_app_status_shortlisted';
  static const nannyAppStatusTrialOffered = 'nanny_app_status_trial_offered';
  static const nannyAppStatusDeclined = 'nanny_app_status_declined';
  static const nannyAppStatusWithdrawn = 'nanny_app_status_withdrawn';
  static const nannyAppStatusHired = 'nanny_app_status_hired';

  // Application detail screen (extra, beyond existing appDetail* keys)
  static const appDetailPendingTitle = 'app_detail_pending_title';
  static const appDetailViewedTitle = 'app_detail_viewed_title';
  static const appDetailWithdrawTitle = 'app_detail_withdraw_title';
  static const appDetailTimelineTitle = 'app_detail_timeline_title';
  static const appDetailStepResponded = 'app_detail_step_responded';
  static const appDetailStepHired = 'app_detail_step_hired';
  static const appDetailLabelHired = 'app_detail_label_hired';
  static const appDetailNoTrialTitle = 'app_detail_no_trial_title';
  static const appDetailNoTrialBody = 'app_detail_no_trial_body';
  static const appDetailViewInMessages = 'app_detail_view_in_messages';
  static const appDetailTrialOfferDetails = 'app_detail_trial_offer_details';
  static const appDetailAcceptOfferLabel = 'app_detail_accept_offer_label';
  static const appDetailDeclineOfferLabel = 'app_detail_decline_offer_label';
  static const appDetailOriginalOffer = 'app_detail_original_offer';

  // --- i18n sweep family/shared ---
  static const browseMatchesFor = 'browse_matches_for';
  static const callHerBtn = 'call_her_btn';
  static const chatActionLabel = 'chat_action_label';
  static const chatImagePreview = 'chat_image_preview';
  static const compareCity = 'compare_city';
  static const compareExp = 'compare_exp';
  static const compareMatch = 'compare_match';
  static const compareType = 'compare_type';
  static const compareVs = 'compare_vs';
  static const contactCallOrWhatsapp = 'contact_call_or_whatsapp';
  static const contactDirectNumber = 'contact_direct_number';
  static const contactFullyUnlocked = 'contact_fully_unlocked';
  static const contactWhatsappLabel = 'contact_whatsapp_label';
  static const dashPlaceholder = 'dash_placeholder';
  static const deleteReasonAppIssues = 'delete_reason_app_issues';
  static const deleteReasonFoundNannyJob = 'delete_reason_found_nanny_job';
  static const deleteReasonNotSatisfied = 'delete_reason_not_satisfied';
  static const deleteReasonOther = 'delete_reason_other';
  static const deleteReasonPrivacy = 'delete_reason_privacy';
  static const deleteReasonTooExpensive = 'delete_reason_too_expensive';
  static const detailsLabel = 'details_label';
  static const docUploadBtn = 'doc_upload_btn';
  static const filterAll = 'filter_all';
  static const filterArabic = 'filter_arabic';
  static const filterFilipino = 'filter_filipino';
  static const filterIndian = 'filter_indian';
  static const legalPrivacy1 = 'legal_privacy_1';
  static const legalPrivacy2 = 'legal_privacy_2';
  static const legalPrivacy3 = 'legal_privacy_3';
  static const legalPrivacy4 = 'legal_privacy_4';
  static const legalPrivacy5 = 'legal_privacy_5';
  static const legalPrivacy6 = 'legal_privacy_6';
  static const legalPrivacy7 = 'legal_privacy_7';
  static const legalPrivacy8 = 'legal_privacy_8';
  static const legalTerms1 = 'legal_terms_1';
  static const legalTerms2 = 'legal_terms_2';
  static const legalTerms3 = 'legal_terms_3';
  static const legalTerms4 = 'legal_terms_4';
  static const legalTerms5 = 'legal_terms_5';
  static const legalTerms6 = 'legal_terms_6';
  static const legalTerms7 = 'legal_terms_7';
  static const legalTerms8 = 'legal_terms_8';
  static const lockedFullCv = 'locked_full_cv';
  static const lockedIntroVideo = 'locked_intro_video';
  static const lockedPhoneNumber = 'locked_phone_number';
  static const matchWithJobN = 'match_with_job_n';
  static const profileLockedSubtitle = 'profile_locked_subtitle';
  static const qualityExcellent = 'quality_excellent';
  static const qualityFair = 'quality_fair';
  static const qualityGood = 'quality_good';
  static const qualityNeedsWork = 'quality_needs_work';
  static const qualityProfileStrength = 'quality_profile_strength';
  static const qualityTipPhoto = 'quality_tip_photo';
  static const qualityTipReferences = 'quality_tip_references';
  static const qualityTipVideo = 'quality_tip_video';
  static const relockedSubtext = 'relocked_subtext';
  static const roleFallbackFamily = 'role_fallback_family';
  static const roleFallbackNanny = 'role_fallback_nanny';
  static const roleFallbackUser = 'role_fallback_user';
  static const shortlistSavedN = 'shortlist_saved_n';
  static const timeAm = 'time_am';
  static const timePm = 'time_pm';
  static const timeYesterday = 'time_yesterday';
  static const trialActiveDaysN = 'trial_active_days_n';
  static const trialActiveFullAccess = 'trial_active_full_access';
  static const trialActiveFullAccessSub = 'trial_active_full_access_sub';
  static const trialCancelledToast = 'trial_cancelled_toast';
  static const trialCountdown = 'trial_countdown';
  static const trialIssueReportedToast = 'trial_issue_reported_toast';
  static const trialOfferRateUnit = 'trial_offer_rate_unit';
  static const trialOfferSentPreview = 'trial_offer_sent_preview';
  static const trialPaymentConfirmedToast = 'trial_payment_confirmed_toast';
  static const unlockProfileSubtitle = 'unlock_profile_subtitle';
  static const unlockProfileTitle = 'unlock_profile_title';
  static const verifiedIdBadge = 'verified_id_badge';
  static const watchLabel = 'watch_label';
  static const whatsappHerBtn = 'whatsapp_her_btn';
  static const yearsAbbrevN = 'years_abbrev_n';

  // --- Profile detail screen redesign (kafi-nanny-profile-detail-redesign) ---
  static const profileIdVerified = 'profile_id_verified';
  static const profileReferencesVerified = 'profile_references_verified';
  static const profileKafiInterviewed = 'profile_kafi_interviewed';
  static const profilePaidTrialAvailable = 'profile_paid_trial_available';
  static const profilePhotosVideos = 'profile_photos_videos';
  static const profilePhotoCountBadge = 'profile_photo_count_badge';
  static const profileExperiencePreferences = 'profile_experience_preferences';
  static const profileHandledChildren = 'profile_handled_children';
  static const profileCamerasLabel = 'profile_cameras_label';
  static const profileCamerasAccepts = 'profile_cameras_accepts';
  static const profileCamerasDeclines = 'profile_cameras_declines';
  static const profilePetsLabel = 'profile_pets_label';
  static const profilePetsAccepts = 'profile_pets_accepts';
  static const profilePetsDeclines = 'profile_pets_declines';
  static const profileHealthIssuesLabel = 'profile_health_issues_label';
  static const profileHealthIssuesNone = 'profile_health_issues_none';
  static const profileHealthIssuesPresent = 'profile_health_issues_present';
  static const profileWillingToWorkIn = 'profile_willing_to_work_in';
  static const profileSalaryExpectation = 'profile_salary_expectation';
  static const profilePerMonth = 'profile_per_month';
  static const profileAboutMe = 'profile_about_me';
  static const profileBookTrial = 'profile_book_trial';
  static const profileGalleryCounter = 'profile_gallery_counter';
  static const profileAgeYrs = 'profile_age_yrs';
  static const profileKafiMatch = 'profile_kafi_match';
  static const profileCallLabel = 'profile_call_label';
  static const profileAvailableNowChip = 'profile_available_now_chip';
  static const profileUaeExperience = 'profile_uae_experience';
  static const profileYearsFull = 'profile_years_full';
  static const profileYearsUaeExperience = 'profile_years_uae_experience';
  static const profileReviews = 'profile_reviews';
  static const profileRoleNannyBabysitter = 'profile_role_nanny_babysitter';
  static const profileHireProceed = 'profile_hire_proceed';
  static const countryUae = 'country_uae';
  static const petDog = 'pet_dog';
  static const petCat = 'pet_cat';
  static const aedAmount = 'aed_amount';
  static const aedPerDay = 'aed_per_day';
  static const currencyAedPrefix = 'currency_aed_prefix';
  static const perDaySuffix = 'per_day_suffix';
  static const deleteConfirmWord = 'delete_confirm_word';

  // --- i18n error messages ---
  static const errAuthOtpIncorrectAttempts = 'err_auth_otp_incorrect_attempts';
  static const errAuthAccountSuspended = 'err_auth_account_suspended';
  static const errAuthSessionExpiredMessage = 'err_auth_session_expired_message';
  static const errAuthWeakPasswordMessage = 'err_auth_weak_password_message';
  static const errPermissionDenied = 'err_permission_denied';
  static const errUploadFileTooLarge = 'err_upload_file_too_large';
  static const errUploadInvalidFormat = 'err_upload_invalid_format';
  static const errUploadNetworkFailure = 'err_upload_network_failure';
  static const errUploadQuotaExceeded = 'err_upload_quota_exceeded';
  static const errTrialOfferExpiredMessage = 'err_trial_offer_expired_message';
  static const errSubPaymentDeclined = 'err_sub_payment_declined';
  static const errSubRestoreFailed = 'err_sub_restore_failed';
  static const errNetNoConnectionMessage = 'err_net_no_connection_message';
  static const errNetTimeoutMessage = 'err_net_timeout_message';
  static const errNetServerDownMessage = 'err_net_server_down_message';
  static const errValRequiredField = 'err_val_required_field';
  static const errValLengthField = 'err_val_length_field';
  static const errRateLimitMessage = 'err_rate_limit_message';
  static const errUnknownSomethingWrong = 'err_unknown_something_wrong';
  static const errUnknownAuthError = 'err_unknown_auth_error';
  static const errUnknownServiceError = 'err_unknown_service_error';
  static const trialCounterOfferLabel = 'trial_counter_offer_label';
}
