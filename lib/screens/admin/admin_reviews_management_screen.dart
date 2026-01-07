import 'package:flutter/material.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/auth_service.dart';
import 'package:tourmate_app/services/notification_service.dart';
import '../../utils/app_theme.dart';

class AdminReviewsManagementScreen extends StatefulWidget {
  const AdminReviewsManagementScreen({super.key});

  @override
  State<AdminReviewsManagementScreen> createState() =>
      _AdminReviewsManagementScreenState();
}

class _AdminReviewsManagementScreenState
    extends State<AdminReviewsManagementScreen> {
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  List<BookingModel> _pendingReviews = [];
  List<BookingModel> _approvedReviews = [];
  List<BookingModel> _flaggedReviews = [];
  bool _isLoading = true;
  String _selectedTab = 'pending'; // pending, approved, flagged

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    try {
      final pendingReviews = await _db.getPendingReviewBookings();
      final approvedReviews = await _db.getApprovedReviewBookings();
      final flaggedReviews = await _db.getModeratedReviewBookings();

      setState(() {
        _pendingReviews = pendingReviews;
        _approvedReviews = approvedReviews;
        _flaggedReviews = flaggedReviews;
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
                _buildTab('Approved', 'approved', _approvedReviews.length),
                _buildTab('Flagged', 'flagged', _flaggedReviews.length),
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
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (count > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    List<BookingModel> reviews;
    String emptyMessage;
    IconData emptyIcon;

    switch (_selectedTab) {
      case 'pending':
        reviews = _pendingReviews;
        emptyMessage = 'No pending reviews';
        emptyIcon = Icons.pending;
        break;
      case 'approved':
        reviews = _approvedReviews;
        emptyMessage = 'No approved reviews';
        emptyIcon = Icons.check_circle;
        break;
      case 'flagged':
        reviews = _flaggedReviews;
        emptyMessage = 'No flagged reviews';
        emptyIcon = Icons.flag;
        break;
      default:
        reviews = [];
        emptyMessage = 'No reviews found';
        emptyIcon = Icons.reviews;
    }

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
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

  Widget _buildReviewModerationCard(BookingModel booking) {
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
                  child: Text(
                    booking.reviewerName?.isNotEmpty == true
                        ? booking.reviewerName![0].toUpperCase()
                        : '?',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.reviewerName ?? 'Anonymous',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Tour Review • ${booking.reviewCreatedAt != null ? _timeAgo(booking.reviewCreatedAt!) : 'Unknown time'}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReviewStatusColor(booking.reviewStatus)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getReviewStatusColor(booking.reviewStatus)
                            .withOpacity(0.3)),
                  ),
                  child: Text(
                    _getReviewStatusText(booking.reviewStatus),
                    style: AppTheme.bodySmall.copyWith(
                      color: _getReviewStatusColor(booking.reviewStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tour Title
            Text(
              booking.tourTitle,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),

            const SizedBox(height: 8),

            // Rating
            if (booking.rating != null)
              Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < booking.rating!.floor()
                            ? Icons.star
                            : booking.rating! - index > 0
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.rating!.toStringAsFixed(1),
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 8),

            // Review content
            if (booking.reviewContent != null &&
                booking.reviewContent!.isNotEmpty) ...[
              Text(
                booking.reviewContent!,
                style: AppTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            // Moderation Actions
            if (booking.reviewStatus == ReviewSubmissionStatus.pending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _moderateReview(
                          booking,
                          ReviewSubmissionStatus.moderated,
                          'Inappropriate content'),
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
                      onPressed: () => _moderateReview(
                          booking, ReviewSubmissionStatus.approved),
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
                    onPressed: () => _showModerationDetails(booking),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _deleteReview(booking),
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

  void _moderateReview(BookingModel booking, ReviewSubmissionStatus status,
      [String? reason]) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) return;

      await _db.updateBookingReviewStatus(
        booking.id,
        status,
        moderatorId: currentUser.uid,
        moderationReason: reason,
      );

      // Create notification for admin
      final currentAdmin = _authService.getCurrentUser();
      if (currentAdmin != null) {
        final adminNotification = status == ReviewSubmissionStatus.approved
            ? _notificationService.createReviewApprovedNotification(
                userId: currentAdmin.uid,
                tourTitle: booking.tourTitle,
                reviewerName: booking.reviewerName ?? 'Anonymous',
              )
            : status == ReviewSubmissionStatus.moderated
                ? _notificationService.createReviewRejectedNotification(
                    userId: currentAdmin.uid,
                    tourTitle: booking.tourTitle,
                    reviewerName: booking.reviewerName ?? 'Anonymous',
                    reason: reason ?? 'Content violation',
                  )
                : _notificationService.createReviewModeratedNotification(
                    userId: currentAdmin.uid,
                    tourTitle: booking.tourTitle,
                    reviewerName: booking.reviewerName ?? 'Anonymous',
                    reason: reason ?? 'Content moderation',
                  );

        await _notificationService.createNotification(adminNotification);
      }

      // Reload reviews
      await _loadReviews();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Review ${status == ReviewSubmissionStatus.moderated ? 'moderated' : status.name} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to moderate review: $e')),
      );
    }
  }

  void _deleteReview(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
            'Are you sure you want to permanently delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _db.deleteBookingReview(booking.id);
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

  void _showModerationDetails(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_getReviewStatusText(booking.reviewStatus)}'),
            if (booking.reviewModeratedAt != null) ...[
              const SizedBox(height: 8),
              Text('Moderated: ${booking.reviewModeratedAt!.toString()}'),
            ],
            if (booking.reviewModerateReason != null &&
                booking.reviewModerateReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: ${booking.reviewModerateReason}'),
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

  String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getReviewStatusColor(ReviewSubmissionStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case ReviewSubmissionStatus.pending:
        return Colors.orange;
      case ReviewSubmissionStatus.approved:
        return Colors.green;
      case ReviewSubmissionStatus.moderated:
        return Colors.red;
    }
  }

  String _getReviewStatusText(ReviewSubmissionStatus? status) {
    if (status == null) return 'No Status';
    switch (status) {
      case ReviewSubmissionStatus.pending:
        return 'Pending';
      case ReviewSubmissionStatus.approved:
        return 'Approved';
      case ReviewSubmissionStatus.moderated:
        return 'Rejected';
    }
  }
}
