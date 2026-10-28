import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/coupon_model.dart';
import '../../providers/offers_provider.dart';
import '../../theme/app_theme.dart';
import '../../screens/home/coupon_detail_screen.dart';
import '../../screens/home/offers_screen.dart';

/// Embeds in the home screen below the promo carousel.
/// Shows up to 5 active coupons in a horizontal scroll.
class OffersSection extends StatefulWidget {
  const OffersSection({super.key});

  @override
  State<OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends State<OffersSection> {
  @override
  void initState() {
    super.initState();
    // Fetch on first render, non-blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OffersProvider>().fetchOffers();
      }
    });
  }

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

  void _openDetail(BuildContext context, CouponModel coupon) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CouponDetailScreen(coupon: coupon)),
    );
  }

  void _openSeeAll(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OffersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OffersProvider>(
      builder: (context, provider, _) {
        // While loading, show skeleton
        if (provider.isLoading) {
          return _buildSkeleton();
        }

        // On error, show nothing (non-intrusive — home screen health first)
        if (provider.error != null) {
          return const SizedBox.shrink();
        }

        // No active coupons — hide section entirely
        if (!provider.hasOffers) {
          return const SizedBox.shrink();
        }

        final preview = provider.previewCoupons(limit: 5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, provider.coupons.length),
            const SizedBox(height: 12),
            SizedBox(
              height: 176,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: preview.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 220,
                    child: _CouponCard(
                      coupon: preview[index],
                      onCopy: () => _copyCode(context, preview[index].code),
                      onTap: () => _openDetail(context, preview[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: AppTheme.primaryColor,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Available Offers',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _openSeeAll(context),
          child: Row(
            children: [
              Text(
                'See All',
                style: GoogleFonts.poppins(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header skeleton
        Shimmer.fromColors(
          baseColor: const Color(0xFFEEEEEE),
          highlightColor: const Color(0xFFF5F5F5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 140, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              Container(width: 56, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: const Color(0xFFEEEEEE),
              highlightColor: const Color(0xFFF5F5F5),
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Individual Coupon Card ────────────────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onCopy;
  final VoidCallback onTap;

  const _CouponCard({
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
        return 'FREE SHIP';
    }
  }

  String _formatExpiry() =>
      'Expires ${DateFormat('dd MMM yyyy').format(coupon.expiryDate)}';

  @override
  Widget build(BuildContext context) {
    final gradient = _gradient();
    final isNew = OffersProvider.isNewCoupon(coupon);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Coloured top strip
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background decorative circle
                      Positioned(
                        right: -16,
                        top: -16,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _formatDiscount(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
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

              // Card body
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 72, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Code row
                    Row(
                      children: [
                        Icon(Icons.confirmation_number_rounded, size: 13, color: gradient.first),
                        const SizedBox(width: 5),
                        Text(
                          coupon.code,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Description or title
                    Text(
                      coupon.title.isNotEmpty ? coupon.title : coupon.description,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Min order
                    if (coupon.minimumOrder > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Min. Rs. ${coupon.minimumOrder.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Bottom row: expiry + copy button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatExpiry(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onCopy,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded, color: Colors.white, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // "New" badge
              if (isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
