import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/coupon_provider.dart';
import '../../models/coupon_model.dart';
import '../../theme/app_theme.dart';
import 'checkout_screen.dart';
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add items from the shop to get started on your baby shopping journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 84,
                              height: 84,
                              color: AppTheme.backgroundColor,
                              child: item.image.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: item.image,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.image_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 28,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 28,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Item Info & Controls
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and delete button
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => cart.removeFromCart(item.productId, item.size),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red.shade700,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Size Tag
                                if (item.size.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Size: ${item.size}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],

                                // Price & Quantity selector Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rs. ${(item.price * item.qty).toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.borderColor),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: item.qty > 1
                                                ? () => cart.updateQuantity(
                                                    item.productId, item.size, item.qty - 1)
                                                : null,
                                            borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(12)),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              child: Icon(Icons.remove, size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(
                                              '${item.qty}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: item.qty < item.stock
                                                ? () => cart.updateQuantity(
                                                    item.productId, item.size, item.qty + 1)
                                                : null,
                                            borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(12)),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              child: Icon(Icons.add, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildCheckoutPanel(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckoutPanel(BuildContext context, CartProvider cart) {
    final couponProvider = context.watch<CouponProvider>();
    final coupon = couponProvider.appliedCoupon;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Coupon Input ──────────────────────────────────────────────
            if (coupon == null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) {
                              // Clear error on new input
                              if (couponProvider.validationError != null) {
                                couponProvider.clearError();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary),
                              filled: true,
                              fillColor: AppTheme.backgroundColor,
                              prefixIcon: const Icon(
                                Icons.local_offer_outlined,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: couponProvider.validationError != null
                                    ? const BorderSide(color: Colors.red, width: 1.2)
                                    : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: AppTheme.primaryColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                            ),
                          ),
                        ),
                        if (couponProvider.validationError != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 13, color: Colors.red),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  couponProvider.validationError!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: couponProvider.isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              final code = _couponController.text.trim();
                              if (code.isEmpty) return;
                              final user =
                                  FirebaseAuth.instance.currentUser;
                              if (user == null) return;
                              await couponProvider.applyCoupon(
                                code: code,
                                userId: user.uid,
                                subtotal: cart.subtotal,
                                cartProductIds: cart.items
                                    .map((i) => i.productId)
                                    .toList(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            child: const Text('Apply',
                                style: TextStyle(fontSize: 14, height: 1.2)),
                          ),
                  ),
                ],
              ),
            ] else ...[
              // ── Applied Coupon Chip ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        coupon.code,
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.title,
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _discountLabel(coupon, cart.discountAmount),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        couponProvider.clearCoupon();
                        _couponController.clear();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.green.shade700,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove coupon',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ── Summary Rows ──────────────────────────────────────────────
            _summaryRow('Subtotal', cart.subtotal),
            if (coupon != null) ...[
              if (cart.discountAmount > 0)
                _summaryRow('Discount (${coupon.code})', -cart.discountAmount,
                    valueColor: Colors.green),
              if (coupon.discountType == DiscountType.freeShipping)
                _summaryRow('Shipping Discount', 0,
                    label2: 'FREE', valueColor: Colors.green),
            ],
            _summaryRow('Delivery', cart.deliveryFee),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: AppTheme.borderColor),
            ),
            _summaryRow('Total', cart.total, isBold: true),
            const SizedBox(height: 20),

            // ── Checkout Button ───────────────────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please login to checkout')),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CheckoutScreen()),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _discountLabel(coupon, double discountAmount) {
    switch (coupon.discountType as DiscountType) {
      case DiscountType.percentage:
        return '${coupon.discountValue.toStringAsFixed(0)}% OFF · Save Rs. ${discountAmount.toStringAsFixed(0)}';
      case DiscountType.fixed:
        return 'Rs. ${discountAmount.toStringAsFixed(0)} OFF applied';
      case DiscountType.freeShipping:
        return 'Free shipping applied';
      default:
        return 'Discount applied';
    }
  }

  Widget _summaryRow(String label, double amount,
      {bool isBold = false, Color? valueColor, String? label2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 15 : 13,
            ),
          ),
          Text(
            label2 != null
                ? label2
                : (amount < 0
                    ? '- Rs. ${(-amount).toStringAsFixed(0)}'
                    : 'Rs. ${amount.toStringAsFixed(0)}'),
            style: TextStyle(
              color: valueColor ?? (isBold ? AppTheme.primaryColor : AppTheme.textPrimary),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
