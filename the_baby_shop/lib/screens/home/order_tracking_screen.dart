import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_baby_shop/models/order_model.dart';
import 'package:the_baby_shop/providers/order_provider.dart';
import 'package:the_baby_shop/theme/app_theme.dart';
import '../profile/help_support_screen.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  String _formatDate(DateTime? dt) => dt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal()) : '';

  int _getStatusLevel(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 1;
      case 'processing': return 2;
      case 'shipped': return 3;
      case 'out_for_delivery': return 4;
      case 'delivered': return 5;
      case 'cancelled': return -1;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Track Order',
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: orderProvider.orderByIdStream(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Order not found'));
          }
          final order = snapshot.data!;
          final currentLevel = _getStatusLevel(order.status);
          
          if (currentLevel == -1) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cancel_outlined, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Order Cancelled',
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          // Extract times from timeline
          final placedTime = order.statusTimeline['pending'] ?? order.createdAt;
          final confirmedTime = order.statusTimeline['processing'];
          final shippedTime = order.statusTimeline['shipped'];
          final outForDeliveryTime = order.statusTimeline['out_for_delivery'];
          final deliveredTime = order.statusTimeline['delivered'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID Card
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER NUMBER',
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${order.orderNumber}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Stepper Timeline Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
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
                    child: ListView(
                      children: [
                        _buildStep(context, 'Order Placed', placedTime, true, currentLevel > 1),
                        _buildStep(context, 'Confirmed', confirmedTime, currentLevel >= 2, currentLevel > 2),
                        _buildStep(context, 'Shipped', shippedTime, currentLevel >= 3, currentLevel > 3),
                        _buildStep(context, 'Out for Delivery', outForDeliveryTime, currentLevel >= 4, currentLevel > 4),
                        _buildStep(context, 'Delivered', deliveredTime, currentLevel >= 5, false, isLast: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, const Color(0xFFFF6B9A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Need Help?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context, String title, DateTime? time, bool isCompleted, bool isLineActive, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppTheme.primaryColor : Colors.transparent,
                  width: 1,
                ),
                boxShadow: isCompleted 
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: isCompleted 
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                  : const SizedBox(),
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 48,
                color: isLineActive ? AppTheme.primaryColor : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? AppTheme.textPrimary : AppTheme.textSecondary.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              if (time != null)
                Text(
                  _formatDate(time),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                )
              else if (!isCompleted)
                const Text(
                  'Pending',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
