import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/permission_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/models/user_model.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:uuid/uuid.dart';

class NannyProfileController extends GetxController {
  final IUserService _userService = Get.find<IUserService>();
  final IStorageService _storageService = Get.find<IStorageService>();
  final AuthController _auth = Get.find<AuthController>();
  final _uuid = const Uuid();

  final Rx<NannyModel?> nanny = Rx<NannyModel?>(null);
  final RxInt currentStep = 1.obs;
  final RxBool isLoading = false.obs;

  // step 1
  final fullNameCtrl = TextEditingController();
  final dobCtrl = TextEditingController(text: '1992-03-14');
  final Rx<DateTime?> dob = Rx<DateTime?>(DateTime(1992, 3, 14));
  final RxString nationality = 'Filipino'.obs;
  final RxList<String> selectedLanguages = <String>['English', 'Arabic (basic)'].obs;
  final Rx<VisaStatus?> visaStatus = Rx<VisaStatus?>(VisaStatus.residenceSponsored);
  final RxBool hasEid = false.obs;
  final Rx<bool?> willingTransferVisa = Rx<bool?>(true);
  final RxList<Emirate> workEmirates = <Emirate>[Emirate.dubai, Emirate.abuDhabi, Emirate.sharjah, Emirate.alAin].obs;
  final RxBool willingRelocate = true.obs;
  final currentAreaCtrl = TextEditingController();
  final Rx<MaritalStatus?> maritalStatus = Rx<MaritalStatus?>(MaritalStatus.single);
  final RxBool hasChildren = false.obs;
  final childrenCountCtrl = TextEditingController();
  final healthCtrl = TextEditingController();
  final medsCtrl = TextEditingController();
  final allergiesCtrl = TextEditingController();
  final RxBool comfortCameras = true.obs;
  final RxBool comfortPets = true.obs;
  final RxBool cooks = true.obs;
  final RxBool nightShifts = false.obs;
  final religionCtrl = TextEditingController();
  final emergencyNameCtrl = TextEditingController();
  final emergencyRelCtrl = TextEditingController();
  final emergencyPhoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  // step 2
  final RxList<String> photoUrls = <String>[].obs;
  final RxnString introVideoUrl = RxnString();

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

  StreamSubscription<NannyModel?>? _nannyWatch;

