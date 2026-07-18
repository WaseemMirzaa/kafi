import 'package:kafi_app/config/app_config.dart';
import 'package:kafi_app/models/review_model.dart';
import 'package:kafi_app/services/interfaces/i_review_service.dart';

class MockReviewService implements IReviewService {
  final List<ReviewModel> _reviews = [];

  @override
  Future<void> submitReview(ReviewModel review) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    _reviews.removeWhere((r) =>
        r.reviewerId == review.reviewerId && r.revieweeId == review.revieweeId);
    _reviews.add(review);
  }

  @override
  Future<List<ReviewModel>> getReviewsFor(String revieweeId) async {
    await Future<void>.delayed(AppConfig.mockDelay);
    return _reviews.where((r) => r.revieweeId == revieweeId && r.isPublic).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<bool> hasReviewed(String reviewerId, String revieweeId) async {
    return _reviews
        .any((r) => r.reviewerId == reviewerId && r.revieweeId == revieweeId);
  }
}
