import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/coupon_model.dart';
import '../models/product_model.dart';
import '../providers/coupon_provider.dart';

class CartItem {
  final String productId;
  final String productName;
  final String image;
  final double price;
  final String size;
  final int qty;
  final int stock;
  final String? categoryId;

  CartItem({
    required this.productId,
    required this.productName,
    required this.image,
    required this.price,
    required this.size,
    required this.qty,
    required this.stock,
    this.categoryId,
  });

  CartItem copyWith({int? qty}) {
    return CartItem(
      productId: productId,
      productName: productName,
      image: image,
      price: price,
      size: size,
      qty: qty ?? this.qty,
      stock: stock,
      categoryId: categoryId,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'image': image,
        'price': price,
        'size': size,
        'qty': qty,
        'stock': stock,
        if (categoryId != null) 'categoryId': categoryId,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      image: map['image'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      size: map['size'] ?? '',
      qty: (map['qty'] ?? 1).toInt(),
      stock: (map['stock'] ?? 99).toInt(),
      categoryId: map['categoryId'] as String?,
    );
  }
}

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CouponProvider _couponProvider;

  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // ─── Coupon passthrough ────────────────────────────────────────────────────

  CouponModel? get appliedCoupon => _couponProvider.appliedCoupon;
  bool get hasCoupon => _couponProvider.hasCoupon;

  // ─── Cart totals ──────────────────────────────────────────────────────────

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.qty));

  double get discountAmount {
    final coupon = _couponProvider.appliedCoupon;
    if (coupon == null) return 0.0;
    return coupon.computeDiscount(subtotal);
  }

  double get deliveryFee {
    if (subtotal <= 0) return 0.0;
    // Free shipping if coupon type is freeShipping
    final coupon = _couponProvider.appliedCoupon;
    if (coupon != null && coupon.discountType == DiscountType.freeShipping) {
      return 0.0;
    }
    return subtotal > 1000 ? 0.0 : 50.0;
  }

  double get total => (subtotal - discountAmount + deliveryFee).clamp(0.0, double.infinity);

  // ─── Legacy coupon getters (kept for backward-compat read-only) ───────────

  String? get couponCode => _couponProvider.appliedCoupon?.code;

  CartProvider(this._couponProvider) {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadCartFromFirestore(user.uid);
      } else {
        _items = [];
        _couponProvider.clearCoupon();
        notifyListeners();
      }
    });

    // Rebuild cart totals whenever coupon state changes
    _couponProvider.addListener(() => notifyListeners());
  }

  Future<void> addToCart(ProductModel product, String size, int qty) async {
    final hasDiscount = product.discountPrice > 0 && product.discountPrice < product.price;
    final itemPrice = hasDiscount ? product.discountPrice : product.price;

    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id && item.size == size,
    );

    if (existingIndex >= 0) {
      final existingItem = _items[existingIndex];
      final newQty = (existingItem.qty + qty).clamp(1, product.stock);
      _items[existingIndex] = existingItem.copyWith(qty: newQty);
    } else {
      _items.add(
        CartItem(
          productId: product.id,
          productName: product.productName,
          image: product.image,
          price: itemPrice,
          size: size,
          qty: qty.clamp(1, product.stock),
          stock: product.stock,
        ),
      );
    }

    notifyListeners();
    _saveCartToFirestore();
  }

  Future<void> removeFromCart(String productId, String size) async {
    _items.removeWhere((item) => item.productId == productId && item.size == size);
    notifyListeners();
    _saveCartToFirestore();
  }

  Future<void> updateQuantity(String productId, String size, int newQty) async {
    final index = _items.indexWhere(
      (item) => item.productId == productId && item.size == size,
    );
    if (index >= 0) {
      final item = _items[index];
      final finalQty = newQty.clamp(1, item.stock);
      _items[index] = item.copyWith(qty: finalQty);
      notifyListeners();
      _saveCartToFirestore();
    }
  }

  void clearCoupon() => _couponProvider.clearCoupon();

  Future<void> clearCart() async {
    _items = [];
    _couponProvider.clearCoupon();
    notifyListeners();
    _saveCartToFirestore();
  }

  /// Adds an item to the cart using individual parameters.
  Future<void> addItem({
    required String productId,
    required String name,
    required String image,
    required double price,
    required String size,
    required int quantity,
    int stock = 0,
    String? categoryId,
  }) async {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == productId && item.size == size,
    );
    if (existingIndex >= 0) {
      final existingItem = _items[existingIndex];
      final newQty =
          (existingItem.qty + quantity).clamp(1, stock > 0 ? stock : existingItem.stock);
      _items[existingIndex] = existingItem.copyWith(qty: newQty);
    } else {
      _items.add(CartItem(
        productId: productId,
        productName: name,
        image: image,
        price: price,
        size: size,
        qty: quantity,
        stock: stock,
        categoryId: categoryId,
      ));
    }
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> _saveCartToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final cartData = _items.map((item) => item.toMap()).toList();
      await _firestore.collection('users').doc(user.uid).set({
        'cart': cartData,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving cart to Firestore: $e');
    }
  }

  Future<void> _loadCartFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['cart'] != null) {
          final cartListRaw = data['cart'] as List<dynamic>;
          _items = cartListRaw
              .map((e) => CartItem.fromMap(e as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cart from Firestore: $e');
    }
  }
}