  bool get _hasRequiredDocs {
    final passport = documents[DocumentType.passport]!;
    final visa = documents[DocumentType.visa]!;
    return passport.status != DocumentStatus.missing &&
        visa.status != DocumentStatus.missing;
  }

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
    currentAreaCtrl.dispose();
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
  }

  void _startApprovalWatch() {
    final user = _auth.currentUser.value;
    if (user == null || user.type != UserType.nanny) return;
    _nannyWatch?.cancel();
    _nannyWatch = _userService.watchNanny(user.id).listen((n) {
      if (n == null) return;
      nanny.value = n;
      for (final d in n.documents) {
        documents[d.type] = d;
      }
      if (n.status == NannyOnboardingStatus.approved) {
        _nannyWatch?.cancel();
        calculateProfileScore();
        if (Get.currentRoute != Routes.nannyHome) {
          Get.offAllNamed(Routes.nannyHome);
          Get.snackbar(
            AppStrings.nannyApprovedTitle.tr,
            AppStrings.nannyApprovedBody.tr,
          );
        }
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
    nationality.value = n.nationality;
    selectedLanguages.value = List.of(n.languages);
    // Visa + work
    visaStatus.value = n.visaStatus;
    hasEid.value = n.hasEmiratesId;
    willingTransferVisa.value = n.willingToTransferVisa;
    workEmirates.value = List.of(n.workEmirates);
    willingRelocate.value = n.willingToRelocate;
    currentAreaCtrl.text = n.currentArea;
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
    religionCtrl.text = n.religion;
    // Emergency contact
    emergencyNameCtrl.text = n.emergencyName;
    emergencyRelCtrl.text = n.emergencyRelationship;
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
        comfortableWithCameras: comfortCameras.value,
        comfortableWithPets: comfortPets.value,
        canCook: cooks.value,
        canDoNightShifts: nightShifts.value,
        emergencyName: emergencyNameCtrl.text.trim(),
        emergencyRelationship: emergencyRelCtrl.text.trim(),
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

  Future<void> savePersonalInfoAndNext({bool advance = true}) async {
    // Required-field validation per onboarding spec.
    if (fullNameCtrl.text.trim().isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyFullNameRequired.tr);
      return;
    }
    if (dob.value == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyDobRequired.tr);
      return;
    }
    if (selectedLanguages.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyLanguagesRequired.tr);
      return;
    }
    if (workEmirates.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyEmiratesRequired.tr);
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
        religion: religionCtrl.text.trim(),
        emergencyName: emergencyNameCtrl.text.trim(),
        emergencyRelationship: emergencyRelCtrl.text.trim(),
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

  Future<void> pickAndUploadPhoto() async {
    if (photoUrls.length >= NannyConstants.maxPhotos) return;
    final user = _auth.currentUser.value;
    if (user == null) return;
    if (!await Get.find<PermissionController>().ensureGallery()) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.permissionGalleryDenied.tr);
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    isLoading.value = true;
    try {
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

  Future<void> pickAndUploadVideo() async {
    final user = _auth.currentUser.value;
    if (user == null) return;
    if (!await Get.find<PermissionController>().ensureGallery()) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.permissionGalleryDenied.tr);
      return;
    }
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: Duration(seconds: NannyConstants.maxVideoSeconds),
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    isLoading.value = true;
    try {
      introVideoUrl.value = await _storageService.uploadBytes(
        path: 'nannies/${user.id}/video.mp4',
        bytes: bytes,
        contentType: 'video/mp4',
      );
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveMediaAndNext({bool advance = true}) async {
    final n = nanny.value;
    if (n == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyCompleteStep1.tr);
      return;
    }
    if (photoUrls.isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyPhotosRequired.tr);
      return;
    }
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

  void addExperience(WorkExperience exp) => experiences.add(exp);
  void removeExperience(int index) {
    if (index < experiences.length) experiences.removeAt(index);
  }

  Future<void> saveExpAndNext({bool advance = true}) async {
    final n = nanny.value;
    if (n == null) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyCompleteStep1.tr);
      return;
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

  void addReference(ReferenceContact r) => references.add(r);
  void removeReference(int index) {
    if (index < references.length) references.removeAt(index);
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

  Future<void> pickAndUploadDocument(DocumentType type) async {
    final user = _auth.currentUser.value;
    if (user == null) return;
    if (!await Get.find<PermissionController>().ensureGallery()) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.permissionGalleryDenied.tr);
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    final ext = (file.extension ?? 'jpg').toLowerCase();
    isLoading.value = true;
    try {
      final url = await _storageService.uploadBytes(
        path: 'nannies/${user.id}/docs/${type.name}.$ext',
        bytes: bytes,
        contentType: ext == 'pdf' ? 'application/pdf' : 'image/jpeg',
      );
      documents[type] = documents[type]!.copyWith(
        url: url,
        status: DocumentStatus.uploaded,
        uploadedAt: DateTime.now(),
      );
      if (AppConfig.useMock &&
          _hasRequiredDocs &&
          nanny.value?.status != NannyOnboardingStatus.pending &&
          nanny.value?.status != NannyOnboardingStatus.approved) {
        await submitForReview();
      }
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Edit-mode save for the Documents screen: persists the current documents
  /// without resubmitting for review or leaving the app shell.
  Future<void> saveDocumentsAndClose() async {
    final n = nanny.value;
    if (n == null) {
      Get.back();
      return;
    }
    isLoading.value = true;
    try {
      final updated = n.copyWith(documents: documents.values.toList());
      await _userService.saveNanny(updated);
      nanny.value = updated;
      calculateProfileScore();
      _closeEdit();
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitForReview() async {
    // Required-docs guard — passport + visa must be uploaded.
    if (!_hasRequiredDocs) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.nannyRequiredDocsMissing.tr);
      return;
    }
    isLoading.value = true;
    try {
      final n = nanny.value;
      if (n == null) return;
      final updated = n.copyWith(
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
      Get.snackbar(
        AppStrings.nannySubmittedTitle.tr,
        AppStrings.nannySubmittedBody.tr,
      );
      Get.offAllNamed(Routes.nannyPending);
    } catch (e) {
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
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
