import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kafi_app/models/review_model.dart';
import 'package:kafi_app/services/interfaces/i_review_service.dart';

class FirestoreReviewService implements IReviewService {
  final _reviews = FirebaseFirestore.instance.collection('reviews');

  String _pairId(String reviewerId, String revieweeId) => '${reviewerId}_$revieweeId';

  @override
  Future<void> submitReview(ReviewModel review) async {
    // Deterministic id = one review per (reviewer, reviewee). Re-submitting is a
    // doc update, which the rules deny (create-only for the reviewer), so a
    // second review is blocked — the app guards with hasReviewed first.
    final id = _pairId(review.reviewerId, review.revieweeId);
    await _reviews.doc(id).set({
      ...review.toMap(),
      'id': id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<ReviewModel>> getReviewsFor(String revieweeId) async {
    // Filter on revieweeId only (no composite index needed); sort client-side.
    final snap = await _reviews.where('revieweeId', isEqualTo: revieweeId).get();
    final list = snap.docs
        .map((d) => ReviewModel.fromMap({
              ...d.data(),
              'id': d.id,
              'createdAt': _iso(d.data()['createdAt']),
            }))
        .where((r) => r.isPublic)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<bool> hasReviewed(String reviewerId, String revieweeId) async {
    final snap = await _reviews.doc(_pairId(reviewerId, revieweeId)).get();
    return snap.exists;
  }

  /// ReviewModel.fromMap expects an ISO string for createdAt; Firestore returns
  /// a Timestamp on read, so normalise it (falling back to now for a pending
  /// server timestamp on a just-written doc).
  String _iso(dynamic v) {
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is String) return v;
    return DateTime.now().toIso8601String();
  }
}
