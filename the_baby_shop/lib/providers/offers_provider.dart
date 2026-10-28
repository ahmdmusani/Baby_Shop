import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon_model.dart';

/// A lightweight, read-only provider dedicated to customer-facing coupon
/// discovery. Intentionally separate from [CouponProvider] which owns
/// checkout validation and admin CRUD operations.
class OffersProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  List<CouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOffers => _coupons.isNotEmpty;

  /// Returns up to [limit] coupons for the home screen preview.
  List<CouponModel> previewCoupons({int limit = 5}) =>
      _coupons.take(limit).toList();

  /// Fetches active, in-date coupons. Skips refetch if data was loaded
  /// within the last [cacheMinutes] minutes (avoids redundant reads).
  Future<void> fetchOffers({int cacheMinutes = 5, bool forceRefresh = false}) async {
    final now = DateTime.now();
    final isCacheValid = _lastFetched != null &&
        now.difference(_lastFetched!).inMinutes < cacheMinutes;

    if (!forceRefresh && isCacheValid && _coupons.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('coupons')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      final List<CouponModel> active = [];

      for (final doc in snap.docs) {
        try {
          final coupon = CouponModel.fromFirestore(doc);
          // Filter: current date must be within [startDate, expiryDate]
          if (!now.isBefore(coupon.startDate) && !now.isAfter(coupon.expiryDate)) {
            active.add(coupon);
          }
        } catch (_) {
          // Skip malformed documents
        }
      }

      _coupons = active;
      _lastFetched = DateTime.now();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load offers. Please try again.';
      notifyListeners();
    }
  }

  /// Returns a real-time stream of active, in-date coupons.
  /// Used by [OffersScreen] for live updates.
  Stream<List<CouponModel>> get offersStream {
    return _firestore
        .collection('coupons')
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final List<CouponModel> active = [];
      for (final doc in snap.docs) {
        try {
          final coupon = CouponModel.fromFirestore(doc);
          if (!now.isBefore(coupon.startDate) && !now.isAfter(coupon.expiryDate)) {
            active.add(coupon);
          }
        } catch (_) {}
      }
      return active;
    });
  }

  /// Whether a coupon was created within the last [days] days (shown as "New").
  static bool isNewCoupon(CouponModel coupon, {int days = 7}) {
    return DateTime.now().difference(coupon.createdAt).inDays <= days;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
