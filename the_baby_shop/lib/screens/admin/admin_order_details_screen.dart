import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/admin/admin_status_chip.dart';
import '../../widgets/admin/status_history_timeline.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final String orderId;
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  static const _pink = AppTheme.primaryColor;
  static const _statuses = [
    'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  ];
  String? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text('Order Details',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: provider.orderByIdStream(widget.orderId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }
          if (!snap.hasData || snap.data == null) {
            return Center(
                child: Text('Order not found.',
                    style: GoogleFonts.poppins()));
          }
          final order = snap.data!;
          _selectedStatus ??= order.status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID & Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id.substring(0, 8).toUpperCase()}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF2D3142)),
                          ),
                          AdminStatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (order.createdAt != null)
                        Text(
                          DateFormat('MMMM dd, yyyy  hh:mm a')
                              .format(order.createdAt!),
                          style: GoogleFonts.poppins(
                              color: Colors.black38, fontSize: 12),
                        ),
                      const Divider(height: 24),
                      _infoRow(Icons.person_rounded, 'Customer',
                          order.customerName.isNotEmpty
                              ? order.customerName
                              : '—'),
                      const SizedBox(height: 10),
                      _infoRow(Icons.receipt_rounded, 'Total Items',
                          '${order.items.length} item(s)'),
                      const SizedBox(height: 10),
                      _infoRow('Rs', 'Total Amount',
                          currency.format(order.totalAmount)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Shipping & Payment Details Card
                _sectionTitle('Shipping & Payment'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(Icons.location_on_rounded, 'Address',
                          order.shippingAddress.isNotEmpty ? order.shippingAddress : 'No shipping address provided'),
                      const SizedBox(height: 12),
                      _infoRow(Icons.payment_rounded, 'Method',
                          order.paymentMethod.isNotEmpty ? order.paymentMethod : 'Not specified'),
                      const SizedBox(height: 12),
                      _infoRow(Icons.monetization_on_rounded, 'Payment Status',
                          order.paymentStatus.isNotEmpty ? order.paymentStatus : 'Pending'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Items list
                _sectionTitle('Ordered Items'),
                const SizedBox(height: 12),
                ...order.items.map((item) => _OrderItemTile(item: item)),

                const SizedBox(height: 20),

                // Status update Card
                _sectionTitle('Update Status'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: const Color(0xFF2D3142)),
                        items: _statuses
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                    s[0].toUpperCase() + s.substring(1),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedStatus = v),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ||
                                  _selectedStatus == order.status
                              ? null
                              : () async {
                                  final adminUid = FirebaseAuth
                                      .instance.currentUser?.uid ?? '';
                                  await provider.updateOrderStatus(
                                    order.id,
                                    _selectedStatus!,
                                    adminUid,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Order status updated!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : Text('Confirm Update',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold, height: 1.2)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status history timeline Card
                _sectionTitle('Status History'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: StatusHistoryTimeline(
                      history: order.statusHistory),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: const Color(0xFF2D3142)),
      );

  Widget _infoRow(dynamic iconOrText, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: iconOrText is IconData
                ? Icon(iconOrText, size: 18, color: AppTheme.primaryColor)
                : SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: Text(
                        iconOrText as String,
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: Colors.black45),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _OrderItemTile extends StatelessWidget {
  final OrderItemModel item;
  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF2D3142)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Qty: ${item.qty}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(
            currency.format(item.price * item.qty),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}
