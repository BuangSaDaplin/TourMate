import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tourmate_app/models/user_model.dart';
import 'package:tourmate_app/services/notification_service.dart';

class UserProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Fetches the complete user profile data from Firestore
  Future<UserModel?> getCompleteUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        // Use the fromFirestore factory method
        return UserModel.fromFirestore(doc.data()!);
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  /// Returns a stream that watches for real-time updates to the user profile
  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!);
      }
      return null;
    });
  }

  /// Updates the active status of the user in Firestore
  Future<void> updateActiveStatus(String uid, int activeStatus) async {
    try {
      await _db.collection('users').doc(uid).update({
        'activeStatus': activeStatus,
      });
    } catch (e) {
      print('Error updating active status: $e');
      throw e;
    }
  }

  /// Updates the user profile and sends a notification
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      await _db.collection('users').doc(uid).update(updates);

      // Send profile updated notification
      final notification =
          _notificationService.createProfileUpdatedNotification(
        userId: uid,
      );
      await _notificationService.createNotification(notification);
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  /// Changes the user password and sends a notification
  Future<void> changePassword(String uid) async {
    try {
      // Note: Password change is handled by Firebase Auth, this is just for notification
      // The actual password change should be done in FirebaseAuthService

      // Send password changed notification
      final notification =
          _notificationService.createPasswordChangedNotification(
        userId: uid,
      );
      await _notificationService.createNotification(notification);
    } catch (e) {
      print('Error changing password: $e');
      throw e;
    }
  }
}
