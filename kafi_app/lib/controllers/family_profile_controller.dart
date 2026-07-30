import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/location_service.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/utils/validators.dart';
import 'package:uuid/uuid.dart';

class FamilyProfileController extends GetxController {
  final IUserService _user = Get.find<IUserService>();
  final IJobService _jobs = Get.find<IJobService>();
  final AuthController _auth = Get.find<AuthController>();
  final LocationService _location = Get.find<LocationService>();
  final _uuid = const Uuid();

  /// The specific post the edit form targets (a family may hold one full-time
  /// and one part-time post). Null = the generic edit, which uses the most
  /// recent post. Set via [startJobEdit] (M6).
  String? _editJobId;

  final Rx<FamilyModel?> family = Rx<FamilyModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool detectingCity = false.obs;

  final fullNameCtrl = TextEditingController();
  final RxString nationality = 'Emirati'.obs;
  final RxString city = ''.obs;
  final childrenCtrl = TextEditingController(text: '2');
  final childrenAgesCtrl = TextEditingController();
  final RxList<String> languages = <String>['English', 'Arabic'].obs;
  final RxBool hasCameras = true.obs;
  final RxList<String> petTypes = <String>[].obs;

  // About the family (free-text, multiline introduction)
  final aboutFamilyCtrl = TextEditingController();

  // Religion & household culture
  final RxString religion = ''.obs;
  final Rx<NannyReligionPreference> religionPref = NannyReligionPreference.noPreference.obs;
  final houseRulesCtrl = TextEditingController();

  final RxList<String> roles = <String>['Nanny'].obs;
  final Rx<JobType> jobType = JobType.liveIn.obs;
  final Rx<JobEmploymentType> employmentType = JobEmploymentType.fullTime.obs;
  final scheduleCtrl = TextEditingController();
  final RxList<String> duties = <String>[].obs;
  final RxList<String> benefits = <String>[].obs;

  final salaryMinCtrl = TextEditingController(text: '2000');
  final salaryMaxCtrl = TextEditingController(text: '3000');
  final trialRateCtrl = TextEditingController(text: '150');
  final RxInt trialDays = 7.obs;

  final Rx<VisaSponsorship> visaSponsorship = VisaSponsorship.full.obs;
  final RxBool commit = false.obs;

  void toggle<T>(RxList<T> list, T value) {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _hydrateFromCurrentUser().then((_) => autoDetectCity());
  }

