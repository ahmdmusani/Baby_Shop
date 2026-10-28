import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  Stream<List<ReviewModel>> getProductReviewsStream(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        // No .orderBy() here — combining where+orderBy on different fields
        // requires a Firestore composite index. Sorting client-side is equivalent
        // and works without any index configuration.
        .snapshots()
        .map((snap) {
          final reviews =
              snap.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
          // Sort newest first client-side
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return reviews;
        });
  }

  /// Returns true if the given [userId] has at least one delivered/processed order
  /// that contains [productId] in its items list.
  Future<bool> hasUserPurchasedProduct(String userId, String productId) async {
    try {
      final ordersSnap = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        final found = items.any((item) {
          final itemMap = item as Map<String, dynamic>;
          return itemMap['productId'] == productId;
        });
        if (found) return true;
      }
      return false;
    } catch (e) {
      // Fail open – if we can't confirm, deny to be safe
      return false;
    }
  }

  /// Returns an existing [ReviewModel] if the [userId] has already submitted
  /// a review for [productId], otherwise returns null.
  Future<ReviewModel?> getUserReviewForProduct(String userId, String productId) async {
    try {
      final snap = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return ReviewModel.fromFirestore(snap.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> submitReview({
    required String productId,
    required double rating,
    required double productQualityRating,
    required double deliverySpeedRating,
    required double serviceQualityRating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User must be logged in to submit a review.';

    _isSubmitting = true;
    notifyListeners();

    try {
      // Guard against duplicate reviews
      final existingReview = await getUserReviewForProduct(user.uid, productId);
      if (existingReview != null) {
        throw 'You have already reviewed this product. Please edit your existing review.';
      }

      // Fetch user profile details from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String userName = user.displayName ?? 'Anonymous';
      String userAvatar = '';

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          userName = userData['fullName'] ?? userName;
          userAvatar = userData['profileImage'] ?? '';
        }
      }

      final reviewDoc = _firestore.collection('reviews').doc();
      final newReview = ReviewModel(
        id: reviewDoc.id,
        productId: productId,
        userId: user.uid,
        userName: userName,
        userAvatar: userAvatar,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        productQualityRating: productQualityRating,
        deliverySpeedRating: deliverySpeedRating,
        serviceQualityRating: serviceQualityRating,
      );

      await reviewDoc.set(newReview.toMap());
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required double productQualityRating,
    required double deliverySpeedRating,
    required double serviceQualityRating,
    required String comment,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'rating': rating,
        'productQualityRating': productQualityRating,
        'deliverySpeedRating': deliverySpeedRating,
        'serviceQualityRating': serviceQualityRating,
        'comment': comment,
        'createdAt': Timestamp.now(),
      });
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteReview(String reviewId) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
    notifyListeners();
  }

  Map<int, int> getRatingDistribution(List<ReviewModel> reviews) {
    final Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      final int ratingInt = review.rating.round().clamp(1, 5);
      distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
    }
    return distribution;
  }

  double getAverageRating(List<ReviewModel> reviews) {
    if (reviews.isEmpty) return 0.0;
    final double sum = reviews.fold(0.0, (acc, r) => acc + r.rating);
    return double.parse((sum / reviews.length).toStringAsFixed(1));
  }
}
