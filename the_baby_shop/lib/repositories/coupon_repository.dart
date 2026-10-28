import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

class CouponRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _coupons => _firestore.collection('coupons');

  // ─── Streams ─────────────────────────────────────────────────────────────

  Stream<List<CouponModel>> couponsStream() {
    return _coupons
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CouponModel.fromFirestore(doc))
            .toList());
  }

  // ─── Lookup ───────────────────────────────────────────────────────────────

  Future<CouponModel?> getCouponByCode(String code) async {
    final snap = await _coupons
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CouponModel.fromFirestore(snap.docs.first);
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  /// Validates coupon against all business rules. Returns
  /// ([CouponModel?], [CouponValidationResult]).
  Future<(CouponModel?, CouponValidationResult)> validateCoupon({
    required String code,
    required String userId,
    required double subtotal,
    required List<String> cartProductIds,
    required List<String> cartCategoryIds,
  }) async {
    final coupon = await getCouponByCode(code);
    if (coupon == null) return (null, CouponValidationResult.notFound);

    final result = coupon.validate(
      userId: userId,
      subtotal: subtotal,
      cartProductIds: cartProductIds,
      cartCategoryIds: cartCategoryIds,
    );

    // Enrich minimumOrderNotMet message with actual amount
    return (coupon, result);
  }

  // ─── Usage Tracking ───────────────────────────────────────────────────────

  /// Atomically increments usedCount and appends userId to usedBy.
  /// Called after a successful order placement.
  Future<void> incrementUsage({
    required String couponCode,
    required String userId,
  }) async {
    final snap = await _coupons
        .where('code', isEqualTo: couponCode.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;

    final docRef = snap.docs.first.reference;
    await _firestore.runTransaction((tx) async {
      final fresh = await tx.get(docRef);
      if (!fresh.exists) return;

      final data = fresh.data() as Map<String, dynamic>;
      final currentCount = (data['usedCount'] ?? 0) as int;
      final usedBy = List<String>.from(data['usedBy'] ?? []);

      usedBy.add(userId);
      tx.update(docRef, {
        'usedCount': currentCount + 1,
        'usedBy': usedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ─── Admin CRUD ───────────────────────────────────────────────────────────

  Future<void> createCoupon(CouponModel coupon) async {
    await _coupons.add(coupon.toMap());
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _coupons.doc(id).update(data);
  }

  Future<void> deleteCoupon(String id) async {
    await _coupons.doc(id).delete();
  }

  Future<void> toggleActive(String id, bool active) async {
    await _coupons.doc(id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
