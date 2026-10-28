import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, fixed, freeShipping }

extension DiscountTypeX on DiscountType {
  /// Returns the canonical string used in Firestore and comparisons.
  String get value {
    switch (this) {
      case DiscountType.percentage:
        return 'percentage';
      case DiscountType.fixed:
        return 'fixed';
      case DiscountType.freeShipping:
        return 'freeShipping';
    }
  }

  bool get isFreeShipping => this == DiscountType.freeShipping;
  bool get isPercentage => this == DiscountType.percentage;
  bool get isFixed => this == DiscountType.fixed;
}

enum CouponValidationResult {
  valid,
  notFound,
  inactive,
  expired,
  notStarted,
  usageLimitReached,
  perUserLimitReached,
  minimumOrderNotMet,
  notApplicable,
}

extension CouponValidationResultMessage on CouponValidationResult {
  String get message {
    switch (this) {
      case CouponValidationResult.valid:
        return 'Coupon applied successfully!';
      case CouponValidationResult.notFound:
        return 'Invalid coupon code. Please check and try again.';
      case CouponValidationResult.inactive:
        return 'This coupon is currently inactive.';
      case CouponValidationResult.expired:
        return 'This coupon has expired.';
      case CouponValidationResult.notStarted:
        return 'This coupon is not yet valid.';
      case CouponValidationResult.usageLimitReached:
        return 'This coupon has reached its usage limit.';
      case CouponValidationResult.perUserLimitReached:
        return 'You have already used this coupon.';
      case CouponValidationResult.minimumOrderNotMet:
        return 'Minimum order amount not met.';
      case CouponValidationResult.notApplicable:
        return 'This coupon is not applicable to your cart items.';
    }
  }
}

class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double minimumOrder;
  final double maximumDiscount;
  final DateTime startDate;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;
  final int perUserLimit;
  final List<String> usedBy;
  final List<String> applicableCategories;
  final List<String> applicableProducts;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrder,
    required this.maximumDiscount,
    required this.startDate,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    required this.perUserLimit,
    required this.usedBy,
    required this.applicableCategories,
    required this.applicableProducts,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computes the discount amount for a given subtotal (never negative, never
  /// exceeds subtotal, capped by maximumDiscount when set).
  double computeDiscount(double subtotal) {
    if (discountType == DiscountType.freeShipping) return 0.0;
    double discount = discountType == DiscountType.percentage
        ? subtotal * (discountValue / 100)
        : discountValue;
    if (maximumDiscount > 0 && discount > maximumDiscount) {
      discount = maximumDiscount;
    }
    if (discount > subtotal) discount = subtotal;
    return discount;
  }

  /// Validates the coupon against business rules. Returns a
  /// [CouponValidationResult] indicating the outcome.
  CouponValidationResult validate({
    required String userId,
    required double subtotal,
    required List<String> cartProductIds,
    required List<String> cartCategoryIds,
  }) {
    final now = DateTime.now();

    if (!active) return CouponValidationResult.inactive;
    if (now.isBefore(startDate)) return CouponValidationResult.notStarted;
    if (now.isAfter(expiryDate)) return CouponValidationResult.expired;
    if (usageLimit > 0 && usedCount >= usageLimit) {
      return CouponValidationResult.usageLimitReached;
    }
    if (perUserLimit > 0 && usedBy.where((uid) => uid == userId).length >= perUserLimit) {
      return CouponValidationResult.perUserLimitReached;
    }
    if (minimumOrder > 0 && subtotal < minimumOrder) {
      return CouponValidationResult.minimumOrderNotMet;
    }

    // Product / category scoping (empty list = applicable to all)
    if (applicableProducts.isNotEmpty) {
      final hasMatch = cartProductIds.any((id) => applicableProducts.contains(id));
      if (!hasMatch) return CouponValidationResult.notApplicable;
    }
    if (applicableCategories.isNotEmpty) {
      final hasMatch = cartCategoryIds.any((id) => applicableCategories.contains(id));
      if (!hasMatch) return CouponValidationResult.notApplicable;
    }

    return CouponValidationResult.valid;
  }

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CouponModel(
      id: doc.id,
      code: d['code'] ?? '',
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      discountType: _parseDiscountType(d['discountType']),
      discountValue: (d['discountValue'] ?? 0.0).toDouble(),
      minimumOrder: (d['minimumOrder'] ?? 0.0).toDouble(),
      maximumDiscount: (d['maximumDiscount'] ?? 0.0).toDouble(),
      startDate: (d['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (d['expiryDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 365)),
      usageLimit: (d['usageLimit'] ?? 0).toInt(),
      usedCount: (d['usedCount'] ?? 0).toInt(),
      perUserLimit: (d['perUserLimit'] ?? 0).toInt(),
      usedBy: List<String>.from(d['usedBy'] ?? []),
      applicableCategories: List<String>.from(d['applicableCategories'] ?? []),
      applicableProducts: List<String>.from(d['applicableProducts'] ?? []),
      active: d['active'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code.toUpperCase(),
        'title': title,
        'description': description,
        'discountType': discountType.value,
        'discountValue': discountValue,
        'minimumOrder': minimumOrder,
        'maximumDiscount': maximumDiscount,
        'startDate': Timestamp.fromDate(startDate),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'usageLimit': usageLimit,
        'usedCount': usedCount,
        'perUserLimit': perUserLimit,
        'usedBy': usedBy,
        'applicableCategories': applicableCategories,
        'applicableProducts': applicableProducts,
        'active': active,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  CouponModel copyWith({
    String? code,
    String? title,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    double? minimumOrder,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? expiryDate,
    int? usageLimit,
    int? usedCount,
    int? perUserLimit,
    List<String>? usedBy,
    List<String>? applicableCategories,
    List<String>? applicableProducts,
    bool? active,
    DateTime? updatedAt,
  }) {
    return CouponModel(
      id: id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      usedBy: usedBy ?? this.usedBy,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      applicableProducts: applicableProducts ?? this.applicableProducts,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DiscountType _parseDiscountType(String? value) {
    switch (value) {
      case 'fixed':
        return DiscountType.fixed;
      case 'freeShipping':
        return DiscountType.freeShipping;
      default:
        return DiscountType.percentage;
    }
  }
}
