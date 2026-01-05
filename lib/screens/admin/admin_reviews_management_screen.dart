import 'package:flutter/material.dart';
import 'package:tourmate_app/models/review_model.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import '../../utils/app_theme.dart';

class AdminReviewsManagementScreen extends StatefulWidget {
  const AdminReviewsManagementScreen({super.key});

  @override
  State<AdminReviewsManagementScreen> createState() => _AdminReviewsManagementScreenState();
}

class _AdminReviewsManagementScreenState extends State<AdminReviewsManagementScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();

  List<ReviewModel> _pendingReviews = [];
  List<ReviewModel> _allReviews = [];
  bool _isLoading = true;
  String _selectedTab = 'pending'; // pending, all, reported

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final pendingReviews = await _db.getPendingReviews();
      // For now, we'll use pending reviews as all reviews (this would need a proper getAllReviews method)
      final allReviews = await _db.getPendingReviews();

      setState(() {
        _pendingReviews = pendingReviews;
        _allReviews = allReviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reviews: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Review Moderation'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Pending', 'pending', _pendingReviews.length),
                _buildTab('All Reviews', 'all', _allReviews.length),
                _buildTab('Reported', 'reported', 0), // Placeholder
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildReviewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String tabId, int count) {
    final isSelected = _selectedTab == tabId;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppTheme.bodyMedium.copyWith(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    final reviews = _selectedTab == 'pending' ? _pendingReviews : _allReviews;

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 'pending' ? Icons.pending : Icons.reviews,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTab == 'pending'
                  ? 'No pending reviews'
                  : 'No reviews found',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        return _buildReviewModerationCard(reviews[index]);
      },
    );
  }

  Widget _buildReviewModerationCard(ReviewModel review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: review.reviewerAvatar != null
                      ? NetworkImage(review.reviewerAvatar!)
                      : null,
                  child: review.reviewerAvatar == null
                      ? Text(
                          review.reviewerName.isNotEmpty
                              ? review.reviewerName[0].toUpperCase()
                              : '?',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${review.type.name.toUpperCase()} Review • ${review.timeAgo}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: review.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: review.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    review.statusText,
                    style: AppTheme.bodySmall.copyWith(
                      color: review.statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rating
            Row(
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.overallRating.floor()
                          ? Icons.star
                          : review.overallRating - index > 0
                              ? Icons.star_half
                              : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  review.overallRating.toStringAsFixed(1),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Review title and content
            if (review.title.isNotEmpty)
              Text(
                review.title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

            if (review.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                review.content,
                style: AppTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Criteria
            if (review.criteria.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: review.criteria.map((criteria) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${criteria.name}: ${criteria.rating.toStringAsFixed(1)}',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // Moderation Actions
            if (review.isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _moderateReview(review, ReviewStatus.rejected, 'Inappropriate content'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _moderateReview(review, ReviewStatus.approved),
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showModerationDetails(review),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                  const Spacer(),
                  if (review.isApproved)
                    TextButton.icon(
                      onPressed: () => _moderateReview(review, ReviewStatus.hidden, 'Admin action'),
                      icon: const Icon(Icons.visibility_off, size: 16, color: Colors.orange),
                      label: const Text('Hide'),
                      style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    ),
                  TextButton.icon(
                    onPressed: () => _deleteReview(review),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _moderateReview(ReviewModel review, ReviewStatus status, [String? reason]) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) return;

      await _db.updateReviewStatus(
        review.id,
        status,
        moderatorId: currentUser.uid,
        moderationReason: reason,
      );

      // Reload reviews
      await _loadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review ${status.name}d successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to moderate review: $e')),
      );
    }
  }

  void _deleteReview(ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to permanently delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _db.deleteReview(review.id);
                Navigator.of(context).pop();
                await _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete review: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showModerationDetails(ReviewModel review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${review.statusText}'),
            if (review.moderatedAt != null) ...[
              const SizedBox(height: 8),
              Text('Moderated: ${review.moderatedAt!.toString()}'),
            ],
            if (review.moderationReason != null && review.moderationReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: ${review.moderationReason}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}