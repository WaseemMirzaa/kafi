import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/nanny_model.dart';
import 'package:kafi_app/utils/constants/nanny_constants.dart';

/// One row of the nanny Profile Quality checklist (System Spec §3.2).
class ProfileQualityFactor {
  const ProfileQualityFactor({
    required this.labelKey,
    required this.points,
    required this.done,
  });

  /// [AppStrings] key — use `.tr` in the UI.
  final String labelKey;
  final int points;
  final bool done;
}

/// Live profile-quality breakdown. Factors sum to 100 when all are done.
class ProfileQualityScore {
  const ProfileQualityScore(this.factors);

  final List<ProfileQualityFactor> factors;

  int get totalScore {
    var sum = 0;
    for (final f in factors) {
      if (f.done) sum += f.points;
    }
    return sum.clamp(0, 100);
  }

  List<ProfileQualityFactor> get remaining =>
      factors.where((f) => !f.done).toList(growable: false);

  /// Builds the checklist from the current nanny profile (System Spec §3.2).
  factory ProfileQualityScore.fromNanny(NannyModel? n) {
    final photos = n?.photoUrls ?? const <String>[];
    final hasPassport = n?.documents.any(
          (d) => d.type == DocumentType.passport && d.status != DocumentStatus.missing,
        ) ??
        false;
    final profileComplete =
        (n?.fullName.isNotEmpty ?? false) && photos.isNotEmpty && hasPassport;
    final recentlyActive = () {
      final at = n?.lastActiveAt;
      if (at == null) return false;
      return DateTime.now().difference(at).inDays <= NannyConstants.recentlyActiveDays;
    }();
    final hasPolice = n?.documents.any(
          (d) =>
              d.type == DocumentType.policeClearance &&
              d.status != DocumentStatus.missing,
        ) ??
        false;
    final hasCert = n?.documents.any(
          (d) =>
              d.type == DocumentType.trainingCert && d.status != DocumentStatus.missing,
        ) ??
        false;

    return ProfileQualityScore([
      ProfileQualityFactor(
        labelKey: AppStrings.qcProfileComplete,
        points: NannyConstants.scoreProfileComplete,
        done: profileComplete,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcVerifiedBadge,
        points: NannyConstants.scoreVerified,
        done: n?.isVerified ?? false,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcVideoUploaded,
        points: NannyConstants.scoreVideo,
        done: (n?.introVideoUrl ?? '').isNotEmpty,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcMultiplePhotos,
        points: NannyConstants.scoreMultiplePhotos,
        done: photos.length > 1,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcPoliceClearance,
        points: NannyConstants.scorePoliceClearance,
        done: hasPolice,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcTrainingCert,
        points: NannyConstants.scoreTrainingCert,
        done: hasCert,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcRecentlyActive,
        points: NannyConstants.scoreLoginBonus,
        done: recentlyActive,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcReferences,
        points: NannyConstants.scoreReferences,
        done: n?.references.isNotEmpty ?? false,
      ),
      ProfileQualityFactor(
        labelKey: AppStrings.qcWorkExperience,
        points: NannyConstants.scoreWorkExperience,
        done: n?.experiences.isNotEmpty ?? false,
      ),
    ]);
  }
}
