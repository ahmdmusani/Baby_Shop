import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:the_baby_shop/models/order_model.dart';
import 'package:the_baby_shop/providers/order_provider.dart';
import 'package:the_baby_shop/providers/cart_provider.dart';
import 'package:the_baby_shop/theme/app_theme.dart';
import 'package:the_baby_shop/services/auth_service.dart';
import 'order_tracking_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  String _formatDate(DateTime dt) => DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<OrderModel?>
            (stream: orderProvider.orderByIdStream(orderId), builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Order not found'));
          }
          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Number & Date Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt ?? DateTime.now()),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(order.status).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _statusColor(order.status).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(order.status),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Delivery address
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.shippingAddress,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Items list
                const Text(
                  'Items Purchased',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 24, color: AppTheme.borderColor),
                    itemBuilder: (context, idx) {
                      final item = order.items[idx];
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.image,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => const SizedBox(
                                width: 60,
                                height: 60,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
                              ),
                              errorWidget: (ctx, url, err) => Container(
                                width: 60,
                                height: 60,
                                color: AppTheme.backgroundColor,
                                child: const Icon(Icons.image_outlined, size: 24, color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (item.size.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.size,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Text(
                                      'Qty: ${item.qty}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs. ${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Info & Billing Invoice Card
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _invoiceRow('Subtotal', order.subtotal),
                      const SizedBox(height: 8),
                      _invoiceRow('Delivery Fee', order.deliveryFee),
                      if (order.discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _invoiceRow('Discount', -order.discountAmount, valueColor: Colors.green),
                      ],
                      if (order.couponCode != null && order.couponCode!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_offer_rounded,
                                    size: 13, color: Colors.green),
                                const SizedBox(width: 5),
                                Text(
                                  order.couponTitle?.isNotEmpty == true
                                      ? order.couponTitle!
                                      : 'Coupon Applied',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                order.couponCode!,
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24, color: AppTheme.borderColor),
                      _invoiceRow('Total Amount', order.totalAmount, isBold: true),
                      const Divider(height: 24, color: AppTheme.borderColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payment Mode',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            order.paymentMethod,
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    // Reorder button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reorder Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            for (var item in order.items) {
                              cartProvider.addItem(
                                productId: item.productId,
                                name: item.name,
                                image: item.image,
                                price: item.price,
                                size: item.size,
                                quantity: item.qty,
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Items added to cart successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (order.status.toLowerCase() == 'pending') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancel Order'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              final uid = AuthService().currentUser?.uid ?? '';
                              await orderProvider.updateOrderStatus(order.id, 'Cancelled', uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order cancelled successfully'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Tracking button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text('Track Shipment Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)));
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _invoiceRow(String label, double amount, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 14 : 12,
          ),
        ),
        Text(
          amount < 0
              ? '- Rs. ${(-amount).toStringAsFixed(0)}'
              : 'Rs. ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: valueColor ?? (isBold ? AppTheme.primaryColor : AppTheme.textPrimary),
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            fontSize: isBold ? 16 : 13,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

