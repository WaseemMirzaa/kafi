import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/geo_location.dart';
import 'package:kafi_app/models/hire_model.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/models/trial_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:kafi_app/utils/validators.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class NannyProfileController extends GetxController {
  static const Set<String> _onboardingRoutes = {
    Routes.nannyInfo,
    Routes.nannyMedia,
    Routes.nannyExp,
    Routes.nannyRefs,
    Routes.nannyDocs,
    Routes.nannyPending,
  };

  final IUserService _userService = Get.find<IUserService>();
  final IStorageService _storageService = Get.find<IStorageService>();
  final IHireService _hireService = Get.find<IHireService>();
  final ITrialService _trialService = Get.find<ITrialService>();
  final AuthController _auth = Get.find<AuthController>();
  final _uuid = const Uuid();

  final Rx<NannyModel?> nanny = Rx<NannyModel?>(null);
  final RxInt currentStep = 1.obs;
  final RxBool isLoading = false.obs;

  /// The nanny's current employment status, surfaced as a card on her home:
  /// an active hire wins; otherwise an active/accepted trial (she's on trial).
  final Rx<HireModel?> activeHire = Rx<HireModel?>(null);
  final Rx<TrialModel?> activeTrial = Rx<TrialModel?>(null);

  // step 1
  final fullNameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final ageCtrl = TextEditingController(); // read-only, auto-filled from dob
  final Rx<DateTime?> dob = Rx<DateTime?>(null);
  final RxString nationality = 'Filipino'.obs;
  // Required selections start unset so a new nanny must actively choose them
  // (previously pre-seeded with demo values that were saved verbatim).
  final RxList<String> selectedLanguages = <String>[].obs;
  final Rx<VisaStatus?> visaStatus = Rx<VisaStatus?>(null);
  final RxBool hasEid = false.obs;
  final Rx<bool?> willingTransferVisa = Rx<bool?>(true);
  final RxList<Emirate> workEmirates = <Emirate>[].obs;
  final RxBool willingRelocate = true.obs;
  final currentAreaCtrl = TextEditingController();
  // Structured current-area location from the map picker (coords/city/country).
  GeoLocation? currentLocationPicked;
  // Work preferences (System Spec §3.2 — required)
  final salaryMinCtrl = TextEditingController();
  final salaryMaxCtrl = TextEditingController();
  final Rx<JobTypePreference> jobTypePref = JobTypePreference.both.obs;
  final Rx<AvailabilityStatus> availability = AvailabilityStatus.availableNow.obs;
  final Rx<DateTime?> availableFrom = Rx<DateTime?>(null);
  final availableFromCtrl = TextEditingController();
  final Rx<MaritalStatus?> maritalStatus = Rx<MaritalStatus?>(null);
  final RxBool hasChildren = false.obs;
  final childrenCountCtrl = TextEditingController();
  final healthCtrl = TextEditingController();
  final medsCtrl = TextEditingController();
  final allergiesCtrl = TextEditingController();
  final RxBool comfortCameras = true.obs;
  final RxBool comfortPets = true.obs;
  final RxBool cooks = true.obs;
  final RxBool nightShifts = false.obs;
  final RxBool comfortDifferentFaith = true.obs;
  final religionCtrl = TextEditingController();
  final emergencyNameCtrl = TextEditingController();
  final emergencyRelCtrl = TextEditingController();
  final emergencyPhoneCtrl = TextEditingController();
  final emergencyCountryCode = '+971'.obs;
  final bioCtrl = TextEditingController();

  // step 2
  final RxList<String> photoUrls = <String>[].obs;
  final RxnString introVideoUrl = RxnString();
  final RxnString introVideoName = RxnString();

  // step 3
  final RxList<WorkExperience> experiences = <WorkExperience>[].obs;

  // step 4
  final RxBool hasReferences = true.obs;
  final RxList<ReferenceContact> references = <ReferenceContact>[].obs;
  final RxBool commitsToShare = false.obs;

  // step 5
  final RxMap<DocumentType, NannyDocument> documents = <DocumentType, NannyDocument>{
    for (final t in DocumentType.values)
      t: NannyDocument(type: t, status: DocumentStatus.missing),
  }.obs;

  /// Documents picked but not yet uploaded — uploaded together on submit.
  final Map<DocumentType, _StagedDoc> _stagedDocs = {};

  StreamSubscription<NannyModel?>? _nannyWatch;
  NannyOnboardingStatus? _lastWatchedStatus;

  bool get hasRequiredDocs {
    final passport = documents[DocumentType.passport]!;
    final visa = documents[DocumentType.visa]!;
    return passport.status != DocumentStatus.missing &&
        visa.status != DocumentStatus.missing;
  }

  /// Live age computed from the picked date of birth (null until chosen).
  int? get age {
    final d = dob.value;
    if (d == null) return null;
    final now = DateTime.now();
    var a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return a;
  }

  void setDob(DateTime d) {
    dob.value = d;
    dobCtrl.text = _fmtDate(d);
    _syncAgeField();
  }

  /// Mirrors the auto-calculated [age] into the read-only age field.
  void _syncAgeField() {
    final a = age;
    ageCtrl.text = a == null ? '' : '$a';
  }

  void setAvailableFrom(DateTime d) {
    availableFrom.value = d;
    availableFromCtrl.text = _fmtDate(d);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  void onInit() {
    super.onInit();
    _bootstrap().then((_) => _startApprovalWatch());
  }

  @override
  void onClose() {
    _nannyWatch?.cancel();
    fullNameCtrl.dispose();
    dobCtrl.dispose();
    ageCtrl.dispose();
    currentAreaCtrl.dispose();
    salaryMinCtrl.dispose();
    salaryMaxCtrl.dispose();
    availableFromCtrl.dispose();
    childrenCountCtrl.dispose();
    healthCtrl.dispose();
    medsCtrl.dispose();
    allergiesCtrl.dispose();
    religionCtrl.dispose();
    emergencyNameCtrl.dispose();
    emergencyRelCtrl.dispose();
    emergencyPhoneCtrl.dispose();
    bioCtrl.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    final user = _auth.currentUser.value;
    if (user == null || user.type != UserType.nanny) return;
    final existing = await _userService.getNanny(user.id);
    final profile = existing ??
        NannyModel(
          id: user.id,
          userId: user.id,
          fullName: user.fullName ?? '',
        );
    if (existing == null) {
      nanny.value = profile;
    } else {
      _hydrate(existing);
    }
    if (AppConfig.useMock && profile.status == NannyOnboardingStatus.pending) {
      await _userService.submitNannyForReview(profile.id);
    }
    await loadEmploymentStatus();
  }

  /// Loads the nanny's active hire and active/accepted trial for the home
  /// status card. Best-effort — a failure just hides the card.
  Future<void> loadEmploymentStatus() async {
    final user = _auth.currentUser.value;
    if (user == null || user.type != UserType.nanny) return;
    try {
      activeHire.value = await _hireService.activeHireForNanny(user.id);
      if (activeHire.value == null) {
        final trials = await _trialService.listTrialsForNanny(user.id);
        activeTrial.value = trials.firstWhereOrNull((t) => t.isAcceptedOrActive);
      } else {
        activeTrial.value = null;
      }
    } catch (_) {
      // Non-fatal — leave prior values; the card degrades gracefully.
    }
  }

  void _startApprovalWatch() {
    final user = _auth.currentUser.value;
    if (user == null || user.type != UserType.nanny) return;
    _nannyWatch?.cancel();
    _nannyWatch = _userService.watchNanny(user.id).listen((n) {
      if (n == null) return;
      final prev = _lastWatchedStatus;
      _lastWatchedStatus = n.status;
      nanny.value = n;
      for (final d in n.documents) {
        documents[d.type] = d;
      }
      if (n.status == NannyOnboardingStatus.approved) {
        _nannyWatch?.cancel();
        calculateProfileScore();
        // Only auto-forward approved nannies out of onboarding routes.
        // Otherwise, opening app screens like My Applications detail gets
        // bounced back to home as soon as the watcher emits.
        if (_onboardingRoutes.contains(Get.currentRoute)) {
          Get.offAllNamed(Routes.nannyHome);
          Get.snackbar(
            AppStrings.nannyApprovedTitle.tr,
            AppStrings.nannyApprovedBody.tr,
          );
        }
      } else if (n.status == NannyOnboardingStatus.rejected &&
          prev != null &&
          prev != NannyOnboardingStatus.rejected) {
        // Live admin rejection — surface the reason and make sure we're on the
        // pending screen, which renders the rejection + resubmit (Spec §6.1).
        // The watch keeps running so a later re-approval still transitions.
        if (_onboardingRoutes.contains(Get.currentRoute) &&
            Get.currentRoute != Routes.nannyPending) {
          Get.offAllNamed(Routes.nannyPending);
        }
        Get.snackbar(
          AppStrings.nannyRejectedTitle.tr,
          (n.rejectionReason?.isNotEmpty ?? false)
              ? n.rejectionReason!
              : AppStrings.nannyRejectedBody.tr,
        );
      }
    });
  }

  void _hydrate(NannyModel n) {
    nanny.value = n;
    // Identity + demographics
    fullNameCtrl.text = n.fullName;
    dob.value = n.dateOfBirth;
    if (n.dateOfBirth != null) {
      dobCtrl.text =
          '${n.dateOfBirth!.day.toString().padLeft(2, '0')}/${n.dateOfBirth!.month.toString().padLeft(2, '0')}/${n.dateOfBirth!.year}';
    }
    _syncAgeField();
    nationality.value = n.nationality;
    selectedLanguages.value = List.of(n.languages);
    // Visa + work
    visaStatus.value = n.visaStatus;
    hasEid.value = n.hasEmiratesId;
    willingTransferVisa.value = n.willingToTransferVisa;
    workEmirates.value = List.of(n.workEmirates);
    willingRelocate.value = n.willingToRelocate;
    currentAreaCtrl.text = n.currentArea;
    currentLocationPicked = n.currentLocation;
    // Work preferences
    salaryMinCtrl.text = n.expectedSalaryMin > 0 ? '${n.expectedSalaryMin}' : '';
    salaryMaxCtrl.text = n.expectedSalaryMax > 0 ? '${n.expectedSalaryMax}' : '';
    jobTypePref.value = n.jobTypePreference;
    availability.value = n.availability;
    availableFrom.value = n.availableFrom;
    if (n.availableFrom != null) availableFromCtrl.text = _fmtDate(n.availableFrom!);
    // Personal
    maritalStatus.value = n.maritalStatus;
    hasChildren.value = n.hasChildren;
    childrenCountCtrl.text = '${n.childrenCount}';
    // Health
    healthCtrl.text = n.healthConditions;
    medsCtrl.text = n.medications;
    allergiesCtrl.text = n.allergies;
    // Preferences
    comfortCameras.value = n.comfortableWithCameras;
    comfortPets.value = n.comfortableWithPets;
    cooks.value = n.canCook;
    nightShifts.value = n.canDoNightShifts;
    comfortDifferentFaith.value = n.comfortableWithDifferentFaith;
    religionCtrl.text = n.religion;
    // Emergency contact
    emergencyNameCtrl.text = n.emergencyName;
    emergencyRelCtrl.text = n.emergencyRelationship;
    emergencyCountryCode.value =
        n.emergencyCountryCode.isNotEmpty ? n.emergencyCountryCode : '+971';
    emergencyPhoneCtrl.text = n.emergencyPhone;
    // Bio + media + history
    bioCtrl.text = n.bio;
    photoUrls.value = List.of(n.photoUrls);
    introVideoUrl.value = n.introVideoUrl;
    experiences.value = List.of(n.experiences);
    references.value = List.of(n.references);
    for (final d in n.documents) {
      documents[d.type] = d;
    }
  }

  void toggleLanguage(String lang) {
    if (selectedLanguages.contains(lang)) {
      selectedLanguages.remove(lang);
    } else {
      selectedLanguages.add(lang);
    }
  }

  void toggleEmirate(Emirate e) {
    if (workEmirates.contains(e)) {
      workEmirates.remove(e);
    } else {
      workEmirates.add(e);
    }
  }

  /// Save profile updates without advancing onboarding step.
  /// Used by Screen 27A (nanny edit profile).
  Future<void> saveProfileDraft() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser.value;
      if (user == null) return;
      final id = nanny.value?.id ?? user.id;
      final updated = (nanny.value ?? NannyModel(id: id, userId: user.id)).copyWith(
        fullName: fullNameCtrl.text.trim(),
        languages: List.of(selectedLanguages),
        workEmirates: List.of(workEmirates),
        currentArea: currentAreaCtrl.text.trim(),
        currentLocation: currentLocationPicked,
        comfortableWithCameras: comfortCameras.value,
        comfortableWithPets: comfortPets.value,
        canCook: cooks.value,
        canDoNightShifts: nightShifts.value,
        emergencyName: emergencyNameCtrl.text.trim(),
        emergencyRelationship: emergencyRelCtrl.text.trim(),
        emergencyCountryCode: emergencyCountryCode.value,
        emergencyPhone: emergencyPhoneCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
      );
      await _userService.saveNanny(updated);
      nanny.value = updated;
      calculateProfileScore();
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.profileUpdated.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Closes an edit-mode screen (opened from the profile tab) after a save,
  /// returning to the profile instead of advancing the onboarding flow.
  void _closeEdit() {
    Get.back();
    Get.snackbar(AppStrings.successTitle.tr, AppStrings.profileUpdated.tr);
  }

  /// First failing required-field message key for the personal-info step, or
  /// null when valid. System Spec §3.2 (required fields) + §14.4 rules.
  String? validatePersonalInfo() {
    if (fullNameCtrl.text.trim().isEmpty) return AppStrings.nannyFullNameRequired;
    final dobErr = Validators.dateOfBirth(dob.value);
    if (dobErr != null) {
      return dob.value == null ? AppStrings.nannyDobRequired : dobErr;
    }
    if (nationality.value.trim().isEmpty) return AppStrings.nannyNationalityRequired;
    if (selectedLanguages.isEmpty) return AppStrings.nannyLanguagesRequired;
    if (visaStatus.value == null) return AppStrings.nannyVisaRequired;
    if (workEmirates.isEmpty) return AppStrings.nannyEmiratesRequired;
    if (currentAreaCtrl.text.trim().isEmpty) return AppStrings.nannyCurrentAreaRequired;
    final salErr = Validators.salaryRange(
      int.tryParse(salaryMinCtrl.text) ?? 0,
      int.tryParse(salaryMaxCtrl.text) ?? 0,
    );
    if (salErr != null) return salErr;
    if (availability.value == AvailabilityStatus.availableFrom &&
        availableFrom.value == null) {
      return AppStrings.nannyAvailableFromRequired;
    }
    if (maritalStatus.value == null) return AppStrings.nannyMaritalRequired;
    if (hasChildren.value && (int.tryParse(childrenCountCtrl.text) ?? 0) < 1) {
      return AppStrings.nannyChildrenCountRequired;
    }
    if (emergencyNameCtrl.text.trim().isEmpty) return AppStrings.nannyEmergencyNameRequired;
    if (emergencyRelCtrl.text.trim().isEmpty) return AppStrings.nannyEmergencyRelRequired;
    if (Validators.contactPhone(emergencyPhoneCtrl.text) != null) {
      return AppStrings.nannyEmergencyPhoneRequired;
    }
    if (bioCtrl.text.trim().isEmpty) return AppStrings.nannyBioRequired;
    return null;
  }

  Future<void> savePersonalInfoAndNext({bool advance = true}) async {
    // Required-field validation — System Spec §3.2 required fields + §14.4.
    final err = validatePersonalInfo();
    if (err != null) {
      Get.snackbar(AppStrings.errorTitle.tr, err.tr);
      return;
    }
    isLoading.value = true;
    try {
      final user = _auth.currentUser.value;
      if (user == null) return;
      final id = nanny.value?.id ?? user.id;
      final updated = (nanny.value ?? NannyModel(id: id, userId: user.id)).copyWith(
        fullName: fullNameCtrl.text.trim(),
        dateOfBirth: dob.value,
        nationality: nationality.value,
        languages: List.of(selectedLanguages),
        visaStatus: visaStatus.value,
        hasEmiratesId: hasEid.value,
        willingToTransferVisa: willingTransferVisa.value,
        workEmirates: List.of(workEmirates),
        willingToRelocate: willingRelocate.value,
        currentArea: currentAreaCtrl.text.trim(),
        currentLocation: currentLocationPicked,
        expectedSalaryMin: int.tryParse(salaryMinCtrl.text) ?? 0,
        expectedSalaryMax: int.tryParse(salaryMaxCtrl.text) ?? 0,
        jobTypePreference: jobTypePref.value,
        availability: availability.value,
        availableFrom: availability.value == AvailabilityStatus.availableFrom
            ? availableFrom.value
            : null,
        maritalStatus: maritalStatus.value,
        hasChildren: hasChildren.value,
        childrenCount: int.tryParse(childrenCountCtrl.text) ?? 0,
        healthConditions: healthCtrl.text.trim(),
        medications: medsCtrl.text.trim(),
        allergies: allergiesCtrl.text.trim(),
        comfortableWithCameras: comfortCameras.value,
        comfortableWithPets: comfortPets.value,
        canCook: cooks.value,
        canDoNightShifts: nightShifts.value,
        comfortableWithDifferentFaith: comfortDifferentFaith.value,
        religion: religionCtrl.text.trim(),
        emergencyName: emergencyNameCtrl.text.trim(),
        emergencyRelationship: emergencyRelCtrl.text.trim(),
        emergencyCountryCode: emergencyCountryCode.value,
        emergencyPhone: emergencyPhoneCtrl.text.trim(),
        bio: bioCtrl.text.trim(),
      );
      await _userService.saveNanny(updated);
      nanny.value = updated;
      if (!advance) {
        _closeEdit();
        return;
      }
      currentStep.value = 2;
      Get.toNamed(Routes.nannyMedia);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadPhoto({ImageSource source = ImageSource.gallery}) async {
    if (photoUrls.length >= NannyConstants.maxPhotos) return;
    final user = _auth.currentUser.value;
    if (user == null) return;
    final permissions = Get.find<PermissionController>();
    final allowed = source == ImageSource.camera
        ? await permissions.requestCamera()
        : await permissions.ensureGallery();
    if (!allowed) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        (source == ImageSource.camera
                ? AppStrings.permissionCameraDenied
                : AppStrings.permissionGalleryDenied)
            .tr,
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    isLoading.value = true;
    try {
      // Mock mode: keep the local file path so Image.file / VideoPlayer can
      // preview immediately (data: URIs and huge in-memory copies break UI).
      if (AppConfig.useMock) {
        photoUrls.add(picked.path);
        return;
      }
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadBytes(
        path: 'nannies/${user.id}/photos/${_uuid.v4()}.jpg',
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      photoUrls.add(url);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void removePhoto(int index) {
    if (index < photoUrls.length) photoUrls.removeAt(index);
  }

  Future<void> pickAndUploadVideo({ImageSource source = ImageSource.gallery}) async {
    final user = _auth.currentUser.value;
    if (user == null) return;
    final permissions = Get.find<PermissionController>();
    final allowed = source == ImageSource.camera
        ? await permissions.ensureCameraAndMic()
        : await permissions.ensureVideoGallery();
    if (!allowed) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        (source == ImageSource.camera
                ? AppStrings.permissionCameraDenied
                : AppStrings.permissionGalleryDenied)
            .tr,
      );
      return;
    }
    final picked = await ImagePicker().pickVideo(
      source: source,
      maxDuration: Duration(seconds: NannyConstants.maxVideoSeconds),
    );
    if (picked == null) return;

    // image_picker's `maxDuration` only caps *camera* recordings — a clip
    // chosen from the gallery is never length-checked. Enforce the limit
    // ourselves so an over-long video is rejected (the nanny trims it first)
    // instead of being uploaded.
    if (await _videoExceedsLimit(picked.path)) {
      Get.snackbar(
        AppStrings.errorTitle.tr,
        AppStrings.nannyVideoTooLong.tr,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    isLoading.value = true;
    try {
      if (AppConfig.useMock) {
        introVideoUrl.value = picked.path;
        introVideoName.value = picked.name;
        return;
      }
      final bytes = await picked.readAsBytes();
      introVideoUrl.value = await _storageService.uploadBytes(
        // Must match storage.rules `/nannies/{uid}/videos/{file}`.
        path: 'nannies/${user.id}/videos/video.mp4',
        bytes: bytes,
        contentType: 'video/mp4',
      );
      introVideoName.value = picked.name;
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// True when the video at [path] runs longer than [NannyConstants.maxVideoSeconds].
  /// Best-effort — returns false when the duration can't be read, so a probe
  /// failure never blocks a valid upload.
  Future<bool> _videoExceedsLimit(String path) async {
    final probe = VideoPlayerController.file(File(path));
    try {
      await probe.initialize();
      final secs = probe.value.duration.inSeconds;
      return secs > NannyConstants.maxVideoSeconds;
    } catch (_) {
      return false;
    } finally {
      await probe.dispose();
    }
  }

  /// First failing required-field message key for the photos/video step, or
  /// null when valid (System Spec §3.2: personal info saved first, >=3 photos,
  /// and an intro video).
  String? validateMedia() {
    if (nanny.value == null) return AppStrings.nannyCompleteStep1;
    if (photoUrls.length < NannyConstants.minPhotos) return AppStrings.nannyPhotosMin3;
    if (introVideoUrl.value == null || introVideoUrl.value!.isEmpty) {
      return AppStrings.nannyVideoRequired;
    }
    return null;
  }

  Future<void> saveMediaAndNext({bool advance = true}) async {
    final err = validateMedia();
    if (err != null) {
      Get.snackbar(AppStrings.errorTitle.tr, err.tr);
      return;
    }
    final n = nanny.value!;
    isLoading.value = true;
    try {
      final updated = n.copyWith(
          photoUrls: List.of(photoUrls), introVideoUrl: introVideoUrl.value);
      await _userService.saveNanny(updated);
      nanny.value = updated;
      if (!advance) {
        _closeEdit();
        return;
      }
      currentStep.value = 3;
      Get.toNamed(Routes.nannyExp);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void addExperience(WorkExperience exp) {
    experiences.add(exp);
    _persistExperiences();
  }

  void removeExperience(int index) {
    if (index < experiences.length) {
      experiences.removeAt(index);
      _persistExperiences();
    }
  }

  /// Fire-and-forget save of the experiences list so an added/removed entry is
  /// persisted immediately, not only when the nanny taps Next.
  Future<void> _persistExperiences() async {
    final n = nanny.value;
    if (n == null) return;
    final updated = n.copyWith(experiences: List.of(experiences));
    nanny.value = updated;
    try {
      await _userService.saveNanny(updated);
    } catch (_) {
      // Best-effort — the step's Next also saves.
    }
  }

  Future<void> saveExpAndNext({bool advance = true}) async {
    final n = nanny.value;
    if (n == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyCompleteStep1.tr);
      return;
    }
    // Guard against invalid date ranges (belt-and-suspenders — the picker also
    // prevents selecting a "from" after "to").
    for (final e in experiences) {
      final dateErr = Validators.experienceDates(e.fromDate, e.toDate);
      if (dateErr != null) {
        Get.snackbar(AppStrings.errorTitle.tr, dateErr.tr);
        return;
      }
    }
    isLoading.value = true;
    try {
      final updated = n.copyWith(experiences: List.of(experiences));
      await _userService.saveNanny(updated);
      nanny.value = updated;
      if (!advance) {
        _closeEdit();
        return;
      }
      currentStep.value = 4;
      Get.toNamed(Routes.nannyRefs);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void addReference(ReferenceContact r) {
    references.add(r);
    _persistReferences();
  }

  void removeReference(int index) {
    if (index < references.length) {
      references.removeAt(index);
      _persistReferences();
    }
  }

  /// Fire-and-forget save of the references list (see [_persistExperiences]).
  Future<void> _persistReferences() async {
    final n = nanny.value;
    if (n == null) return;
    final updated = n.copyWith(references: List.of(references));
    nanny.value = updated;
    try {
      await _userService.saveNanny(updated);
    } catch (_) {
      // Best-effort — the step's Next also saves.
    }
  }

  Future<void> saveRefsAndNext({bool advance = true}) async {
    final n = nanny.value;
    if (n == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyCompleteStep1.tr);
      return;
    }
    isLoading.value = true;
    try {
      final updated = n.copyWith(references: List.of(references));
      await _userService.saveNanny(updated);
      nanny.value = updated;
      if (!advance) {
        _closeEdit();
        return;
      }
      currentStep.value = 5;
      Get.toNamed(Routes.nannyDocs);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Max size for a nanny document, aligned with storage.rules `under(25)` so
  /// oversized files are rejected client-side with a friendly message instead
  /// of failing the upload against Storage security rules. Documents may be
  /// images, PDFs, videos or other formats — hence the larger cap.
  static const int _maxDocBytes = 25 * 1024 * 1024;

  /// Best-effort content type from a file extension so uploaded documents carry
  /// a correct MIME type (drives the admin panel's image/video/PDF preview).
  static String _docContentType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Picks a document and stages it locally. Nothing is uploaded until the user
  /// submits (or saves in edit mode) — see [_uploadStagedDocs].
  Future<void> pickDocument(DocumentType type) async {
    final user = _auth.currentUser.value;
    if (user == null) return;
    // Documents are chosen through the system file picker (Storage Access
    // Framework on Android / UIDocumentPicker on iOS), which grants one-shot
    // access to the picked file. That needs NO photo-library permission, so we
    // must not gate on it — doing so previously blocked PDF uploads outright on
    // Android 13+ where the photos permission does not apply to documents.
    FilePickerResult? result;
    try {
      // Accept any document format — pictures, PDFs, videos or other files —
      // per the admin verification requirements.
      result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
    } catch (_) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.docPickFailed.tr);
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    // `withData: true` usually populates bytes, but large files on some
    // platforms are exposed only via a path. Fall back to reading the file so a
    // valid pick never silently no-ops.
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      try {
        bytes = await File(file.path!).readAsBytes();
      } catch (_) {
        // handled by the null check below
      }
    }
    if (bytes == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.docPickFailed.tr);
      return;
    }
    if (bytes.length > _maxDocBytes) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.docTooLarge.tr);
      return;
    }
    final ext = (file.extension ?? 'jpg').toLowerCase();
    _stagedDocs[type] = _StagedDoc(
      bytes: bytes,
      ext: ext,
      contentType: _docContentType(ext),
    );
    // Mark selected locally (drives the ✓ tile); real upload happens on submit.
    documents[type] = documents[type]!.copyWith(
      status: DocumentStatus.uploaded,
      uploadedAt: DateTime.now(),
    );
  }

  /// Nanny declares they have no Emirates ID (visit visa / new to UAE).
  void markNoEid() {
    hasEid.value = false;
    _stagedDocs.remove(DocumentType.emiratesId);
    documents[DocumentType.emiratesId] =
        documents[DocumentType.emiratesId]!.copyWith(status: DocumentStatus.missing);
  }

  /// Uploads every staged document to Firebase Storage, setting its URL and
  /// `reviewing` status. Throws on failure (caller shows a localized error);
  /// already-uploaded docs are removed from the staging map so they are not
  /// re-uploaded on a retry.
  Future<void> _uploadStagedDocs(String userId) async {
    final uploadedUrls = <DocumentType, String>{};
    for (final entry in _stagedDocs.entries.toList()) {
      final type = entry.key;
      final staged = entry.value;
      final url = await _storageService.uploadBytes(
        // Must match storage.rules `/nannies/{uid}/documents/{file}` — the old
        // `docs/` prefix matched no rule and was rejected by Storage.
        path: 'nannies/$userId/documents/${type.name}.${staged.ext}',
        bytes: staged.bytes,
        contentType: staged.contentType,
      );
      documents[type] = documents[type]!.copyWith(
        url: url,
        status: DocumentStatus.reviewing,
        uploadedAt: DateTime.now(),
      );
      uploadedUrls[type] = url;
      _stagedDocs.remove(type);
    }
    // Persist the sensitive download URLs to the private
    // nannies/{id}/documents/{type} subcollection (owner/admin only). saveNanny
    // then writes only status/metadata to the world-readable parent doc (C5).
    if (uploadedUrls.isNotEmpty) {
      await _userService.saveNannyDocumentUrls(userId, uploadedUrls);
    }
  }

  void _showBlockingLoader(String message) {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: KafiColors.cardBorder),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1FFF5C8A), blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: KafiColors.roseP,
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(13),
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: KafiColors.roseD),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: KafiTheme.fredoka(13, color: KafiColors.td, w: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.docUploadingHint.tr,
                  textAlign: TextAlign.center,
                  style: KafiTheme.nunito(10, color: KafiColors.ts, w: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _hideBlockingLoader() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// Edit-mode save for the Documents screen: uploads any newly-picked docs
  /// (which return to `reviewing` for admin re-verification) and persists.
  Future<void> saveDocumentsAndClose() async {
    final n = nanny.value;
    if (n == null) {
      Get.back();
      return;
    }
    _showBlockingLoader(AppStrings.docUploading.tr);
    isLoading.value = true;
    try {
      await _uploadStagedDocs(n.id);
      final updated = n.copyWith(documents: documents.values.toList());
      await _userService.saveNanny(updated);
      nanny.value = updated;
      calculateProfileScore();
      _hideBlockingLoader();
      _closeEdit();
    } catch (e) {
      _hideBlockingLoader();
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.docUploadFailed.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitForReview() async {
    // Required-docs guard — passport + visa must be uploaded.
    if (!hasRequiredDocs) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyRequiredDocsMissing.tr);
      return;
    }
    final n = nanny.value;
    if (n == null) return;
    _showBlockingLoader(AppStrings.docUploading.tr);
    isLoading.value = true;
    try {
      // Upload all staged documents first, then flip the profile to pending.
      await _uploadStagedDocs(n.id);
      final updated = (nanny.value ?? n).copyWith(
        documents: documents.values
            .map((d) => d.status == DocumentStatus.uploaded
                ? d.copyWith(status: DocumentStatus.reviewing)
                : d)
            .toList(),
        status: NannyOnboardingStatus.pending,
      );
      await _userService.saveNanny(updated);
      await _userService.submitNannyForReview(updated.id);
      nanny.value = updated;
      _hideBlockingLoader();
      Get.snackbar(
        AppStrings.nannySubmittedTitle.tr,
        AppStrings.nannySubmittedBody.tr,
      );
      Get.offAllNamed(Routes.nannyPending);
    } catch (e) {
      _hideBlockingLoader();
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.docUploadFailed.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void calculateProfileScore() {
    var score = 0;
    final n = nanny.value;
    if (n == null) return;
    if (n.fullName.isNotEmpty) score += 15;
    if (n.photoUrls.isNotEmpty) score += 15;
    if (n.introVideoUrl != null) score += 15;
    if (n.experiences.isNotEmpty) score += 15;
    if (n.references.isNotEmpty) score += 10;
    if (n.documents.any((d) => d.type == DocumentType.passport && d.status != DocumentStatus.missing)) score += 15;
    if (n.documents.any((d) => d.type == DocumentType.policeClearance && d.status != DocumentStatus.missing)) {
      score += NannyConstants.scorePoliceClearance;
    }
    if (n.documents.any((d) => d.type == DocumentType.trainingCert && d.status != DocumentStatus.missing)) {
      score += NannyConstants.scoreTrainingCert;
    }
    nanny.value = n.copyWith(profileScore: score.clamp(0, 100));
  }
}

class _StagedDoc {
  _StagedDoc({required this.bytes, required this.ext, required this.contentType});
  final Uint8List bytes;
  final String ext;
  final String contentType;
}
