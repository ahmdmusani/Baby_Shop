import 'package:flutter/material.dart';
import '../models/coupon_model.dart';
import '../repositories/coupon_repository.dart';

class CouponProvider extends ChangeNotifier {
  final CouponRepository _repository = CouponRepository();

  CouponModel? _appliedCoupon;
  bool _isLoading = false;
  String? _validationError;

  CouponModel? get appliedCoupon => _appliedCoupon;
  bool get isLoading => _isLoading;
  String? get validationError => _validationError;
  bool get hasCoupon => _appliedCoupon != null;

  // ─── Stream for admin panel ───────────────────────────────────────────────

  Stream<List<CouponModel>> get couponsStream => _repository.couponsStream();

  // ─── Customer-facing ──────────────────────────────────────────────────────

  /// Validates and applies a coupon. Updates [appliedCoupon] on success or
  /// sets [validationError] on failure.
  Future<bool> applyCoupon({
    required String code,
    required String userId,
    required double subtotal,
    required List<String> cartProductIds,
    List<String> cartCategoryIds = const [],
  }) async {
    if (code.trim().isEmpty) {
      _validationError = 'Please enter a coupon code.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _validationError = null;
    notifyListeners();

    try {
      final (coupon, result) = await _repository.validateCoupon(
        code: code,
        userId: userId,
        subtotal: subtotal,
        cartProductIds: cartProductIds,
        cartCategoryIds: cartCategoryIds,
      );

      if (result == CouponValidationResult.valid && coupon != null) {
        _appliedCoupon = coupon;
        _validationError = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Build enriched error for minimum order
        String errorMsg = result.message;
        if (result == CouponValidationResult.minimumOrderNotMet &&
            coupon != null) {
          errorMsg =
              'Minimum order of Rs. ${coupon.minimumOrder.toStringAsFixed(0)} required.';
        }
        _appliedCoupon = null;
        _validationError = errorMsg;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _appliedCoupon = null;
      _validationError = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearCoupon() {
    _appliedCoupon = null;
    _validationError = null;
    notifyListeners();
  }

  void clearError() {
    _validationError = null;
    notifyListeners();
  }

  // ─── Admin CRUD ───────────────────────────────────────────────────────────

  Future<void> createCoupon(CouponModel coupon) async {
    await _repository.createCoupon(coupon);
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    await _repository.updateCoupon(id, data);
  }

  Future<void> deleteCoupon(String id) async {
    await _repository.deleteCoupon(id);
  }

  Future<void> toggleActive(String id, bool active) async {
    await _repository.toggleActive(id, active);
  }

  // ─── Usage recording (called post-order) ─────────────────────────────────

  Future<void> recordUsage(String couponCode, String userId) async {
    await _repository.incrementUsage(couponCode: couponCode, userId: userId);
  }
}
