import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/coupon_model.dart';
import '../../theme/app_theme.dart';

class CouponDetailScreen extends StatelessWidget {
  final CouponModel coupon;

  const CouponDetailScreen({super.key, required this.coupon});

  String _formatDiscount() {
    switch (coupon.discountType) {
      case DiscountType.percentage:
        return '${coupon.discountValue.toStringAsFixed(0)}% OFF';
      case DiscountType.fixed:
        return 'Rs. ${coupon.discountValue.toStringAsFixed(0)} OFF';
      case DiscountType.freeShipping:
        return 'FREE SHIPPING';
    }
  }

  String _formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  Color _discountColor() {
    switch (coupon.discountType) {
      case DiscountType.percentage:
        return const Color(0xFFFF4071);
      case DiscountType.fixed:
        return const Color(0xFF7C6AE8);
      case DiscountType.freeShipping:
        return const Color(0xFF4CAF8A);
    }
  }

  List<Color> _cardGradient() {
    switch (coupon.discountType) {
      case DiscountType.percentage:
        return [const Color(0xFFFF4071), const Color(0xFFFF6B9A)];
      case DiscountType.fixed:
        return [const Color(0xFF7C6AE8), const Color(0xFF9D8FF0)];
      case DiscountType.freeShipping:
        return [const Color(0xFF4CAF8A), const Color(0xFF6DC9A8)];
    }
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Coupon copied successfully.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF8A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _cardGradient();
    final discountColor = _discountColor();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero App Bar ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: gradient.first,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background decorative circle
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -30,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              _formatDiscount(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            coupon.title.isNotEmpty ? coupon.title : coupon.code,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  // Coupon code card (perforated look)
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: _buildCodeCard(context, discountColor),
                  ),
                  // Details section
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Column(
                      children: [
                        _buildDetailCard(discountColor),
                        const SizedBox(height: 12),
                        if (coupon.description.isNotEmpty)
                          _buildDescriptionCard(),
                        const SizedBox(height: 12),
                        _buildValidityCard(),
                        const SizedBox(height: 12),
                        _buildTermsCard(discountColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _buildCopyButton(context, gradient),
        ),
      ),
    );
  }

  Widget _buildCodeCard(BuildContext context, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coupon Code',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        coupon.code,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _copyCode(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: accentColor, size: 14),
                        const SizedBox(width: 5),
                        Text(
                          'Copy',
                          style: GoogleFonts.poppins(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Perforated divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Transform.translate(
                  offset: const Offset(-12, 0),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          (constraints.maxWidth / 14).floor(),
                          (i) => Container(
                            width: 6,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Savings amount
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_rounded, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Save ${_formatDiscount()} on your order',
                  style: GoogleFonts.poppins(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(Color accentColor) {
    final items = <_DetailItem>[];

    if (coupon.minimumOrder > 0) {
      items.add(_DetailItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Minimum Order',
        value: 'Rs. ${coupon.minimumOrder.toStringAsFixed(0)}',
      ));
    }

    if (coupon.maximumDiscount > 0 && coupon.discountType == DiscountType.percentage) {
      items.add(_DetailItem(
        icon: Icons.price_check_rounded,
        label: 'Maximum Discount',
        value: 'Rs. ${coupon.maximumDiscount.toStringAsFixed(0)}',
      ));
    }

    if (coupon.usageLimit > 0) {
      items.add(_DetailItem(
        icon: Icons.people_alt_outlined,
        label: 'Total Usage Limit',
        value: '${coupon.usageLimit} uses',
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      title: 'Offer Details',
      accentColor: accentColor,
      icon: Icons.info_outline_rounded,
      child: Column(
        children: items
            .map((item) => _buildDetailRow(item.icon, item.label, item.value))
            .toList(),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return _buildCard(
      title: 'Description',
      accentColor: AppTheme.primaryColor,
      icon: Icons.description_outlined,
      child: Text(
        coupon.description,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppTheme.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildValidityCard() {
    return _buildCard(
      title: 'Validity Period',
      accentColor: const Color(0xFF4CAF8A),
      icon: Icons.calendar_today_rounded,
      child: Column(
        children: [
          _buildDetailRow(
            Icons.play_circle_outline_rounded,
            'Start Date',
            _formatDate(coupon.startDate),
          ),
          _buildDetailRow(
            Icons.stop_circle_outlined,
            'Expiry Date',
            _formatDate(coupon.expiryDate),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard(Color accentColor) {
    final terms = <String>[];

    if (coupon.minimumOrder > 0) {
      terms.add('Minimum order of Rs. ${coupon.minimumOrder.toStringAsFixed(0)} required.');
    }
    if (coupon.maximumDiscount > 0 && coupon.discountType == DiscountType.percentage) {
      terms.add('Maximum discount capped at Rs. ${coupon.maximumDiscount.toStringAsFixed(0)}.');
    }
    if (coupon.applicableCategories.isNotEmpty) {
      terms.add('Applicable only to specific product categories.');
    }
    if (coupon.applicableProducts.isNotEmpty) {
      terms.add('Applicable only to specific products.');
    }
    if (coupon.perUserLimit > 0) {
      terms.add('Can be used up to ${coupon.perUserLimit} time(s) per user.');
    }
    if (coupon.usageLimit > 0) {
      terms.add('Limited to ${coupon.usageLimit} total uses.');
    }
    terms.add('Coupon cannot be combined with other offers.');
    terms.add('Valid till ${_formatDate(coupon.expiryDate)}.');
    terms.add('The Baby Shop reserves the right to modify or withdraw this offer at any time.');

    return _buildCard(
      title: 'Terms & Conditions',
      accentColor: accentColor,
      icon: Icons.gavel_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: terms.map((term) => _buildTermRow(term)).toList(),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Color accentColor,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermRow(String term) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppTheme.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              term,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, List<Color> gradient) {
    return GestureDetector(
      onTap: () => _copyCode(context),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              'Copy Code: ${coupon.code}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
