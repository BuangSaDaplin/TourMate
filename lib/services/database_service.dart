import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/models/chat_room_model.dart';
import 'package:tourmate_app/models/guide_verification_model.dart';
import 'package:tourmate_app/models/itinerary_model.dart';
import 'package:tourmate_app/models/message_model.dart';
import 'package:tourmate_app/models/payment_model.dart';
import 'package:tourmate_app/models/review_model.dart';
import 'package:tourmate_app/models/tour_model.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  // User operations
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc.data()!);
    }
    return null;
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> updateUserVerification(
      String uid, String idUrl, String lguUrl) async {
    await _db.collection('users').doc(uid).update({
      'certificatesURL': idUrl,
      'lguDocumentURL': lguUrl,
      'verificationStatus': 'pending',
    });

    // Send credentials submitted notification to guide
    final credentialsNotification =
        _notificationService.createCredentialsSubmittedNotification(
      userId: uid,
    );
    await _notificationService.createNotification(credentialsNotification);

    // Send LGU document submitted notification to guide
    final lguNotification =
        _notificationService.createLGUDocumentSubmittedNotification(
      userId: uid,
    );
    await _notificationService.createNotification(lguNotification);
  }

  Future<void> updateUserField(String uid, String field, dynamic value) async {
    await _db.collection('users').doc(uid).update({field: value});
  }

  Future<String> uploadCredentialDocument(
      String userId, String credentialType, PlatformFile file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${timestamp}_${file.name}';
    final ref = _storage
        .ref()
        .child('credentials')
        .child(userId)
        .child(credentialType)
        .child(fileName);

    // Handle both mobile and web platforms
    if (kIsWeb) {
      // Web platform - use file bytes
      if (file.bytes == null) {
        throw Exception('File bytes not available for web upload');
      }
      await ref.putData(file.bytes!,
          SettableMetadata(contentType: 'application/octet-stream'));
    } else {
      // Mobile platforms - use file path
      if (file.path == null) {
        throw Exception('File path not available for mobile upload');
      }
      await ref.putFile(File(file.path!));
    }

    return await ref.getDownloadURL();
  }

  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(uid).update(updates);
  }

  // Tour operations
  Future<void> createTour(TourModel tour) async {
    await _db.collection('tours').doc(tour.id).set(tour.toMap());

    // Send tour created notification to guide
    final notification = _notificationService.createTourCreatedNotification(
      userId: tour.createdBy,
      tourTitle: tour.title,
    );
    await _notificationService.createNotification(notification);
  }

  Future<TourModel?> getTour(String id) async {
    final doc = await _db.collection('tours').doc(id).get();
    if (doc.exists) {
      return TourModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateTour(TourModel tour) async {
    await _db.collection('tours').doc(tour.id).update(tour.toMap());

    // Send tour updated notification to guide
    final notification = _notificationService.createTourUpdatedNotification(
      userId: tour.createdBy,
      tourTitle: tour.title,
    );
    await _notificationService.createNotification(notification);
  }

  Future<void> deleteTour(String id) async {
    await _db.collection('tours').doc(id).delete();
  }

  Future<List<TourModel>> getToursByGuide(String guideId) async {
    final snapshot = await _db
        .collection('tours')
        .where('createdBy', isEqualTo: guideId)
        .get();
    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data())).toList();
  }

  Future<List<TourModel>> searchTours(
    String query, {
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    // TODO: Implement advanced search with Algolia or complex Firestore queries
    // For now, return approved tours only (this would need proper implementation)
    final snapshot = await _db
        .collection('tours')
        .where('status', isEqualTo: 'approved')
        .get();
    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data())).toList();
  }

  Future<List<TourModel>> getToursByStatus(String status) async {
    final snapshot =
        await _db.collection('tours').where('status', isEqualTo: status).get();
    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data())).toList();
  }

  Future<List<TourModel>> getAllTours() async {
    final snapshot = await _db.collection('tours').get();
    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data())).toList();
  }

  Future<List<TourModel>> getApprovedTours() async {
    final snapshot = await _db
        .collection('tours')
        .where('status', isEqualTo: 'approved')
        .get();
    return snapshot.docs.map((doc) => TourModel.fromMap(doc.data())).toList();
  }

  Future<void> updateTourStatus(String tourId, String status) async {
    await _db.collection('tours').doc(tourId).update({'status': status});

    // Get tour details for notification
    final tour = await getTour(tourId);
    if (tour != null) {
      // Send tour suggestion approved notification to guide
      if (status == 'approved') {
        final notification =
            _notificationService.createTourSuggestionApprovedNotification(
          userId: tour.createdBy,
          tourTitle: tour.title,
        );
        await _notificationService.createNotification(notification);
      }

      // Send tour suggestion rejected notification to guide
      if (status == 'rejected') {
        final notification =
            _notificationService.createTourSuggestionRejectedNotification(
          userId: tour.createdBy,
          tourTitle: tour.title,
        );
        await _notificationService.createNotification(notification);
      }
    }
  }

  // Booking operations
  Future<void> createBooking(BookingModel booking) async {
    await _db.collection('bookings').doc(booking.id).set(booking.toMap());

    // Send notification to guide about new booking request
    if (booking.guideId != null) {
      // Get tourist details for notification
      final tourist = await getUser(booking.touristId);
      final touristName = tourist?.displayName ?? 'Tourist';

      final notification =
          _notificationService.createNewBookingRequestNotification(
        userId: booking.guideId!,
        tourTitle: booking.tourTitle,
        touristName: touristName,
      );
      await _notificationService.createNotification(notification);
    }
  }

  Future<BookingModel?> getBooking(String id) async {
    final doc = await _db.collection('bookings').doc(id).get();
    if (doc.exists) {
      return BookingModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<BookingModel>> getBookingsByTourist(String touristId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('touristId', isEqualTo: touristId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Stream<List<BookingModel>> getBookingsByTouristStream(String touristId) {
    return _db
        .collection('bookings')
        .where('touristId', isEqualTo: touristId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<List<BookingModel>> getBookingsByGuide(String guideId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('guideId', isEqualTo: guideId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<BookingModel>> getBookingsByTour(String tourId) async {
    final snapshot = await _db
        .collection('bookings')
        .where('tourId', isEqualTo: tourId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<PaymentModel>> getPaymentsByGuide(String guideId) async {
    try {
      // First try with index (if created)
      final snapshot = await _db
          .collection('payments')
          .where('guideId', isEqualTo: guideId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Index not available for payments, trying fallback: $e');
      try {
        // Fallback: fetch without ordering and sort in code
        final snapshot = await _db
            .collection('payments')
            .where('guideId', isEqualTo: guideId)
            .limit(50) // Get more to sort
            .get();

        final payments = snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return payments.take(20).toList();
      } catch (fallbackError) {
        print('Fallback query also failed: $fallbackError');
        // Return empty list if collection doesn't exist or other errors
        return [];
      }
    }
  }

  Future<List<ReviewModel>> getRecentGuideReviews(String guideId) async {
    try {
      // First try with index (if created)
      final snapshot = await _db
          .collection('reviews')
          .where('targetId', isEqualTo: guideId)
          .where('type', isEqualTo: ReviewType.guide.index)
          .where('status', isEqualTo: ReviewStatus.approved.index)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Fallback: fetch without complex filtering and sort in code
      print('Index not available for reviews, using fallback query: $e');
      final snapshot = await _db
          .collection('reviews')
          .where('targetId', isEqualTo: guideId)
          .limit(50) // Get more to filter and sort
          .get();

      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .where((review) =>
              review.type == ReviewType.guide &&
              review.status == ReviewStatus.approved)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reviews.take(20).toList();
    }
  }

  Stream<List<BookingModel>> getBookingsByGuideStream(String guideId) {
    return _db
        .collection('bookings')
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> updateBooking(BookingModel booking) async {
    // Get the existing booking to compare changes
    final existingBooking = await getBooking(booking.id);
    if (existingBooking != null) {
      // Check if tourStartDate was updated
      if (existingBooking.tourStartDate != booking.tourStartDate &&
          booking.guideId != null) {
        final tourist = await getUser(booking.touristId);
        final touristName = tourist?.displayName ?? 'Tourist';
        final notification =
            _notificationService.createBookingDateModifiedNotification(
          userId: booking.guideId!,
          tourTitle: booking.tourTitle,
          touristName: touristName,
        );
        await _notificationService.createNotification(notification);
      }

      // Check if specialRequests was updated
      if (existingBooking.specialRequests != booking.specialRequests &&
          booking.guideId != null) {
        final tourist = await getUser(booking.touristId);
        final touristName = tourist?.displayName ?? 'Tourist';
        final notification =
            _notificationService.createBookingItineraryModifiedNotification(
          userId: booking.guideId!,
          tourTitle: booking.tourTitle,
          touristName: touristName,
        );
        await _notificationService.createNotification(notification);
      }
    }

    await _db.collection('bookings').doc(booking.id).update(booking.toMap());
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status, {
    String? cancellationReason,
    DateTime? cancelledAt,
    DateTime? completedAt,
    DateTime? paidAt,
  }) async {
    final updateData = <String, dynamic>{
      'status': status.index,
    };

    if (cancellationReason != null) {
      updateData['cancellationReason'] = cancellationReason;
    }
    if (cancelledAt != null) {
      updateData['cancelledAt'] = cancelledAt;
    }
    if (completedAt != null) {
      updateData['completedAt'] = completedAt;
    }
    if (paidAt != null) {
      updateData['paidAt'] = paidAt;
    }

    await _db.collection('bookings').doc(bookingId).update(updateData);

    // Get booking details for notification
    final booking = await getBooking(bookingId);
    if (booking != null) {
      // Get tour details for tour title
      final tour = await getTour(booking.tourId);
      final tourTitle = tour?.title ?? 'Tour';

      // Get tourist details for guide notifications
      final tourist = await getUser(booking.touristId);
      final touristName = tourist?.displayName ?? 'Tourist';

      // Send booking confirmed notification to tourist
      if (status == BookingStatus.confirmed) {
        final guide = await getUser(booking.guideId!);
        final guideName = guide?.displayName ?? 'Guide';
        final notification = _notificationService.createBookingNotification(
          userId: booking.touristId,
          tourTitle: tourTitle,
          guideName: guideName,
          bookingDate: booking.bookingDate,
        );
        await _notificationService.createNotification(notification);

        // Send booking accepted notification to guide
        final guideNotification =
            _notificationService.createBookingAcceptedNotification(
          userId: booking.guideId!,
          tourTitle: tourTitle,
          touristName: touristName,
        );
        await _notificationService.createNotification(guideNotification);
      }

      // Send booking rejected notification to tourist
      if (status == BookingStatus.rejected) {
        final guide = await getUser(booking.guideId!);
        final guideName = guide?.displayName ?? 'Guide';
        final notification =
            _notificationService.createBookingRejectedNotification(
          userId: booking.touristId,
          tourTitle: tourTitle,
          guideName: guideName,
        );
        await _notificationService.createNotification(notification);

        // Send booking declined notification to guide
        final guideNotification =
            _notificationService.createBookingDeclinedNotification(
          userId: booking.guideId!,
          tourTitle: tourTitle,
          touristName: touristName,
        );
        await _notificationService.createNotification(guideNotification);
      }

      // Send booking canceled notification to tourist
      if (status == BookingStatus.cancelled) {
        final notification =
            _notificationService.createTourCancelledByTouristNotification(
          userId: booking.touristId,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(notification);
      }

      // Send payment successful notification to tourist
      if (paidAt != null) {
        final notification = _notificationService.createPaymentNotification(
          userId: booking.touristId,
          amount: booking.totalPrice,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(notification);

        // Send payment received notification to guide
        final paymentReceivedNotification =
            _notificationService.createPaymentReceivedNotification(
          userId: booking.guideId!,
          tourTitle: tourTitle,
          amount: booking.totalPrice,
        );
        await _notificationService
            .createNotification(paymentReceivedNotification);
      }

      // Send payment recorded notification to tourist
      if (paidAt != null) {
        final notification =
            _notificationService.createPaymentRecordedNotification(
          userId: booking.touristId,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(notification);
      }

      // Send tour completed notification to tourist
      if (completedAt != null) {
        final notification =
            _notificationService.createTourCompletedNotification(
          userId: booking.touristId,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(notification);

        // Send tour completed successfully notification to guide
        final guideNotification =
            _notificationService.createTourCompletedSuccessfullyNotification(
          userId: booking.guideId!,
          tourTitle: tourTitle,
        );
        await _notificationService.createNotification(guideNotification);
      }
    }
  }

  Future<void> updateBookingWithReview(
    String bookingId, {
    required String reviewContent,
    required double rating,
    required DateTime reviewCreatedAt,
    required String reviewerId,
    required String reviewerName,
    required ReviewSubmissionStatus reviewStatus,
    DateTime? reviewModeratedAt,
    String? reviewModerateReason,
  }) async {
    final updateData = <String, dynamic>{
      'reviewContent': reviewContent,
      'rating': rating,
      'reviewCreatedAt': reviewCreatedAt,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewStatus': reviewStatus.index,
    };

    if (reviewModeratedAt != null) {
      updateData['reviewModeratedAt'] = reviewModeratedAt;
    }
    if (reviewModerateReason != null) {
      updateData['reviewModerateReason'] = reviewModerateReason;
    }

    await _db.collection('bookings').doc(bookingId).update(updateData);
  }

  // Itinerary operations
  Future<void> createItinerary(ItineraryModel itinerary) async {
    await _db
        .collection('itineraries')
        .doc(itinerary.id)
        .set(itinerary.toMap());
  }

  Future<ItineraryModel?> getItinerary(String id) async {
    final doc = await _db.collection('itineraries').doc(id).get();
    if (doc.exists) {
      return ItineraryModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Review operations
  Future<void> createReview(ReviewModel review) async {
    final reviewData = review.toMap();
    reviewData['createdAt'] = FieldValue.serverTimestamp();
    reviewData['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('reviews').doc(review.id).set(reviewData);
  }

  Future<ReviewModel?> getReview(String reviewId) async {
    final doc = await _db.collection('reviews').doc(reviewId).get();
    if (doc.exists) {
      return ReviewModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<ReviewModel>> getReviewsByTarget(
      String targetId, ReviewType type) async {
    final snapshot = await _db
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .where('type', isEqualTo: type.index)
        .where('status', isEqualTo: ReviewStatus.approved.index)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data())).toList();
  }

  Future<List<ReviewModel>> getTourReviews(String tourId) async {
    return getReviewsByTarget(tourId, ReviewType.tour);
  }

  Future<List<ReviewModel>> getGuideReviews(String guideId) async {
    return getReviewsByTarget(guideId, ReviewType.guide);
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    final snapshot = await _db
        .collection('reviews')
        .where('reviewerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => ReviewModel.fromMap(doc.data())).toList();
  }

  Future<void> updateReviewStatus(
    String reviewId,
    ReviewStatus status, {
    String? moderatorId,
    String? moderationReason,
  }) async {
    final updateData = {
      'status': status.index,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (moderatorId != null) {
      updateData['moderatorId'] = moderatorId;
      if (moderationReason != null) {
        updateData['moderationReason'] = moderationReason;
      }
      updateData['moderatedAt'] = FieldValue.serverTimestamp();
    }

    await _db.collection('reviews').doc(reviewId).update(updateData);
  }

  Future<void> addGuideResponse(
      String reviewId, String response, String guideId) async {
    await _db.collection('reviews').doc(reviewId).update({
      'guideResponse': response,
      'guideResponseDate': FieldValue.serverTimestamp(),
      'guideResponseId': guideId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReviewHelpful(String reviewId, String userId) async {
    final reviewRef = _db.collection('reviews').doc(reviewId);

    // Check if user already marked as helpful
    final reviewDoc = await reviewRef.get();
    if (reviewDoc.exists) {
      final review = ReviewModel.fromMap(reviewDoc.data()!);
      if (!review.helpfulUsers.contains(userId)) {
        await reviewRef.update({
          'helpfulCount': FieldValue.increment(1),
          'helpfulUsers': FieldValue.arrayUnion([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<Map<String, dynamic>> getReviewAnalytics(
      String targetId, ReviewType type) async {
    final reviews = await getReviewsByTarget(targetId, type);

    if (reviews.isEmpty) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        'criteriaAverages': {},
      };
    }

    final ratingDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final criteriaSums = <String, double>{};
    final criteriaCounts = <String, int>{};

    for (final review in reviews) {
      final rating = review.overallRating.round();
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;

      for (final criteria in review.criteria) {
        criteriaSums[criteria.name] =
            (criteriaSums[criteria.name] ?? 0) + criteria.rating;
        criteriaCounts[criteria.name] =
            (criteriaCounts[criteria.name] ?? 0) + 1;
      }
    }

    final criteriaAverages = <String, double>{};
    criteriaSums.forEach((name, sum) {
      criteriaAverages[name] = sum / (criteriaCounts[name] ?? 1);
    });

    return {
      'totalReviews': reviews.length,
      'averageRating':
          reviews.map((r) => r.overallRating).reduce((a, b) => a + b) /
              reviews.length,
      'ratingDistribution': ratingDistribution,
      'criteriaAverages': criteriaAverages,
    };
  }

  Future<void> deleteReview(String reviewId) async {
    await _db.collection('reviews').doc(reviewId).delete();
  }

  // Get bookings with reviews for admin moderation
  Future<List<BookingModel>> getBookingsWithReviews() async {
    final snapshot = await _db
        .collection('bookings')
        .where('reviewStatus', isNotEqualTo: null)
        .orderBy('reviewCreatedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<BookingModel>> getPendingReviewBookings() async {
    final snapshot = await _db
        .collection('bookings')
        .where('reviewStatus', isEqualTo: ReviewSubmissionStatus.pending.index)
        .orderBy('reviewCreatedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<BookingModel>> getApprovedReviewBookings() async {
    final snapshot = await _db
        .collection('bookings')
        .where('reviewStatus', isEqualTo: ReviewSubmissionStatus.approved.index)
        .orderBy('reviewCreatedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Future<List<BookingModel>> getModeratedReviewBookings() async {
    final snapshot = await _db
        .collection('bookings')
        .where('reviewStatus',
            isEqualTo: ReviewSubmissionStatus.moderated.index)
        .orderBy('reviewCreatedAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateBookingReviewStatus(
    String bookingId,
    ReviewSubmissionStatus status, {
    String? moderatorId,
    String? moderationReason,
  }) async {
    final updateData = {
      'reviewStatus': status.index,
      'reviewModeratedAt': FieldValue.serverTimestamp(),
    };

    if (moderatorId != null) {
      updateData['moderatorId'] = moderatorId;
      if (moderationReason != null) {
        updateData['reviewModerateReason'] = moderationReason;
      }
    }

    await _db.collection('bookings').doc(bookingId).update(updateData);
  }

  Future<void> deleteBookingReview(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).update({
      'reviewContent': FieldValue.delete(),
      'rating': FieldValue.delete(),
      'reviewCreatedAt': FieldValue.delete(),
      'reviewerId': FieldValue.delete(),
      'reviewerName': FieldValue.delete(),
      'reviewStatus': FieldValue.delete(),
      'reviewModeratedAt': FieldValue.delete(),
      'reviewModerateReason': FieldValue.delete(),
    });
  }

  // Enhanced Messaging operations
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(MessageModel message) async {
    final messageData = message.toMap();
    messageData['timestamp'] = FieldValue.serverTimestamp();

    // Add message to chat room
    await _db
        .collection('chat_rooms')
        .doc(message.chatRoomId)
        .collection('messages')
        .add(messageData);

    // Update chat room's last message info
    await _db.collection('chat_rooms').doc(message.chatRoomId).update({
      'lastMessage': message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageSenderName': message.senderName,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Increment unread count for other participants
    final chatRoomDoc =
        await _db.collection('chat_rooms').doc(message.chatRoomId).get();
    if (chatRoomDoc.exists) {
      final chatRoom = ChatRoomModel.fromMap(chatRoomDoc.data()!);
      final otherParticipants =
          chatRoom.participants.where((id) => id != message.senderId);

      // Update unread counts for other participants
      for (final participantId in otherParticipants) {
        await _db.collection('chat_rooms').doc(message.chatRoomId).update({
          'unreadCount_$participantId': FieldValue.increment(1),
        });

        // Send new message notification to other participants
        final notification = _notificationService.createMessageNotification(
          userId: participantId,
          senderName: message.senderName,
          message: message.content,
        );
        await _notificationService.createNotification(notification);
      }
    }
  }

  Future<ChatRoomModel?> getChatRoom(String chatRoomId) async {
    final doc = await _db.collection('chat_rooms').doc(chatRoomId).get();
    if (doc.exists) {
      return ChatRoomModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<ChatRoomModel?> createChatRoom(ChatRoomModel chatRoom) async {
    final chatRoomData = chatRoom.toMap();
    chatRoomData['createdAt'] = FieldValue.serverTimestamp();
    chatRoomData['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection('chat_rooms').doc(chatRoom.id).set(chatRoomData);
    return chatRoom;
  }

  Future<ChatRoomModel?> getOrCreateChatRoom({
    required String currentUserId,
    required String otherUserId,
    required String currentUserName,
    required String otherUserName,
    required String currentUserRole,
    required String otherUserRole,
    String? relatedBookingId,
    String? relatedTourId,
  }) async {
    // Generate consistent chat room ID
    final chatRoomId =
        ChatRoomModel.generateChatRoomId(currentUserId, otherUserId);

    // Check if chat room already exists
    final existingRoom = await getChatRoom(chatRoomId);
    if (existingRoom != null) {
      return existingRoom;
    }

    // Create new chat room
    final newChatRoom = ChatRoomModel(
      id: chatRoomId,
      title: '$currentUserName & $otherUserName',
      description: 'Private conversation',
      type: ChatRoomType.touristGuide,
      participants: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      participantRoles: {
        currentUserId: currentUserRole,
        otherUserId: otherUserRole,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      relatedBookingId: relatedBookingId,
      relatedTourId: relatedTourId,
    );

    return await createChatRoom(newChatRoom);
  }

  Stream<List<ChatRoomModel>> getUserChatRooms(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: ChatRoomStatus.active.index)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Add current user's unread count
        data['unreadCount'] = data['unreadCount_$userId'] ?? 0;
        return ChatRoomModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    // Reset unread count for this user
    await _db.collection('chat_rooms').doc(chatRoomId).update({
      'unreadCount_$userId': 0,
    });

    // Mark all messages in this chat room as read by this user
    final messages = await _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('readBy', arrayContains: userId)
        .get();

    final batch = _db.batch();
    for (final doc in messages.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? []);
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        batch.update(doc.reference, {'readBy': readBy});
      }
    }
    await batch.commit();
  }

  Future<void> updateChatRoomStatus(
      String chatRoomId, ChatRoomStatus status) async {
    await _db.collection('chat_rooms').doc(chatRoomId).update({
      'status': status.index,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin monitoring methods
  Stream<List<ChatRoomModel>> getAllChatRooms() {
    return _db
        .collection('chat_rooms')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<MessageModel>> getChatRoomMessages(String chatRoomId,
      {int limit = 50}) async {
    final snapshot = await _db
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MessageModel.fromMap(data);
    }).toList();
  }

  Future<Map<String, dynamic>> getMessagingAnalytics() async {
    final chatRooms = await _db.collection('chat_rooms').get();
    final messages = await _db
        .collection('chat_rooms')
        .get()
        .then((chatRoomsSnapshot) async {
      int totalMessages = 0;
      for (final chatRoomDoc in chatRoomsSnapshot.docs) {
        final messagesSnapshot =
            await chatRoomDoc.reference.collection('messages').get();
        totalMessages += messagesSnapshot.docs.length;
      }
      return totalMessages;
    });

    return {
      'totalChatRooms': chatRooms.docs.length,
      'totalMessages': messages,
      'activeChatRooms': chatRooms.docs
          .where((doc) => doc.data()['status'] == ChatRoomStatus.active.index)
          .length,
    };
  }

  // Guide Verification operations
  Future<void> submitGuideVerification(GuideVerification verification) async {
    await _db
        .collection('guide_verifications')
        .doc(verification.id)
        .set(verification.toMap());
  }

  Future<GuideVerification?> getGuideVerification(String guideId) async {
    final doc = await _db.collection('guide_verifications').doc(guideId).get();
    if (doc.exists) {
      return GuideVerification.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<GuideVerification>> getAllGuideVerifications() async {
    final snapshot = await _db.collection('guide_verifications').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return GuideVerification.fromMap(data);
    }).toList();
  }

  Future<List<GuideVerification>> getGuideVerificationsByStatus(
      VerificationStatus status) async {
    // TODO: Implement Firebase Firestore integration
    // final snapshot = await _db
    //     .collection('guide_verifications')
    //     .where('status', isEqualTo: status.index)
    //     .get();
    // return snapshot.docs.map((doc) => GuideVerification.fromMap(doc.data())).toList();
    throw UnimplementedError(
        'getGuideVerificationsByStatus not implemented yet');
  }

  Future<void> updateGuideVerificationStatus(
    String verificationId,
    VerificationStatus status,
    String reviewedBy, {
    String? rejectionReason,
  }) async {
    await _db.collection('guide_verifications').doc(verificationId).update({
      'status': status.index,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    });
  }

  // Tour moderation operations
  Future<void> reportTour(
      String tourId, String reporterId, String reason) async {
    // TODO: Implement Firebase Firestore integration
    // await _db.collection('tour_reports').add({
    //   'tourId': tourId,
    //   'reporterId': reporterId,
    //   'reason': reason,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
    throw UnimplementedError('reportTour not implemented yet');
  }

  Future<List<Map<String, dynamic>>> getTourReports(String tourId) async {
    // TODO: Implement Firebase Firestore integration
    // final snapshot = await _db.collection('tour_reports').where('tourId', isEqualTo: tourId).get();
    // return snapshot.docs.map((doc) => doc.data()).toList();
    throw UnimplementedError('getTourReports not implemented yet');
  }

  Future<void> moderateTour(
      String tourId, String moderatorId, String action, String? reason) async {
    // TODO: Implement Firebase Firestore integration
    // await _db.collection('tour_moderations').add({
    //   'tourId': tourId,
    //   'moderatorId': moderatorId,
    //   'action': action, // 'approve', 'suspend', 'review'
    //   'reason': reason,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
    throw UnimplementedError('moderateTour not implemented yet');
  }

  // Media operations for tours
  Future<String> uploadTourMedia(String tourId, PlatformFile file) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${timestamp}_${file.name}';
    final ref =
        _storage.ref().child('tour_media').child(tourId).child(fileName);

    // Handle both mobile and web platforms
    if (kIsWeb) {
      // Web platform - use file bytes
      if (file.bytes == null) {
        throw Exception('File bytes not available for web upload');
      }
      await ref.putData(
          file.bytes!, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      // Mobile platforms - use file path
      if (file.path == null) {
        throw Exception('File path not available for mobile upload');
      }
      await ref.putFile(File(file.path!));
    }

    return await ref.getDownloadURL();
  }

  Future<void> deleteTourMedia(String mediaUrl) async {
    // TODO: Implement Firebase Storage integration
    // final ref = _storage.refFromURL(mediaUrl);
    // await ref.delete();
    throw UnimplementedError('deleteTourMedia not implemented yet');
  }
}
