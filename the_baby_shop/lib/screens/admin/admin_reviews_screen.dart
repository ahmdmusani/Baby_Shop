import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/review_model.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../theme/app_theme.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  static const _pink = AppTheme.primaryColor;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Review',
      message: 'Are you sure you want to delete this review? This action is permanent.',
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review deleted successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting review: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.04),
            width: 1,
          ),
        ),
        title: Text(
          'Reviews & Ratings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by User name or comment...',
                hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: _pink),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.trim().toLowerCase());
              },
            ),
          ),

          // Reviews List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _pink));
                }

                var docs = snap.data?.docs ?? [];
                
                // Convert to ReviewModel list
                var reviews = docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();

                // Apply search filter locally
                if (_searchQuery.isNotEmpty) {
                  reviews = reviews.where((r) {
                    return r.userName.toLowerCase().contains(_searchQuery) ||
                        r.comment.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rate_review_outlined, size: 60, color: Colors.black12),
                        const SizedBox(height: 12),
                        Text('No reviews found.', style: GoogleFonts.poppins(color: Colors.black38)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final DateTime dt = review.createdAt;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.black.withOpacity(0.02)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: user name and delete button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    review.userName,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF2D3142)),
                                  ),
                                  Text(
                                    '${dt.day}/${dt.month}/${dt.year}  |  ID: ${review.productId.substring(0, review.productId.length > 8 ? 8 : review.productId.length)}...',
                                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.black38),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                onPressed: () => _deleteReview(review.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Rating Stars
                          Row(
                            children: [
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < review.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${review.rating.toStringAsFixed(1)})',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Sub-ratings
                          if (review.productQualityRating > 0 || review.deliverySpeedRating > 0 || review.serviceQualityRating > 0) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (review.productQualityRating > 0)
                                  _buildSubRatingBadge('Quality', review.productQualityRating),
                                if (review.deliverySpeedRating > 0)
                                  _buildSubRatingBadge('Delivery', review.deliverySpeedRating),
                                if (review.serviceQualityRating > 0)
                                  _buildSubRatingBadge('Service', review.serviceQualityRating),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Comment
                          Text(
                            review.comment,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubRatingBadge(String label, double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: _pink),
          ),
          const SizedBox(width: 1),
          const Icon(Icons.star_rounded, size: 9, color: Colors.amber),
        ],
      ),
    );
  }
}
