class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewerType; // 'family' or 'nanny'
  final String revieweeId;
  final String revieweeType; // 'family' or 'nanny'
  final String? trialId;
  final int rating; // 1-5
  final String? comment;
  final DateTime createdAt;
  final bool isPublic;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewerType,
    required this.revieweeId,
    required this.revieweeType,
    this.trialId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.isPublic = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'reviewerId': reviewerId,
        'reviewerType': reviewerType,
        'revieweeId': revieweeId,
        'revieweeType': revieweeType,
        'trialId': trialId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'isPublic': isPublic,
      };

  factory ReviewModel.fromMap(Map<String, dynamic> m) => ReviewModel(
        id: m['id'] as String,
        reviewerId: m['reviewerId'] as String,
        reviewerType: m['reviewerType'] as String,
        revieweeId: m['revieweeId'] as String,
        revieweeType: m['revieweeType'] as String,
        trialId: m['trialId'] as String?,
        rating: m['rating'] as int,
        comment: m['comment'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        isPublic: m['isPublic'] as bool? ?? true,
      );
}
