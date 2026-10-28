import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/category_utils.dart';
import '../../utils/pakistan_time_greeting.dart';
import '../../widgets/home/home_promo_carousel.dart';
import '../../widgets/home/offers_section.dart';
import '../../widgets/home/chatbot_dialog.dart';
import '../../providers/review_provider.dart';
import '../../models/review_model.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'product_listing_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  Stream<DocumentSnapshot>? _userDocStream;

  String _searchQuery = '';
  String _selectedCategoryId = '';
  bool _isCategoriesExpanded = false;

  @override
  void initState() {
    super.initState();
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      _userDocStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SafeArea(child: _buildHomeTab()),
          const SafeArea(
            child: ProductListingScreen(
              categoryId: '',
              categoryName: 'My Wishlist',
              wishlistOnly: true,
              embeddedInShell: true,
            ),
          ),
          const SafeArea(child: CartScreen()),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.favorite_rounded, Icons.favorite_border_rounded, 'Wishlist'),
                _buildNavItem(
                  2,
                  Icons.shopping_cart_rounded,
                  Icons.shopping_cart_outlined,
                  'Cart',
                  badgeCount: context.watch<CartProvider>().items.length,
                ),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AnimatedPadding(
                padding: MediaQuery.of(context).viewInsets,
                duration: const Duration(milliseconds: 100),
                curve: Curves.decelerate,
                child: const ChatbotDialog(),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(
            Icons.chat_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 20),
          HomePromoCarousel(
            onShopNow: () => setState(() => _selectedCategoryId = ''),
          ),
          const SizedBox(height: 24),
          const OffersSection(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'Categories',
            buttonText: _isCategoriesExpanded ? 'See less' : 'See all',
            icon: _isCategoriesExpanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.arrow_forward_ios_rounded,
            onSeeAll: () {
              setState(() {
                _isCategoriesExpanded = !_isCategoriesExpanded;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildCategoriesAndProducts(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    if (_userDocStream == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        String displayName = 'Guest';
        String? profileImage;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            displayName = data['fullName'] ?? 'Guest';
            profileImage = data['profileImage'];
          }
        } else if (_authService.currentUser?.displayName != null) {
          displayName = _authService.currentUser!.displayName!;
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PakistanTimeGreeting.greetingWithEmoji(),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  backgroundImage: profileImage != null && profileImage.isNotEmpty
                      ? CachedNetworkImageProvider(profileImage)
                      : null,
                  child: profileImage == null || profileImage.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary, size: 22),
              onSelected: (value) async {
                if (value == 'logout') await _authService.signOut();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                      const SizedBox(width: 10),
                      Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 12, offset: const Offset(0, 4))
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search baby products...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {}),
              borderRadius: BorderRadius.circular(16),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onSeeAll,
    String buttonText = 'See all',
    IconData icon = Icons.arrow_forward_ios_rounded,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text(
                buttonText,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 2),
              Icon(icon, size: 10, color: AppTheme.primaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesAndProducts() {
    return StreamBuilder<List<CategoryModel>>(
      stream: context.read<ProductProvider>().categoriesStream,
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data ?? [];

        final Widget categoriesSection;
        if (!categorySnapshot.hasData) {
          categoriesSection = const SizedBox(
            height: 108,
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        } else if (categories.isEmpty) {
          categoriesSection = const SizedBox(
            height: 80,
            child: Center(child: Text('No categories available')),
          );
        } else {
          categoriesSection = AnimatedCrossFade(
            firstChild: SizedBox(
              height: 116,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryItem(
                      label: 'All',
                      imageUrl: '',
                      isSelected: _selectedCategoryId.isEmpty,
                      onTap: () => setState(() => _selectedCategoryId = ''),
                    );
                  }
                  final category = categories[index - 1];
                  return _buildCategoryItem(
                    label: category.categoryName,
                    imageUrl: category.image,
                    isSelected: _selectedCategoryId == category.id,
                    onTap: () => setState(() => _selectedCategoryId = category.id),
                  );
                },
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  _buildCategoryItem(
                    label: 'All',
                    imageUrl: '',
                    isSelected: _selectedCategoryId.isEmpty,
                    onTap: () => setState(() => _selectedCategoryId = ''),
                    isExpanded: true,
                  ),
                  ...categories.map((category) => _buildCategoryItem(
                    label: category.categoryName,
                    imageUrl: category.image,
                    isSelected: _selectedCategoryId == category.id,
                    onTap: () => setState(() => _selectedCategoryId = category.id),
                    isExpanded: true,
                  )),
                ],
              ),
            ),
            crossFadeState: _isCategoriesExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            categoriesSection,
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: 'Featured Products',
              onSeeAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProductListingScreen(
                      categoryId: '',
                      categoryName: 'All Products',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<ProductModel>>(
              stream: context.read<ProductProvider>().productsStream,
              builder: (context, productSnapshot) {
                if (!productSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
                    ),
                  );
                }

                var filtered = productSnapshot.data!;
                if (_selectedCategoryId.isNotEmpty) {
                  filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((p) =>
                          p.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No products found',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 258,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 168,
                        child: _buildProductCard(filtered[index], categories),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem({
    required String label,
    required String imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
    bool isExpanded = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: isExpanded ? 0 : 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFEAEFF5),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: label == 'All' || imageUrl.isEmpty
                      ? Icon(
                          Icons.grid_view_rounded,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                          size: 28,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(6),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.category_rounded,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 12,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, List<CategoryModel> categories) {
    final hasDiscount =
        product.discountPrice > 0 && product.discountPrice < product.price;
    final displayPrice = hasDiscount ? product.discountPrice : product.price;

    // Dynamically map the adult suit photo placeholder to a high-end baby carrier photo
    final displayImageUrl = product.image.contains('photo-1507679799987-c73779587ccf')
        ? 'https://images.unsplash.com/photo-1617331140180-e8262094733a?q=80&w=600&auto=format&fit=crop'
        : product.image;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F3F6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium image container
                      Stack(
                        children: [
                          Container(
                            height: 122,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: displayImageUrl.isNotEmpty
                                ? Hero(
                                    tag: 'product-image-${product.id}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: CachedNetworkImage(
                                        imageUrl: displayImageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(
                                            color: AppTheme.primaryColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.image,
                                          size: 32,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.image, size: 32, color: AppTheme.textSecondary),
                                  ),
                          ),
                          if (product.stock <= 0)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Text(
                                    'OUT OF STOCK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Title Text (Semi-bold, elegant spacing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          product.productName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: StreamBuilder<List<ReviewModel>>(
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
                      ),
                      const Spacer(),
                      // Bottom Row: Price stack and elegant rounded Add button
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasDiscount)
                                    Text(
                                      'Rs. ${product.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                        height: 1.1,
                                      ),
                                    ),
                                  Text(
                                    'Rs. ${displayPrice.toStringAsFixed(0)}',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: product.stock > 0
                                  ? () async {
                                      final isClothing = CategoryUtils.isClothingProduct(
                                          product.categoryId, categories);
                                      final size = isClothing ? 'M' : '';
                                      await Provider.of<CartProvider>(context, listen: false)
                                          .addToCart(product, size, 1);
                                      if (!context.mounted) return;
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
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: product.stock > 0
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    if (product.stock > 0)
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Gradient-filled discount badge
                if (hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7E9F), AppTheme.primaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${(100 - (product.discountPrice / product.price * 100)).toStringAsFixed(0)}% OFF',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Premium out-of-stock overlay
                if (product.stock <= 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Text(
                            'OUT OF STOCK',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
