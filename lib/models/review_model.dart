import 'package:flutter/material.dart';

enum ReviewType {
  tour,      // Review for a specific tour
  guide,     // Review for a tour guide
  booking,   // Review for a booking experience
}

enum ReviewStatus {
  pending,   // Awaiting moderation
  approved,  // Approved and visible
  rejected,  // Rejected by moderator
  hidden,    // Hidden by user or admin
}

class ReviewCriteria {
  final String name;
  final double rating;
  final String? comment;

  ReviewCriteria({
    required this.name,
    required this.rating,
    this.comment,
  });

  factory ReviewCriteria.fromMap(Map<String, dynamic> data) {
    return ReviewCriteria(
      name: data['name'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rating': rating,
      'comment': comment,
    };
  }
}

class ReviewModel {
  final String id;
  final ReviewType type;
  final String targetId; // tourId, guideId, or bookingId depending on type
  final String reviewerId; // User who wrote the review
  final String reviewerName; // Cached name for display
  final String? reviewerAvatar; // Cached avatar URL

  // Overall rating
  final double overallRating;

  // Detailed criteria ratings
  final List<ReviewCriteria> criteria;

  // Review content
  final String title;
  final String content;
  final List<String>? photos; // URLs of review photos
  final bool isVerified; // Whether reviewer actually experienced the service

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ReviewStatus status;
  final String? moderatorId; // Admin who moderated this review
  final String? moderationReason;
  final DateTime? moderatedAt;

  // Engagement
  final int helpfulCount; // How many users found this helpful
  final List<String> helpfulUsers; // User IDs who marked as helpful

  // Guide response (if applicable)
  final String? guideResponse;
  final DateTime? guideResponseDate;
  final String? guideResponseId;

  // Additional data
  final Map<String, dynamic>? metadata;

  ReviewModel({
    required this.id,
    required this.type,
    required this.targetId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.overallRating,
    this.criteria = const [],
    required this.title,
    required this.content,
    this.photos,
    this.isVerified = false,
    required this.createdAt,
    this.updatedAt,
    this.status = ReviewStatus.pending,
    this.moderatorId,
    this.moderationReason,
    this.moderatedAt,
    this.helpfulCount = 0,
    this.helpfulUsers = const [],
    this.guideResponse,
    this.guideResponseDate,
    this.guideResponseId,
    this.metadata,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> data) {
    return ReviewModel(
      id: data['id'] ?? '',
      type: ReviewType.values[data['type'] ?? 0],
      targetId: data['targetId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? 'Anonymous',
      reviewerAvatar: data['reviewerAvatar'],
      overallRating: (data['overallRating'] ?? 0).toDouble(),
      criteria: (data['criteria'] as List<dynamic>?)
          ?.map((c) => ReviewCriteria.fromMap(c))
          .toList() ?? [],
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
      status: ReviewStatus.values[data['status'] ?? 0],
      moderatorId: data['moderatorId'],
      moderationReason: data['moderationReason'],
      moderatedAt: data['moderatedAt']?.toDate(),
      helpfulCount: data['helpfulCount'] ?? 0,
      helpfulUsers: List<String>.from(data['helpfulUsers'] ?? []),
      guideResponse: data['guideResponse'],
      guideResponseDate: data['guideResponseDate']?.toDate(),
      guideResponseId: data['guideResponseId'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'targetId': targetId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerAvatar': reviewerAvatar,
      'overallRating': overallRating,
      'criteria': criteria.map((c) => c.toMap()).toList(),
      'title': title,
      'content': content,
      'photos': photos ?? [],
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'status': status.index,
      'moderatorId': moderatorId,
      'moderationReason': moderationReason,
      'moderatedAt': moderatedAt,
      'helpfulCount': helpfulCount,
      'helpfulUsers': helpfulUsers,
      'guideResponse': guideResponse,
      'guideResponseDate': guideResponseDate,
      'guideResponseId': guideResponseId,
      'metadata': metadata,
    };
  }

  // Helper methods
  bool get isApproved => status == ReviewStatus.approved;
  bool get isPending => status == ReviewStatus.pending;
  bool get isRejected => status == ReviewStatus.rejected;
  bool get isHidden => status == ReviewStatus.hidden;

  bool get hasGuideResponse => guideResponse != null && guideResponse!.isNotEmpty;

  double get averageCriteriaRating {
    if (criteria.isEmpty) return overallRating;
    final sum = criteria.fold<double>(0, (sum, c) => sum + c.rating);
    return sum / criteria.length;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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

  Color get statusColor {
    switch (status) {
      case ReviewStatus.pending:
        return Colors.orange;
      case ReviewStatus.approved:
        return Colors.green;
      case ReviewStatus.rejected:
        return Colors.red;
      case ReviewStatus.hidden:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case ReviewStatus.pending:
        return 'Pending Review';
      case ReviewStatus.approved:
        return 'Published';
      case ReviewStatus.rejected:
        return 'Rejected';
      case ReviewStatus.hidden:
        return 'Hidden';
    }
  }

  // Create a copy with updated fields
  ReviewModel copyWith({
    String? id,
    ReviewType? type,
    String? targetId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatar,
    double? overallRating,
    List<ReviewCriteria>? criteria,
    String? title,
    String? content,
    List<String>? photos,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReviewStatus? status,
    String? moderatorId,
    String? moderationReason,
    DateTime? moderatedAt,
    int? helpfulCount,
    List<String>? helpfulUsers,
    String? guideResponse,
    DateTime? guideResponseDate,
    String? guideResponseId,
    Map<String, dynamic>? metadata,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatar: reviewerAvatar ?? this.reviewerAvatar,
      overallRating: overallRating ?? this.overallRating,
      criteria: criteria ?? this.criteria,
      title: title ?? this.title,
      content: content ?? this.content,
      photos: photos ?? this.photos,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      moderatorId: moderatorId ?? this.moderatorId,
      moderationReason: moderationReason ?? this.moderationReason,
      moderatedAt: moderatedAt ?? this.moderatedAt,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      helpfulUsers: helpfulUsers ?? this.helpfulUsers,
      guideResponse: guideResponse ?? this.guideResponse,
      guideResponseDate: guideResponseDate ?? this.guideResponseDate,
      guideResponseId: guideResponseId ?? this.guideResponseId,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Legacy compatibility - keep old constructor for backward compatibility
class LegacyReviewModel {
  final String id;
  final String tourId;
  final String touristId;
  final double rating;
  final String review;
  final DateTime timestamp;

  LegacyReviewModel({
    required this.id,
    required this.tourId,
    required this.touristId,
    required this.rating,
    required this.review,
    required this.timestamp,
  });

  // Convert legacy to new format
  ReviewModel toNewFormat() {
    return ReviewModel(
      id: id,
      type: ReviewType.tour,
      targetId: tourId,
      reviewerId: touristId,
      reviewerName: 'Legacy User', // Would need to be populated from user data
      overallRating: rating,
      title: 'Tour Review',
      content: review,
      createdAt: timestamp,
      status: ReviewStatus.approved, // Assume legacy reviews are approved
    );
  }
}
