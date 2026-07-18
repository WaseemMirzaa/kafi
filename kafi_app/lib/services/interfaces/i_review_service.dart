import 'package:kafi_app/models/review_model.dart';

/// Family↔nanny reviews. A review's `rating` is aggregated into the reviewee's
/// `stats.averageRating` / `reviewsCount` by the `onReviewCreated` Cloud
/// Function (the rules forbid a reviewer from writing the reviewee's doc).
abstract class IReviewService {
  /// Submits a review. Deterministic id (`reviewerId_revieweeId`) keeps it to
  /// one review per pair — a duplicate submit is rejected by the rules.
  Future<void> submitReview(ReviewModel review);

  /// Public reviews left for [revieweeId], newest first.
  Future<List<ReviewModel>> getReviewsFor(String revieweeId);

  /// Whether [reviewerId] has already reviewed [revieweeId].
  Future<bool> hasReviewed(String reviewerId, String revieweeId);
}
