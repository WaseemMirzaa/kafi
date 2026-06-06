import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/config/routes.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:uuid/uuid.dart';

class FamilyProfileController extends GetxController {
  final IUserService _user = Get.find<IUserService>();
  final IJobService _jobs = Get.find<IJobService>();
  final AuthController _auth = Get.find<AuthController>();
  final _uuid = const Uuid();

  final Rx<FamilyModel?> family = Rx<FamilyModel?>(null);
  final RxBool isLoading = false.obs;

  final fullNameCtrl = TextEditingController();
  final RxString nationality = 'Emirati'.obs;
  final RxString city = 'Dubai'.obs;
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
    _hydrateFromCurrentUser();
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
      // Reuse the most recent job post for role/duties/benefits/visa.
      final posts = await _jobs.getJobsByFamily(user.id);
      if (posts.isNotEmpty) {
        final p = posts.first;
        roles.value = List<String>.from(p.rolesNeeded);
        jobType.value = p.jobType;
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
  Future<bool> _persist({bool reuseExistingPost = false}) async {
    if (fullNameCtrl.text.trim().isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.familyNameRequired.tr);
      return false;
    }
    if (city.value.trim().isEmpty) {
      Get.snackbar(AppStrings.errorTitle.tr, AppStrings.familyCityRequired.tr);
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

      String? existingPostId;
      if (reuseExistingPost) {
        final posts = await _jobs.getJobsByFamily(fid);
        if (posts.isNotEmpty) existingPostId = posts.first.id;
      }

      await _jobs.saveJobPost(JobPostModel(
        id: existingPostId ?? _uuid.v4(),
        familyId: fid,
        familyName: fam.fullName.split(' ').first,
        city: city.value,
        rolesNeeded: List.of(roles),
        jobType: jobType.value,
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
      Get.snackbar(AppStrings.errorTitle.tr, e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
