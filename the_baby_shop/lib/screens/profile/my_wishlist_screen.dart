import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../home/product_detail_screen.dart';
import '../../models/product_model.dart';
import '../../providers/wishlist_provider.dart';

class MyWishlistScreen extends StatelessWidget {
  const MyWishlistScreen({Key? key}) : super(key: key);

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              size: 44,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your wishlist is empty',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final List<String> ids = wishlistProvider.wishlistItemIds;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in to view your wishlist.'))
          : ids.isEmpty
              ? _buildEmptyState()
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where(FieldPath.documentId, whereIn: ids.take(30).toList())
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final docId = doc.id;
                        
                        // Support both 'image' and 'imageUrl' dynamically
                        final String displayImage = data['image'] ?? data['imageUrl'] ?? '';

                        final double rawPrice = (data['price'] is num) 
                            ? (data['price'] as num).toDouble() 
                            : double.tryParse(data['price']?.toString() ?? '0') ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            onTap: () {
                              final product = ProductModel.fromFirestore(doc);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: AppTheme.backgroundColor,
                                child: displayImage.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: displayImage,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                                      )
                                    : const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                              ),
                            ),
                            title: Text(
                              data['productName'] ?? 'Baby Product',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Rs. ${rawPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                wishlistProvider.toggleFavorite(docId);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.red.shade700,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
