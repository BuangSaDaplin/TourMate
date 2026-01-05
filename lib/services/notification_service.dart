import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
      // Sort in memory instead of using compound query
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Get unread notifications count
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Create a new notification
  Future<void> createNotification(NotificationModel notification) async {
    await _db
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': DateTime.now().toIso8601String(),
    });
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final notifications = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // Send notification to multiple users
  Future<void> sendBulkNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
  }) async {
    final batch = _db.batch();
    final now = DateTime.now();

    for (final userId in userIds) {
      final notificationId =
          '${userId}_${now.millisecondsSinceEpoch}_${userIds.indexOf(userId)}';
      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        data: data,
        createdAt: now,
      );

      final docRef = _db.collection('notifications').doc(notificationId);
      batch.set(docRef, notification.toMap());
    }

    await batch.commit();
  }

  // Initialize Firebase Messaging
  Future<void> initializeMessaging() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');
      // Handle the message (show local notification, etc.)
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from notification: ${message.notification?.title}');
      // Navigate to relevant screen
    });
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling background message: ${message.notification?.title}');
  }

  // Send push notification via FCM (would typically be done from backend)
  Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // This would typically be handled by your backend server
    // Integrate with Firebase Cloud Messaging or similar service
    throw UnimplementedError('Push notification integration not implemented');
  }

  // Notification templates for common events
  NotificationModel createBookingNotification({
    required String userId,
    required String tourTitle,
    required String guideName,
    required DateTime bookingDate,
  }) {
    return NotificationModel(
      id: 'booking_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Confirmed',
      message:
          'Your booking for "$tourTitle" with $guideName has been confirmed for ${bookingDate.toString().split(' ')[0]}.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {
        'tourTitle': tourTitle,
        'guideName': guideName,
        'bookingDate': bookingDate.toIso8601String(),
      },
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPaymentNotification({
    required String userId,
    required double amount,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'payment_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Payment Successful',
      message:
          'Payment of \$${amount.toStringAsFixed(2)} for "$tourTitle" has been processed successfully.',
      type: NotificationType.payment,
      priority: NotificationPriority.normal,
      data: {
        'amount': amount,
        'tourTitle': tourTitle,
      },
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createMessageNotification({
    required String userId,
    required String senderName,
    required String message,
  }) {
    return NotificationModel(
      id: 'message_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'New Message',
      message:
          '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      type: NotificationType.message,
      priority: NotificationPriority.normal,
      data: {
        'senderName': senderName,
        'fullMessage': message,
      },
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createReviewNotification({
    required String userId,
    required String tourTitle,
    required double rating,
  }) {
    return NotificationModel(
      id: 'review_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'New Review',
      message:
          'You received a ${rating.toStringAsFixed(1)} star review for "$tourTitle".',
      type: NotificationType.review,
      priority: NotificationPriority.normal,
      data: {
        'tourTitle': tourTitle,
        'rating': rating,
      },
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createVerificationNotification({
    required String userId,
    required String status,
  }) {
    final isApproved = status == 'approved';
    return NotificationModel(
      id: 'verification_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: isApproved ? 'Verification Approved' : 'Verification Update',
      message: isApproved
          ? 'Congratulations! Your guide verification has been approved. You can now start accepting bookings.'
          : 'Your verification documents need review. Please check your submitted documents.',
      type: NotificationType.verification,
      priority:
          isApproved ? NotificationPriority.high : NotificationPriority.normal,
      data: {'status': status},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createSystemNotification({
    required String userId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return NotificationModel(
      id: 'system_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.system,
      priority: priority,
      createdAt: DateTime.now(),
    );
  }

  // Additional notification templates for tourist-specific events
  NotificationModel createBookingSubmittedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'booking_submitted_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Request Submitted',
      message:
          'Your booking request for "$tourTitle" has been submitted successfully. You will be notified once the guide responds.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingRejectedNotification({
    required String userId,
    required String tourTitle,
    required String guideName,
  }) {
    return NotificationModel(
      id: 'booking_rejected_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Rejected',
      message:
          'Your booking request for $tourTitle has been rejected by the tour guide.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'guideName': guideName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingAutoCancelledNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'booking_auto_cancelled_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Auto-Cancelled',
      message:
          'Your booking request for "$tourTitle" has been auto-cancelled due to no response from the guide within the time limit.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPaymentFailedNotification({
    required String userId,
    required double amount,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'payment_failed_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Payment Failed',
      message:
          'Payment of \$${amount.toStringAsFixed(2)} for "$tourTitle" has failed. Please try again or contact support.',
      type: NotificationType.payment,
      priority: NotificationPriority.high,
      data: {'amount': amount, 'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createRefundProcessedNotification({
    required String userId,
    required double amount,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'refund_processed_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Refund Processed',
      message:
          'Refund of \$${amount.toStringAsFixed(2)} for "$tourTitle" has been processed successfully.',
      type: NotificationType.payment,
      priority: NotificationPriority.normal,
      data: {'amount': amount, 'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPartialRefundNotification({
    required String userId,
    required double amount,
    required String tourTitle,
    required String reason,
  }) {
    return NotificationModel(
      id: 'partial_refund_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Partial Refund Issued',
      message:
          'A partial refund of \$${amount.toStringAsFixed(2)} for "$tourTitle" has been issued. Reason: $reason.',
      type: NotificationType.payment,
      priority: NotificationPriority.normal,
      data: {'amount': amount, 'tourTitle': tourTitle, 'reason': reason},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourScheduleUpdatedNotification({
    required String userId,
    required String tourTitle,
    required String guideName,
  }) {
    return NotificationModel(
      id: 'tour_schedule_updated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Schedule Updated',
      message:
          'The schedule for your tour "$tourTitle" with $guideName has been updated. Please check the details.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'guideName': guideName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourStartingSoonNotification({
    required String userId,
    required String tourTitle,
    required String timeRemaining,
  }) {
    return NotificationModel(
      id: 'tour_starting_soon_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Starting Soon',
      message:
          'Your tour "$tourTitle" is starting in $timeRemaining. Get ready!',
      type: NotificationType.booking,
      priority: NotificationPriority.high,
      data: {'tourTitle': tourTitle, 'timeRemaining': timeRemaining},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCompletedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_completed_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Completed Successfully',
      message:
          'Your tour "$tourTitle" has been completed successfully. Don\'t forget to rate and review your guide!',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCompletedForGuideNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'tour_completed_guide_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Completed Successfully',
      message:
          'Your tour "$tourTitle" with $touristName has been completed successfully. Don\'t forget to rate and review your tourist!',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCancelledByGuideNotification({
    required String userId,
    required String tourTitle,
    required String guideName,
  }) {
    return NotificationModel(
      id: 'tour_cancelled_guide_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Cancelled by Guide',
      message:
          'Your booking for $tourTitle has been cancelled by the tour guide.',
      type: NotificationType.booking,
      priority: NotificationPriority.high,
      data: {'tourTitle': tourTitle, 'guideName': guideName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCancelledByAdminNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_cancelled_admin_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Cancelled by Admin',
      message:
          'Your tour "$tourTitle" has been cancelled by the administrator.',
      type: NotificationType.system,
      priority: NotificationPriority.high,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCancelledByTouristNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_cancelled_tourist_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'You Cancelled a Tour',
      message: 'You cancelled your $tourTitle tour.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingCompletedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'booking_completed_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Completed Successfully',
      message:
          'Your booking for "$tourTitle" has been completed successfully. Don\'t forget to rate and review your guide!',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createRateAndReviewPromptNotification({
    required String userId,
    required String tourTitle,
    required String guideName,
  }) {
    return NotificationModel(
      id: 'rate_review_prompt_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Rate and Review Your Guide',
      message:
          'How was your experience with $guideName on "$tourTitle"? Please take a moment to rate and review.',
      type: NotificationType.review,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'guideName': guideName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createReviewSubmittedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'review_submitted_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Review Successfully Submitted',
      message:
          'Your review for "$tourTitle" has been submitted successfully. Thank you for your feedback!',
      type: NotificationType.review,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createAccountSuspendedNotification({
    required String userId,
    required String reason,
  }) {
    return NotificationModel(
      id: 'account_suspended_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Account Suspended or Restricted',
      message:
          'Your account has been suspended or restricted. Reason: $reason. Please contact support for assistance.',
      type: NotificationType.system,
      priority: NotificationPriority.urgent,
      data: {'reason': reason},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createItineraryUpdatedNotification({
    required String userId,
    required String tourTitle,
    required String guideName,
  }) {
    return NotificationModel(
      id: 'itinerary_updated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Itinerary Updated',
      message:
          'The itinerary for your tour "$tourTitle" with $guideName has been updated. Please check the details.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'guideName': guideName},
      createdAt: DateTime.now(),
    );
  }

  // Tourist-specific notification templates
  NotificationModel createSuccessfulRegistrationNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'registration_success_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Welcome to TourMate!',
      message: 'Your account has been created successfully.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createLoginAlertNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'login_alert_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Login Alert',
      message: 'You logged in to your account.',
      type: NotificationType.system,
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createProfileUpdatedNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'profile_updated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Profile Updated',
      message: 'Your profile information was updated.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPasswordChangedNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'password_changed_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Password Changed',
      message: 'Your password has been changed successfully.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createUpcomingTourReminderNotification({
    required String userId,
    required String tourTitle,
    required DateTime tourDate,
  }) {
    return NotificationModel(
      id: 'upcoming_tour_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Upcoming Tour Reminder',
      message:
          'You have an upcoming tour scheduled on ${tourDate.toString().split(' ')[0]}.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'tourDate': tourDate.toIso8601String()},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPaymentRecordedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'payment_recorded_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Payment Recorded',
      message: 'A new transaction has been added to your payment history.',
      type: NotificationType.payment,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createItineraryGeneratedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'itinerary_generated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Itinerary Generated',
      message: 'Your itinerary has been generated.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createItinerarySharedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'itinerary_shared_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Itinerary Shared',
      message: 'Your itinerary has been shared.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  // Tour Guide specific notification templates
  NotificationModel createGuideLoginNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'guide_login_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Login Successful',
      message: 'You have successfully logged in.',
      type: NotificationType.system,
      priority: NotificationPriority.low,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createGuideProfileUpdatedNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'guide_profile_updated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Profile Updated',
      message: 'Your profile information has been updated.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createGuidePasswordChangedNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'guide_password_changed_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Password Changed',
      message: 'Your password has been changed successfully.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createCredentialsSubmittedNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'credentials_submitted_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Credentials Submitted',
      message: 'Your guide credentials have been submitted for verification.',
      type: NotificationType.verification,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createLGUDocumentSubmittedNotification({
    required String userId,
  }) {
    return NotificationModel(
      id: 'lgu_document_submitted_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'LGU Document Submitted',
      message: 'Your LGU certification has been submitted for verification.',
      type: NotificationType.verification,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createVerificationStatusUpdateNotification({
    required String userId,
    required String status,
  }) {
    String title;
    String message;
    NotificationPriority priority;

    switch (status.toLowerCase()) {
      case 'approved':
        title = 'Verification Approved';
        message =
            'Your guide verification status has been updated to Approved.';
        priority = NotificationPriority.high;
        break;
      case 'pending':
        title = 'Verification Pending';
        message = 'Your guide verification status has been updated to Pending.';
        priority = NotificationPriority.normal;
        break;
      case 'rejected':
        title = 'Verification Rejected';
        message =
            'Your guide verification status has been updated to Rejected.';
        priority = NotificationPriority.high;
        break;
      default:
        title = 'Verification Status Update';
        message = 'Your guide verification status has been updated.';
        priority = NotificationPriority.normal;
    }

    return NotificationModel(
      id: 'verification_status_update_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.verification,
      priority: priority,
      data: {'status': status},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCreatedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_created_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Suggestion Submitted',
      message:
          'Your tour listing "$tourTitle" has been successfully submitted for suggestion. Wait for admin approval.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourUpdatedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_updated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Updated',
      message:
          'Your tour details for "$tourTitle" (price, duration, or category) were updated.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createMediaUploadedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'media_uploaded_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Media Uploaded',
      message:
          'Images/videos have been added to your tour listing "$tourTitle".',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createNewBookingRequestNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'new_booking_request_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'New Booking Request',
      message:
          'You received a new booking request for "$tourTitle" from $touristName.',
      type: NotificationType.booking,
      priority: NotificationPriority.high,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingAcceptedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'booking_accepted_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Accepted',
      message:
          'You accepted a booking request for "$tourTitle" from $touristName.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingDeclinedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'booking_declined_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Declined',
      message:
          'You declined a booking request for "$tourTitle" from $touristName.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingModifiedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'booking_modified_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Modified',
      message:
          'Booking time or status for "$tourTitle" with $touristName has been updated.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourCompletedSuccessfullyNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_completed_success_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Completed Successfully',
      message:
          'Your tour "$tourTitle" has been completed successfully. You can check the tourist review in history tab!',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createGuideUpcomingTourReminderNotification({
    required String userId,
    required String tourTitle,
    required DateTime tourDate,
  }) {
    return NotificationModel(
      id: 'guide_upcoming_tour_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Upcoming Tour Reminder',
      message:
          'You have an upcoming tour "$tourTitle" scheduled on ${tourDate.toString().split(' ')[0]}.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'tourDate': tourDate.toIso8601String()},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPaymentRecordAvailableNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'payment_record_available_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Payment Record Available',
      message:
          'A new payment record for "$tourTitle" is available in your payment history.',
      type: NotificationType.payment,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createMessageFromTouristNotification({
    required String userId,
    required String touristName,
    required String message,
  }) {
    return NotificationModel(
      id: 'message_from_tourist_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Message from Tourist',
      message:
          'You received a new message from $touristName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      type: NotificationType.message,
      priority: NotificationPriority.normal,
      data: {'touristName': touristName, 'fullMessage': message},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createGuideItineraryGeneratedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'guide_itinerary_generated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Itinerary Generated',
      message:
          'An auto-generated itinerary for "$tourTitle" with $touristName is available for a booking.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createGuideItineraryUpdatedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'guide_itinerary_updated_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Itinerary Updated',
      message:
          'The itinerary for "$tourTitle" with $touristName has been updated.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createGuideItinerarySharedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'guide_itinerary_shared_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Itinerary Shared',
      message:
          'The itinerary for "$tourTitle" has been shared with $touristName.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createNewReviewReceivedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
    required double rating,
  }) {
    return NotificationModel(
      id: 'new_review_received_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'New Review Received',
      message:
          'You received new feedback (${rating.toStringAsFixed(1)} stars) from $touristName for "$tourTitle".',
      type: NotificationType.review,
      priority: NotificationPriority.normal,
      data: {
        'tourTitle': tourTitle,
        'touristName': touristName,
        'rating': rating
      },
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingDateModifiedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'booking_date_modified_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Date Modified',
      message:
          'The booking date for "$tourTitle" with $touristName has been updated.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createBookingItineraryModifiedNotification({
    required String userId,
    required String tourTitle,
    required String touristName,
  }) {
    return NotificationModel(
      id: 'booking_itinerary_modified_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Booking Itinerary Modified',
      message:
          'The itinerary for "$tourTitle" with $touristName has been updated.',
      type: NotificationType.booking,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'touristName': touristName},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createPaymentReceivedNotification({
    required String userId,
    required String tourTitle,
    required double amount,
  }) {
    return NotificationModel(
      id: 'payment_received_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Payment Received',
      message:
          'You have received payment of \$${amount.toStringAsFixed(2)} for "$tourTitle".',
      type: NotificationType.payment,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle, 'amount': amount},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourSuggestionApprovedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_suggestion_approved_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Suggestion Approved',
      message: 'Your tour suggestion "$tourTitle" has been approved.',
      type: NotificationType.system,
      priority: NotificationPriority.high,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }

  NotificationModel createTourSuggestionRejectedNotification({
    required String userId,
    required String tourTitle,
  }) {
    return NotificationModel(
      id: 'tour_suggestion_rejected_${userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: 'Tour Suggestion Rejected',
      message: 'Your tour suggestion "$tourTitle" has been rejected.',
      type: NotificationType.system,
      priority: NotificationPriority.normal,
      data: {'tourTitle': tourTitle},
      createdAt: DateTime.now(),
    );
  }
}
