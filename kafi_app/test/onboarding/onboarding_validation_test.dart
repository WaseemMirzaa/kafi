import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:kafi_app/controllers/auth_controller.dart';
import 'package:kafi_app/controllers/family_profile_controller.dart';
import 'package:kafi_app/controllers/nanny_profile_controller.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/services/interfaces/i_auth_service.dart';
import 'package:kafi_app/services/interfaces/i_hire_service.dart';
import 'package:kafi_app/services/interfaces/i_job_service.dart';
import 'package:kafi_app/services/interfaces/i_storage_service.dart';
import 'package:kafi_app/services/interfaces/i_trial_service.dart';
import 'package:kafi_app/services/interfaces/i_user_service.dart';
import 'package:kafi_app/services/location_service.dart';
import 'package:kafi_app/services/mock/mock_auth_service.dart';
import 'package:kafi_app/services/mock/mock_hire_service.dart';
import 'package:kafi_app/services/mock/mock_job_service.dart';
import 'package:kafi_app/services/mock/mock_storage_service.dart';
import 'package:kafi_app/services/mock/mock_trial_service.dart';
import 'package:kafi_app/services/mock/mock_user_service.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mandatory required-field validation for every onboarding screen — the gates
/// that decide what is allowed to be written to Firestore (`saveNanny` /
/// `saveFamily` / `saveJobPost`). If a gate passes, the controller writes the
/// profile; if it fails, nothing is written. Each validator reads only form
/// state, so we drive the REAL controllers with mock services and assert the
/// exact l10n error key for each missing field.
///
/// Spec §3.2 (nanny profile), §3.3/§3.4 (family + job post), §14.4 (rules).
///
/// Note: the Experience (N07) and References (N08) steps have no mandatory
/// required-field gate in the current implementation, so there is nothing to
/// assert there (tracked separately in docs/BACKEND_IMPLEMENTATION_PLAN.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void bindNanny() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put<IAuthService>(MockAuthService());
    Get.put<IUserService>(MockUserService());
    Get.put<IStorageService>(MockStorageService());
    // NannyProfileController resolves the hire + trial services in its field
    // initializers (for the home employment-status card), so they must be
    // registered before it is constructed.
    Get.put<IHireService>(MockHireService());
    Get.put<ITrialService>(MockTrialService());
    Get.put(AuthController());
  }

  void bindFamily() {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    Get.put<IAuthService>(MockAuthService());
    Get.put<IUserService>(MockUserService());
    Get.put<IJobService>(MockJobService());
    Get.put(LocationService());
    Get.put(AuthController());
  }

  // ════════════════ Nanny · About You (N05) ════════════════
  group('Nanny onboarding · About You (N05) — required fields', () {
    late NannyProfileController c;

    setUp(() {
      bindNanny();
      c = NannyProfileController();
      _fillValidPersonalInfo(c);
    });
    tearDown(Get.reset);

    test('all required fields filled → passes', () {
      expect(c.validatePersonalInfo(), isNull);
    });
    test('missing full name is rejected', () {
      c.fullNameCtrl.text = '   ';
      expect(c.validatePersonalInfo(), AppStrings.nannyFullNameRequired);
    });
    test('no date of birth is rejected', () {
      c.dob.value = null;
      expect(c.validatePersonalInfo(), AppStrings.nannyDobRequired);
    });
    test('under-18 date of birth is rejected', () {
      c.setDob(DateTime(2020, 1, 1));
      expect(c.validatePersonalInfo(), AppStrings.valAgeMin18);
    });
    test('empty nationality is rejected', () {
      c.nationality.value = '';
      expect(c.validatePersonalInfo(), AppStrings.nannyNationalityRequired);
    });
    test('no languages selected is rejected', () {
      c.selectedLanguages.clear();
      expect(c.validatePersonalInfo(), AppStrings.nannyLanguagesRequired);
    });
    test('no visa status is rejected', () {
      c.visaStatus.value = null;
      expect(c.validatePersonalInfo(), AppStrings.nannyVisaRequired);
    });
    test('no work emirate is rejected', () {
      c.workEmirates.clear();
      expect(c.validatePersonalInfo(), AppStrings.nannyEmiratesRequired);
    });
    test('empty current area is rejected', () {
      c.currentEmirate.value = null;
      expect(c.validatePersonalInfo(), AppStrings.nannyCurrentAreaRequired);
    });
    test('inverted salary range is rejected', () {
      c.salaryMinCtrl.text = '3000';
      c.salaryMaxCtrl.text = '2000';
      expect(c.validatePersonalInfo(), AppStrings.valSalaryOrder);
    });
    test('zero salary is rejected', () {
      c.salaryMinCtrl.text = '0';
      expect(c.validatePersonalInfo(), AppStrings.valRequired);
    });
    test('availability "from" without a date is rejected', () {
      c.availability.value = AvailabilityStatus.availableFrom;
      c.availableFrom.value = null;
      expect(c.validatePersonalInfo(), AppStrings.nannyAvailableFromRequired);
    });
    test('no marital status is rejected', () {
      c.maritalStatus.value = null;
      expect(c.validatePersonalInfo(), AppStrings.nannyMaritalRequired);
    });
    test('has children but count < 1 is rejected', () {
      c.hasChildren.value = true;
      c.childrenCountCtrl.text = '0';
      expect(c.validatePersonalInfo(), AppStrings.nannyChildrenCountRequired);
    });
    test('empty bio is rejected', () {
      c.bioCtrl.text = '';
      expect(c.validatePersonalInfo(), AppStrings.nannyBioRequired);
    });
    test('no employment type is rejected', () {
      c.employmentTypes.clear();
      expect(c.validatePersonalInfo(), AppStrings.nannyEmploymentTypeRequired);
    });
    test('part-time with no availability is rejected', () {
      c.employmentTypes.assignAll([EmploymentType.partTime]);
      expect(c.validatePersonalInfo(), AppStrings.nannyPartTimeAvailabilityRequired);
    });
    test('part-time with a day and times passes', () {
      c.employmentTypes.assignAll([EmploymentType.partTime]);
      c.partTimeAvailability
          .add(DayAvailability(weekday: 1, from: '08:00', until: '17:00'));
      expect(c.validatePersonalInfo(), isNull);
    });
  });

  // ════════════════ Nanny · Photos & video (N06) ════════════════
  group('Nanny onboarding · Photos & video (N06) — required', () {
    late NannyProfileController c;
    final enough =
        List.generate(NannyConstants.minPhotos, (i) => 'https://p$i.jpg');
    final tooFew =
        List.generate(NannyConstants.minPhotos - 1, (i) => 'https://p$i.jpg');

    setUp(() {
      bindNanny();
      c = NannyProfileController();
    });
    tearDown(Get.reset);

    test('step 1 (personal info) must be saved first', () {
      expect(c.validateMedia(), AppStrings.nannyCompleteStep1);
    });
    test('fewer than the minimum photos is rejected', () {
      c.nanny.value = NannyModel(id: 'n', userId: 'n');
      c.photoUrls.assignAll(tooFew);
      c.introVideoUrl.value = 'https://v.mp4';
      expect(c.validateMedia(), AppStrings.nannyPhotosMin3);
    });
    test('a missing intro video is rejected', () {
      c.nanny.value = NannyModel(id: 'n', userId: 'n');
      c.photoUrls.assignAll(enough);
      c.introVideoUrl.value = null;
      expect(c.validateMedia(), AppStrings.nannyVideoRequired);
    });
    test('enough photos + a video → passes', () {
      c.nanny.value = NannyModel(id: 'n', userId: 'n');
      c.photoUrls.assignAll(enough);
      c.introVideoUrl.value = 'https://v.mp4';
      expect(c.validateMedia(), isNull);
    });
  });

  // ════════════════ Nanny · Documents (N09) ════════════════
  group('Nanny onboarding · Documents (N09) — passport + visa required', () {
    late NannyProfileController c;
    setUp(() {
      bindNanny();
      c = NannyProfileController();
    });
    tearDown(Get.reset);

    NannyDocument uploaded(DocumentType t) =>
        NannyDocument(type: t, status: DocumentStatus.uploaded);

    test('all documents missing → not submittable', () {
      expect(c.hasRequiredDocs, isFalse);
    });
    test('passport alone is not enough', () {
      c.documents[DocumentType.passport] = uploaded(DocumentType.passport);
      expect(c.hasRequiredDocs, isFalse);
    });
    test('passport + visa uploaded → submittable', () {
      c.documents[DocumentType.passport] = uploaded(DocumentType.passport);
      c.documents[DocumentType.visa] = uploaded(DocumentType.visa);
      expect(c.hasRequiredDocs, isTrue);
    });
  });

  // ════════════════ Family · Job & family form (F05) ════════════════
  group('Family onboarding · Job & family form (F05) — required fields', () {
    late FamilyProfileController c;
    setUp(() {
      bindFamily();
      c = FamilyProfileController();
      _fillValidFamily(c);
    });
    tearDown(Get.reset);

    test('all required fields filled → passes', () {
      expect(c.validateFamily(), isNull);
    });
    test('missing family name is rejected', () {
      c.fullNameCtrl.text = '';
      expect(c.validateFamily(), AppStrings.familyNameRequired);
    });
    test('empty nationality is rejected', () {
      c.nationality.value = '';
      expect(c.validateFamily(), AppStrings.familyNationalityRequired);
    });
    test('empty city is rejected', () {
      c.city.value = '';
      expect(c.validateFamily(), AppStrings.familyCityRequired);
    });
    test('children present but no ages is rejected', () {
      c.childrenCtrl.text = '2';
      c.childrenAgesCtrl.text = '';
      expect(c.validateFamily(), AppStrings.familyChildrenAgesRequired);
    });
    test('zero children needs no ages → passes', () {
      c.childrenCtrl.text = '0';
      c.childrenAgesCtrl.text = '';
      expect(c.validateFamily(), isNull);
    });
    test('no languages is rejected', () {
      c.languages.clear();
      expect(c.validateFamily(), AppStrings.familyLanguagesRequired);
    });
    test('no roles is rejected', () {
      c.roles.clear();
      expect(c.validateFamily(), AppStrings.familyRolesRequired);
    });
    test('empty schedule is rejected', () {
      c.scheduleCtrl.text = '';
      expect(c.validateFamily(), AppStrings.familyScheduleRequired);
    });
    test('no duties is rejected', () {
      c.duties.clear();
      expect(c.validateFamily(), AppStrings.familyDutiesRequired);
    });
    test('no benefits is rejected', () {
      c.benefits.clear();
      expect(c.validateFamily(), AppStrings.familyBenefitsRequired);
    });
    test('inverted salary range is rejected', () {
      c.salaryMinCtrl.text = '3000';
      c.salaryMaxCtrl.text = '2000';
      expect(c.validateFamily(), AppStrings.valSalaryOrder);
    });
    test('non-positive trial days is rejected', () {
      c.trialDays.value = 0;
      expect(c.validateFamily(), AppStrings.familyTrialDaysRequired);
    });
    test('non-positive trial rate is rejected', () {
      c.trialRateCtrl.text = '0';
      expect(c.validateFamily(), AppStrings.familyTrialRateRequired);
    });
  });
}

