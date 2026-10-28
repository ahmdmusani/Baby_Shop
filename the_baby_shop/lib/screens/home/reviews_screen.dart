import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/review_model.dart';
import '../../providers/review_provider.dart';
import '../../theme/app_theme.dart';

class ReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  /// Whether to show the write/edit review form.
  /// Set to true only for users who have purchased the product.
  final bool showReviewForm;

  /// If non-null, the form opens pre-populated in edit mode for this review.
  final ReviewModel? initialReview;

  const ReviewsScreen({
    Key? key,
    required this.productId,
    required this.productName,
    this.showReviewForm = false,
    this.initialReview,
  }) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  double _userRating = 5.0;
  double _productQualityRating = 5.0;
  double _deliverySpeedRating = 5.0;
  double _serviceQualityRating = 5.0;
  String? _editingReviewId;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Pre-populate form if editing an existing review
    if (widget.initialReview != null) {
      _editingReviewId = widget.initialReview!.id;
      _userRating = widget.initialReview!.rating;
      _productQualityRating = widget.initialReview!.productQualityRating;
      _deliverySpeedRating = widget.initialReview!.deliverySpeedRating;
      _serviceQualityRating = widget.initialReview!.serviceQualityRating;
      _commentController.text = widget.initialReview!.comment;

      // Auto-scroll to form after build
      if (widget.showReviewForm) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToForm());
      }
    }
  }

  void _scrollToForm() {
    final ctx = _formKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reviews',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        centerTitle: true,
        // Scroll-to-form action shown only when form is available
        actions: widget.showReviewForm
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                  tooltip: widget.initialReview != null ? 'Edit your review' : 'Write a review',
                  onPressed: _scrollToForm,
                ),
              ]
            : null,
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: reviewProvider.getProductReviewsStream(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load reviews.\nPlease try again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            );
          }

          final reviews = snapshot.data ?? [];
          final avgRating = reviewProvider.getAverageRating(reviews);
          final distribution = reviewProvider.getRatingDistribution(reviews);

          // Calculate sub-rating averages
          final avgQuality = reviews.isNotEmpty
              ? double.parse(
                  (reviews.fold(0.0, (acc, r) => acc + r.productQualityRating) / reviews.length)
                      .toStringAsFixed(1))
              : 0.0;
          final avgDelivery = reviews.isNotEmpty
              ? double.parse(
                  (reviews.fold(0.0, (acc, r) => acc + r.deliverySpeedRating) / reviews.length)
                      .toStringAsFixed(1))
              : 0.0;
          final avgService = reviews.isNotEmpty
              ? double.parse(
                  (reviews.fold(0.0, (acc, r) => acc + r.serviceQualityRating) / reviews.length)
                      .toStringAsFixed(1))
              : 0.0;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  widget.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                // ─── Rating Summary Card ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Average rating number + stars
                          Column(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < avgRating.round()
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 28),
                          // Distribution bars
                          Expanded(
                            child: Column(
                              children: List.generate(5, (i) {
                                final star = 5 - i;
                                final count = distribution[star] ?? 0;
                                final ratio =
                                    reviews.isNotEmpty ? count / reviews.length : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Text('$star',
                                          style: const TextStyle(
                                              fontSize: 12, color: AppTheme.textSecondary)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star_rounded,
                                          size: 12, color: Colors.amber),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: ratio,
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                                Colors.amber),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(
                                              fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (reviews.isNotEmpty) ...[
                        const Divider(height: 24, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummarySubRating('Quality', avgQuality),
                            _buildSummarySubRating('Delivery', avgDelivery),
                            _buildSummarySubRating('Service', avgService),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Write / Edit Review Section ───────────────────────────
                if (widget.showReviewForm) ...[
                  Container(
                    key: _formKey,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingReviewId != null ? 'Edit Your Review' : 'Write a Review',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                            ),
                            if (_editingReviewId != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _editingReviewId = null;
                                    _userRating = 5.0;
                                    _productQualityRating = 5.0;
                                    _deliverySpeedRating = 5.0;
                                    _serviceQualityRating = 5.0;
                                    _commentController.clear();
                                  });
                                },
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.red)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStarSelectorRow('Overall Rating', _userRating,
                            (val) => setState(() => _userRating = val)),
                        const SizedBox(height: 10),
                        _buildStarSelectorRow('Product Quality', _productQualityRating,
                            (val) => setState(() => _productQualityRating = val)),
                        const SizedBox(height: 10),
                        _buildStarSelectorRow('Delivery Speed', _deliverySpeedRating,
                            (val) => setState(() => _deliverySpeedRating = val)),
                        const SizedBox(height: 10),
                        _buildStarSelectorRow('Service Quality', _serviceQualityRating,
                            (val) => setState(() => _serviceQualityRating = val)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your experience with this product...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide:
                                  const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: reviewProvider.isSubmitting
                                ? null
                                : () async {
                                    if (_commentController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please write a comment'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      if (_editingReviewId != null) {
                                        await reviewProvider.updateReview(
                                          reviewId: _editingReviewId!,
                                          rating: _userRating,
                                          productQualityRating: _productQualityRating,
                                          deliverySpeedRating: _deliverySpeedRating,
                                          serviceQualityRating: _serviceQualityRating,
                                          comment: _commentController.text.trim(),
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Review updated successfully!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } else {
                                        await reviewProvider.submitReview(
                                          productId: widget.productId,
                                          rating: _userRating,
                                          productQualityRating: _productQualityRating,
                                          deliverySpeedRating: _deliverySpeedRating,
                                          serviceQualityRating: _serviceQualityRating,
                                          comment: _commentController.text.trim(),
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Review submitted! Thank you.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      }
                                      _commentController.clear();
                                      setState(() {
                                        _editingReviewId = null;
                                        _userRating = 5.0;
                                        _productQualityRating = 5.0;
                                        _deliverySpeedRating = 5.0;
                                        _serviceQualityRating = 5.0;
                                      });
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: reviewProvider.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _editingReviewId != null
                                        ? 'Update Review'
                                        : 'Submit Review',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // ─── All Reviews List ──────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'All Reviews',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${reviews.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (reviews.isEmpty)
                  _buildEmptyReviewsState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _buildReviewTile(review, reviewProvider);
                    },
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────────────────────

  Widget _buildEmptyReviewsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to share your experience\nwith this product!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarSelectorRow(
      String label, double rating, ValueChanged<double> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary),
        ),
        Row(
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => onChanged((i + 1).toDouble()),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  i < rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 26,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSummarySubRating(String label, double rating) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '-',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _buildSubRatingBadge(String label, double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary),
          ),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildReviewTile(ReviewModel review, ReviewProvider reviewProvider) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User avatar
        CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          backgroundImage: review.userAvatar.isNotEmpty
              ? CachedNetworkImageProvider(review.userAvatar)
              : null,
          child: review.userAvatar.isEmpty
              ? Text(
                  review.userName.isNotEmpty
                      ? review.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + time + edit/delete actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeAgo(review.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (review.userId == currentUserId) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _editingReviewId = review.id;
                              _userRating = review.rating;
                              _productQualityRating = review.productQualityRating;
                              _deliverySpeedRating = review.deliverySpeedRating;
                              _serviceQualityRating = review.serviceQualityRating;
                              _commentController.text = review.comment;
                            });
                            // Scroll to form after state update
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => _scrollToForm());
                          },
                          child: const Icon(Icons.edit_rounded,
                              size: 14, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Text('Delete Review'),
                                content: const Text(
                                    'Are you sure you want to delete this review?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && mounted) {
                              await reviewProvider.deleteReview(review.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Review deleted'),
                                      backgroundColor: Colors.green),
                                );
                              }
                            }
                          },
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 14, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Star rating row
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              // Sub-rating badges
              if (review.productQualityRating > 0 ||
                  review.deliverySpeedRating > 0 ||
                  review.serviceQualityRating > 0) ...[
                const SizedBox(height: 6),
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
              ],
              const SizedBox(height: 8),
              // Review comment
              Text(
                review.comment,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
