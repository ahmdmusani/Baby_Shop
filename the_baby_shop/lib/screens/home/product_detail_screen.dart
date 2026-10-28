import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_utils.dart';
import 'reviews_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String _selectedSize = 'M';
  String? _selectedColor;
  int _quantity = 1;
  bool _isAdding = false;
  bool _isCheckingReview = false;

  // Categories local state
  List<CategoryModel> _categories = [];

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];
  final List<Map<String, dynamic>> _availableColors = const [
    {'name': 'Pink', 'hex': '#FF6B9A', 'color': Color(0xFFFF6B9A)},
    {'name': 'Soft Blue', 'hex': '#ADD8E6', 'color': Color(0xFFADD8E6)},
    {'name': 'Mint Green', 'hex': '#A8E6CF', 'color': Color(0xFFA8E6CF)},
    {'name': 'Pastel Yellow', 'hex': '#FFD3B6', 'color': Color(0xFFFFD3B6)},
    {'name': 'Lavender', 'hex': '#DED2F9', 'color': Color(0xFFDED2F9)},
    {'name': 'White', 'hex': '#FFFFFF', 'color': Color(0xFFFFFFFF)},
    {'name': 'Charcoal', 'hex': '#333333', 'color': Color(0xFF333333)},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    _categories = productProvider.categories;

    // Direct fetch fallback in case categories list is not loaded/empty
    if (_categories.isEmpty) {
      FirebaseFirestore.instance.collection('categories').get().then((snap) {
        if (mounted) {
          setState(() {
            _categories = snap.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
            _initDefaults();
          });
        }
      }).catchError((e) {
        print("Error fetching categories directly in details screen: $e");
        _initDefaults();
      });
    } else {
      _initDefaults();
    }
  }

  void _initDefaults() {
    // Set default selected size from product sizes if available
    if (widget.product.sizes != null && widget.product.sizes!.isNotEmpty) {
      _selectedSize = widget.product.sizes!.first;
    }
    // Set default selected color from product colors if available
    if (widget.product.colors != null && widget.product.colors!.isNotEmpty) {
      _selectedColor = widget.product.colors!.first;
    }
  }

  Color _getColorFromHex(String hex) {
    var hexColor = hex.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  String _getColorName(String hex) {
    final match = _availableColors.firstWhere(
      (c) => c['hex'].toString().toLowerCase() == hex.toLowerCase(),
      orElse: () => {'name': hex},
    );
    return match['name'] as String;
  }

  void _showSizeChartDialog() {
    if (widget.product.sizeChartUrl == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Size Chart',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: InteractiveViewer(
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: widget.product.sizeChartUrl!,
                            placeholder: (context, url) => const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              ),
                            ),
                            errorWidget: (context, url, error) => const SizedBox(
                              height: 200,
                              child: Icon(Icons.error_outline, size: 48, color: Colors.red),
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pinch or double tap to zoom chart details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrostedButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Icon(icon, color: iconColor ?? AppTheme.textPrimary, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        widget.product.discountPrice > 0 && widget.product.discountPrice < widget.product.price;
    final displayPrice = hasDiscount ? widget.product.discountPrice : widget.product.price;
    final discountPercent = hasDiscount
        ? (100 - (widget.product.discountPrice / widget.product.price * 100)).round()
        : 0;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav = wishlistProvider.isFavorite(widget.product.id);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    final categoryName = CategoryUtils.nameForId(widget.product.categoryId, _categories);
    final isClothing = CategoryUtils.isClothing(categoryName);
    final showSizeOptions = isClothing;
    final brandLabel = categoryName.isNotEmpty ? categoryName : 'BabyShop';

    final displayImageUrl = widget.product.image.contains('photo-1507679799987-c73779587ccf')
        ? 'https://images.unsplash.com/photo-1617331140180-e8262094733a?q=80&w=600&auto=format&fit=crop'
        : widget.product.image;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Scrollable Content
          Navigator.canPop(context) ? const SizedBox.shrink() : const SizedBox.shrink(), // dummy code to keep context import
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Image Showcase
                Hero(
                  tag: 'product-image-${widget.product.id}',
                  child: Container(
                    width: double.infinity,
                    height: 400,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: displayImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: displayImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryColor),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.image,
                              size: 80,
                              color: AppTheme.textSecondary,
                            ),
                          )
                        : const Icon(Icons.image, size: 80, color: AppTheme.textSecondary),
                  ),
                ),

                // Details Rounded Panel
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greet Row: Brand Name & Rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                brandLabel.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            StreamBuilder<List<ReviewModel>>(
                              stream: reviewProvider.getProductReviewsStream(widget.product.id),
                              builder: (context, snapshot) {
                                final reviews = snapshot.data ?? [];
                                final avgRating = reviewProvider.getAverageRating(reviews);

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ReviewsScreen(
                                          productId: widget.product.id,
                                          productName: widget.product.productName,
                                          showReviewForm: false,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${avgRating.toStringAsFixed(1)} (${reviews.length} review${reviews.length == 1 ? '' : 's'})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Product Title
                        Text(
                          widget.product.productName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pricing Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Rs. ${displayPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 10),
                              Text(
                                'Rs. ${widget.product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$discountPercent% OFF',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 32, color: AppTheme.borderColor),

                        // Sizes Selector
                        if (showSizeOptions) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Size',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (widget.product.sizeChartUrl != null && widget.product.sizeChartUrl!.isNotEmpty)
                                InkWell(
                                  onTap: _showSizeChartDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.straighten_rounded, size: 16, color: AppTheme.primaryColor),
                                        SizedBox(width: 4),
                                        Text(
                                          'Size Guide',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: (widget.product.sizes ?? _sizes).map((size) {
                                final isSelected = _selectedSize == size;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSize = size),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 50,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryColor.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.015),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        size,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Color Options Selector
                        if (isClothing && widget.product.colors != null && widget.product.colors!.isNotEmpty) ...[
                          const Text(
                            'Select Color',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: widget.product.colors!.map((hex) {
                              final color = _getColorFromHex(hex);
                              final isSelected = _selectedColor == hex;
                              final isWhite = hex.toUpperCase() == '#FFFFFF' || hex.toUpperCase() == '#FFF';

                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = hex),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 14),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                          ? AppTheme.primaryColor 
                                          : (isWhite ? Colors.black12 : Colors.transparent),
                                      width: isSelected ? 3.5 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppTheme.primaryColor.withOpacity(0.15)
                                            : Colors.black.withOpacity(0.03),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      )
                                    ],
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Icon(
                                            Icons.check_rounded,
                                            color: isWhite ? Colors.black : Colors.white,
                                            size: 16,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Quantity Options Selector
                        const Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_rounded, size: 18, color: AppTheme.textPrimary),
                                onPressed: () {
                                  if (_quantity > 1) {
                                    setState(() => _quantity--);
                                  }
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_rounded, size: 18, color: AppTheme.textPrimary),
                                onPressed: () {
                                  if (_quantity < widget.product.stock) {
                                    setState(() => _quantity++);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Only ${widget.product.stock} items left in stock!',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Fabric Details
                        if (isClothing && widget.product.fabric != null && widget.product.fabric!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.texture_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Material: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  widget.product.fabric!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Description Card
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            widget.product.description.isNotEmpty
                                ? widget.product.description
                                : 'This premium product is specially designed for your newborn\'s sensitive skin, offering absolute comfort and unmatched hygiene.',
                            style: TextStyle(
                              height: 1.6,
                              fontSize: 13,
                              color: AppTheme.textPrimary.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Fit Instructions Card
                        if (isClothing && widget.product.detailedDescription != null && widget.product.detailedDescription!.isNotEmpty) ...[
                          const Text(
                            'Care & Fit Instructions',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Text(
                              widget.product.detailedDescription!,
                              style: TextStyle(
                                height: 1.6,
                                fontSize: 13,
                                color: AppTheme.textPrimary.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        const SizedBox(height: 24),
                        // Customer Reviews Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Customer Reviews',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // View All button
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReviewsScreen(
                                          productId: widget.product.id,
                                          productName: widget.product.productName,
                                          showReviewForm: false,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.textSecondary,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  child: const Text('View All'),
                                ),
                                const SizedBox(width: 4),
                                // Add Review button
                                _isCheckingReview
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryColor,
                                        ),
                                      )
                                    : TextButton.icon(
                                        onPressed: _handleAddReview,
                                        icon: const Icon(Icons.edit_outlined, size: 14),
                                        label: const Text('Add Review'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primaryColor,
                                          backgroundColor:
                                              AppTheme.primaryColor.withOpacity(0.08),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<ReviewModel>>(
                          stream: reviewProvider.getProductReviewsStream(widget.product.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              );
                            }
                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Text(
                                  'Could not load reviews. Please try again.',
                                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                                ),
                              );
                            }
                            final reviews = snapshot.data ?? [];
                            if (reviews.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.rate_review_outlined, color: AppTheme.textSecondary.withOpacity(0.4), size: 40),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'No reviews yet',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Be the first to share your experience!',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final avgRating = reviewProvider.getAverageRating(reviews);
                            final previewReviews = reviews.take(3).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Rating summary row
                                Row(
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: List.generate(5, (i) {
                                            return Icon(
                                              i < avgRating.round()
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              color: Colors.amber,
                                              size: 16,
                                            );
                                          }),
                                        ),
                                        Text(
                                          'Based on ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Preview review cards (up to 3)
                                ...previewReviews.map((review) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              AppTheme.primaryColor.withOpacity(0.1),
                                          backgroundImage: review.userAvatar.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  review.userAvatar)
                                              : null,
                                          child: review.userAvatar.isEmpty
                                              ? Text(
                                                  review.userName.isNotEmpty
                                                      ? review.userName[0]
                                                          .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      review.userName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: AppTheme.textPrimary,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    _timeAgo(review.createdAt),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: List.generate(5, (i) {
                                                  return Icon(
                                                    i < review.rating.round()
                                                        ? Icons.star_rounded
                                                        : Icons.star_border_rounded,
                                                    color: Colors.amber,
                                                    size: 12,
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                review.comment,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppTheme.textSecondary,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                // "View more" hint if more than 3 reviews exist
                                if (reviews.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewsScreen(
                                            productId: widget.product.id,
                                            productName: widget.product.productName,
                                            showReviewForm: false,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '+ ${reviews.length - 3} more reviews',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Glassmorphic App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFrostedButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                Row(
                  children: [
                    _buildFrostedButton(
                      icon: Icons.share_rounded,
                      onTap: () {
                        final textToCopy = 'Check out this product on The Baby Shop: ${widget.product.productName} - Rs. ${displayPrice.toStringAsFixed(0)}\nFind the best care for your little one!';
                        Clipboard.setData(ClipboardData(text: textToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product details copied to clipboard! Share it with your friends.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildFrostedButton(
                      icon: isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      iconColor: isFav ? AppTheme.primaryColor : null,
                      onTap: () => wishlistProvider.toggleFavorite(widget.product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating Bottom action layout
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Row(
                    children: [
                      // Cart quantity icon overlay
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, color: AppTheme.textPrimary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'x$_quantity',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: widget.product.stock > 0 && !_isAdding
                                ? () => _addToCart(showSizeOptions)
                                : null,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              backgroundColor: widget.product.stock > 0
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                            child: _isAdding
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Handle Add Review tap ───────────────────────────────────────────────
  Future<void> _handleAddReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add a review.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCheckingReview = true);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    try {
      // 1. Check if user has purchased this product
      final hasPurchased = await reviewProvider.hasUserPurchasedProduct(
          user.uid, widget.product.id);

      if (!mounted) return;

      if (!hasPurchased) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'You can review this product only after purchasing it.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1F24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // 2. Check if user already has a review for this product
      final existingReview = await reviewProvider.getUserReviewForProduct(
          user.uid, widget.product.id);

      if (!mounted) return;

      // 3. Navigate with appropriate parameters
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewsScreen(
            productId: widget.product.id,
            productName: widget.product.productName,
            showReviewForm: true,
            initialReview: existingReview, // null = new review, non-null = edit mode
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingReview = false);
    }
  }

  Future<void> _addToCart(bool showSizeOptions) async {
    setState(() => _isAdding = true);

    // Add selected color details to size variant string
    String finalSize = '';
    if (showSizeOptions) {
      if (_selectedColor != null) {
        final String finalColorName = _getColorName(_selectedColor!);
        finalSize = '$_selectedSize ($finalColorName)';
      } else {
        finalSize = _selectedSize;
      }
    }

    await Provider.of<CartProvider>(context, listen: false)
        .addToCart(widget.product, finalSize, _quantity);

    if (!mounted) return;
    setState(() => _isAdding = false);
    final sizeLabel = showSizeOptions ? ' ($finalSize)' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.productName}$sizeLabel added to cart successfully!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ─── Relative time helper ─────────────────────────────────────────────────
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