/// Fills every required About-You field with a valid value so each test can
/// break exactly one and assert its error.
void _fillValidPersonalInfo(NannyProfileController c) {
  c.fullNameCtrl.text = 'Maria Santos';
  c.setDob(DateTime(1995, 6, 15));
  c.nationality.value = 'Filipino';
  c.selectedLanguages.assignAll(['English']);
  c.visaStatus.value = VisaStatus.ownResidence;
  c.workEmirates.assignAll([Emirate.dubai]);
  c.currentEmirate.value = Emirate.dubai;
  c.salaryMinCtrl.text = '2000';
  c.salaryMaxCtrl.text = '3000';
  c.availability.value = AvailabilityStatus.availableNow;
  c.maritalStatus.value = MaritalStatus.single;
  c.hasChildren.value = false;
  c.employmentTypes.assignAll([EmploymentType.fullTimeLiveIn]);
  c.bioCtrl.text = 'Experienced and caring nanny who loves children.';
}

/// Fills every required family/job field (some have sensible defaults already).
void _fillValidFamily(FamilyProfileController c) {
  c.fullNameCtrl.text = 'Al Mansoori';
  c.city.value = 'Dubai';
  c.childrenCtrl.text = '2';
  c.childrenAgesCtrl.text = '3, 5';
  c.scheduleCtrl.text = 'Mon-Fri, 8am-6pm';
  c.duties.assignAll(['Cooking', 'School runs']);
  c.benefits.assignAll(['Health insurance']);
  // nationality ('Emirati'), languages, roles, salary, trial days/rate use the
  // controller's valid defaults.
}