  /// Loads the signed-in family's profile + latest job post (if any) and
  /// fills the form controllers so the Edit screen shows existing values.
  Future<void> _hydrateFromCurrentUser() async {
    final user = _auth.currentUser.value;
    if (user == null || !user.isFamily) return;
    isLoading.value = true;
    try {
      final fam = await _user.getFamily(user.id);
      if (fam != null) {
        family.value = fam;
        fullNameCtrl.text = fam.fullName;
        if (fam.nationality.isNotEmpty) nationality.value = fam.nationality;
        if (fam.city.isNotEmpty) city.value = fam.city;
        childrenCtrl.text = '${fam.childrenCount}';
        childrenAgesCtrl.text = fam.childrenAges.join(', ');
        languages.value = List<String>.from(fam.languagesAtHome);
        hasCameras.value = fam.hasCameras;
        petTypes.value = List<String>.from(fam.petTypes);
        religion.value = fam.religion;
        religionPref.value = fam.nannyReligionPreference;
        houseRulesCtrl.text = fam.houseRules ?? '';
        aboutFamilyCtrl.text = fam.aboutFamily ?? '';
      }
      // Load the targeted post (see [_selectEditPost]) for role/duties/
      // benefits/visa — not a bare posts.first, which ignores which job the
      // family chose to edit.
      final posts = await _jobs.getJobsByFamily(user.id);
      if (posts.isNotEmpty) {
        final p = _selectEditPost(posts);
        roles.value = List<String>.from(p.rolesNeeded);
        jobType.value = p.jobType;
        employmentType.value = p.employmentType;
        scheduleCtrl.text = p.schedule;
        duties.value = List<String>.from(p.duties);
        benefits.value = List<String>.from(p.benefits);
        salaryMinCtrl.text = '${p.salaryMin}';
        salaryMaxCtrl.text = '${p.salaryMax}';
        // Guard against legacy/empty profiles whose value isn't a selectable option.
        trialDays.value = FamilyConstants.trialDurations.contains(p.trialDurationDays)
            ? p.trialDurationDays
            : trialDays.value;
        trialRateCtrl.text = '${p.trialDailyRate}';
        visaSponsorship.value = p.visaSponsorship;
        commit.value = p.commitmentAgreed;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-hydrates the edit form for a SPECIFIC job so a family with more than
  /// one post (e.g. one full-time + one part-time) edits the intended one
  /// instead of always the first — pass null for the generic Settings edit,
  /// which targets the most-recent post (M6).
  Future<void> startJobEdit(String? jobId) async {
    _editJobId = jobId;
    await _hydrateFromCurrentUser();
  }

  /// The post the edit form loads and saves against: the one matching
  /// [_editJobId] when set and still present, else the most-recently created.
  /// (getJobsByFamily has no server ordering, so a bare `posts.first` is
  /// arbitrary — this makes the fallback deterministic.)
  JobPostModel _selectEditPost(List<JobPostModel> posts) {
    if (_editJobId != null) {
      final match = posts.firstWhereOrNull((p) => p.id == _editJobId);
      if (match != null) return match;
    }
    return posts.reduce((a, b) =>
        (a.createdAt ?? DateTime(1970)).isAfter(b.createdAt ?? DateTime(1970))
            ? a
            : b);
  }

  /// Auto-fills [city] from the device GPS location on first load, unless the
  /// family already has a saved city. Requests location permission. No-op when
  /// the Google Maps key is the placeholder (reverse geocoding unavailable).
  Future<void> autoDetectCity() async {
    if (city.value.trim().isNotEmpty) return;
    if (!_location.hasMapsKey) return;
    detectingCity.value = true;
    try {
      final detected = await _location.detectCurrentCity();
      if (detected != null && city.value.trim().isEmpty) {
        city.value = detected;
      }
    } finally {
      detectingCity.value = false;
    }
  }

  @override
  void onClose() {
    fullNameCtrl.dispose();
    childrenCtrl.dispose();
    childrenAgesCtrl.dispose();
    houseRulesCtrl.dispose();
    aboutFamilyCtrl.dispose();
    scheduleCtrl.dispose();
    salaryMinCtrl.dispose();
    salaryMaxCtrl.dispose();
    trialRateCtrl.dispose();
    super.onClose();
  }

  Future<void> savePostAndBrowse() async {
    final ok = await _persist();
    if (ok) Get.offAllNamed(Routes.browse);
  }

  /// Edit-screen path — save in place and stay on the screen with a snackbar.
  Future<void> saveEdit() async {
    final ok = await _persist(reuseExistingPost: true);
    if (ok) {
      Get.snackbar(AppStrings.successTitle.tr, AppStrings.profileUpdated.tr);
      Get.back();
    }
  }

  /// Shared persistence used by both the onboarding form and edit screen.
  /// When [reuseExistingPost] is true and a post already exists, that post is
  /// updated in place instead of inserting a new one (avoids duplicate jobs).
  /// First failing required-field message key for the family/job form, or null
  /// when valid. System Spec §3.3 (family) + §3.4 (job post) + §14.4 rules.
  String? validateFamily() {
    if (fullNameCtrl.text.trim().isEmpty) return AppStrings.familyNameRequired;
    if (nationality.value.trim().isEmpty) return AppStrings.familyNationalityRequired;
    if (city.value.trim().isEmpty) return AppStrings.familyCityRequired;
    final childText = childrenCtrl.text.trim();
    final parsedChildren = int.tryParse(childText);
    // A non-numeric entry previously parsed to 0 and silently skipped the ages
    // rule below (FAM-2) — reject it explicitly.
    if (childText.isNotEmpty && (parsedChildren == null || parsedChildren < 0)) {
      return AppStrings.familyChildrenInvalid;
    }
    final childCount = parsedChildren ?? 0;
    final ages = childrenAgesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (childCount > 0 && ages.isEmpty) return AppStrings.familyChildrenAgesRequired;
    if (languages.isEmpty) return AppStrings.familyLanguagesRequired;
    if (roles.isEmpty) return AppStrings.familyRolesRequired;
    if (scheduleCtrl.text.trim().isEmpty) return AppStrings.familyScheduleRequired;
    if (duties.isEmpty) return AppStrings.familyDutiesRequired;
    if (benefits.isEmpty) return AppStrings.familyBenefitsRequired;
    final salErr = Validators.salaryRange(
      int.tryParse(salaryMinCtrl.text) ?? 0,
      int.tryParse(salaryMaxCtrl.text) ?? 0,
    );
    if (salErr != null) return salErr;
    if (trialDays.value <= 0) return AppStrings.familyTrialDaysRequired;
    if ((int.tryParse(trialRateCtrl.text) ?? 0) <= 0) {
      return AppStrings.familyTrialRateRequired;
    }
    return null;
  }

  Future<bool> _persist({bool reuseExistingPost = false}) async {
    final err = validateFamily();
    if (err != null) {
      Get.snackbar(AppStrings.errorTitle.tr, err.tr);
      return false;
    }
    isLoading.value = true;
    try {
      final user = _auth.currentUser.value;
      final fid = user?.id;
      if (fid == null) return false;
      final ages = childrenAgesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final fam = FamilyModel(
        id: fid,
        userId: user?.id ?? fid,
        fullName: fullNameCtrl.text.trim(),
        nationality: nationality.value,
        city: city.value,
        childrenCount: int.tryParse(childrenCtrl.text) ?? 0,
        childrenAges: ages,
        languagesAtHome: List.of(languages),
        hasCameras: hasCameras.value,
        hasPets: petTypes.isNotEmpty,
        petTypes: List.of(petTypes),
        religion: religion.value,
        nannyReligionPreference: religionPref.value,
        houseRules: houseRulesCtrl.text.trim().isEmpty ? null : houseRulesCtrl.text.trim(),
        aboutFamily: aboutFamilyCtrl.text.trim().isEmpty ? null : aboutFamilyCtrl.text.trim(),
      );
      await _user.saveFamily(fam);
      family.value = fam;

      // One active full-time + one active part-time job per family. In edit
      // mode reuse the existing post; on a fresh post block a duplicate of the
      // same employment type (the old one must be closed / reposted first).
      final existingPosts = await _jobs.getJobsByFamily(fid);
      String? existingPostId;
      if (reuseExistingPost) {
        // Save back to the SAME post the form was hydrated from (M6), so
        // editing the second post doesn't overwrite the first.
        if (existingPosts.isNotEmpty) existingPostId = _selectEditPost(existingPosts).id;
      } else {
        final clash = existingPosts.any((j) =>
            j.status == JobPostStatus.active &&
            j.employmentType == employmentType.value);
        if (clash) {
          Get.snackbar(AppStrings.errorTitle.tr, AppStrings.familyJobTypeLimit.tr);
          return false;
        }
      }

      await _jobs.saveJobPost(JobPostModel(
        id: existingPostId ?? _uuid.v4(),
        familyId: fid,
        familyName: fam.fullName.split(' ').first,
        city: city.value,
        rolesNeeded: List.of(roles),
        jobType: jobType.value,
        employmentType: employmentType.value,
        schedule: scheduleCtrl.text.trim(),
        duties: List.of(duties),
        benefits: List.of(benefits),
        salaryMin: int.tryParse(salaryMinCtrl.text) ?? 0,
        salaryMax: int.tryParse(salaryMaxCtrl.text) ?? 0,
        trialDurationDays: trialDays.value,
        trialDailyRate: int.tryParse(trialRateCtrl.text) ?? 0,
        visaSponsorship: visaSponsorship.value,
        commitmentAgreed: commit.value,
      ));
      return true;
    } catch (e) {
      // Log the raw error; show a generic localized message (FAM-1).
      Get.log('family/job save failed: $e', isError: true);
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.profileSaveFailed.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
