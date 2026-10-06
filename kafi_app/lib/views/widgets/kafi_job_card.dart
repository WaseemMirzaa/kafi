import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kafi_app/l10n/app_strings.dart';
import 'package:kafi_app/models/family_model.dart';
import 'package:kafi_app/models/job_post_model.dart';
import 'package:kafi_app/utils/constants/family_constants.dart';
import 'package:kafi_app/views/shared/kafi_theme.dart';
import 'package:kafi_app/views/widgets/kafi_avatar.dart';

/// Job card shown to nannies (Home + Jobs feed). One widget so both screens
/// stay identical. The family photo is a centre-cropped square.
///
class KafiJobCard extends StatelessWidget {
  const KafiJobCard({
    super.key,
    required this.job,
    required this.isHot,
    required this.onTap,
    required this.tags,
  });

  final JobPostModel job;

  /// Strong match → rose border / pink avatar fallback (no number shown; see M8).
  final bool isHot;
  final VoidCallback onTap;
  final List<String> tags;

  static const double _photoSize = 104;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        job.jobType == JobType.liveOut ? AppStrings.jobLiveOut.tr : AppStrings.jobLiveIn.tr;
    final initial = job.familyName.isNotEmpty ? job.familyName[0].toUpperCase() : 'F';

    // Photo on the left (square, centre-cropped); title, details and tags
    // stacked beside it — all in one row, tags no longer drop below the photo.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: isHot ? KafiColors.roseL : const Color(0xFFFFD6E4), width: 1.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x12FF5F96), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        // Photo stays pinned top-left however tall the text column grows.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KafiAvatar(
              photoUrl: FamilyConstants.resolvedPhotoUrl(
                job.familyPhotoUrl,
                job.familyId.isNotEmpty ? job.familyId : job.familyName,
              ),
              fallbackText: initial,
              size: _photoSize,
              radius: 14,
              gradient: isHot
                  ? const [Color(0xFFFF8FAB), Color(0xFFFF5C8A)]
                  : const [Color(0xFFFFB347), Color(0xFFFF8042)],
              fontSize: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$typeLabel ${AppStrings.nannySuffix.tr} · ${job.city}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(17.5, color: KafiColors.td, w: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      '${AppStrings.jobSalaryRange.trParams({
                            'min': '${job.salaryMin}',
                            'max': '${job.salaryMax}',
                          })} · ${job.familyName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KafiTheme.nunito(13.2, color: KafiColors.ts, w: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in tags) _tag(t)],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: KafiColors.roseP,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label,
            style: KafiTheme.nunito(12.4, color: KafiColors.roseD, w: FontWeight.w700)),
      );
}
