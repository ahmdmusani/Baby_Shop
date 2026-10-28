import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_utils.dart';
import 'product_detail_screen.dart';
import '../../providers/review_provider.dart';
import '../../models/review_model.dart';

class ProductListingScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final bool wishlistOnly;
  final bool embeddedInShell;

  const ProductListingScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.wishlistOnly = false,
    this.embeddedInShell = false,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  bool _isGridView = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sort and filter configurations
  String _sortBy = 'newest'; // 'newest', 'price_asc', 'price_desc'
  double _maxPriceFilter = 5000.0;
  bool _inStockOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isClothingProduct(ProductModel product, List<CategoryModel> categories) {
    if (widget.wishlistOnly || widget.categoryId.isEmpty) {
      return CategoryUtils.isClothingProduct(product.categoryId, categories);
    }
    return CategoryUtils.isClothing(widget.categoryName);
  }

  Future<void> _addProductToCart(ProductModel product, List<CategoryModel> categories) async {
    final isClothing = _isClothingProduct(product, categories);
    final size = isClothing ? 'M' : '';
    await Provider.of<CartProvider>(context, listen: false).addToCart(product, size, 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isClothing
              ? '${product.productName} (M) added to cart!'
              : '${product.productName} added to cart!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSortOption(
                    title: 'Newest Arrivals',
                    value: 'newest',
                    icon: Icons.new_releases_outlined,
                    setModalState: setModalState,
                  ),
                  _buildSortOption(
                    title: 'Price: Low to High',
                    value: 'price_asc',
                    icon: Icons.trending_up_rounded,
                    setModalState: setModalState,
                  ),
                  _buildSortOption(
                    title: 'Price: High to Low',
                    value: 'price_desc',
                    icon: Icons.trending_down_rounded,
                    setModalState: setModalState,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required String value,
    required IconData icon,
    required StateSetter setModalState,
  }) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        setModalState(() {});
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _maxPriceFilter = 5000.0;
                            _inStockOnly = false;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Price Limit (Up to Rs. ${_maxPriceFilter.toInt()})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  Slider(
                    value: _maxPriceFilter,
                    min: 100.0,
                    max: 5000.0,
                    divisions: 49,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.borderColor,
                    label: 'Rs. ${_maxPriceFilter.toInt()}',
                    onChanged: (value) {
                      setModalState(() {
                        _maxPriceFilter = value;
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Stock Only',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      Switch.adaptive(
                        value: _inStockOnly,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setModalState(() {
                            _inStockOnly = value;
                          });
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: !widget.embeddedInShell,
        leading: widget.embeddedInShell
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                widget.categoryName,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: AppTheme.textSecondary),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Sort Header Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showSortBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.swap_vert_rounded, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            _sortBy == 'newest' ? 'Newest' : _sortBy == 'price_asc' ? 'Price Low-High' : 'Price High-Low',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: _showFilterBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // StreamBuilder Product Loader
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: context.read<ProductProvider>().categoriesStream,
              builder: (context, categorySnapshot) {
                final categories = categorySnapshot.data ?? [];

                return StreamBuilder<List<ProductModel>>(
                  stream: context.read<ProductProvider>().productsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                    }

                    if (snapshot.data!.isEmpty) {
                      return _buildNoProductsWidget();
                    }

                    var products = List<ProductModel>.from(snapshot.data!);

                    // Apply Category Filter
                    if (widget.categoryId.isNotEmpty) {
                      products = products.where((p) => p.categoryId == widget.categoryId).toList();
                    }

                    // Apply Wishlist Filter
                    if (widget.wishlistOnly) {
                      final wishlistIds = context.watch<WishlistProvider>().wishlistItemIds;
                      products = products.where((p) => wishlistIds.contains(p.id)).toList();
                    }

                    // Apply Search Query
                    if (_searchQuery.isNotEmpty) {
                      products = products.where((p) => p.productName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    }

                    // Apply Price & Stock filters
                    products = products.where((p) {
                      final displayPrice = p.discountPrice > 0 && p.discountPrice < p.price ? p.discountPrice : p.price;
                      final matchesPrice = displayPrice <= _maxPriceFilter;
                      final matchesStock = !_inStockOnly || p.stock > 0;
                      return matchesPrice && matchesStock;
                    }).toList();

                    // Apply Sorting
                    if (_sortBy == 'newest') {
                      products.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
                    } else if (_sortBy == 'price_asc') {
                      products.sort((a, b) {
                        final pA = a.discountPrice > 0 && a.discountPrice < a.price ? a.discountPrice : a.price;
                        final pB = b.discountPrice > 0 && b.discountPrice < b.price ? b.discountPrice : b.price;
                        return pA.compareTo(pB);
                      });
                    } else if (_sortBy == 'price_desc') {
                      products.sort((a, b) {
                        final pA = a.discountPrice > 0 && a.discountPrice < a.price ? a.discountPrice : a.price;
                        final pB = b.discountPrice > 0 && b.discountPrice < b.price ? b.discountPrice : b.price;
                        return pB.compareTo(pA);
                      });
                    }

                    if (products.isEmpty) {
                      return _buildNoProductsWidget();
                    }

                    return _isGridView
                        ? _buildGridViewLayout(products, categories)
                        : _buildListViewLayout(products, categories);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProductsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              widget.wishlistOnly
                  ? 'No favorites yet — tap the heart on products you love'
                  : 'No products available matching your choices',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridViewLayout(List<ProductModel> products, List<CategoryModel> categories) {
    final width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width > 1200 ? 5 : (width > 800 ? 3 : 2);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildGridCard(products[index], categories);
      },
    );
  }

  Widget _buildListViewLayout(List<ProductModel> products, List<CategoryModel> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildListTile(products[index], categories);
      },
    );
  }

  Widget _buildGridCard(ProductModel product, List<CategoryModel> categories) {
    final hasDiscount = product.discountPrice > 0 && product.discountPrice < product.price;
    final displayPrice = hasDiscount ? product.discountPrice : product.price;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav = wishlistProvider.isFavorite(product.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: product.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.image,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.image, size: 40, color: AppTheme.textSecondary),
                              )
                            : const Icon(Icons.image, size: 40, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),

                  // Wishlist heart
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => wishlistProvider.toggleFavorite(product.id),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFav ? AppTheme.primaryColor : AppTheme.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Discount Badge
                  if (hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(100 - (product.discountPrice / product.price * 100)).toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Out of stock
                  if (product.stock <= 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<List<ReviewModel>>(
                    stream: Provider.of<ReviewProvider>(context, listen: false)
                        .getProductReviewsStream(product.id),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      final avgRating = Provider.of<ReviewProvider>(context, listen: false)
                          .getAverageRating(reviews);
                      if (reviews.isEmpty) {
                        return const SizedBox(height: 14);
                      }
                      return Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${avgRating.toStringAsFixed(1)} (${reviews.length})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                'Rs. ${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              'Rs. ${displayPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: product.stock > 0 ? () => _addProductToCart(product, categories) : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: product.stock > 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(ProductModel product, List<CategoryModel> categories) {
    final hasDiscount = product.discountPrice > 0 && product.discountPrice < product.price;
    final displayPrice = hasDiscount ? product.discountPrice : product.price;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final isFav = wishlistProvider.isFavorite(product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Thumbnail image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFFF7F8FA),
                    child: product.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.image, size: 30, color: AppTheme.textSecondary),
                          )
                        : const Icon(Icons.image, size: 30, color: AppTheme.textSecondary),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${(100 - (product.discountPrice / product.price * 100)).toStringAsFixed(0)}% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Product Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<List<ReviewModel>>(
                    stream: Provider.of<ReviewProvider>(context, listen: false)
                        .getProductReviewsStream(product.id),
                    builder: (context, snapshot) {
                      final reviews = snapshot.data ?? [];
                      final avgRating = Provider.of<ReviewProvider>(context, listen: false)
                          .getAverageRating(reviews);
                      if (reviews.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '${avgRating.toStringAsFixed(1)} (${reviews.length} reviews)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Rs. ${displayPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, decoration: TextDecoration.lineThrough),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.stock > 0 ? 'In Stock (${product.stock})' : 'Out of stock',
                    style: TextStyle(
                      color: product.stock > 0 ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Heart / Add buttons
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => wishlistProvider.toggleFavorite(product.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppTheme.primaryColor : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: product.stock > 0 ? () => _addProductToCart(product, categories) : null,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: product.stock > 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
