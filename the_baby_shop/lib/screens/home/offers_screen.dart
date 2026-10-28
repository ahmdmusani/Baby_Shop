import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/coupon_model.dart';
import '../../providers/offers_provider.dart';
import '../../theme/app_theme.dart';
import 'coupon_detail_screen.dart';

/// Full-screen "See All" offers page, opened when the user taps
/// "See All" in the home screen offers section.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: StreamBuilder<List<CouponModel>>(
        stream: context.read<OffersProvider>().offersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(context);
          }

          final coupons = snapshot.data ?? [];

          if (coupons.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () =>
                context.read<OffersProvider>().fetchOffers(forceRefresh: true),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              physics: const BouncingScrollPhysics(),
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _FullCouponCard(
                  coupon: coupons[index],
                  onCopy: () => _copyCode(context, coupons[index].code),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CouponDetailScreen(coupon: coupons[index]),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offers & Coupons',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          Text(
            'Tap a coupon to see details',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.borderColor),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Offers Available',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No offers are available at the moment.\nCheck back soon for exciting deals!',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Couldn\'t load offers',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please check your connection and try again.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context
                  .read<OffersProvider>()
                  .fetchOffers(forceRefresh: true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Full Coupon Card (vertical list) ─────────────────────────────────────────

class _FullCouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onCopy;
  final VoidCallback onTap;

  const _FullCouponCard({
    required this.coupon,
    required this.onCopy,
    required this.onTap,
  });

  List<Color> _gradient() {
    switch (coupon.discountType) {
      case DiscountType.percentage:
        return [const Color(0xFFFF4071), const Color(0xFFFF6B9A)];
      case DiscountType.fixed:
        return [const Color(0xFF7C6AE8), const Color(0xFF9D8FF0)];
      case DiscountType.freeShipping:
        return [const Color(0xFF4CAF8A), const Color(0xFF6DC9A8)];
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient();
    final isNew = OffersProvider.isNewCoupon(coupon);
    final expiryStr =
        DateFormat('dd MMM yyyy').format(coupon.expiryDate);
    final startStr =
        DateFormat('dd MMM yyyy').format(coupon.startDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── Gradient header strip ──────────────────────────────────
              Container(
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDiscount(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (coupon.title.isNotEmpty)
                            Text(
                              coupon.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Perforated divider ─────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
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
                  Container(
                    width: 16,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Card body ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code row
                    Row(
                      children: [
                        Icon(Icons.confirmation_number_rounded,
                            size: 14, color: gradient.first),
                        const SizedBox(width: 6),
                        Text(
                          'Code:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          coupon.code,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    if (coupon.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        coupon.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Detail chips row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (coupon.minimumOrder > 0)
                          _InfoChip(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Min. Rs. ${coupon.minimumOrder.toStringAsFixed(0)}',
                            color: gradient.first,
                          ),
                        if (coupon.maximumDiscount > 0 &&
                            coupon.discountType == DiscountType.percentage)
                          _InfoChip(
                            icon: Icons.price_check_rounded,
                            label: 'Max. Rs. ${coupon.maximumDiscount.toStringAsFixed(0)}',
                            color: gradient.first,
                          ),
                        _InfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: '$startStr — $expiryStr',
                          color: gradient.first,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Copy Code button — full width
                    GestureDetector(
                      onTap: onCopy,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.first.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.copy_rounded, color: Colors.white, size: 15),
                            const SizedBox(width: 8),
                            Text(
                              'Copy Code',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Info Chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Card ─────────────────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
