import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/booking_model.dart';
import 'package:tourmate_app/services/database_service.dart';
import 'package:tourmate_app/services/notification_service.dart';

class TourReminderService {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _reminderTimer;
  static const Duration _checkInterval =
      Duration(minutes: 30); // Check every 30 minutes
  static const Duration _reminderThreshold =
      Duration(hours: 1); // Notify 1 hour before

  // Collection to track sent reminders to avoid duplicates
  static const String _remindersCollection = 'tour_reminders';

  void startReminderService() {
    print('Starting tour reminder service...');
    _checkAndSendReminders(); // Initial check
    _reminderTimer =
        Timer.periodic(_checkInterval, (_) => _checkAndSendReminders());
  }

  void stopReminderService() {
    print('Stopping tour reminder service...');
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  Future<void> _checkAndSendReminders() async {
    try {
      print('Checking for tours starting soon...');
      final now = DateTime.now();
      final reminderTime = now.add(_reminderThreshold);

      // Get all confirmed/paid bookings
      final bookingsSnapshot =
          await _firestore.collection('bookings').where('status', whereIn: [
        BookingStatus.confirmed.index,
        BookingStatus.paid.index,
        BookingStatus.inProgress.index
      ]).get();

      for (final doc in bookingsSnapshot.docs) {
        final booking = BookingModel.fromMap(doc.data());
        final timeUntilTour = booking.tourStartDate.difference(now);

        // Check if tour starts within the reminder threshold
        if (timeUntilTour > Duration.zero &&
            timeUntilTour <= _reminderThreshold) {
          // Check if reminder already sent
          final reminderId =
              'reminder_${booking.id}_${booking.tourStartDate.millisecondsSinceEpoch}';
          final existingReminder = await _firestore
              .collection(_remindersCollection)
              .doc(reminderId)
              .get();

          if (!existingReminder.exists) {
            await _sendTourStartingSoonNotification(booking);

            // Mark reminder as sent
            await _firestore
                .collection(_remindersCollection)
                .doc(reminderId)
                .set({
              'bookingId': booking.id,
              'touristId': booking.touristId,
              'tourTitle': booking.tourTitle,
              'tourStartDate': booking.tourStartDate,
              'reminderSentAt': now,
              'reminderType': 'starting_soon',
            });

            print(
                'Sent tour starting soon notification for booking: ${booking.id}');
          }
        }
      }
    } catch (e) {
      print('Error checking tour reminders: $e');
    }
  }

  Future<void> _sendTourStartingSoonNotification(BookingModel booking) async {
    try {
      // Calculate time remaining
      final now = DateTime.now();
      final timeUntilTour = booking.tourStartDate.difference(now);
      final hours = timeUntilTour.inHours;
      final minutes = timeUntilTour.inMinutes.remainder(60);

      String timeRemaining;
      if (hours > 0) {
        timeRemaining =
            '$hours hour${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes minute${minutes > 1 ? 's' : ''}' : ''}';
      } else {
        timeRemaining = '$minutes minute${minutes > 1 ? 's' : ''}';
      }

      // Create and send notification
      final notification =
          _notificationService.createTourStartingSoonNotification(
        userId: booking.touristId,
        tourTitle: booking.tourTitle,
        timeRemaining: timeRemaining.trim(),
      );

      await _notificationService.createNotification(notification);
    } catch (e) {
      print('Error sending tour starting soon notification: $e');
    }
  }

  // Manual trigger for testing or admin purposes
  Future<void> triggerReminderCheck() async {
    await _checkAndSendReminders();
  }

  // Get reminder history for a user (for debugging/admin purposes)
  Future<List<Map<String, dynamic>>> getUserReminders(String userId) async {
    final snapshot = await _firestore
        .collection(_remindersCollection)
        .where('touristId', isEqualTo: userId)
        .orderBy('reminderSentAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Clean up old reminders (older than 30 days)
  Future<void> cleanupOldReminders() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final oldReminders = await _firestore
          .collection(_remindersCollection)
          .where('reminderSentAt', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldReminders.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('Cleaned up ${oldReminders.docs.length} old reminders');
    } catch (e) {
      print('Error cleaning up old reminders: $e');
    }
  }
}
