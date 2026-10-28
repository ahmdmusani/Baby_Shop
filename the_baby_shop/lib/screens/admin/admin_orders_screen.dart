import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../widgets/admin/admin_status_chip.dart';
import 'admin_order_details_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  static const _pink = AppTheme.primaryColor;
  static const _statuses = [
    'all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context
            .read<OrderProvider>()
            .setStatusFilter(_statuses[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text('Manage Orders',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          indicator: BoxDecoration(
            color: _pink,
            borderRadius: BorderRadius.circular(20),
          ),
          indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: _statuses
              .map((s) =>
                  Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(s[0].toUpperCase() + s.substring(1)),
                    ),
                  ))
              .toList(),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: provider.filteredOrdersStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.black12),
                  const SizedBox(height: 12),
                  Text('No orders found.',
                      style: GoogleFonts.poppins(color: Colors.black38)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, i) => _OrderTile(order: orders[i]),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final dateStr = order.createdAt != null
        ? DateFormat('MMM dd, yyyy  hh:mm a').format(order.createdAt!)
        : '—';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AdminOrderDetailsScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black38),
                      ),
                      const SizedBox(width: 8),
                      AdminStatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.customerName.isNotEmpty
                        ? order.customerName
                        : 'Customer',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${order.items.length} item(s) • Rs. ${order.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                            color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                        color: Colors.black38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
