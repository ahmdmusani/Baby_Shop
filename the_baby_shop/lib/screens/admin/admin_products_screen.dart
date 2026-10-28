import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/admin/admin_search_bar.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../theme/app_theme.dart';
import 'admin_add_edit_product_screen.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  static const _pink = AppTheme.primaryColor;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text('Manage Products',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: _pink, size: 26),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminAddEditProductScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AdminSearchBar(
              hintText: 'Search products...',
              onChanged: provider.setSearchQuery,
            ),
          ),

          // Category filter chips
          StreamBuilder<List<CategoryModel>>(
            stream: provider.categoriesStream,
            builder: (ctx, snap) {
              final categories = snap.data ?? [];
              provider.updateCategoryList(categories);
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: provider.selectedCategoryId.isEmpty,
                      onTap: () => provider.setCategoryFilter(''),
                    ),
                    ...categories.map((cat) => _FilterChip(
                          label: cat.categoryName,
                          selected: provider.selectedCategoryId == cat.id,
                          onTap: () => provider.setCategoryFilter(cat.id),
                        )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Products list
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: provider.productsStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _pink));
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final products = snap.data ?? [];
                provider.updateProductList(products);
                final filtered = provider.products;

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64, color: Colors.black12),
                        const SizedBox(height: 12),
                        Text('No products found.',
                            style: GoogleFonts.poppins(color: Colors.black38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _ProductTile(product: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminAddEditProductScreen()),
        ),
        backgroundColor: _pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Product',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : Colors.black.withOpacity(0.08)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProductProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: product.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.image,
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            const SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF2D3142)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Rs. ${product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  _StockBadge(stock: product.stock),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: Color(0xFF2196F3), size: 22),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AdminAddEditProductScreen(product: product)),
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded,
                      color: Colors.red, size: 22),
                  onPressed: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete Product',
                      message:
                          'Are you sure you want to delete "${product.productName}"? This cannot be undone.',
                    );
                    if (confirmed == true && context.mounted) {
                      await provider.deleteProduct(
                          product.id, product.image);
                    }
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 68,
      height: 68,
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: const Icon(Icons.image_outlined,
          color: AppTheme.primaryColor, size: 28),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final isLow = stock < 10;
    final isEmpty = stock == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEmpty
            ? Colors.red.withOpacity(0.08)
            : (isLow ? Colors.orange.withOpacity(0.08) : Colors.green.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty
              ? Colors.red.withOpacity(0.2)
              : (isLow ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2)),
          width: 1,
        ),
      ),
      child: Text(
        isEmpty ? 'Out of Stock' : 'Stock: $stock',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isEmpty ? Colors.red : (isLow ? Colors.orange : Colors.green),
        ),
      ),
    );
  }
}
