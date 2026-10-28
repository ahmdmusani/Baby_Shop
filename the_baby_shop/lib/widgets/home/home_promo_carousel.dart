import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';

class PromoSlide {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final List<Color> gradientColors;
  final IconData icon;
  final Color iconColor;
  final String imageUrl;

  const PromoSlide({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.gradientColors,
    required this.icon,
    required this.iconColor,
    this.imageUrl = '',
  });
}

class HomePromoCarousel extends StatefulWidget {
  final VoidCallback? onShopNow;

  const HomePromoCarousel({super.key, this.onShopNow});

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  static const List<PromoSlide> _staticSlides = [
    PromoSlide(
      title: 'Super Sale',
      subtitle: 'Up to 40% Off',
      buttonLabel: 'Shop Now',
      gradientColors: [Color(0xFFE8E4FF), Color(0xFFD6CCFF)],
      icon: Icons.local_offer_rounded,
      iconColor: Color(0xFF7C6AE8),
    ),
    PromoSlide(
      title: 'New Arrivals',
      subtitle: 'Fresh picks for baby',
      buttonLabel: 'Explore',
      gradientColors: [Color(0xFFFFE8F0), Color(0xFFFFD6E8)],
      icon: Icons.child_care_rounded,
      iconColor: Color(0xFFFF6B9A),
    ),
    PromoSlide(
      title: 'Free Delivery',
      subtitle: 'On orders above Rs. 999',
      buttonLabel: 'Order Now',
      gradientColors: [Color(0xFFE3F5EE), Color(0xFFCDEFDF)],
      icon: Icons.delivery_dining_rounded,
      iconColor: Color(0xFF4CAF8A),
    ),
  ];

  List<PromoSlide> _currentSlides = _staticSlides;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) => _advanceSlide());
  }

  void _advanceSlide() {
    if (!_pageController.hasClients || !mounted || _currentSlides.isEmpty) return;
    final next = (_currentPage + 1) % _currentSlides.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey.shade300;
    }
  }

  PromoSlide _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final start = data['gradientStart'] ?? '#E8E4FF';
    final end = data['gradientEnd'] ?? '#D6CCFF';
    final iconColor = data['iconColor'] ?? '#7C6AE8';
    final int codePoint = data['iconCodePoint'] ?? Icons.local_offer_rounded.codePoint;
    final String imageUrl = data['imageUrl'] ?? '';

    return PromoSlide(
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      buttonLabel: data['buttonLabel'] ?? 'Shop Now',
      gradientColors: [_parseHexColor(start), _parseHexColor(end)],
      icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
      iconColor: _parseHexColor(iconColor),
      imageUrl: imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final slides = docs.isNotEmpty
            ? docs.map((doc) => _fromFirestore(doc)).toList()
            : _staticSlides;
        
        _currentSlides = slides;

        return Column(
          children: [
            SizedBox(
              height: 168,
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _PromoCard(
                      slide: slide,
                      onTap: widget.onShopNow,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoSlide slide;
  final VoidCallback? onTap;

  const _PromoCard({required this.slide, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = slide.imageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: slide.gradientColors.last.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (hasImage)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CachedNetworkImage(
                  imageUrl: slide.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.white70),
                ),
              ),
            ),
          if (hasImage)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          Positioned(
            right: -8,
            bottom: -8,
            child: hasImage
                ? const SizedBox.shrink()
                : Icon(
                    slide.icon,
                    size: 110,
                    color: slide.iconColor.withOpacity(0.22),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: hasImage ? Colors.white : AppTheme.textPrimary,
                    shadows: hasImage
                        ? const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slide.subtitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: hasImage ? Colors.white.withOpacity(0.9) : AppTheme.textSecondary,
                    shadows: hasImage
                        ? const [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                ),
                const Spacer(),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      child: Text(
                        slide.buttonLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
