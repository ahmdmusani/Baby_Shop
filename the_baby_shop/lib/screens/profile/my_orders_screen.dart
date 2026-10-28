import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../home/order_detail_screen.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'My Orders',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Past History'),
            ],
          ),
        ),
        body: userId == null
            ? const Center(child: Text('Please log in to view orders.'))
            : TabBarView(
                children: [
                  _OrdersList(userId: userId, isActive: true),
                  _OrdersList(userId: userId, isActive: false),
                ],
              ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final String userId;
  final bool isActive;

  const _OrdersList({required this.userId, required this.isActive});

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 44,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isActive ? 'No active orders' : 'No past orders', 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return StreamBuilder<List<OrderModel>>(
      stream: orderProvider.userOrdersStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final orders = snapshot.data!.where((order) {
          final status = order.status.toLowerCase();
          final isDeliveredOrCancelled = status == 'delivered' || status == 'cancelled';
          return isActive ? !isDeliveredOrCancelled : isDeliveredOrCancelled;
        }).toList();

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final orderId = order.id;
            final status = order.status;
            final dateStr = order.createdAt != null 
                ? DateFormat('MMM dd, yyyy').format(order.createdAt!) 
                : 'Unknown Date';

            Color statusColor;
            switch (status.toLowerCase()) {
              case 'pending':
                statusColor = Colors.orange;
                break;
              case 'processing':
                statusColor = Colors.orangeAccent;
                break;
              case 'shipped':
                statusColor = Colors.blue;
                break;
              case 'delivered':
                statusColor = Colors.green;
                break;
              case 'cancelled':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            final int itemsCount = order.items.fold(0, (sum, item) => sum + item.qty);
            final double rawAmount = order.totalAmount;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: orderId),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : orderId.substring(orderId.length > 8 ? orderId.length - 8 : 0).toUpperCase()}', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)
                            ),
                            Text(dateStr, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const Divider(height: 24, color: AppTheme.borderColor),
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${itemsCount} Items', 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs. ${rawAmount.toStringAsFixed(0)}', 
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primaryColor)
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
