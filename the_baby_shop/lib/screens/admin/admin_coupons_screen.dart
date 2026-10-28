import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/coupon_model.dart';
import '../../providers/coupon_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/coupon_form_bottom_sheet.dart';

class AdminCouponsScreen extends StatelessWidget {
  const AdminCouponsScreen({super.key});

  static const _pink = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CouponProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        shape: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.04), width: 1),
        ),
        title: Text(
          'Coupons',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Promo Codes',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _pink,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Coupon',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        onPressed: () => _openForm(context, null),
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: provider.couponsStream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final coupons = snap.data ?? [];
          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer_rounded,
                        size: 40, color: _pink),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Coupons Yet',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first promo code.',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: coupons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _CouponCard(
              coupon: coupons[i],
              onEdit: () => _openForm(context, coupons[i]),
              onDelete: () => _confirmDelete(context, coupons[i]),
              onToggle: (active) =>
                  provider.toggleActive(coupons[i].id, active),
            ),
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, CouponModel? coupon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CouponProvider>(),
        child: CouponFormBottomSheet(existingCoupon: coupon),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CouponModel coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Coupon',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${coupon.code}"? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<CouponProvider>().deleteCoupon(coupon.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coupon deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final expired = DateTime.now().isAfter(coupon.expiryDate);
    final statusColor = !coupon.active
        ? Colors.grey
        : expired
            ? Colors.orange
            : Colors.green;
    final statusLabel = !coupon.active
        ? 'Inactive'
        : expired
            ? 'Expired'
            : 'Active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: !coupon.active
              ? Colors.grey.shade200
              : expired
                  ? Colors.orange.shade100
                  : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                // Code badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.85),
                        const Color(0xFFFF8FB1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon.code,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    coupon.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Active toggle
                Switch.adaptive(
                  value: coupon.active,
                  activeColor: Colors.green,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),

          // Details row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip(_discountValueLabel(), Icons.discount_rounded,
                    AppTheme.primaryColor),
                if (coupon.minimumOrder > 0)
                  _chip(
                      'Min Rs. ${coupon.minimumOrder.toStringAsFixed(0)}',
                      Icons.shopping_bag_outlined,
                      Colors.blue.shade600),
                _chip(
                    'Used: ${coupon.usedCount}${coupon.usageLimit > 0 ? '/${coupon.usageLimit}' : ''}',
                    Icons.people_outline_rounded,
                    Colors.purple.shade600),
                _chip(
                    statusLabel,
                    Icons.circle,
                    statusColor),
              ],
            ),
          ),

          // Expiry row + action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: Row(
              children: [
                Icon(Icons.event_rounded,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${DateFormat('dd MMM yyyy').format(coupon.expiryDate)}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                _iconBtn(
                    icon: Icons.edit_rounded,
                    color: AppTheme.primaryColor,
                    onTap: onEdit),
                const SizedBox(width: 4),
                _iconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                    onTap: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _discountValueLabel() {
    switch (coupon.discountType) {
      case DiscountType.percentage:
        return '${coupon.discountValue.toStringAsFixed(0)}% OFF';
      case DiscountType.fixed:
        return 'Rs. ${coupon.discountValue.toStringAsFixed(0)} OFF';
      case DiscountType.freeShipping:
        return 'Free Shipping';
    }
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _iconBtn(
      {required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
