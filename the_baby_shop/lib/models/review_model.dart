import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final double productQualityRating;
  final double deliverySpeedRating;
  final double serviceQualityRating;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.productQualityRating = 0.0,
    this.deliverySpeedRating = 0.0,
    this.serviceQualityRating = 0.0,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productQualityRating: (data['productQualityRating'] ?? 0.0).toDouble(),
      deliverySpeedRating: (data['deliverySpeedRating'] ?? 0.0).toDouble(),
      serviceQualityRating: (data['serviceQualityRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
        'productQualityRating': productQualityRating,
        'deliverySpeedRating': deliverySpeedRating,
        'serviceQualityRating': serviceQualityRating,
      };
}
